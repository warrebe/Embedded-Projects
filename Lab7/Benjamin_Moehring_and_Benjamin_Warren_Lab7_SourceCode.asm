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
;*	 Author: Benjamin Warren and Benjamin Moehring
;*	   Date: 11/18/2022
;*
;***********************************************************

.include "m32U4def.inc"         ; Include definition file

;***********************************************************
;*  Internal Register Definitions and Constants
;***********************************************************
.def    mpr = r16               ; Multi-Purpose Register
.def	waitcnt = r17			; Wait loop counter
.def	ilcnt = r18				; Inner loop counter
.def	olcnt = r19				; outer loop counter
.def	Ready1 = r0				;
.def	Ready2 = r1				;

.equ	Tx = 2
.equ	Rx = 3
.equ	Start = 7				; PD7 Input

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
	    rjmp    INIT            ; Reset interrupt

.org	$0032					
		rjmp	Receive			; Receive Interrupt

.org    $0056                   ; End of Interrupt Vectors

;***********************************************************
;*  Program Initialization
;***********************************************************
INIT:
	;Stack Pointer (VERY IMPORTANT!!!!)
ldi mpr, high(RAMEND)
out SPH, mpr
ldi mpr, low(RAMEND)
out SPL, mpr

	;I/O Ports
ldi		mpr, $00		; Set Port D Data Direction Register
out		DDRD, mpr		; for input
ldi		mpr, $FF		; Initialize Port D Data Register
out		PORTD, mpr		; so all Port D inputs are Tri-State

ldi		mpr, $FF		; Set Port B Data Direction Register
out		DDRB, mpr		; for output
ldi		mpr, $00		; Initialize Port B Data Register
out		PORTB, mpr		; so all Port B outputs are low

	;USART1
ldi		mpr, 0b00100010	; Set double data rate
sts		UCSR1A, mpr		; 

		;Set baudrate at 2400bps
ldi		mpr, high(416)	; Load high byte of 416
sts		UBRR1H, mpr		; UBRR0H extended I/O
ldi		mpr, low(416)	; Load low byte of 416
sts		UBRR1L, mpr	; 

		;Enable receiver and transmitter
ldi		mpr, 0b10011000	;
sts		UCSR1B, mpr		;

		;Set frame format: 8 data bits, 2 stop bits
ldi		mpr, 0b00001110	;
sts		UCSR1C, mpr		; UCSR0C extended I/O

	;TIMER/COUNTER1 Set Normal mode
ldi		mpr, 0b00000000	; Normal mode
sts		TCCR1A, mpr		;
ldi		mpr, 0b00000001	; Prescalar 1
sts		TCCR1B, mpr		;

	;Other
rcall	LCDInit			; Initialize LCD
rcall	ClearLCD		; Clear LCD screen

sei						; Turn on Interrupts

;***********************************************************
;*  Main Program
;***********************************************************
MAIN:
	rcall	LCDBacklightOn	; Backlight for visibility
	
	in		mpr, PIND				; Input from PIND
	andi	mpr, (1<<Start)|(1<<Tx)|(1<<Rx)	; Decode Input
	cpi		mpr, (1<<Tx)|(1<<Rx)	; Check for PD7 Input
	brne	MAIN					; If no input, continue

	rcall	Transmit				; Call Transmit Subroutine

WaitForComm:
	ldi		mpr, 0b11111111			; Checks for both boards ready
	and		mpr, Ready1				;
	and		mpr, Ready2				;
	cpi		mpr, 0b11111111			;
	brne	WaitForComm				;

	rcall	LCDclr
	; "Game Start"
	ldi     XL, low(CounterRPS)
    ldi     XH, high(CounterRPS)
    ldi     mpr, 1
	st      X, mpr
	ldi		ZL, low(STRING5<<1)		; 
	ldi		ZH, high(STRING5<<1)	; 
	ldi		olcnt, 10				; 
	rcall	WL1						; Write line 1

	; LED Counter
	rcall GameStart					; Start Game Loops

rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func:	GameStart
; Desc:	Starts the game loop
;-----------------------------------------------------------

