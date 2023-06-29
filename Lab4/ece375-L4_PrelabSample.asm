;***********************************************************
;*
;*	Lab4 PrelabSample.asm
;*
;*	This is a sample ASM program, meant to be run only via
;*	simulation. First, four registers are loaded with certain
;*	values. Then, while the simulation is paused, the user
;*	must copy these values into the data memory. Finally, a
;*	function is called, which performs an operation, using
;*	the previously-entered values in memory as input.
;*
;***********************************************************
;*
;*	 Author: Taylor Johnson
;*	   Date: January 15th, 2016
;*
;***********************************************************

.include "m128def.inc"				; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************

.def	mpr = r16
.def	i = r17
.def	A = r18
.def	B = r19

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg								; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000						; Beginning of IVs
		rjmp 	INIT				; Reset interrupt

.org	$0046						; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:								; The initialization routine
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
		clr		r0					; *** SET BREAKPOINT HERE *** (#1)
		dec		r0					; initialize r0 value


		clr		r1					; *** SET BREAKPOINT HERE *** (#2)
		ldi		i, $04
LOOP:	lsl		r1					; initialize r1 value
		inc		r1
		lsl		r1
		dec		i
		brne	LOOP				; *** SET BREAKPOINT HERE *** (#3)


		clr		r2					; *** SET BREAKPOINT HERE *** (#4)
		ldi		i, $0F
LOOP2:	inc		r2					; initialize r2 value
		cp		r2, i
		brne	LOOP2		 		; *** SET BREAKPOINT HERE *** (#5)

									; initialize r3 value
		mov		r3, r2				; *** SET BREAKPOINT HERE *** (#6)

		;		Note: At this point, you need to enter several values
		;		directly into the Data Memory. FUNCTION is written to
		;		expect memory locations $0101:$0100 and $0103:$0102
		;		to represent two 16-bit operands.
		;
		;		So at this point, the contents of r0, r1, r2, and r3
		;		MUST be manually typed into Data Memory locations
		;		$0100, $0101, $0102, and $0103 respectively.

									; call FUNCTION
		rcall	FUNCTION			; *** SET BREAKPOINT HERE *** (#7)

									; infinite loop at end of MAIN
 DONE:	rjmp	DONE

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: FUNCTION
; Desc: ???
;-----------------------------------------------------------
FUNCTION:
		ldi		XL, $00
		ldi		XH, $01
		ldi		YL, $02
		ldi		YH, $01
		ldi		ZL, $04
		ldi		ZH, $01
		ld		A, X+
		ld		B, Y+
		add		B, A
		st		Z+, B
		ld		A, X
		ld		B, Y
		adc		B, A
		st		Z+, B
		brcc	EXIT
		st		Z, XH
EXIT:
		ret							; return from rcall













		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand <- load operand 1 first byte
		ld		B, Y			; Get byte of B operand <- load operand 2 first byte
		mul		A,B				; Multiply A and B <- multiply, store in rhi:rlo
		ld		A, Z+			; Get a result byte from memory <- Get result byte 1
		ld		B, Z+			; Get the next result byte from memory < - get result byte 2
		add		rlo, A			; rlo <= rlo + A <-
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		Expect: FFFFFE000001
				656463626160
				FE01FE00FF01