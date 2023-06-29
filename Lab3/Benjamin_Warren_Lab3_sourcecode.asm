;***********************************************************
;*	Lab 3 completed source code, prints two strings to LCD display
;*	on AVR board, using the 4 PORTD input buttons for different 
;*	functionality
;*
;*	 Author: Benjamin Warren
;*	   Date: 10/14/22
;*
;***********************************************************

.include "m32U4def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register is required for LCD Driver
.def	waitcnt = r17			; Wait Loop Counter
.def	ilcnt = r18				; Inner Loop Counter
.def	olcnt = r19				; Outer Loop Counter

.equ	WTime = 100				; Time to wait in wait loop

.equ	Clear	= 4				; Button 4 Input Bit
.equ	Wr		= 5				; Button 5 Input Bit
.equ	WrRev	= 6				; Button 6 Input Bit
.equ	WrScrl	= 7				; Button 7 Input Bit

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp INIT				; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:	; The initialization routine
		; Initialize Stack Pointer
		ldi		mpr, low(RAMEND)
		out		SPL, mpr									; Load SPL with low byte of RAMEND
		ldi		mpr, high(RAMEND)
		out		SPH, mpr									; Load SPH with high byte of RAMEND

		; Initialize LCD Display
		rcall	LCDInit

		; Initialize Port D for input
		ldi		mpr, $00		; Set Port D Data Direction Register
		out		DDRD, mpr		; for input
		ldi		mpr, $FF		; Initialize Port D Data Register
		out		PORTD, mpr		; so all Port D inputs are Tri-State
		; NOTE that there is no RET or RJMP from INIT,
		; this is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:							; The Main program
		rcall	LCDBacklightOn	; Turn on LCD backlight, so stuff can be seen :)

		in		mpr, PIND									; Get button input	
		andi	mpr, (1<<Clear|1<<Wr|1<<WrRev|1<<WrScrl)	; Decode input
		cpi		mpr, (1<<Wr|1<<WrRev|1<<WrScrl)				; Check for Button 4 input
		brne	NEXT										; Continue with next check
		rcall	ClearLCD									; Call the subroutine Clear
		rjmp	MAIN										; jump back to main

		NEXT:	cpi		mpr, (1<<Clear|1<<WrRev|1<<WrScrl)	; Check for Button 5 input
		brne	NEXT1										; No button 5 input, continue program
		rcall	Write										; Call subroutine Write
		rjmp	MAIN										; Continue through main

		NEXT1:	cpi		mpr, (1<<Wr|1<<Clear|1<<WrScrl)		; Check for Button 6 input
		brne	NEXT2										; No button 6 input, continue program
		rcall	WriteRev									; Call subroutine WriteRev
		rjmp	MAIN										; Continue through main

		NEXT2:	cpi		mpr, (1<<Wr|1<<Clear|1<<WrRev)		; Check for Button 7 input
		brne	MAIN										; No button 7 input, continue program
		rcall	WriteScroll									; Call subroutine WriteSroll
		rjmp	MAIN										; Continue through main

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ClearLCD
; Desc: Clears any data currently on LCD, called when pd4 is 
;		triggered
;-----------------------------------------------------------
ClearLCD:							
		; Save variables by pushing them to the stack
		; Execute the function here
		rcall	LCDClr			; Clear LCD

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Write
; Desc: Reads data in from program memory stored STRING1 and
;		STRING2 and writes them to the LCD displays lines 1 
;		and 2 respectively
;-----------------------------------------------------------
Write:	; Begin a function with a label
		; Save variables by pushing them to the stack
		
		push	mpr
		push	olcnt
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL

		; Execute the function here
		rcall	LCDClr							; Clears LCD
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING1<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING1<<1)			; The LSB of that pointer
				
		ldi		XL, $00							; Load low memory location of Line 1 of LCD
		ldi		XH, $01							; Load high memory location of Line 1 of LCD

		ldi		olcnt, 10						; Load loop counter to write String 1
Wrloop1:	lpm		mpr, Z+						; Read the byte at address in Z to the register R16, the post-inc
		st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	Wrloop1							; Continue writing until nothing left to write

		; Execute the function here
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING2<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING2<<1)			; The LSB of that pointer
				
		ldi		YL, $10							; Load low memory location of Line 2 of LCD
		ldi		YH, $01							; Load high memory location of Line 2 of LCD

		ldi		olcnt, 14						; Load loop counter to write String 2