GameStart:
	; Save variables by pushing them to the stack
	push mpr
	push XH
	push XL

	ldi		XL, low(LEDCounter)
	ldi		XH, high(LEDCounter)
	ldi		mpr, 4
	st		X, mpr
TimerLoop:
	rcall 	LEDChange		; Call LEDChange subroutine
	rcall 	WAIT_1_5msec		; Call WAIT_05msec subroutine
	dec		mpr
	rjmp 	TimerLoop		; Loop 4 times
END:
	
	; Restore variables by popping from stack in reverse order
	pop XL
	pop XH
	pop mpr

	ret						; End Function

;-----------------------------------------------------------
; Func:	LEDChange
; Desc:	Changes LEDs corresponding to time left to choose
;-----------------------------------------------------------

LEDChange:
	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push XH
	push XL

    ldi		XL, low(LEDCounter)
    ldi     XH, high(LEDCounter)
    ld      mpr, X
    cpi     mpr, 4
    brne    OP2
    ldi     ilcnt, 0b11110000
    out     PORTB, ilcnt
    rjmp    LAST
    OP2:
        cpi		mpr, 3
        brne    OP3
        ldi     ilcnt, 0b11100000
        out     PORTB, ilcnt
        rjmp    LAST
    OP3:
        cpi     mpr, 2
        brne    OP4
        ldi     ilcnt, 0b11000000
        out     PORTB, ilcnt
        rjmp    LAST
    OP4:
        cpi     mpr, 1
        brne    OP5
        ldi     ilcnt, 0b10000000
        out     PORTB, ilcnt
        rjmp    LAST
    OP5:
        cpi     mpr, 0
        brne    LAST
        ldi     ilcnt, 0
        out     PORTB, ilcnt
    LAST:
        dec     mpr
        st      X, mpr
	
	; Restore variables by popping from stack in reverse order
	pop XL
	pop XH
	pop olcnt
	pop mpr

	ret										; End Function

;-----------------------------------------------------------
; Func:	WAIT_05msec
; Desc:	Wait function for LEDs
;-----------------------------------------------------------

WAIT_1_5msec:
	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push ilcnt

	ldi		olcnt, 150			; Load loop count = 150
WAIT_10msec:
	in		mpr, PIND			; Input from PIND
	andi	mpr, (1<<4)			; Decode Input
	cpi		mpr, 0				; Check for PD7 Input
	brne	Cont					; If no input, continue
	rcall	RPSChoice
Cont:
	ldi		ilcnt, 178			; (Re)load value for delay
	sts		TCNT1L, ilcnt
	; Wait for TCNT1 to roll over
CHECK1:
	sbis	TIFR1, TOV1
	rjmp	CHECK1
	ldi		ilcnt, 0b00000001	; Otherwise, Reset TOV1
	out		TIFR1, ilcnt		; Note - write 1 to reset
	dec		olcnt				; Decrement count
	brne	WAIT_10msec

	; Restore variables by popping from stack in reverse order
	pop ilcnt
	pop olcnt
	pop mpr

	ret							; End Function

;-----------------------------------------------------------
; Func:	WL1
; Desc:	Writes STRING to LCD line 1
;-----------------------------------------------------------
WL1:

	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push XH
	push XL
	push YH
	push YL
	push ZH
	push ZL

	rcall	LCDClrLn1		; Clear first line of LCD

	ldi		XL, $00			; Load low memory loaction of Line 1
	ldi		XH, $01			; Load high memory loaction of Line 1

WRLOOP1:
	lpm		mpr, Z+			; Read byte from address Z into mpr post increment
	st		X+, mpr			; Store byte from memory into LCD, increment to next
	dec		olcnt			; Decrement counter
	brne	WRLOOP1			; 

	rcall	LCDWrLn1		; Write to first line of LCD

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop XL
	pop XH
	pop olcnt
	pop mpr

	ret						; End function

