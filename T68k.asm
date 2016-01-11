; FILE NAME U68K.ASM 
; 
; zBug V1.0 is a small monitor program for 68000-Based Single Board Computer
; The source code was assembled using C32 CROSS ASSEMBLER VERSION 3.0
;

; Copyright (c) 2002 WICHIT SIRICHOTE email kswichit@kmitl.ac.th
; 
;
; This program is free software; you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation; either version 2 of the License, or
; (at your option) any later version.
;
; This program is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
;
;

;   CPU     "68000.TBL"      ; CPU TABLE
;   HOF     "BIN16"          ; HEX OUTPUT FORMAT
 ;  HOF     "MOT16"          ; OUTPUT MOTOROLA S-RECORD


BIT_ESC      EQU 0              ; ESC BIT POSITION #0

DCODE68K  EQU $400

RAM      EQU $100000
DIN      EQU $300001 
DOUT     EQU $700001       

ACIAC    EQU $600000
ACIAD    EQU ACIAC+2
PIT      EQU $700001

INT_ON   EQU  $2000    ; BOTH, SET SUPERVISOR MODE, S=1
INT_OFF  EQU  $2700

RDRF    EQU 0
TDRE    EQU 1

SUPERVISOR_BIT EQU 5

TRACE_BIT EQU 7

CR      EQU 13
LF      EQU 10
SP      EQU 32
BS      EQU 8
RS      EQU $1E
ESC     EQU $1B

SUPER_STACK   EQU $130000

TRAP0   EQU RAM+$80
TRAP1   EQU TRAP0+4
TRAP2   EQU TRAP1+4
TRAP3   EQU TRAP2+4
TRAP4   EQU TRAP3+4
TRAP5   EQU TRAP4+4
TRAP6   EQU TRAP5+4
TRAP7   EQU TRAP6+4
TRAP8   EQU TRAP7+4
TRAP9   EQU TRAP8+4
TRAP10  EQU TRAP9+4
TRAP11  EQU TRAP10+4
TRAP12  EQU TRAP11+4
TRAP13  EQU TRAP12+4
TRAP14  EQU TRAP13+4
TRAP15  EQU TRAP14+4

BUS_ERROR EQU RAM+8
ADDRESS_ERROR EQU RAM+$C
ILLEGAL_INSTRUCTION EQU RAM+$10


   ORG 0
   dc.l SUPER_STACK        ; TOP OF SUPERVISOR STACK $130000
   dc.l MAIN
   dc.l BUS_ERROR
   dc.l ADDRESS_ERROR
   dc.l ILLEGAL_INSTRUCTION

   ORG $24
   dc.l SERVICE_TRAP0      ; TRACE THE SAME AS TRAP #0 


   ORG $80
   dc.l SERVICE_TRAP0      ; TRAP #0

   ORG $C0
RAMBASE  dc.l   $130000     ; RAM BASE ADDRESS


; RESERVED SPACE FOR FILE DECODE68K DISASSEMBLER
; RAM+$400 TO RAM+10E0
; THE DISASSEMBLER MUST BE LOADED BEFORE USING 

   ORG $400
   ;INCBIN "DIS.IMG"


   ORG $2000

MAIN  MOVE.W #INT_OFF,SR  ; INTERRUPT OFF, SUPERVISOR MODE SET

;      MOVE.L #RAMBASE+USER_STACK,SP ; INIT TOP OF USER STACK
      movea.l #DOUT,a1
      move.b #$FF,d2    ; with cpld
      MOVE.B D2,(A1)    ; OFF LEDS

      BSR INIT_ACIA

      ;BSR SCROLL

      BSR CLEAR_MON_RAM

      LEA.L TITLE1.L,A3
      BSR PSTR

      MOVEA.L RAMBASE.L,A6
      MOVE.L #RAM,POINTER_NOW(A6)
      MOVE.L #RAM+$400,USER_PC(A6)    ; INIT USER PC TO START OF RAM

      MOVE.L #SUPER_STACK+USER_STACK,USER_USP(A6) ; INIT USER STACK
      MOVE.W SR,D0
      MOVE.W D0,USER_SR(A6) 

      CLR.L FLAG(A6)         ; CLEAR SYSTEM MONITOR FLAG
      MOVE.W #INT_ON,SR       ; ON INTERRUPT, SUPERVISOR MODE SET

loop  BSR SEND_PROMPT
      BSR CIN
      CMP.B #$40,D0
      BLT.S NO_CHANGE

      AND.B #$DF,D0

NO_CHANGE

      CMP.B #"L",D0
      BNE NEXT1
      BSR READ_S_REC
      BRA LOOP

NEXT1 CMP.B #"S",D0       
      BNE NEXT2
      BSR VIEW_USP      ; VIEW USER STACK
      BRA LOOP


NEXT2 CMP.B #"H",D0
      BNE NEXT3
      BSR HEX_DUMP
      BRA LOOP

NEXT3 CMP.B #"N",D0
      BNE NEXT4
      BSR NEW_POINTER
      BRA LOOP

NEXT4 CMP.B #"J",D0
      BNE NEXT5
      BSR JUMP
      BRA LOOP

NEXT5 CMP.B #"Z",D0
      BNE NEXT6
      BSR UPLOAD         ; PRINT_DEBUG <------ USE Z FOR UPLOAD BINARY IMAGE
      BRA LOOP


NEXT6 CMP.B #"F",D0
      BNE NEXT7
      BSR FILL_MEMORY
      BRA LOOP

NEXT7 CMP.B #"E",D0
      BNE NEXT8
      BSR EDIT_MEMORY
      BRA LOOP

NEXT8 CMP.B #"C",D0
      BNE NEXT9
      BSR CLEAR_MEMORY
      BRA LOOP

NEXT9 CMP.B #"Q",D0
      BNE NEXT10
      BSR QUICK_HOME
      BRA LOOP

NEXT10 CMP.B #"?",D0
       BNE.S NEXT11
       BSR HELP
       BRA LOOP


NEXT11 CMP.B #"R",D0
      BNE.S NEXT12
      BSR DISPLAY_REG
      BRA LOOP

NEXT12 CMP.B #".",D0
      BNE.S NEXT13
      BSR MODIFY_REG
      BRA LOOP

NEXT13 CMP.B #"D",D0
       BNE.S NEXT14
       BSR DISASSEMBLE
       BRA LOOP

NEXT14 CMP.B #"A",D0
       BNE.S NEXT15
       BSR ABOUT
       BRA LOOP


NEXT15 CMP.B #"T",D0
       BNE.S NEXT16
       BSR TRACE_JUMP
       BRA LOOP

NEXT16 CMP.B #"G",D0
       BNE.S NEXT17
       JMP $102000.L       ; USE G COMMAND FOR SIMPLE JUMP TO RAM


NEXT17 CMP.B #"B",D0
       BNE.S NEXT18
       BRA BOOT_RAM

NEXT18  BSR NEW_LINE
      BSR SEND_TITLE
      bra loop

; INIT ACIA

INIT_ACIA  MOVE.B #3,ACIAC.L   ; RESET ACIA
           MOVE.W #10000,D0
           ;DBRA  D0,$
           ;DBRA  D0,INIT_ACIA
           ;MOVE.B #$15,ACIAC.L   ; rts enabled 9600 8ne
           MOVE.B #$2,ACIAC.L   ; rts enabled 9600 8ne
           RTS

COUT      BTST.B #TDRE,ACIAC.L
          BEQ.S  COUT
          MOVE.B D0,ACIAD.L
          RTS


CINS      BTST.B #RDRF,ACIAC.L
          BEQ.S  CINS
          MOVE.B ACIAD.L,D0
          RTS


CIN      BTST.B #RDRF,ACIAC.L
         BEQ.S  CIN
         MOVE.B ACIAD.L,D0
         BSR COUT
         RTS

; A3 POINTED TO FIRST BYTE
; END WITH 0

PSTR     MOVE.B (A3)+,D0
         CMP.B  #0,D0
         BEQ.S PSTR1
         BSR COUT
         BRA.S PSTR

PSTR1    RTS

; NEW LINE

NEW_LINE MOVE.L D0,-(SP)
         MOVE.B #CR,D0
         BSR COUT
         MOVE.B #LF,D0
         BSR COUT
         MOVE.L (SP)+,D0
         RTS

SPACE    MOVE.B #SP,D0
         BSR COUT
         RTS

SCROLL   MOVE.W #25,D1
SCROLL1  BSR NEW_LINE
         DBF D1,SCROLL1
         RTS

SEND_PROMPT
        MOVEA.L RAMBASE.L,A6
        BSR NEW_LINE
        MOVE.L POINTER_NOW(A6),D0
        BSR OUT6X
        LEA.L PROMPT.L,A3
        BSR PSTR
        RTS

SEND_TITLE LEA.L TITLE.L,A3
           BSR PSTR
           RTS

; S19 LOADER

; CONVERT ASCII LETTER TO 8-BIT VALUE

TO_HEX SUBI.B #$30,D0
       CMPI.B #$A,D0
       BMI  ZERO_TO_NINE
       ;AND.B #$11011111B,D0
       AND.B #$DF,D0
       SUBI.B #7,D0

ZERO_TO_NINE

       MOVE.B D0,D1

        RTS

; READ TWO BYTES ASCII AND CONVERT TO SINGLE BYTE DATA

; ENTRY: D0 FROM CIN 
; EXIT: D1 8-BIT VALUE 
;       


GET_HEX  BSR CIN

         CMP.B #" ",D0         ; IF BIT_ESC PRESSED
         BNE.S GET_HEX1
         BSET.B #BIT_ESC,FLAG(A6)
         RTS


GET_HEX1 CMP.B #CR,D0
         BNE.S GET_HEX2
         BSET.B #1,FLAG(A6)       ; ENTER PRESSED
         RTS


GET_HEX2 BSR TO_HEX
         ROL.B #4,D1
         MOVE.B D1,D2
         BSR CIN
         BSR TO_HEX
         ADD.B D2,D1
         RTS


GET_HEXS   BSR CINS
         BSR TO_HEX
         ROL.B #4,D1
         MOVE.B D1,D2
         BSR CINS
         BSR TO_HEX
         ADD.B D2,D1
         RTS

;
;S214000400227C00400001143C00006100002C128297
;S804000000FB

; READ S-RECORD
; D5 = BYTE CHECK SUM FOR EACH RECORD
; D4 = NUMBER OF BYTE RECEIVED

READ_S_REC      LEA.L LOAD.L,A3
                BSR PSTR
                CLR.L D4     ; CLEAR NUMBER OF BYTE 
                CLR.L D5     ; CLEAR CHECK SUM AND ERROR BYTE

READ_S_REC1     BSR CINS
                CMP.B #"S",D0
                BNE.S CHECK_ESC
                BRA.S GET_TYPE


CHECK_ESC       CMP.B #ESC,D0
                BNE.S READ_S_REC1

                RTS


GET_TYPE        BSR CINS
                CMP.B #"8",D0
                BNE CHECK_START

WAIT_CR         BSR CINS
                CMP.B #LF,D0
                BNE.S WAIT_CR

                BSR NEW_LINE
                BSR NEW_LINE
                MOVE.L D4,D0
                BSR PRINT_DEC     ; SHOW NUMBER OF BYTE RECEIVED
                MOVEA.L #NUMBER,A3
                BSR PSTR

                SWAP.W D5
                CLR.L D0
                MOVE.W D5,D0
                BSR PRINT_DEC
                MOVEA.L #ERROR,A3
                BSR PSTR
                RTS


CHECK_START     CMP.B #"2",D0
                BEQ.S START_FOUND

                CMP.B #"0",D0
                BEQ.S READ_S_REC1
                BRA.S READ_S_REC1


START_FOUND     CLR.W D5          ; CLEAR BYTE CHECK SUM

                BSR GET_HEXS
                CLR.L D7
                MOVE.B D1,D7       ; NUMBER OF BYTE SAVED TO D7
                SUBQ.B #5,D7
                MOVE.L D7,D0

                ADD.B  D1,D5       ; ADD CHECK SUM

; GET 24-BIT ADDRESS, SAVE TO A6

              CLR.L D6
              BSR GET_HEXS
              MOVE.B D1,D6
              ADD.B  D1,D5

              ROL.L #8,D6
              BSR GET_HEXS
              MOVE.B D1,D6
              ADD.B D1,D5

              ROL.L #8,D6

              BSR GET_HEXS
              MOVE.B D1,D6
              ADD.B D1,D5

              MOVEA.L D6,A6
                         
READ_DATA     BSR GET_HEXS
              ADD.B  D1,D5      ; ADD CHECK SUM
              MOVE.B D1,(A6)+

              not.b d1          ; complement before sending

              MOVE.B D1,DOUT.L  ; INDICATOR WHILE LOADING

              ADDQ.L #1,D4      ; BUMP NUMBER OF BYTE RECEIVED
              DBF D7,READ_DATA

              NOT.B D5          ; ONE'S COMPLEMENT OF BYTE CHECK SUM         

              BSR GET_HEXS      ; GET BYTE CHECK SUM

              CMP.B D1,D5       ; COMPARE CHECK SUM
              BEQ.S NO_ERROR

              ADD.L #$10000,D5  ; ADD 1 TO UPPER WORD
              MOVE.B #"X",D0    ; IF NOT EQUAL SEND "X" FOR ERROR
              BRA.S CHECKSUM_ERROR

NO_ERROR      MOVE.B #"_",D0      ; "_" NO ERROR RECORD
CHECKSUM_ERROR BSR COUT

              BRA READ_S_REC1


LOOP_BACK     BSR CIN
              CMP.B #13,D0
              BNE LOOP_BACK
              RTS



; PRINT HEX 
; OUT1X = PRINT ONE HEX
; OUT2X = PRINT TWO
; OUT4X = PRINT FOUR
; OUT8X = PRINT EIGHT
; ENTRY: D0

OUT1X        MOVE.B D0,-(SP)    ;SAVE D0
             AND.B #$F,D0
             ADD.B #"0",D0
             CMP.B #"9",D0
             BLS.S   OUT1X1
             ADD.B #7,D0
OUT1X1       BSR COUT
             MOVE.B (SP)+,D0    ;RESTORE D0
             RTS

OUT2X        ROR.B #4,D0
             BSR.S OUT1X
             ROL.B #4,D0
             BRA OUT1X

OUT4X        ROR.W #8,D0
             BSR.S OUT2X
             ROL.W #8,D0
             BRA.S OUT2X

OUT6X        SWAP.W D0        ; OUT 24-BIT HEX NUMBER
             BSR.S OUT2X
             SWAP.W D0
             BRA.S OUT4X

OUT8X        SWAP.W D0        ; OUT 32-BIT HEX NUMBER
             BSR.S  OUT4X
             SWAP.W D0
             BRA.S  OUT4X


; PRINT D0 CONTENT

PRINT_D0  BSR.S OUT8X
          RTS

; HEX DUMP
; DUMP MEMORY CONTENT
; A3: START ADDRESS

HEX_DUMP    LEA.L HEX.L,A3
            BSR PSTR

            MOVEA.L RAMBASE.L,A6
            MOVEA.L POINTER_NOW(A6),A3
            MOVE.W #15,D6
            BSR NEW_LINE

HEX_DUMP2   BSR NEW_LINE
            MOVE.L A3,D0
            BSR OUT6X
            BSR SPACE
            BSR SPACE

            MOVE.W #15,D7

HEX_DUMP1   MOVE.B (A3)+,D0
            BSR OUT2X
            BSR SPACE

            DBF D7,HEX_DUMP1

            BSR SPACE
            SUBA.L #16,A3       ; GET BACK TO BEGINING 
            MOVE.W #15,D7

HEX_DUMP6   MOVE.B (A3)+,D0

            CMP.B #$20,D0
            BGE.S HEX_DUMP3

HEX_DUMP4   MOVE.B #".",D0
            BRA.S  HEX_DUMP5

HEX_DUMP3   CMP.B #$7F,D0
            BGT.S HEX_DUMP4

HEX_DUMP5   BSR COUT
            DBF D7,HEX_DUMP6


            DBF D6,HEX_DUMP2

            MOVE.L A3,POINTER_NOW(A6)   ; UPDATE POINTER_NOW
            BSR NEW_LINE
            RTS


; NEW POINTER
; CHANGE 24-BIT ADDRESS-> POINTER_NOW

NEW_POINTER   LEA.L NEW.L,A3
              BSR PSTR

              BSR SEND_PROMPT

              MOVEA.L RAMBASE.L,A6
              CLR.L D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6

              BCLR.L #0,D6        ; FORCE TO EVEN ADDRESS

              MOVE.L D6,POINTER_NOW(A6)
              RTS

PRINT_DEBUG   BSR NEW_LINE
              MOVE.L DEBUG(A6),D0
              BSR OUT8X
              RTS

QUICK_HOME    LEA.L QUICK.L,A3
              BSR PSTR
              MOVEA.L RAMBASE.L,A6
              MOVE.L #RAM,POINTER_NOW(A6)
              RTS  

; TEST RAM

; GET 32BIT DATA
; EXIT: D6 CONTAINS 32-BIT ADDRESS

GET_32BIT     CLR.L D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              RTS


; GET_ADDRESS
; EXIT: D6 CONTAINS 24-BIT ADDRESS

GET_ADDRESS   CLR.L D6
              BSR GET_HEX

GET_ADDRESS1  MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              ROL.L #8,D6
              BSR GET_HEX
              MOVE.B D1,D6
              RTS

TEST_RAM      RTS

; FILL MEMORY WITH 0xFF

FILL_MEMORY   LEA.L FILL.L,A3
              BSR PSTR

              LEA.L START.L,A3
              BSR PSTR
              BSR GET_ADDRESS
              MOVEA.L D6,A4             ; A4 START ADDRESS

              LEA.L STOP.L,A3
              BSR PSTR
              BSR GET_ADDRESS
              MOVEA.L D6,A5             ; A5 STOP ADDRESS

FILL_MEMORY1  MOVE.W #$FFFF,(A4)+
              CMPA.L A4,A5
              BGE.S FILL_MEMORY1

              MOVEA.L #DONE,A3
              BSR PSTR
              RTS

; CLEAR MEMORY WITH 0x00

CLEAR_MEMORY  LEA.L CLEAR.L,A3
              BSR PSTR

              LEA.L START.L,A3
              BSR PSTR
              BSR GET_ADDRESS
              MOVEA.L D6,A4             ; A4 START ADDRESS

              LEA.L STOP.L,A3
              BSR PSTR
              BSR GET_ADDRESS
              MOVEA.L D6,A5             ; A5 STOP ADDRESS

CLEAR_MEMORY1 MOVE.W #$0000,(A4)+
              CMPA.L A4,A5
              BGE.S CLEAR_MEMORY1

              MOVEA.L #DONE,A3
              BSR PSTR
              RTS

; EDIT MEMORY
; PRESS SPACE BAR TO QUIT

EDIT_MEMORY   LEA.L EDIT1.L,A3
              BSR PSTR

              LEA.L EDIT.L,A3
              BSR PSTR
              BSR GET_ADDRESS

              BCLR.L #0,D6        ; FORCE TO EVEN ADDRESS
              MOVEA.L D6,A3       ; EDIT ADDRESS

             ; MOVEA.L POINTER_NOW.L,A3

EDIT_MEMORY2  BSR NEW_LINE
              MOVE.L A3,D0
              BSR OUT6X
              BSR SPACE
              BSR SPACE

              MOVE.B #"[",D0
              BSR COUT
              MOVE.W (A3),D0
              BSR OUT4X
              MOVE.B #"]",D0
              BSR COUT

              BSR SPACE

              CLR.W D1
              BSR GET_HEX

              BCLR.B #BIT_ESC,FLAG(A6); TEST BIT_ESC BIT
              BNE.S EDIT_MEMORY3  ; IF BIT = 1 THEN EXIT

              BCLR.B #1,FLAG(A6)  ; CHECK IF ENTER KEY PRESSED
              BNE.S EDIT_MEMORY4  ; SKIP WRITE TO RAM

              ROL.W #8,D1
              BSR GET_HEX

              MOVE.W #0,(A3)

              MOVE.W (A3),D0   ; TEST RAM OR ROM BY WRITING 0 AND READ BACK
              CMP.W #0,D0
              BNE.S EDIT_MEMORY5

              MOVE.W D1,(A3)     ; OK WRITE TO RAM
              BRA.S EDIT_MEMORY4 

EDIT_MEMORY5  MOVE.L A3,-(SP)
              LEA.L ROM.L,A3
              BSR PSTR
              MOVEA.L (SP)+,A3

EDIT_MEMORY4  ADDQ.L #2,A3     ; BUMP A3

              BRA.S EDIT_MEMORY2

EDIT_MEMORY3  BSR NEW_LINE
              RTS


; HELP LIST MONITOR COMMANDS

HELP          LEA.L HELP_LIST.L,A3
              BSR PSTR
              RTS

;----------------------------------------------------------------------
; PRINT_DEC
; D0 32-BIT BINARY NUMBER

PRINT_DEC MOVE.L D0,-(SP)  ; SAVE D0
          MOVEA.L RAMBASE.L,A5
          ADDA.L #BUFFER,A5
          BSR HEX2DEC
          MOVEA.L RAMBASE.L,A3
          ADDA.L #BUFFER,A3
          BSR PSTR
          MOVE.L (SP)+,D0 ; RESTORE D0
          RTS

;**************************************************************************
; The portion of code within STAR lines are modified from Tutor source code
;
;
; HEX2DEC   HEX2DEC convert hex to decimal                   
; CONVERT BINARY TO DECIMAL  REG D0 PUT IN (A5) BUFFER AS ASCII

HEX2DEC  MOVEM.L D1/D2/D3/D4/D5/D6/D7,-(SP)   ;SAVE REGISTERS
         MOVE.L  D0,D7               ;SAVE IT HERE
         BPL.S   HX2DC
         NEG.L   D7             ;CHANGE TO POSITIVE
         BMI.S   HX2DC57        ;SPECIAL CASE (-0)
         MOVE.B  #"-",(A5)+     ;PUT IN NEG SIGN
HX2DC    CLR.W   D4             ;FOR ZERO SURPRESS
         MOVEQ.L   #10,D6         ;COUNTER
HX2DC0   MOVEQ.L   #1,D2          ;VALUE TO SUB
         MOVE.L  D6,D1          ;COUNTER
         SUBQ.L  #1,D1          ;ADJUST - FORM POWER OF TEN
         BEQ.S   HX2DC2         ;IF POWER IS ZERO
HX2DC1   MOVE.W  D2,D3          ;D3=LOWER WORD
         MULU.W    #10,D3
         SWAP.W    D2             ;D2=UPPER WORD
         MULU.W    #10,D2
         SWAP.W    D3             ;ADD UPPER TO UPPER
         ADD.W   D3,D2
         SWAP.W    D2             ;PUT UPPER IN UPPER
         SWAP.W    D3             ;PUT LOWER IN LOWER
         MOVE.W  D3,D2          ;D2=UPPER & LOWER
         SUBQ.L  #1,D1
         BNE     HX2DC1
HX2DC2   CLR.L   D0             ;HOLDS SUB AMT
HX2DC22  CMP.L   D2,D7
         BLT.S   HX2DC3         ;IF NO MORE SUB POSSIBLE
         ADDQ.L  #1,D0          ;BUMP SUBS
         SUB.L   D2,D7          ;COUNT DOWN BY POWERS OF TEN
         BRA.S   HX2DC22        ;DO MORE
HX2DC3   TST.B   D0             ;ANY VALUE?
         BNE.S   HX2DC4
         TST.W   D4             ;ZERO SURPRESS
         BEQ.S   HX2DC5
HX2DC4   ADDI.B  #$30,D0        ;BINARY TO ASCII
         MOVE.B  D0,(A5)+       ;PUT IN BUFFER
         MOVE.B  D0,D4          ;MARK AS NON ZERO SURPRESS
HX2DC5   SUBQ.L  #1,D6          ;NEXT POWER
         BNE     HX2DC0
         TST.W   D4             ;SEE IF ANYTHING PRINTED
         BNE.S   HX2DC6
HX2DC57  MOVE.B  #"0",(A5)+     ;PRINT AT LEST A ZERO
HX2DC6   MOVE.B  #0,(A5)        ; PUT TERMINATOR
         MOVEM.L (SP)+,D1/D2/D3/D4/D5/D6/D7   ;RESTORE REGISTERS
         RTS                    ;END OF ROUTINE

;******************************************************************************


; DISPLAY USER REGISTERS D0-D7 AND A0-A7
;

DISPLAY_REG  LEA.L REGISTER_DISP.L,A3
             BSR PSTR

DISPLAY_REG1 MOVEA.L RAMBASE.L,A6
             BSR NEW_LINE
             BSR NEW_LINE
             MOVEA.L #PC_REG,A3
             BSR PSTR
             MOVE.L USER_PC(A6),D0
             BSR OUT6X

             BSR SPACE

             MOVEA.L #SR_REG,A3
             BSR PSTR
             MOVE.W USER_SR(A6),D0
             BSR OUT4X

; NOW PRINT FLAG LOGIC IN BINARY
             MOVE.B D0,D4       ; SAVE TO D4

             LSL.B #3,D4        ; BIT POSITION BEFORE SHIFTING OUT

             BSR SPACE
             MOVEA.L #X_FLAG,A3
             BSR PSTR
             LSL.B #1,D4
             BSR PRINT_BIT

             BSR SPACE
             MOVEA.L #N_FLAG,A3
             BSR PSTR
             LSL.B #1,D4
             BSR PRINT_BIT

             BSR SPACE
             MOVEA.L #Z_FLAG,A3
             BSR PSTR
             LSL.B #1,D4
             BSR PRINT_BIT

             BSR SPACE
             MOVEA.L #V_FLAG,A3
             BSR PSTR
             LSL.B #1,D4
             BSR PRINT_BIT

             BSR SPACE
             MOVEA.L #CARRY_FLAG,A3
             BSR PSTR
             LSL.B #1,D4
             BSR PRINT_BIT


             BSR NEW_LINE
             MOVE.B #0,D2

             MOVEA.L RAMBASE.L,A6

             LEA.L USER_DATA(A6),A3

REG1         MOVE.B #"D",D0
             BSR COUT
             MOVE.B D2,D0
             BSR OUT1X
             MOVE.B #"=",D0
             BSR COUT

             MOVE.L (A3)+,D0
             BSR OUT8X
             ADDQ.B #1,D2
             CMPI.B #8,D2
             BEQ.S REG4
             BSR SPACE

             CMPI.B #4,D2
             BNE.S REG1
             BSR NEW_LINE
             BRA.S REG1

REG4         BSR NEW_LINE
             MOVE.B #0,D2

REG3         MOVE.B #"A",D0
             BSR COUT
             MOVE.B D2,D0
             BSR OUT1X
             MOVE.B #"=",D0
             BSR COUT

             MOVE.L (A3)+,D0
             BSR OUT8X
             ADDQ.B #1,D2
             CMPI.B #8,D2
             BEQ.S REG2
             BSR SPACE

             CMPI.B #4,D2
             BNE.S REG3
             BSR NEW_LINE
             BRA.S REG3

REG2         BSR NEW_LINE
             RTS




; SEND '0' OR '1' TO SCREEN

PRINT_BIT   BCS.S WRITE_1
            MOVE.B #"0",D0
            BSR COUT
            RTS

WRITE_1     MOVE.B #"1",D0
            BSR COUT
            RTS

; JUMP TO USER PROGRAM
; 

JUMP       LEA.L JUMP_TO.L,A3
           BSR PSTR

           MOVEA.L RAMBASE.L,A6
           MOVE.L USER_PC(A6),D0
           BSR OUT6X
           MOVE.B #">",D0

           BSR COUT

           BSR GET_HEX

           BCLR.B #BIT_ESC,FLAG(A6); TEST BIT_ESC BIT
           BNE.S ABORT             ; IF BIT = 1 THEN EXIT

           BCLR.B #1,FLAG(A6)  ; CHECK IF ENTER KEY PRESSED
           BNE.S JUMP1         ; RUN USER PROGRAM

           CLR.L D6
           BSR GET_ADDRESS1

; GOT D6 FOR DESTINATION

           MOVE.L D6,USER_PC(A6)  ; SAVE TO USER PC
           BRA.S JUMP1

ABORT      RTS                 ; GET BACK MONITOR

JUMP1      MOVEA.L RAMBASE.L,A6     ; POINTED TO START MONITOR RAM

           MOVEA.L USER_USP(A6),A0
           MOVE.L  A0,USP           ; WRITE TO REAL USER STACK (A7)

           MOVE.L  USER_PC(A6),-(SP)     ; PUSH PC

           BCLR.B   #5,USER_SR(A6) ; SET USER MODE     

           MOVE.W  USER_SR(A6),-(SP)
           MOVEM.L USER_DATA(A6),D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6
           RTE                     ; JUMP TO USER PROGRAM


; TRACE JUMP
; SET TRACE BIT IN SAVED STATUS REGISTER

TRACE_JUMP LEA.L TRACE_MSG.L,A3
           BSR PSTR
           BSR NEW_LINE

           MOVEA.L RAMBASE.L,A6
           MOVEA.L USER_PC(A6),A4
           MOVEM.L (A4),D0/D1/D2
           MOVEA.L RAMBASE.L,A5
           ADDA.L #BUFFER,A5      ; LOAD A5 WITH $130000+BUFFER

           JSR  DCODE68K.L


           BSR NEW_LINE
           BSR PRINT_LINE

           MOVEA.L RAMBASE.L,A6

           BSET.B #TRACE_BIT,USER_SR(A6)  ; SET TRACE BIT
           BRA JUMP1                    ; BORROW JUMP ROUTINE

; CLEAR MONITOR RAM

CLEAR_MON_RAM MOVEA.L RAMBASE.L,A6
              MOVE.W  #512,D7

CLEAR1        MOVE.W #0000,(A6)+
              DBRA D7,CLEAR1
              RTS



; MODIFY USER REGISTERS

MODIFY_REG    MOVEA.L RAMBASE.L,A6
              BSR CIN
              AND.B #$DF,D0
              CMPI.B #"P",D0
              BNE.S DATA_REGP

              MOVE.B #"C",D0
              BSR COUT
              MOVE.B #"=",D0
              BSR COUT
              BSR GET_ADDRESS

              MOVE.L D6,USER_PC(A6)
              RTS

DATA_REGP     CMPI.B #"D",D0
              BNE.S ADDRESS_REGP
              BSR CIN
              SUB.B #"0",D0

              CLR.L D7
              MOVE.B D0,D7

              MOVE.B #"=",D0
              BSR COUT

              BSR GET_32BIT

              LSL.B #2,D7        ; D7*4
              ADDA.W D7,A6
              MOVE.L D6,USER_DATA(A6)  ; SAVE TO USER DATA REGISTERS

              RTS
              
ADDRESS_REGP  CMPI.B #"A",D0
              BNE.S WHATP
              BSR CIN
              SUB.B #"0",D0

              CLR.L D7
              MOVE.B D0,D7

              MOVE.B #"=",D0
              BSR COUT

              BSR GET_32BIT

              LSL.B #2,D7        ; D7*4
              ADDA.W D7,A6
              MOVE.L D6,USER_ADDR(A6)  ; SAVE TO USER ADDRESS REGISTERS

WHATP         RTS

;=======================================================================
; TRAP #N SERVICES
;

SERVICE_TRAP0   MOVE.L A0,-(SP)      ; SAVE A0 BEFOREHAND
                MOVEA.L RAMBASE.L,A0  ; USE A0 AS THE POINTER
                LEA.L USER_DATA(A0),A0
                MOVEM.L D0/D1/D2/D3/D4/D5/D6/D7/A0/A1/A2/A3/A4/A5/A6,(A0)
                MOVE.L (SP)+,32(A0)  ; RESTORE A0

                MOVEA.L RAMBASE.L,A0
                MOVE.W (SP)+,USER_SR(A0)
                BCLR.B #TRACE_BIT,USER_SR(A0) ; TURN TRACE BIT OFF
                MOVE.L (SP)+,USER_PC(A0)

                MOVE.L USP,A2
                MOVE.L A2,USER_USP(A0)

                BSR DISPLAY_REG1

                MOVE.L #SUPER_STACK,SP  ; REINIT SYSTEM STACK
                MOVE.W #INT_ON,SR   ; REENTER SUPERVISOR MODE

                JMP LOOP.L        ; GET BACK MONITOR


; DISASSEMBLE THE MACHNIE CODE INTO MNEMONIC

DISASSEMBLE     LEA.L DIS.L,A3
                BSR PSTR

           ;   LEA.L $102000.L,A4

               MOVEA.L RAMBASE.L,A6

               MOVE.W #19,D7       ; 20 LINES DISASSEMBLE

               MOVEA.L POINTER_NOW(A6),A4

DIS1           MOVEM.L (A4),D0/D1/D2
               MOVEA.L RAMBASE.L,A5
               ADDA.L #BUFFER,A5      ; LOAD A5 WITH $130000+BUFFER

               MOVEM.L A6/D7,-(SP)

               JSR  DCODE68K.L

               BSR NEW_LINE
               BSR PRINT_LINE

               MOVEM.L (SP)+,D7/A6

               DBRA D7,DIS1

               MOVE.L A4,POINTER_NOW(A6) ; NEXT BLOCK
               BSR NEW_LINE
               RTS

PRINT_LINE     MOVE.B (A5)+,D0
               BSR COUT
               CMPA.L A5,A6
               BNE.S PRINT_LINE
               RTS


; UPLOAD BINARY IMAGE FROM MEMORY
; SEND IT TO TERMINAL AS HEX CODE IN LONG WORD FORMAT
; USE FOR DISASSEMBLER HEX CODE PREPARATION

UPLOAD        LEA.L UPLOAD1.L,A3
              BSR PSTR
              BSR CIN

              LEA.L $100400.L,A5    ; START
              LEA.L $102000.L,A6    ; STOP

UPLOAD3       BSR NEW_LINE
              LEA.L STRING1.L,A3
              BSR PSTR

              MOVE.W #7,D7

UPLOAD2       MOVE.B #"$",D0
              BSR COUT
              MOVE.L (A5)+,D0
              BSR OUT8X
              MOVE.B #",",D0
              BSR COUT
              DBRA D7,UPLOAD2

              CMPA.L A5,A6
              BGT  UPLOAD3

              RTS

; ABOUT zBUG V1.0

ABOUT         LEA.L ABOUTZBUG.L,A3
              BSR PSTR
              RTS

; VIEW USER STACK

VIEW_USP      LEA.L VIEW.L,A3
              BSR PSTR

              BSR NEW_LINE

              MOVEA.L #SUPER_STACK+USER_STACK,A1 ; TOP OF USER STACK

              LEA.L -32(A1),A0    ; EACH COMPOSED OF TWO BYTES

              MOVE.W #16,D7
              MOVEA.L RAMBASE.L,A6


VIEW1         MOVE.L A0,D0

              MOVE.L D0,-(SP)

              CMPA.L USER_USP(A6),A0
              BNE.S NOT_TOS

              LEA.L TOP_OF_STACK.L,A3
              BSR PSTR
              BRA.S SKIP_PRINT_BLANK

NOT_TOS       LEA.L BLANK_BLOCK.L,A3
              BSR PSTR

SKIP_PRINT_BLANK

              MOVE.L (SP)+,D0
              BSR OUT6X
              BSR SPACE

              MOVE.B #"[",D0
              BSR COUT

              MOVE.W (A0)+,D0
              BSR OUT4X

              MOVE.B #"]",D0
              BSR COUT

              BSR NEW_LINE
              DBRA D7,VIEW1

              RTS


; LOAD SP WITH [RAM] AND PC [RAM+4]

BOOT_RAM      MOVEA.L RAM.L,SP
              MOVEA.L 4+RAM.L,A0
              JMP     (A0)


;----------------------- STRING CONSTANT -------------------------------------

TITLE  dc.b 13,10,"zBug V1.0 for 68000-Based Single Board Computer",13,10,0
TITLE1 dc.b 13,10,"zBug V1.0 for 68000-Based Single Board Computer (press ? for help)",13,10,0

PROMPT dc.b ">",0

CLEAR  dc.b "lear memory with 0x0000",0
FILL   dc.b "ill memory with 0xFFFF",0 
START  dc.b 13,10,10,"start address=",0
STOP   dc.b 13,10,"stop  address=",0
DONE   dc.b 13,10,"done...",0

EDIT1  dc.b "dit memory (quit: SPACE BAR, next address: ENTER)",0
EDIT   dc.b 13,10,10,"Address=",0
ROM    dc.b "  rom",0

NEW    dc.b "ew 24-bit pointer",0

QUICK  dc.b "uick home, get back to start of RAM!",13,10,0
HEX    dc.b "ex dump memory",13,10,10
       dc.b "ADDRESS  0  1  2  3  4  5  6  7  8  9  A  B  C  D  E  F",0

LOAD   dc.b "oad Motorola s-record (accept s2 and s8) quit: ESC",13,10,0

NUMBER dc.b " bytes loaded, ",0
ERROR  dc.b " records checksum error",13,10,0

JUMP_TO dc.b "ump to user program ",0 

TRAP_0 dc.b " TRAP 0 !",0

REGISTER_DISP dc.b "egister(user) display (A7= user stack pointer)",0

DIS    dc.b "isassemble machine code to mnemonic",13,10,0

UPLOAD1 dc.b "pload binary image, hit any key to begin ",0
STRING1 dc.b "  DFL ",0

ABOUTZBUG dc.b "bout zBuG V1.0",13,10,10
          dc.b "zBug V1.0 Copyright (C) 2002 W.SIRICHOTE",13,10,0

TRACE_MSG dc.b "race instruction",0

VIEW      dc.b "tack (user)'s content, shows 16-WORD deep",13,10,0

TOP_OF_STACK dc.b "TOS--->",0
BLANK_BLOCK  dc.b "       ",0

PC_REG dc.b "PC=",0
SR_REG dc.b "SR=",0

CARRY_FLAG dc.b "C=",0
V_FLAG     dc.b "V=",0
Z_FLAG     dc.b "Z=",0
N_FLAG     dc.b "N=",0
X_FLAG     dc.b "X=",0


HELP_LIST dc.b " monitor commands",13,10,10

       dc.b "A   About zBug V1.0",13,10
       dc.b "B   Boot from RAM [100000] -> SP [100004] ->PC",13,10
       dc.b "C   Clear memory with 0x0000",13,10
       dc.b "D   Disassemble machine code to mnemonic",13,10
       dc.b "E   Edit memory",13,10
       dc.b "F   Fill memory with 0xFFFF",13,10
       dc.b "H   Hex dump memory",13,10
       dc.b "J   Jump to address",13,10
       dc.b "L   Load Motorola s-record",13,10
       dc.b "N   New 24-bit pointer",13,10
       dc.b "R   Register(user) display",13,10
       dc.b "S   Stack(user)'s content",13,10
       dc.b "T   Trace instruction",13,10
       dc.b ".   Modify user registers, exp .PC .D0 .A0",13,10
       dc.b "?   Monitor commands list",13,10,0


; MONITOR'S RAM AREA
; MUST BE EVEN ADDRESS FOE RAMBASE
; THE A6 WAS LOADED WITH RAMBASE AS THE BASE MEMORY POINTER
; THE FOLLOWING VARIABLE CAN BE ACCEESED BY USING INDIRECT WITH DISPLACMENT

;RAMBASE     DFL   $130000     ; RAM BASE ADDRESS

; OFFSET(DISPLACEMENT) DEFINITION

OFFSET      EQU  0               ; FOR DISASSEMBLER USAGE
DEBUG       EQU  OFFSET+32
FLAG        EQU  DEBUG+4         ; 16-BIT MONITOR FLAG
BUFFER      EQU  FLAG+2
POINTER_NOW EQU  BUFFER+128
USER_DATA   EQU  POINTER_NOW+4   ; USER D0-D7 AND A0-A7
USER_ADDR   EQU  USER_DATA+32    ; USER ADDRESS REGISTERS, A0-A7
USER_USP    EQU  USER_ADDR+28    ; A7 = USP
USER_SR     EQU  USER_USP+4      ; 
USER_SS     EQU  USER_SR+2
USER_PC     EQU  USER_SS+4

STACK_AREA  EQU  USER_PC+4           ; 32kB USER STACK
USER_STACK  EQU  STACK_AREA+$7000    ; TOP OF STACK



       END


