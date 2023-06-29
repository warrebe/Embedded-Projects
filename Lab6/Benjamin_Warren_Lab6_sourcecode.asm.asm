;***********************************************************
;*
;*	Source Code for lab 6 of ECE 375
;*
;*	 Author: Benjamin Warren
;*	   Date: 11/11/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 10		; Time to wait in wait loop
.equ	step = 17

.equ	EngEnR = 5				; right Engine Enable Bit
.equ	EngEnL = 6				; left Engine Enable Bit
.equ	EngDirR = 4				; right Engine Direction Bit
.equ	EngDirL = 7				; left Engine Direction Bit

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00						; Move Backward Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org	$0002					
		rcall Increase				; PD4 interrupt
		reti

.org	$0004
		rcall Decrease				; PD5 interrupt
		reti

.org	$0008
		rcall MaxSpeed					; PD6 interrupt
		reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
		; Initialize the Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr	

		; Configure I/O ports
		; Initialize Port B for output
		ldi		mpr, $FF		; Set Port B Data Direction Register
		out		DDRB, mpr		; for output
		ldi		mpr, $00		; Initialize Port B Data Register
		out		PORTB, mpr		; so all Port B outputs are low
		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State

		; Configure External Interrupts
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC31)|(0<<ISC30)
		sts		EICRA, mpr

		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIMSK, mpr

		; Configure 16-bit Timer/Counter 1A and 1B
		; Fast PWM, 8-bit mode, no prescaling
		ldi 	mpr, 0b10100001  ; Activate pwm mode
		sts 	TCCR1A, mpr ;
		ldi 	mpr, 0b00001001  ; Set prescaler to 1
		sts 	TCCR1B, mpr ;

		; Set TekBot to Move Forward (1<<EngDirR|1<<EngDirL) on Port B
		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		; Set initial speed, display on Port B pins 3:0
		rcall	MinSpeed

		; Enable global interrupts (if any are used)
		sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		rjmp	MAIN			; return to top of MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
;----------------------------------------------------------------
; Sub:	Increase
; Desc:	Increases the PWM Duty Cycle to increase tekbot speed
;		Effectively increasing the brightness of PORTB LEDs
;----------------------------------------------------------------
Increase:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH

		; Increment PWM duty cycle
		lds		mpr, OCR1AL
		cpi 	mpr, 255
		breq	SKIP		; Already at max speed
		ldi		ilcnt, 17
		add		mpr, ilcnt
		sts		OCR1AL, mpr 
		lds		mpr, OCR1BL
		ldi		ilcnt, 17
		add		mpr, ilcnt
		sts		OCR1BL, mpr 
		
		ori		mpr, MovFwd
		out		PORTB, mpr
SKIP:		
		ldi		waitcnt, WTime	; Wait for .2 second
		rcall	Wait			; Call wait function

		;Prohibit Queueing 
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; Return from subroutine

;----------------------------------------------------------------
; Sub:	Decrease
; Desc:	Increases the PWM Duty Cycle to decrease tekbot speed
;		Effectively decreasing the brightness of PORTB LEDs
;----------------------------------------------------------------
Decrease:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH

		
		; Decrement PWN duty cycle
		lds		mpr, OCR1AL
		cpi 	mpr, 0
		breq	SKIP1		; Already at min speed
		ldi		ilcnt, 17
		sub		mpr, ilcnt
		sts		OCR1AL, mpr 
		lds		mpr, OCR1BL
		ldi		ilcnt, 17
		sub		mpr, ilcnt
		sts		OCR1BL, mpr 
		
		ori		mpr, MovFwd
		out		PORTB, mpr

SKIP1:		
		ldi		waitcnt, WTime	; Wait for .2 second
		rcall	Wait			; Call wait function

		;Prohibit Queueing 
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; Return from subroutine

;-----------------------------------------------------------
; Func: MaxSpeed
; Desc: Initializes LCD Display as well as PWM Duty 
;		Cycle and displays it to LCD, also used to 
;		set speed to max
;-----------------------------------------------------------
MaxSpeed:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH
		
		ldi		mpr, $FF
		sts		OCR1BH, mpr
		sts		OCR1AH, mpr
		ldi		mpr, $FF
		sts		OCR1BL, mpr	
		sts		OCR1AL, mpr	
		
		ori		mpr, MovFwd
		out		PORTB, mpr

		ldi		XL, low(SpeedLevel)
		ldi		XH, high(SpeedLevel)
		ldi		mpr, 15
		st		X, mpr


		ldi		waitcnt, WTime	; Wait for .2 second
		rcall	Wait			; Call wait function

		;Avoid Queueing
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; End a function with RET

;-----------------------------------------------------------
; Func: MinSpeed
; Desc: Initializes LCD Display as well as PWM Duty 
;		Cycle and displays it to LCD, also used to 
;		set speed to min
;-----------------------------------------------------------
MinSpeed:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH

		ldi		mpr, $FF
		sts		OCR1BH, mpr
		sts		OCR1AH, mpr
		ldi		mpr, $00
		sts		OCR1BL, mpr	
		sts		OCR1AL, mpr	
		
		ori		mpr, MovFwd
		out		PORTB, mpr

		ldi		XL, low(SpeedLevel)
		ldi		XH, high(SpeedLevel)
		ldi		mpr, 0
		st		X, mpr	

		ldi		waitcnt, WTime	; Wait for .2 second
		rcall	Wait			; Call wait function

		;Avoid Queueing
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret						; End a function with RET

;----------------------------------------------------------------
; Sub:	Wait
; Desc:	A wait loop that is 16 + 159975*waitcnt cycles or roughly
;		waitcnt*10ms.  Just initialize wait for the specific amount
;		of time in 10ms intervals. Here is the general eqaution
;		for the number of clock cycles in the wait loop:
;			(((((3*ilcnt)-1+4)*olcnt)-1+4)*waitcnt)-1+16
;----------------------------------------------------------------
Wait:
		push	waitcnt			; Save wait register
		push	ilcnt			; Save ilcnt register
		push	olcnt			; Save olcnt register

Loop:	ldi		olcnt, 224		; load olcnt register
OLoop:	ldi		ilcnt, 237		; load ilcnt register
ILoop:	dec		ilcnt			; decrement ilcnt
		brne	ILoop			; Continue Inner Loop
		dec		olcnt		; decrement olcnt
		brne	OLoop			; Continue Outer Loop
		dec		waitcnt		; Decrement wait
		brne	Loop			; Continue Wait loop

		pop		olcnt		; Restore olcnt register
		pop		ilcnt		; Restore ilcnt register
		pop		waitcnt		; Restore wait register
		ret				; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************
STRING1:
.DB		"Speed level:  "			; Declaring data in ProgMem

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0999				; data memory allocation
SpeedLevel:
	.byte 1					; allocate 1 byte for speed counter decimal value 0-15
TCNT1:
	.byte 2					; allocate 2 bytes for speed write/read

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