;-----------------------------------------------------------
; Func:	WL2
; Desc:	Writes STRING to LCD line 2
;-----------------------------------------------------------
WL2:

	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push XH
	push XL
	push YH
	push YL
	push ZH
	push ZL

	rcall	LCDClrLn2		; Clear second line of LCD

	ldi		YL, $10			; Load low memory loaction of Line 2
	ldi		YH, $01			; Load high memory loaction of Line 2

WRLOOP2:
	lpm		mpr, Z+			; Read byte from address Z into mpr post increment
	st		Y+, mpr			; Store byte from memory into LCD, increment to next
	dec		olcnt			; Decrement counter
	brne	WRLOOP2			; 

	rcall	LCDWrLn2		; Write to second line of LCD

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop XL
	pop XH
	pop olcnt
	pop mpr

	ret						; End function

;-----------------------------------------------------------
; Func:	ClearLCD
; Desc:	Clears LCD, beginning program
;-----------------------------------------------------------
ClearLCD: 
	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push ZH
	push ZL

	rcall	LCDClr				; Clear LCD
	
	; "Welcome!"
	ldi		ZL, low(STRING1<<1)	; 
	ldi		ZH, high(STRING1<<1); 
	ldi		olcnt, 8			; 
	rcall	WL1					; Write line 1

	; "Please Press PD7"
	ldi		ZL, low(STRING2<<1)	; 
	ldi		ZH, high(STRING2<<1);
	ldi		olcnt, 16			;
	rcall	WL2					; Write line 2

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop olcnt
	pop mpr

	ret							; End function

;-----------------------------------------------------------
; Func:	Transmit
; Desc:	Begins Transmission
;-----------------------------------------------------------
Transmit:
	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push ZH
	push ZL

USART_T:
	lds		mpr, UCSR1A			; Load UCSR1A into mpr
	sbrs	mpr, 5				; Stop loop when UCSR1A bit 5 is set
	rjmp	USART_T				;
	
	; Confirmation
	ldi		mpr, SendReady		; Load SendReady (0b11111111) into mpr
	sts		UDR1, mpr			; Store SendReady in UDR1
	mov		Ready1, mpr			; Copy to Ready1 state as SendReady

	rcall LCDClr				; Clear LCD

	; "Ready. Waiting"
	ldi		ZL, low(STRING3<<1)	;
	ldi		ZH, high(STRING3<<1);
	ldi		olcnt, 14			;
	rcall	WL1					; Write line 1

	; "For The Opponent"
	ldi		ZL, low(STRING4<<1)	;
	ldi		ZH, high(STRING4<<1);
	ldi		olcnt, 16			;
	rcall	WL2					; Write line 2

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop olcnt
	pop mpr

	ret

;-----------------------------------------------------------
; Func:	Receive
; Desc:	Begins Receiving
;-----------------------------------------------------------
Receive:
	; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push XH
	push XL
	push ZH
	push ZL

USART_R:
	; Confirmation
	lds		mpr, UDR1			; Load SendReady confirmation from UDR1 into mpr
	mov		Ready2, mpr			; Copy to Ready2 state as SendReady

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop XL
	pop XH
	pop olcnt
	pop mpr

	ret							; End function

;-----------------------------------------------------------
; Func:	RPSChoice
; Desc:	Allows PD4 input for cycling RPS choices
;-----------------------------------------------------------
RPSChoice:
	; Save variables by pushing them to the stack
	push mpr
	push XH
	push XL
	push ilcnt
	push olcnt

CHOOSELOOP:
;	in		mpr, PIND				; Input from PIND
;	andi	mpr, (1<<4)	; Decode Input
;	cpi		mpr, 0		; Check for PD4 Input
;	breq	CHOOSELOOP

	ldi     XL, low(CounterRPS)
    ldi     XH, high(CounterRPS)
    ld      mpr, X
	inc		mpr
    cpi     mpr, 4
    brne    SKIP
    ldi     mpr, 1
SKIP:    
	st		X, mpr
	rcall   WriteRPS
	ldi		olcnt, 30			; Load loop count = 150
WAIT_10msec1:
	ldi		ilcnt, 178			; (Re)load value for delay
	sts		TCNT1L, ilcnt
	; Wait for TCNT1 to roll over
CHECK:
	sbis	TIFR1, TOV1
	rjmp	CHECK
	ldi		ilcnt, 0b00000001	; Otherwise, Reset TOV1
	out		TIFR1, ilcnt		; Note - write 1 to reset
	dec		olcnt				; Decrement count
	brne	WAIT_10msec1

	; Restore variables by popping from stack in reverse order
	pop olcnt
	pop ilcnt
	pop XL
	pop XH
	pop mpr

	ret							; End Function

;-----------------------------------------------------------
; Func:	WriteRPS
; Desc:	Writes current RPS choice to LCD 2nd row
;-----------------------------------------------------------
WriteRPS:
		; Save variables by pushing them to the stack
	push mpr
	push olcnt
	push XH
	push XL
	push YH
	push YL
	push ZH
	push ZL

	ldi     XL, low(CounterRPS)
    ldi     XH, high(CounterRPS)
	ld      mpr, X
	
	; is Scissors?
    cpi     mpr, 3
	brne	NEXTCHOICE1

	; "Scissors"
	ldi		ZL, low(STRING8<<1)		; 
	ldi		ZH, high(STRING8<<1)	; 
	ldi		olcnt, 8				; 
	rjmp	RPSWRITEOUT				;

NEXTCHOICE1:
	; is Paper?
    cpi     mpr, 2
	brne	NEXTCHOICE2

	; "Paper "
	ldi		ZL, low(STRING7<<1)		; 
	ldi		ZH, high(STRING7<<1)	; 
	ldi		olcnt, 6				;
	rjmp	RPSWRITEOUT 

NEXTCHOICE2:
	; is Rock?
    cpi     mpr, 1
	brne	RPSWRITEOUT

	; "Rock"
	ldi		ZL, low(STRING6<<1)		; 
	ldi		ZH, high(STRING6<<1)	; 
	ldi		olcnt, 4				; 

RPSWRITEOUT:
	rcall	LCDClrLn2		; Clear second line of LCD

	ldi		YL, $10			; Load low memory loaction of Line 2
	ldi		YH, $01			; Load high memory loaction of Line 2

RPSLOOP1:
	lpm		mpr, Z+			; Read byte from address Z into mpr post increment
	st		Y+, mpr			; Store byte from memory into LCD, increment to next
	dec		olcnt			; Decrement counter
	brne	RPSLOOP1		; 

	rcall	LCDWrLn2		; Write to second line of LCD

	; Restore variables by popping from stack in reverse order
	pop ZL
	pop ZH
	pop YL
	pop YH
	pop XL
	pop XH
	pop olcnt
	pop mpr

	ret						; End Function

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; Strings
;-----------------------------------------------------------
STRING1:
    .DB		"Welcome!"			; Declaring String 1 data in ProgMem
STRING2:
	.DB		"Please press PD7"	; Declaring String 2 data in ProgMem
STRING3:
	.DB		"Ready. Waiting"	; Declaring String 3 data in ProgMem
STRING4:
	.DB		"For The Opponent"	; Declaring String 4 data in ProgMem
STRING5:
	.DB		"Game Start"		; Declaring String 5 data in ProgMem
STRING6:
	.DB		"Rock"				; Declaring String 6 data in ProgMem
STRING7:
	.DB		"Paper "			; Declaring String 7 data in ProgMem
STRING8:
	.DB		"Scissors"			; Declaring String 8 data in ProgMem
STRING9:
	.DB		"You Won!"			; Declaring String 9 data in ProgMem
STRING10:
	.DB		"You Lost"			; Declaring String 10 data in ProgMem
STRING11:
	.DB		"Draw"				; Declaring String 11 data in ProgMem

;------------------------------------------------------------
;    Data Memory Allocation
;------------------------------------------------------------
.dseg
.org	$0999				; data memory allocation
CounterRPS:
    .byte 1					; allocate 1 byte for CounterRPS
LEDCounter:
	.byte 1					; allocate 1 byte of LEDCounter

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver












