OUT equ $7a000

start:	ORG $400
START	BRA	CSTART
CSTART	move.l #hello,a0     ;Load the base address of the string
    ;lea.l hello.l,a0     ;Load the base address of the string
    ;clr.l d0            ;Keep high byte of d0.w empty
loop:
    move.b (a0)+,d0     ;Read next character
    beq done           ;If it was zero (terminator), we're done
    move.b d0,OUT       ;Write that character to the memory mapped i/o
    bra loop           ;Next character
done:
    bra done           ;Lock the CPU when we're done
    
HELLO dc.b 13,10,'zBug(ROM) for 68Katy (press ? for help)',13,10,0
TEST dc.b 'Testing',13,10,0
text:
    dc.b "Hello world!",$A,10,0
