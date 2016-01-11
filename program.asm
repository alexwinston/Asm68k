
INPUT_ADDRESS   equ $800000
OUTPUT_ADDRESS  equ $400000
CIRCULAR_BUFFER equ $c0
CAN_OUTPUT      equ $d0
STACK_AREA      equ $100
                   
vector_table:
	dc.l STACK_AREA				;  0: SP
	dc.l init					;  1: PC
	dc.l unhandled_exception	;  2: bus error
	dc.l unhandled_exception	;  3: address error
	dc.l unhandled_exception	;  4: illegal instruction
	dc.l unhandled_exception	;  5: zero divide
	dc.l unhandled_exception	;  6: chk
	dc.l unhandled_exception	;  7: trapv
	dc.l unhandled_exception	;  8: privilege violation
	dc.l unhandled_exception	;  9: trace
	dc.l unhandled_exception	; 10: 1010
	dc.l unhandled_exception	; 11: 1111
	dc.l unhandled_exception	; 12: -
	dc.l unhandled_exception	; 13: -
	dc.l unhandled_exception	; 14: -
	dc.l unhandled_exception	; 15: uninitialized interrupt
	dc.l unhandled_exception	; 16: -
	dc.l unhandled_exception	; 17: -
	dc.l unhandled_exception	; 18: -
	dc.l unhandled_exception	; 19: -
	dc.l unhandled_exception	; 20: -
	dc.l unhandled_exception	; 21: -
	dc.l unhandled_exception	; 22: -
	dc.l unhandled_exception	; 23: -
	dc.l unhandled_exception	; 24: spurious interrupt
	dc.l output_ready			; 25: l1 irq
	dc.l input_ready			; 26: l2 irq
	dc.l unhandled_exception	; 27: l3 irq
	dc.l unhandled_exception	; 28: l4 irq
	dc.l unhandled_exception	; 29: l5 irq
	dc.l unhandled_exception	; 30: l6 irq
	dc.l nmi					; 31: l7 irq
	dc.l unhandled_exception	; 32: trap 0
	dc.l unhandled_exception	; 33: trap 1
	dc.l unhandled_exception	; 34: trap 2
	dc.l unhandled_exception	; 35: trap 3
	dc.l unhandled_exception	; 36: trap 4
	dc.l unhandled_exception	; 37: trap 5
	dc.l unhandled_exception	; 38: trap 6
	dc.l unhandled_exception	; 39: trap 7
	dc.l unhandled_exception	; 40: trap 8
	dc.l unhandled_exception	; 41: trap 9
	dc.l unhandled_exception	; 42: trap 10
	dc.l unhandled_exception	; 43: trap 11
	dc.l unhandled_exception	; 44: trap 12
	dc.l unhandled_exception	; 45: trap 13
	dc.l unhandled_exception	; 46: trap 14
	dc.l unhandled_exception	; 47: trap 15
                        ; This is the end of the useful part of the table.
                        ; We will now do the Capcom thing and put code starting at $c0.
                        
init:
                        ; Copy the exception vector table to RAM.
	move.l  #0, a1						; a1 is RAM index
	move.w  #47, d0						; d0 is counter (48 vectors)
	lea.l   (copy_table,PC), a0			; a0 is scratch
	move.l  a0, d1						; d1 is ROM index
	neg.l   d1
copy_table:
	dc.l    $22fb18fe					; stoopid as68k generates 020 code here
                        ;	move.l  (copy_table,PC,d1.l), (a1)+
	addq    #4, d1
	dbf     d0, copy_table
                        
main_init:
                        ; Initialize main program
	move.b  #0, CAN_OUTPUT
	lea.l   CIRCULAR_BUFFER, a6
	moveq   #0, d6						; output buffer ptr
	moveq   #0, d7						; input buffer ptr
	andi    #$f8ff, SR					; clear interrupt mask
main:
                        ; Main program
	tst.b   CAN_OUTPUT					; can we output?
	beq     main
	cmp.b   d6, d7						; is there data?
	beq     main
	move.b  #0, CAN_OUTPUT
	move.b  (0,a6,d6.w), OUTPUT_ADDRESS	; write data 0000
	addq    #1, d6
	andi.b  #15, d6						; update circular buffer
	bra     main
                        
                        
input_ready:
	move.l  d0, -(a7)
	move.l  d1, -(a7)
	move.b  INPUT_ADDRESS, d1			; read data
	move.b  d7, d0						; check if buffer full
	addq    #1, d0
	andi.b  #15, d0
	cmp.b   d0, d6
	beq     input_ready_quit			; throw away if full
	move.b  d1, (0,a6,d7.w)				; store the data
	addq    #1, d7
	andi.b  #15, d7						; update circular buffer
input_ready_quit:
	move.l  (a7)+, d1
	move.l  (a7)+, d0
	rte
                        
output_ready:
	move.l  d0, -(a7)
	move.b  #1, CAN_OUTPUT
	move.b  OUTPUT_ADDRESS, d0			; acknowledge the interrupt
	move.l  (a7)+, d0
	rte
                        
unhandled_exception:
	stop	#$2700						; wait for NMI
	bra     unhandled_exception			; shouldn't get here
                        
nmi:
                        ; perform a soft reset
	move    #$2700, SR					; set status register
	move.l  (vector_table,PC), a7		; reset stack pointer
	reset								; reset peripherals
	jmp     (vector_table+4,PC)			; reset program counter
                        
END