Wrloop2:	lpm		mpr, Z+						; Read the byte at address in Z to the register R16, the post-inc
		st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter						
		brne	Wrloop2							; Continue writing until nothing left to write

		; Display the strings on the LCD Display
		rcall	LCDWrite		; Write to LCD

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
; Func: WriteRev
; Desc: Reads data in from program memory stored STRING2 and
;		STRING1 and writes them to the LCD displays lines 1 
;		and 2 respectively (opposite of Write)
;-----------------------------------------------------------
WriteRev:							; Begin a function with a label
		; Save variables by pushing them to the stack
		
		push	mpr
		push	olcnt
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL
		
		; Execute the function here
		rcall	LCDClr							; Clears LCD
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING2<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING2<<1)			; The LSB of that pointer
				
		ldi		XL, $00							; Load low memory location of Line 1 of LCD
		ldi		XH, $01							; Load high memory location of Line 1 of LCD

		ldi		olcnt, 14						; Load loop counter to write String 2
WrRev1:	lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc		
		st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	WrRev1							; Continue writing until nothing left to write

		; Execute the function here
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING1<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING1<<1)			; The LSB of that pointer
				
		ldi		YL, $10							; Load low memory location of Line 2 of LCD
		ldi		YH, $01							; Load high memory location of Line 2 of LCD

		ldi		olcnt, 10						; Load loop counter to write String 1
WrRev2:	lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	WrRev2							; Continue writing until nothing left to write

		; Display the strings on the LCD Display
		rcall	LCDWrite		; Write to LCD

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
; Func: WriteScroll
; Desc: Reads data in from program memory stored STRING1 and
;		STRING2 and writes them to the LCD displays lines 1 
;		and 2 respectively. Then, the routine loops but 
;		incrementing the starting location of the LCD address,
;		effectively causing a scrolling effect.
;-----------------------------------------------------------
WriteScroll:							; Begin a function with a label
		; Save variables by pushing them to the stack
		
		push	mpr
		push	olcnt
		push	XH
		push	XL
		push	YH
		push	YL
		push	ZH
		push	ZL

		ldi		ilcnt, 60		; Load loop counter for scoll loop
WrScrl1:	
		; Execute the function here
		rcall	LCDClr							; Clears LCD
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING1<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING1<<1)			; The LSB of that pointer
				
		ldi		XL, $00							; Load low memory location of Line 1 of LCD
		ldi		XH, $01							; Load high memory location of Line 1 of LCD
		
		ldi		r20, 60
		sub		r20, ilcnt						; Get number of scroll loops so far using difference
XChange:
		inc		XL								; Increment starting location based on scroll loop count
		dec		r20								; Dec loop counter
		brne	XChange							; Loop # of scroll times

		ldi		olcnt, 10
WrScl1:	lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		cpi		XL,	$20							; Compare XL lower pointer to max LCD mem location
		brne	XCont							; If XL doesn't point to memory location past max for LCD, skip next
		ldi		XL, $00							; Else adjust to beginning of LCD
XCont:	st		X+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	WrScl1							; Continue writing until nothing left to write

		; Execute the function here
		; Move strings from Program Memory to Data Memory
		ldi		ZL, low(STRING2<<1)				; The MSB of the pointer
		ldi		ZH, high(STRING2<<1)			; The LSB of that pointer
				
		ldi		YL, $10							; Load low memory location of Line 1 of LCD
		ldi		YH, $01							; Load high memory location of Line 1 of LCD
		
		ldi		r20, 60
		sub		r20, ilcnt						; Get number of scroll loops so far using difference
YChange:
		inc		YL								; Increment starting location based on scroll loop count
		dec		r20								; Dec loop counter
		brne	YChange							; Loop # of scroll times

		ldi		olcnt, 14	
WrScl2:	lpm		mpr, Z+							; Read the byte at address in Z to the register R16, the post-inc
		cpi		YL,	$20							; Compare YL lower pointer to max LCD mem location
		brne	YCont							; If YL doesn't point to memory location past max for LCD, skip next
		ldi		YL, $00							; Else adjust to beginning of LCD
YCont:	st		Y+, mpr							; Store byte loaded from memory into LCD memory location, increment to next subsequent location
		dec		olcnt							; Dec write counter
		brne	WrScl2							; Continue writing until nothing left to write

		; Display the strings on the LCD Display
		rcall	LCDWrite		; Write to LCD
		ldi		waitcnt, WTime	; Wait for 1 second
		rcall	Wait			; Call wait function
		dec		ilcnt			; Dec scroll loop counter
		brne	WrScrl1			; Loop back to beginning

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
;
;
;*****	 Copied from provided Lab 1 BasicBumpBot.asm   ***********
;
;
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
		ret					; Return from subroutine

;***********************************************************
;*	Stored Program Data
;***********************************************************

STRING1:
.DB		"Ben Warren"			; Declaring data in ProgMem
STRING2:
.DB		"Hello, World! "			; Declaring data in ProgMem

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
