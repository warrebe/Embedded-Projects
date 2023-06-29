;***********************************************************
;*	Source code for Lab 4 modeled from skeleton code
;*
;*	 Author: Ben Warren
;*	   Date: 10/28/2022
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable
.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0056					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:								; The initialization routine
		ldi		mpr, low(RAMEND)	; initialize Stack Pointer
		out		SPL, mpr
		ldi		mpr, high(RAMEND)
		out		SPH, mpr

		clr		zero			; Set the zero register to zero, maintain
										; these semantics, meaning, don't
										; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program

		; Call function to load ADD16 operands
		rcall loadADD16
		nop ; Check load ADD16 operands (Set Break point here #1)

		; Call ADD16 function to display its results (calculate FCBA + FFFF)
		rcall ADD16
		nop ; Check ADD16 result (Set Break point here #2)

		; Call function to load SUB16 operands
		rcall loadSUB16
		nop ; Check load SUB16 operands (Set Break point here #3)

		; Call SUB16 function to display its results (calculate FCB9 - E420)
		rcall SUB16
		nop ; Check SUB16 result (Set Break point here #4)


		; Call function to load MUL24 operands
		rcall loadMUL24
		nop ; Check load MUL24 operands (Set Break point here #5)

		; Call MUL24 function to display its results (calculate FFFFFF * FFFFFF)
		rcall MUL24
		nop ; Check MUL24 result (Set Break point here #6)

		; Setup the COMPOUND function direct test
		rcall loadCOMPOUND
		nop ; Check load COMPOUND operands (Set Break point here #7)

		; Call the COMPOUND function
		rcall COMPOUND
		nop ; Check COMPOUND result (Set Break point here #8)

DONE:	rjmp	DONE			; Create an infinite while loop to signify the
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: loadADD16
; Desc: Loads operands from program memory to data memory
;       to be used in the ADD16 funcion
;-----------------------------------------------------------
loadADD16:

		ldi	ZL, low(OperandA<<1)	; Load LSB of first operand 
		ldi	ZH, high(OperandA<<1)	; Load MSB of first operand
		ldi XL, low(ADD16_OP1)		; Load LSB of mem location to store first operand
		ldi XH, high(ADD16_OP1)		; Load MSB of mem location to store first operand
		lpm mpr, Z+					; Load first byte of first operand into data memory
		st  X+, mpr			
		lpm mpr, Z					; Load second byte of first operand into data memory
		st  X, mpr
		ldi	ZL, low(OperandB<<1)	; Load LSB of second operand 
		ldi	ZH, high(OperandB<<1)   ; Load MSB of second operand 
		ldi YL, low(ADD16_OP2)		; Load LSB of mem location to store second operand
		ldi YH, high(ADD16_OP2)		; Load MSB of mem location to store second operand
		lpm mpr, Z+					; Load first byte of second operand into data memory
		st  Y+, mpr
		lpm mpr, Z					; Load second byte of second operand into data memory
		st  Y, mpr

		ret

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;       where the high byte of the result contains the carry
;       out bit.
;-----------------------------------------------------------
ADD16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		; Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)	; Load low byte of address
		ldi		XH, high(ADD16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address
		
		; Load beginning address of result into Z
		ldi		ZL, low(ADD16_Result)	; Load low byte of address
		ldi		ZH, high(ADD16_Result)	; Load high byte of address

		; Execute the function
		ld		A, X+					; Load first byte of first operand into A variable
		ld		B, Y+					; Load first byte of second operand into B variable
		add		B, A					; Perform the add operation for the first bytes
		st		Z+, B					; Store result
		ld		A, X					; Repeat above operation, but with carry bit on second bytes
		ld		B, Y
		adc		B, A
		st		Z+, B
		brcc	EXIT					; Exit if no carry
		st		Z, XH					; Else add th carry in and then exit

EXIT:	pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: loadSUB16
; Desc: Loads operands from program memory to data memory
;       to be used in the SUB16 funcion
;-----------------------------------------------------------
loadSUB16:

		ldi	ZL, low(OperandC<<1)	; Load LSB of first operand 
		ldi	ZH, high(OperandC<<1)	; Load MSB of first operand
		ldi XL, low(SUB16_OP1)		; Load LSB of mem location to store first operand
		ldi XH, high(SUB16_OP1)		; Load MSB of mem location to store first operand
		lpm mpr, Z+					; Load first byte of first operand into data memory
		st  X+, mpr			
		lpm mpr, Z					; Load second byte of first operand into data memory
		st  X, mpr
		ldi	ZL, low(OperandD<<1)	; Load LSB of second operand 
		ldi	ZH, high(OperandD<<1)   ; Load MSB of second operand 
		ldi YL, low(SUB16_OP2)		; Load LSB of mem location to store second operand
		ldi YH, high(SUB16_OP2)		; Load MSB of mem location to store second operand
		lpm mpr, Z+					; Load first byte of second operand into data memory
		st  Y+, mpr
		lpm mpr, Z					; Load second byte of second operand into data memory
		st  Y, mpr

		ret

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;       result. Always subtracts from the bigger values.
;-----------------------------------------------------------
SUB16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)	; Load low byte of address
		ldi		XH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)	; Load low byte of address
		ldi		YH, high(SUB16_OP2)	; Load high byte of address
		; Load beginning address of result into Z
		ldi		ZL, low(SUB16_Result)	; Load low byte of address
		ldi		ZH, high(SUB16_Result)	; Load high byte of address

		; Execute the function
		ld		A, X+					; Load first byte of first operand into A variable
		ld		B, Y+					; Load first byte of second operand into B variable
		sub		A, B					; Perform the add operation for the first bytes
		st		Z+, A					; Store result
		ld		A, X					; Repeat above operation on second bytes
		ld		B, Y
		sub		A, B
		st		Z+, A

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET


;-----------------------------------------------------------
; Func: loadMUL24
; Desc: Loads operands from program memory to data memory
;       to be used in the MUL24 funcion
;-----------------------------------------------------------
loadMUL24:

		ldi	ZL, low(OperandE1<<1)	; Load LSB of first operand 
		ldi	ZH, high(OperandE1<<1)	; Load the middle byte of first operand
		ldi XL, low(MUL24_OP1)		; Load LSB of mem location to store first operand
		ldi XH, high(MUL24_OP1)		; Load the middle byte of mem location to store first operand
		lpm mpr, Z+					; Load first byte of first operand into data memory
		st  X+, mpr			
		lpm mpr, Z					; Load second byte of first operand into data memory
		st  X+, mpr
		ldi	ZL, low(OperandE2<<1)	; Load highest byte of first operand 
		lpm mpr, Z					; Load highest byte of first operand into data memory
		st  X, mpr

		ldi	ZL, low(OperandF1<<1)	; Load LSB of first operand 
		ldi	ZH, high(OperandF1<<1)	; Load the middle byte of first operand
		ldi YL, low(MUL24_OP2)		; Load LSB of mem location to store first operand
		ldi YH, high(MUL24_OP2)		; Load the middle byte of mem location to store first operand
		lpm mpr, Z+					; Load first byte of first operand into data memory
		st  Y+, mpr			
		lpm mpr, Z					; Load second byte of first operand into data memory
		st  Y+, mpr
		ldi	ZL, low(OperandF2<<1)	; Load highest byte of first operand 
		lpm mpr, Z					; Load highest byte of first operand into data memory
		st  Y, mpr

		ret

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit
;       result.
;-----------------------------------------------------------
MUL24:
		;* - Simply adopting MUL16 ideas to MUL24 will not give you steady results. You should come up with different ideas.
		; Execute the function here
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		; Load beginning address of second operand into Y
		ldi		YL, low(MUL24_OP2)	; Load low byte of address
		ldi		YH, high(MUL24_OP2)	; Load high byte of address
		; Load beginning address of result into Z
		ldi		ZL, low(MUL24_Result)	; Load low byte of address
		ldi		ZH, high(MUL24_Result)	; Load high byte of address

		clr		zero			; Maintain zero semantics

		; Begin outer for loop, 3 loops for looping through 3 bytes of second operand
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of Operand 1
		ldi		XL, low(MUL24_OP1)	; Load low byte of address
		ldi		XH, high(MUL24_OP1)	; Load high byte of address

		; Begin inner for loop
		ldi		iloop, 3		; Load counter, 3 loops for looping through 3 bytes of first operand
MUL24_ILOOP:
		clr		zero			; Clear carry on each loop 
		ld		A, X+			; Get byte of A operand <- load operand 1 first byte
		ld		B, Y			; Get byte of B operand <- load operand 2 first byte
		mul		A,B				; Multiply A and B <- multiply, store in rhi:rlo
		ld		A, Z+			; Get a result byte from memory <- Get result byte 1
		ld		B, Z+			; Get the next result byte from memory < - get result byte 2
		add		rlo, A			; rlo <= rlo + A <- 
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z+			; Get a third byte from the result, inc Z
		adc		A, zero			; Add carry to A
		adc		zero, zero		; Add carry to zero
		st		Z, zero			; Store carry 
		st		-Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2 <- Changes for 24 bit, need to go back 2 places
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET

loadCOMPOUND:
;-----------------------------------------------------------
; Func: loadCOMPOUND
; Desc: Loads operands from program memory to data memory
;       to be used in the COMPOUND funcion
;-----------------------------------------------------------
		ldi	ZL, low(OperandG<<1)	; Load LSB of first SUB operand 
		ldi	ZH, high(OperandG<<1)	; Load MSB of first SUB operand
		ldi XL, low(SUB16_OP1)		; Load LSB of mem location to store first SUB operand
		ldi XH, high(SUB16_OP1)		; Load MSB of mem location to store first SUB operand
		lpm mpr, Z+					; Load first byte of first operand into data memory
		st  X+, mpr			
		lpm mpr, Z					; Load second byte of first SUB operand into data memory
		st  X, mpr
		ldi	ZL, low(OperandH<<1)	; Load LSB of second SUB operand 
		ldi	ZH, high(OperandH<<1)   ; Load MSB of second SUB operand 
		ldi YL, low(SUB16_OP2)		; Load LSB of mem location to store second SUB operand
		ldi YH, high(SUB16_OP2)		; Load MSB of mem location to store second SUB operand
		lpm mpr, Z+					; Load first byte of second SUB operand into data memory
		st  Y+, mpr
		lpm mpr, Z					; Load second byte of second SUB operand into data memory
		st  Y, mpr

		;First ADD operand is the SUB16_Result loaded after operation
		ldi	ZL, low(OperandI<<1)	; Load LSB of second ADD operand 
		ldi	ZH, high(OperandI<<1)   ; Load MSB of second ADD operand 
		ldi YL, low(ADD16_OP2)		; Load LSB of mem location to store second ADD operand
		ldi YH, high(ADD16_OP2)		; Load MSB of mem location to store second ADD operand
		lpm mpr, Z+					; Load first byte of second ADD operand into data memory
		st  Y+, mpr
		lpm mpr, Z					; Load second byte of second ADD operand into data memory
		st  Y, mpr

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((G - H) + I)^2
;       by making use of SUB16, ADD16, and MUL24.
;
;       D, E, and F are declared in program memory, and must
;       be moved into data memory for use as input operands.
;
;       All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP2)	; Load low byte of address
		ldi		XH, high(SUB16_OP2)	; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP1)	; Load low byte of address
		ldi		YH, high(SUB16_OP1)	; Load high byte of address

		; Load beginning address of result into Z
		ldi		ZL, low(SUB16_Result)	; Load low byte of address
		ldi		ZH, high(SUB16_Result)	; Load high byte of address

		; Execute the function
		ld		A, X+					; Load first byte of first operand into A variable
		ld		B, Y+					; Load first byte of second operand into B variable
		sub		B, A					; Perform the add operation for the first bytes
		st		Z+, B					; Store result
		ld		A, X					; Repeat above operation on second bytes
		ld		B, Y
		sub		B, A
		st		Z+, B

		; Setup the ADD16 function with SUB16 result and operand I
		; Load beginning address of SUB16_Result operand into X
		ldi		XL, low(SUB16_Result)
		ldi		XH, high(SUB16_Result)
		; Load beginning address of second ADD operand into Y
		ldi		YL, low(ADD16_OP2)	; Load low byte of address
		ldi		YH, high(ADD16_OP2)	; Load high byte of address
		
		; Load beginning address of ADD result into Z
		ldi		ZL, low(ADD16_Result)	; Load low byte of address
		ldi		ZH, high(ADD16_Result)	; Load high byte of address

		; Execute the function
		ld		A, X+					; Load first byte of first operand into A variable
		ld		B, Y+					; Load first byte of second operand into B variable
		add		B, A					; Perform the add operation for the first bytes
		st		Z+, B					; Store result
		ld		A, X					; Repeat above operation, but with carry bit on second bytes
		ld		B, Y
		adc		B, A
		st		Z+, B
		brcc	EXIT1					; Exit if no carry
		st		Z, XH					; Else add th carry in and then exit

EXIT1:
		; Load beginning address of ADD result into Y
		ldi		YL, low(ADD16_Result)	; Load low byte of address
		ldi		YH, high(ADD16_Result)	; Load high byte of address
		; Load beginning address of result into Z
		ldi		ZL, low(COMPOUND_Result)	; Load low byte of address
		ldi		ZH, high(COMPOUND_Result)	; Load high byte of address

		; Maintain zero semantics
		clr		zero	
				
		; Begin outer for loop, 3 loops for looping through 3 bytes of second operand
		ldi		oloop, 3		; Load counter
MUL24_OLOOP1:
		; Load beginning address of ADD result into X
		ldi		XL, low(ADD16_Result)	; Load low byte of address
		ldi		XH, high(ADD16_Result)	; Load high byte of address

		; Begin inner for loop
		ldi		iloop, 3		; Load counter, 3 loops for looping through 3 bytes of first operand
MUL24_ILOOP1:
		clr		zero			; Clear carry on each loop
		ld		A, X+			; Get byte of A operand <- load operand 1 first byte
		ld		B, Y			; Get byte of B operand <- load operand 2 first byte
		mul		A,B				; Multiply A and B <- multiply, store in rhi:rlo
		ld		A, Z+			; Get a result byte from memory <- Get result byte 1
		ld		B, Z+			; Get the next result byte from memory < - get result byte 2
		add		rlo, A			; rlo <= rlo + A <- 
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z+			; Get a third byte from the result, inc Z
		adc		A, zero			; Add carry to A
		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1
		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP1		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2 <- Changes for 24 bit, need to go back 2 places
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP1	; Loop if oLoop != 0
		; End outer for loop
		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;       A - Operand A is gathered from address $0101:$0100
;       B - Operand B is gathered from address $0103:$0102
;       Res - Result is stored in address
;             $0107:$0106:$0105:$0104
;       You will need to make sure that Res is cleared before
;       calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop

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
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B
		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
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

		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET

;-----------------------------------------------------------
; Func: Template function header
; Desc: Cut and paste this and fill in the info at the
;       beginning of your functions
;-----------------------------------------------------------
FUNC:							; Begin a function with a label
		; Save variable by pushing them to the stack

		; Execute the function here

		; Restore variable by popping them from the stack in reverse order
		ret						; End a function with RET


;***********************************************************
;*	Stored Program Data
;*	Do not edit section.
;***********************************************************
; ADD16 operands
OperandA:
	.DW 0xFCBA
OperandB:
	.DW 0xFFFF

; SUB16 operands
OperandC:
	.DW 0XFCB9
OperandD:
	.DW 0XE420

; MUL24 operands
OperandE1:
	.DW	0XFFFF
OperandE2:
	.DW	0X00FF
OperandF1:
	.DW	0XFFFF
OperandF2:
	.DW	0X00FF

; Compoud operands
OperandG:
	.DW	0xFCBA				; test value for operand G
OperandH:
	.DW	0x2022				; test value for operand H
OperandI:
	.DW	0x21BB				; test value for operand I

;***********************************************************
;*	Data Memory Allocation
;***********************************************************
.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

; Below is an example of data memory allocation for ADD16.
; Consider using something similar for SUB16 and MUL24.
.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16

.org	$0120				; data memory allocation for results
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0130				; data memory allocation for operands
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of SUB16

.org	$0140				; data memory allocation for results
SUB16_Result:
		.byte 2				; allocate three bytes for SUB16 result

.org	$0150				; data memory allocation for operands
MUL24_OP1:
		.byte 3				; allocate two bytes for first operand of MUL24
MUL24_OP2:
		.byte 3				; allocate two bytes for second operand of MUL24

.org	$0160				; data memory allocation for results
MUL24_Result:
		.byte 6				; allocate six bytes for MUL24 result

.org	$0170				; data memory allocation for results
COMPOUND_Result:
		.byte 6				; allocate six bytes for MUL24 result

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program
