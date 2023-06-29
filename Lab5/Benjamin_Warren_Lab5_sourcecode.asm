;***********************************************************
;*	This is the skeleton file for Lab 5 of ECE 375
;*
;*	 Author: Benjamin Warren
;*	   Date: 11/4/2022
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multi-Purpose Register
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 10		; Time to wait in wait loop

.equ	WskrR = 4				; Right Whisker Input Bit
.equ	WskrL = 5				; Left Whisker Input Bit
.equ	Clear = 6				; Clear Whisker Input Bit
.equ	EngEnR = 5				; Right Engine Enable Bit
.equ	EngEnL = 6				; Left Engine Enable Bit
.equ	EngDirR = 4				; Right Engine Direction Bit
.equ	EngDirL = 7				; Left Engine Direction Bit


;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////

.equ	MovFwd = (1<<EngDirR|1<<EngDirL)	; Move Forward Command
.equ	MovBck = $00						; Move Backward Command
.equ	TurnR = (1<<EngDirL)				; Turn Right Command
.equ	TurnL = (1<<EngDirR)				; Turn Left Command
.equ	Halt = (1<<EngEnR|1<<EngEnL)		; Halt Command

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

		; Set up interrupt vectors for any interrupts being used
.org	$0002					
	rcall HitRight				; PD4 interrupt
	reti

.org	$0004
	rcall HitLeft				; PD5 interrupt
	reti

.org	$0008
	rcall ClearLCD				; PD6 interrupt
	reti

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:	; The initialization routine
		ldi		mpr, low(RAMEND)
		out		SPL, mpr		; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr		; Load SPH with high byte of RAMEND

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
		
		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		rcall	LCDInit
		
		rcall	LCDClr

		rcall	ClearLCD

		; Initialize external interrupt
		; Set the Interrupt Sense Control to falling edge
		ldi		mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10)|(1<<ISC21)|(0<<ISC20)|(1<<ISC31)|(0<<ISC30)
		sts		EICRA, mpr

		; Configure the External Interrupt Mask
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIMSK, mpr

		; Turn on interrupts
		sei
			; NOTE: This must be the last thing to do in the INIT function

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		rcall	LCDBacklightOn	; Turn on LCD backlight, so stuff can be seen :)

		; Initialize TekBot Forward Movement
		ldi		mpr, MovFwd		; Load Move Forward Command
		out		PORTB, mpr		; Send command to motors

		rjmp	MAIN			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
;	You will probably want several functions, one to handle the
;	left whisker interrupt, one to handle the right whisker
;	interrupt, and maybe a wait function
;------------------------------------------------------------

;----------------------------------------------------------------
; Sub:	HitRight
; Desc:	Handles functionality of the TekBot when the right whisker
;		is triggered.
;----------------------------------------------------------------
HitRight:
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH

		; Move Backwards for a second
		ldi		mpr, MovBck		; Load Move Backward command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn left for a second
		ldi		mpr, TurnL		; Load Turn Left Command
		out		PORTB, mpr		; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd		; Load Move Forward command
		out		PORTB, mpr		; Send command to port

		ldi		XL, low(RightCounter)
		ldi		XH, high(RightCounter)
		ld		mpr, X
		inc		mpr
		mov		ilcnt, mpr
		rcall	Bin2ASCII

		rcall	WrLn1

		st		X, ilcnt

		
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
; Sub:	HitLeft
; Desc:	Handles functionality of the TekBot when the left whisker
;		is triggered.
;----------------------------------------------------------------
HitLeft:
		push	mpr			; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG	; Save program state
		push	mpr			;
		push	XL
		push	XH

		; Move Backwards for a second
		ldi		mpr, MovBck	; Load Move Backward command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Turn right for a second
		ldi		mpr, TurnR	; Load Turn Left Command
		out		PORTB, mpr	; Send command to port
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function

		; Move Forward again
		ldi		mpr, MovFwd	; Load Move Forward command
		out		PORTB, mpr	; Send command to port
		
		ldi		XL, low(LeftCounter)
		ldi		XH, high(LeftCounter)
		ld		mpr, X
		inc		mpr
		mov		ilcnt, mpr
		rcall	Bin2ASCII

		rcall	WrLn2

		st		X, ilcnt
		
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr
		
		pop		XH
		pop		XL
		pop		mpr		; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr		; Restore mpr
		ret				; Return from subroutine

;-----------------------------------------------------------
; Func: ClearLCD
; Desc: Clears any data currently on LCD, called when pd4 is 
;		triggered
;-----------------------------------------------------------
ClearLCD:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	waitcnt			; Save wait register
		in		mpr, SREG		; Save program state
		push	mpr				;
		push	XL
		push	XH

		ldi		XL, low(RightCounter)
		ldi		XH, high(RightCounter)
		ldi		mpr, 0
		st		X, mpr	
		
		ldi		XL, low(LeftCounter)
		ldi		XH, high(LeftCounter)
		ldi		mpr, 0
		st		X, mpr	

		ldi		XL, low(RightCounter)
		ldi		XH, high(RightCounter)
		ld		mpr, X
		mov		ilcnt, mpr
		rcall	Bin2ASCII

		rcall	WrLn1

		st		X, ilcnt

		ldi		XL, low(LeftCounter)
		ldi		XH, high(LeftCounter)
		ld		mpr, X
		mov		ilcnt, mpr
		rcall	Bin2ASCII

		rcall	WrLn2

		st		X, ilcnt
		
		ldi		mpr, (1<<INT0)|(1<<INT1)|(1<<INT3)
		out		EIFR, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore program state
		out		SREG, mpr	;
		pop		waitcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: WrLn1
; Desc: Reads data in from program memory stored STRING1
;		and writes it to the LCD display line 1
;-----------------------------------------------------------
WrLn1:	; Begin a function with a label
		; Save variables by pushing them to the stack
		
		push	mpr
		push	olcnt
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL

		rcall	LCDClrLn1

		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING1<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING1<<1)			; The LSB of that pointer
				
		ldi		XL, $00							; Load low memory location of Line 1 of LCD
		ldi		XH, $01							; Load high memory location of Line 1 of LCD

		ldi		olcnt, 11						; Load loop counter to write String 1
Wrloop1:	
		lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	Wrloop1							; Continue writing until nothing left to write

		ldi		ZL, low(RightCounter)
		ldi		ZH, high(RIghtCounter)
Wrloop3:
		ld		mpr, Z+							; Read the byte at address in Z to the register R16
		st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		count
		brne	Wrloop3

		; Display the strings on the LCD Display
		rcall	LCDWrLn1		; Write to LCD

		; Restore variables by popping them from the stack,
		; in reverse order
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		olcnt
		pop		mpr

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: WrLn2
; Desc: Reads data in from program memory stored STRING2
;		and writes it to the LCD display line 2
;-----------------------------------------------------------
WrLn2:	; Begin a function with a label
		; Save variables by pushing them to the stack
		
		push	mpr
		push	olcnt
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL
		
		rcall LCDClrLn2

		; Execute the function here
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING2<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING2<<1)			; The LSB of that pointer
				
		ldi		YL, $10							; Load low memory location of Line 2 of LCD
		ldi		YH, $01							; Load high memory location of Line 2 of LCD

		ldi		olcnt, 11						; Load loop counter to write String 2
Wrloop2:	
		lpm		mpr, Z+						; Read the byte at address in Z to the register R16, the post-inc
		st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter						
		brne	Wrloop2							; Continue writing until nothing left to write
		
		ldi		ZL, low(LeftCounter)
		ldi		ZH, high(LeftCounter)
Wrloop4:
		ld		mpr, Z+							; Read the byte at address in Z to the register R16
		st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		count
		brne	Wrloop4

		; Display the strings on the LCD Display
		rcall	LCDWrLn2		; Write to LCD

		; Restore variables by popping them from the stack,
		; in reverse order
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		olcnt
		pop		mpr

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

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;		beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label

		; Save variable by pushing them to the stack

		; Execute the function here

		; Restore variable by popping them from the stack in reverse order

		ret						; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
STRING1:
.DB		"Right Hit:  "			; Declaring data in ProgMem
STRING2:
.DB		"Left Hit :  "			; Declaring data in ProgMem

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0999				; data memory allocation
RightCounter:
	.byte 2					; allocate 1 byte for number of right whisker hits
LeftCounter:
	.byte 2					; allocate 1 byte for number of left whisker hits



;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

