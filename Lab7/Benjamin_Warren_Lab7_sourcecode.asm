
;***********************************************************
;*
;*	This is the TRANSMIT file for Lab 7 of ECE 375
;*
;*  	Rock Paper Scissors
;* 	Requirement:
;* 	1. USART1 communication
;* 	2. Timer/counter1 Normal mode to create a 1.5-sec delay
;***********************************************************
;*
;*	 Author: Benjamin Warren
;*	   Date: 11/18/2022
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	Tx = 2					; PORTD2 Input Bit
.equ	Rx = 3					; PORTD3 Input Bit
.equ	Begin = 7				; Button 7 Input Bit

; Use this signal code between two boards for their game ready
.equ    SendReady = 0b11111111

;***********************************************************
;*  Start of Code Segment
;***********************************************************
.cseg                           ; Beginning of code segment

;***********************************************************
;*  Interrupt Vectors
;***********************************************************
.org    $0000                   ; Beginning of IVs
	    rjmp    INIT            	; Reset interrupt
.org	$0032
		rjmp	Receive			; Receive complete

.org    $0056                   ; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
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
	;USART1
		ldi		mpr, 0b00100010 ; Set double data rate
		sts		UCSR1A, mpr
	;Set baudrate at 2400bps
		ldi		mpr, high(416) ; Load high byte of 416
		sts		UBRR1H, mpr ; UBRR0H in extended I/O space
		ldi		mpr, low(416) ; Load low byte of 416
		sts		UBRR1L, mpr ;
	;Enable receiver and transmitter
		ldi		mpr, 0b10011000
		sts		UCSR1B, mpr ;
	;Set frame format: 8 data bits, 2 stop bits
		ldi		mpr, 0b00001110
		sts		UCSR1C, mpr ; UCSR0C in extended I/O space

	;TIMER/COUNTER1
		;Set Normal mode
		ldi 	mpr, 0b10000000  ; Activate normal mode
		sts 	TCCR1A, mpr ;
		ldi 	mpr, 0b00000101  ; Set prescaler to 1024
		sts 	TCCR1B, mpr ;

		rcall	LCDInit			 ; LCD initialization
		
		rcall	LCDBacklightOn

		rcall	ClearLCD

		; Other
		; Turn on interrupts
		sei

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
		ldi		XL, low(ReceiveData)
		ldi		XH, high(ReceiveData)
		ldi		mpr, 0
		st		X, mpr
		in		mpr, PIND
		andi	mpr, (1<<Begin)|(1<<Tx)|(1<<Rx)	; Decode input
		cpi		mpr, (1<<Tx)|(1<<Rx)			; Check for Button 7 input
		brne	MAIN							; No button 7 input, continue program
		rcall	Transmit						; Call subroutine Transmit

WaitForComm:
		ldi		XL, low(ReceiveData)
		ldi		XH, high(ReceiveData)
		ld		mpr, X
		cpi		mpr, SendReady					; Loop until RXC1 is set		breq	WaitForComm						; Write game start to screen
		rcall	LCDClr

		ldi		ZL, low(STRING5<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING5<<1)			; The LSB of that pointer
		ldi		olcnt, 10						; Load loop counter to write String 3

		rcall	WrLn1

		; Subroutine to wait for 500 ms
		WAIT_05msec:
			LDI		olcnt, 50 ; Load loop count = 50
		WAIT_10msec:
			LDI		ilcnt, 178 ; (Re)load value for delay
			sts		OCR1AL, ilcnt
		; Wait for TCNT0 to roll over
		CHECK:
			SBIS	TIFR1, TOV1
			RJMP	CHECK
			LDI		ilcnt, 0b00000001 ; Otherwise, Reset TOV1
			OUT		TIFR, ilcnt ; Note - write 1 to reset
			DEC		olcnt ; Decrement count

		rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************
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

		ldi		XL, $00							; Load low memory location of Line 1 of LCD
		ldi		XH, $01							; Load high memory location of Line 1 of LCD

Wrloop1:	
		lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	Wrloop1							; Continue writing until nothing left to write

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
				
		ldi		YL, $10							; Load low memory location of Line 2 of LCD
		ldi		YH, $01							; Load high memory location of Line 2 of LCD

Wrloop2:	
		lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter						
		brne	Wrloop2							; Continue writing until nothing left to write
		
		; Display the strings on the LCD Display
		rcall	LCDWrLn2						; Write to LCD

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
; Func: ClearLCD
; Desc: Begins program, called to display intro 
;-----------------------------------------------------------
ClearLCD:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	olcnt			; Save wait register
		push	mpr				;
		push	ZL
		push	ZH
		
		rcall	LCDClr

		ldi		ZL, low(STRING1<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING1<<1)			; The LSB of that pointer
		ldi		olcnt, 8						; Load loop counter to write String 1
		rcall	WrLn1
		
		ldi		ZL, low(STRING2<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING2<<1)			; The LSB of that pointer
		ldi		olcnt, 16						; Load loop counter to write String 2
		rcall	WrLn2

		pop		ZH
		pop		ZL
		pop		mpr			; Restore program state
		pop		olcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; End a function with RET

;-----------------------------------------------------------
; Func: Transmit
; Desc: Begins Transmission
;-----------------------------------------------------------
Transmit:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	olcnt			; Save wait register
		push	ZL
		push	ZH
		
USART_Transmit:								; Transmit Ready
		lds		mpr, UCSR1A
		sbrs	mpr, UDRE1						; Loop until UDR1 is empty
		rjmp	USART_Transmit
		ldi		mpr, SendReady
		sts		UDR1, mpr

		; Write ready to screen
		ldi		ZL, low(STRING3<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING3<<1)			; The LSB of that pointer
		ldi		olcnt, 14						; Load loop counter to write String 3
		rcall	WrLn1
		
		ldi		ZL, low(STRING4<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING4<<1)			; The LSB of that pointer
		ldi		olcnt, 16						; Load loop counter to write String 4
		rcall	WrLn2
		
		pop		ZH
		pop		ZL
		pop		olcnt		; Restore wait register
		pop		mpr			; Restore mpr
		ret					; End a function with RET

;-----------------------------------------------------------
; Func: Receive
; Desc: Begins Transmission
;-----------------------------------------------------------
Receive:							
		; Save variables by pushing them to the stack
		; Execute the function here
		push	mpr				; Save mpr register
		push	XL
		push	XH

		lds		mpr, UDR1
		ldi		XL, low(ReceiveData)
		ldi		XH, high(ReceiveData)
		st		X, mpr

		pop		XH
		pop		XL
		pop		mpr			; Restore mpr
		ret					; End a function with RET

;***********************************************************
;*	Stored Program Data
;***********************************************************
STRING1:
    .DB		"Welcome!"		; Declaring data in ProgMem
STRING2:
    .DB		"Please press PD7"		; Declaring data in ProgMem
STRING3:
    .DB		"Ready. Waiting"		; Declaring data in ProgMem
STRING4:
    .DB		"for the opponent"		; Declaring data in ProgMem
STRING5:
    .DB		"Game start"		; Declaring data in ProgMem
STRING6:
    .DB		"Rock"		; Declaring data in ProgMem
STRING7:
    .DB		"Paper "		; Declaring data in ProgMem
STRING8:
    .DB		"Scissors"		; Declaring data in ProgMem
STRING9:
    .DB		"You Won!"		; Declaring data in ProgMem
STRING10:
    .DB		"You Lost"		; Declaring data in ProgMem

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0999				; data memory allocation
ReceiveData:
	.byte 1					; allocate 1 byte for speed counter decimal value 0-15

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver

