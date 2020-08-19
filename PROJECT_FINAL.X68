*————————————————————————————————————
* Title      :  Hexspeak Disassembler
* Written by :  Mitchell Dang, Julia Brosseau, Andrew Goupinets
* Date       :  July 19 - August 10, 2020
* Description:  This is the reverse assembler for the Motorola MC68000
*               Microprocessor created as a group project for CSS 422:
*               Hardware and Computer Organization at University of
*               Washington Bothell taught by Professor Yang Peng.
*------------------------------------------------------------------------
CR          EQU         $0D
LF          EQU         $0A
DOLLAR      EQU         $24
TAB         EQU         $09
OUTPUTLINE_LOCATION  EQU     $5000


*/////////////////////////////////////////////////////////////////
*
*                        MAIN METHOD
*
*
*////////////////////////////////////////////////////////////////

START       ORG         $1000
         

* ================= WELCOME SCREEN PROMPT ================= *
WELC                  
            MOVE.B      #1, LINES_ON_SCREEN ; START COUNTING LINES ON SCREEN
            LEA         WELCOME,A1      ; LOAD WELCOME PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT WELCOME PROMPT

STADDR      ADD.B       #1, LINES_ON_SCREEN
            LEA         STARTADDR,A1    ; LOAD START PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT START PROMPT
            MOVEA.L     #0,A1

            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ START ADDRESS

            ; TODO: ERROR HANDLING/INPUT VALIDATION


STORESTARTADD
            CMP.B       #$8,D1          ; STORE STARTING ADDRESS
            BLE         STORESTARTADD_1

STRTADDR_OVERFLOW
            ADD.B       #1, LINES_ON_SCREEN
            LEA         TOOLONGADDR,A1          ; INVALID ADDR. TOO LONG
            MOVE.B      #13,D0
            TRAP        #15
            BRA         STADDR

STORESTARTADD_1
            JSR         ASCII2HEX	    ; Convert starting address to hex. Stored at D3
            ; VERIFY THAT FIRST 4 DIGITS ARE O'S
            ; TEMPORARILY STORE THE ADDRESS TO D2
            MOVE.L      D3, D2
            CMP.L       #$00FFFFFF,D2
            BGT         STRTADDR_OVERFLOW    ; CATCH ADDRESS GREATER THAN FFFFFF
            ; REJECT ANYTHING OVER $00FFFFFF
            ; NEED TO ENSURE THAT FIRST 2 DIGITS ARE 0'S

            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            AND.L       #$000000FF,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 2
            CMP.B       #$00,D2       ; FIRST 2 DIGITS OF START ADDRESS MUST BE 0'S
            BNE         STORESTARTADD_2_ERROR

STORESTARTADD_2_NOTERROR
            ; CHECK IF NEXT 2 DIGITS ARE 00'S, IF NOT, SKIP CHECK OF BEING UNDER 9000
            CLR         D2
            MOVE.L      D3, D2
            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            AND.L       #$000000FF,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 2
            CMP.B       #$00,D2       ; FIRST 2 DIGITS OF START ADDRESS MUST BE 0'S
            BNE         STORESTARTADD_2

STORESTARTADD_2_NEXT
            ; VERIFIES THAT SECOND PART OF PROVIDED ADDRESS (LAST 4 DIGITS MATCH THE START ADDRESS CRITERIA)
            ; BETWEEEN $0 TO $9000 WILL BE REJECTED
            CLR         D2
            MOVE.L      D3, D2
            ROL.L       #$08,D2
            ROL.L       #$08,D2
            ROL.L       #$04,D2
            AND.L       #$0000000F,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 1, WHICH WILL BE 9 IF GIVEN $00009000
            CMP.B       #$09,D2
            BGE         STORESTARTADD_2 ;TECHNICALLY 9000 WILL BE LOWER THAN 0020 FOR EXAMPLE
            CMP.B       #$09,D2
            BLT         STORESTARTADD_2_ERROR

STORESTARTADD_2_ERROR
            CLR         D3
            CLR         D2
            CLR         D1
            CLR         D0
            MOVE.L      #0,A2
            ADD.B       #1, LINES_ON_SCREEN
            LEA         TOOLONGADDR,A1          ; INVALID ADDR. TOO LONG
            MOVE.B      #13,D0
            TRAP        #15
            BRA         STADDR

STORESTARTADD_2
            CLR         D2             ; CLEAR AFTER USING THE D2 AS TEMP STORAGE
            ; VALIDATE THAT ADDRESS IS OF EVEN NUMBER
            MOVE.L      D3, D2
            AND.B       #1, D2
            BEQ         STORESTARTADD_3

STARTODDERROR
            CLR         D3
            CLR         D2
            CLR         D1
            CLR         D0
            MOVE.L      #0,A2
            ADD.B       #1, LINES_ON_SCREEN
            LEA         ADDR_NOTEVEN,A1
            MOVE.L      #13,D0
            TRAP        #15
            BRA         STADDR

STORESTARTADD_3
            CLR         D2             ; CLEAR AFTER USING THE D2 AS TEMP STORAGE
            ; ONCE VERIFIED THAT ADDRESS IS VALID, STORE START ADDRESS IN D5
            MOVE.L      D3, D5          ; STORES START ADDRESS IN HEX INTO D5
            CLR         D3              ; CLEAR D3 AFTER USING IT
            MOVE.L      D5, A4          ; SAVE START ADDRESS IN A4 REGISTER

EADDR       ADD.B       #1, LINES_ON_SCREEN
            LEA         ENDADDR,A1      ; LOAD END PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT END PROMPT
            MOVEA.L     #0,A1

            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ END ADDRESS

            ; TODO: ERROR HANDLING/INPUT VALIDATION

STOREENDADD
            CMP.B       #$8,D1          ; VALIDATES THAT ADDRESS PROVIDED IS UNDER 6 DIGITS
            BLE         STOREENDADD_1

ENDADDR_OVERFLOW
            ADD.B       #1, LINES_ON_SCREEN
            LEA         TOOLONGADDR,A1          ; INVALID ADDR. TOO LONG
            MOVE.B      #13,D0
            TRAP        #15

            BRA         EADDR

STOREENDADD_1
            JSR         ASCII2HEX	    ; Convert starting address to hex. Stored at D3

            ; REJECT ANYTHING OVER $00FFFFFF
            ; NEED TO ENSURE THAT FIRST 2 DIGITS ARE 0'S
            MOVE.L      D3, D2
            CMP.L       #$00FFFFFF,D2
            BGT         ENDADDR_OVERFLOW    ; CATCH ADDRESS GREATER THAN FFFFFF
            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            AND.L       #$000000FF,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 2
            CMP.B       #$00,D2       ; FIRST 2 DIGITS OF START ADDRESS MUST BE 0'S
            BNE         STOREENDADD_2_ERROR

STOREEAADDRGOODSOFAR
            ; CHECK IF NEXT 2 DIGITS ARE 00'S, IF NOT, SKIP CHECK OF BEING UNDER 9000
            CLR         D2
            MOVE.L      D3, D2
            
            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            ROL.L       #$08,D2  ; MOVE FIRST 2 DIGITS IN PLACE OF LAST 2 DIGITS
            AND.L       #$000000FF,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 2
            CMP.B       #$00,D2       ; FIRST 2 DIGITS OF START ADDRESS MUST BE 0'S
            BNE         STOREENDADD_2

STOREENDADD_2_NEXT
            ; VERIFIES THAT SECOND PART OF PROVIDED ADDRESS (LAST 4 DIGITS MATCH THE START ADDRESS CRITERIA)
            ; BETWEEEN $0 TO $9000 WILL BE REJECTED
            CLR         D2
            MOVE.L      D3, D2
            ROL.L       #$08,D2
            ROL.L       #$08,D2
            ROL.L       #$04,D2
            AND.L       #$0000000F,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST 1, WHICH WILL BE 9 IF GIVEN $00009000
            CMP.B       #$09,D2
            BGE         STOREENDADD_2 ;TECHNICALLY 9000 WILL BE LOWER THAN 0020 FOR EXAMPLE
            CMP.B       #$09,D2
            BLT         STOREENDADD_2_ERROR

STOREENDADD_2_ERROR
            CLR         D3
            CLR         D2
            CLR         D1
            CLR         D0
            MOVE.L      #0,A2
            ADD.B       #1, LINES_ON_SCREEN
            LEA         TOOLONGADDR,A1          ; INVALID ADDR. TOO LONG
            MOVE.B      #13,D0
            TRAP        #15
            BRA         EADDR

STOREENDADD_2
            CLR         D2             ; CLEAR AFTER USING THE D2 AS TEMP STORAGE
            ; VALIDATE THAT ADDRESS IS OF EVEN NUMBER
            MOVE.L      D3, D2
            AND.B       #1, D2
            BEQ         STOREENDADD_3

ENDODDERROR
            CLR         D3
            CLR         D2
            CLR         D1
            CLR         D0
            MOVE.L      #0,A2
            ADD.B       #1, LINES_ON_SCREEN
            LEA         ADDR_NOTEVEN,A1
            MOVE.L      #13,D0
            TRAP        #15
            BRA         EADDR

STOREENDADD_3
            CLR         D2             ; CLEAR AFTER USING THE D2 AS TEMP STORAGE
            ; AT THIS POINT THE CONTENT OF D3 WAS VALIDATED
            MOVE.L      D3, D6          ; STORES END ADDRESS IN HEX INTO D6
            CLR         D3              ; CLEAR D3 AFTER USING IT

            ; AT THIS POINT SUCCESSFULLY STORED START AND END ADDRESSES;
            ; VALIDATE IF END ADDRESS >=START ADDRESS
COMPARESTARTENDADDR
            CMP.L   D5,D6
            BGE     STARTNEWLINE

STARTENDMISMATCH
            ADD.B       #1, LINES_ON_SCREEN
            LEA         INVALID_RANGE,A1
            MOVE.L      #13,D0
            TRAP        #15
            BRA         EADDR


STARTNEWLINE ;MOVE.B  #0, LINES_ON_SCREEN ; START COUNTING LINES ON SCREEN

ADDRESSLOOP
            CMP.L      D5,D6       ; COMPARE START/CURRENT AND END ADDRESSES
            BLT        GOAGAIN     ; GIVE OPTION TO RESTART IF START IS MORE THAN END ADDRESS

LIMITLINESONSCREEN

            CMP.B       #29, LINES_ON_SCREEN ; LIMIT OF 30 LINE + QUESTION AT END
            BLE         FILLOUTPUTLINE  ; IF UNDER 30, FILL AND PRINT LINES
            JSR         ASKIFPRINTNEXTLINE   ; IF MORE - ASK IF PRINTING MORE IS NEEDED

FILLOUTPUTLINE:
            ADD.B   #1, LINES_ON_SCREEN ; COUNT THE LINE THAT IS ABOUT TO BE PRINTED
            LEA     OUTPUTLINE_LOCATION, A6 ; ASSOCIATE OUTPUT_LOCATION AND A6

ADDADDRINTOLINE:
            MOVE.L  D5,D3   ; COPY CURRENT ADDRESS INTO D3 FOR CONVERSION
            JSR L_HEXTOASCII    ; FIRST CONVERT ADDRESS STORED IN HEX INTO ASCII -> A2 HAS RESULT

ADDRTOLINELOOP:
            MOVE.B      (A2)+, (A6)+    ; CARRY OVER ONE CHAR AT A TIME FROM A2 TO A6
            BNE.S       ADDRTOLINELOOP  ; TEST FOR END OF STRING, CONTINUE IF NOT
            SUBQ        #$1, A6          ; REMOVE THE NULL TERMINATOR FROM CARRIEVED OVER ADDRESS
            MOVE.B      #TAB,(A6)+   ; KEEP ON ADDING WHAT YOU WANT TO PRINT

            ; CHECK IF CONTENT OF (A4) IS NOT #$0000FFFF (WHICH INDICATES THAT IT IS END OF FILE)

            ; PLACE TO D2 FOR PROCESSING (DECODING ONLY IF KNOW THAT THIS IS NOT END OF FILE)

            ; GO TO THE SUBROUTINES FOR THE OP CODES
            ; NEED TO PUT 4 HEX VALUES INTO D2 FOR PROCESSING ->
            ; SO SAY AT LOCATION $9000 WE HAVE '4E71' SO NEED TO MOVE IT TO D2
            ; 9000 IS INCREMENTED WITH EACH LOOP AND SAVED IN D5 AND A4

ISOPCODEVALID:
            MOVE.W  (A4),D2      ; MOVE CONTENTS OF CURRENT LOCATION TO DECOdE THE OPCODE
            AND.L   #$0000FFFF,D2 ; ENSURE THAT ONLY SEND 4 HEX DIGITS AT A TIME
            CMP.W   #$0000FFFF,D2   ; IF $FFFF IS PRESENT IN .S68 FILE MEANS IT IS END OF FILE OR INVALID IF ON ITS OWN
            BEQ     INVALID_OPCODE ; INVALID SINCE $FFFF

            CMP.W   #$0000FFFF,D2   ; IF $FFFF IS PRESENT IN .S68 FILE MEANS IT IS END OF FILE OR INVALID IF ON ITS OWN
            BNE     VALID_OPCODE ; NOT $FFFF, SO POTENTIALLY VALID ->SEND FOR PROCESSING


VALID_OPCODE:
            BRA SENDTOOPCODES
SENDTOOPCODES:
            CLR      D0
            CLR      D1
            CLR         D3              ; CLEAR D3 AFTER USING IT
            MOVE.L   #$00000000, A2
            ; D2 IS FILLED WITH DATA TO DECODE
            CLR.L       D0
            MOVE.L      D2,D0
            JMP      CHECKOPCODE ; GO TO DECODE THE 4 HEX VALUES GIVEN TO IT


PRINTA6     BRA      FINISHOUTPUTLINE ; IF VALID, SKIP INVALID MESSAGE

INVALID_OPCODE:
            MOVE.L      #$5009,A6
            
            MOVE.B      #'D',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'A',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'T',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'A',(A6)+   ; ERROR MESSAGE
            MOVE.B      #TAB,(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #DOLLAR,(A6)+   ; ERROR MESSAGE
            

ADDRFORERROR:
            MOVE.L  D2,D3   ; COPY CURRENT ADDRESS INTO D3 FOR CONVERSION
            JSR L_HEXTOASCII    ; FIRST CONVERT ADDRESS STORED IN HEX INTO ASCII -> A2 HAS RESULT
            ; SINCE IT IS A $FFFF (WORD), NEED TO SKIP FIRST 4 HEX DIGITS IN A2
            

ADDRFORERRORLOOP:
            MOVE.B      (A2)+, (A6)+    ; CARRY OVER ONE CHAR AT A TIME FROM A2 TO A6
            BNE.S       ADDRFORERRORLOOP ; TEST FOR END OF STRING, CONTINUE IF NOT
            SUBQ        #$1, A6          ; REMOVE THE NULL TERMINATOR FROM CARRIEVED OVER ADDRESS
            CLR.L       D2      ; ENSURE THAT D2 USED IS CLEAN

FINISHOUTPUTLINE:
            MOVE.B      #0, (A6)  ; EVERY LINE WILL NEED TO HAVE A NULL TERMINATOR TO BE PRINTED

            BRA         PRINTOUTPUTLINE


PRINTOUTPUTLINE:
            LEA         OUTPUTLINE_LOCATION, A1 ;USED TO PRINT RESULT OF
            MOVE.L      #13,D0  ; PRINT CONTENT OF LINE
            TRAP        #15

            MOVE.B      #$FF, (A6) ; PUT FF IN CURRENT LOCATION OF A6

CLEANOUTPUTAFTERFILLING:
           ; A6 WILL POINT TO THE END OF PREVIOUS OUTPUT ; replace previous line with F's
            CMP.L       #$5000,A6
            BEQ         NEXTLINE
            MOVE.B      #$FF,-(A6)
            BRA         CLEANOUTPUTAFTERFILLING

            ; LOOP TO READ NEXT LINE (SOME OP CODES ARE OK TO INCREMENT D5 AS WELL IF MORE THAN STANDARD 2 IS NEEDED)

NEXTLINE    ADD.L    #$2,D5      ; INCREMENT THE ADDRESS BY 2 (SOME OP CODES WILL ALSO INCREMENT THE ADDRESS BY MORE)
            MOVE.L      D5, A4   ; UPDATE A4 (CURRENT LOCATION) AS WELL
            BRA ADDRESSLOOP


ASKIFPRINTNEXTLINE:

            LEA         NEXTLINEPROMPT ,A1  ; LOAD NEXTLINEPROMPT PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT AGAIN PROMPT

            LEA         NEWLINERESPONSE,A1 ; LOAD USER RESPONSE VAR
            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ USER RESPONSE

            JSR         ASCII2HEX       ; CONVERT USER INPUT INTO HEX
            CLR         D3
            CMP.B       #$00,NEWLINERESPONSE ; IS USER INPUT AN ENTER KEY
            BEQ         PREPFORNEWLINE ; CONTINUE ANOTHER TIME

            ; NO, ASK IF WANT TO RUN AGAIN WITH NEW FILE
            JMP         GOAGAIN

PREPFORNEWLINE:
            CLR.L       D0                  ; CLEAR ALL VALUES
            CLR.L       D1                  ; NOTE: IN THE FUTURE ANY ADDITIONAL REGISTERS
            CLR.L       D2                  ; USED CAN BE CLEARED HERE TOO
            CLR.L       D3
            CLR.L       D7                  ; USED FOR CONVERTING TO HEX
            MOVE.L      #0,A1
            MOVE.L      #0,A2
            MOVE.L      #0,A3
            JMP         CLRSCRN

CLRSCRN MOVE.W   #$FF00,D1
        MOVE.B    #11,D0
        TRAP    #15
        MOVE.B  #0, LINES_ON_SCREEN
        JMP     STARTNEWLINE

*--------END OF PRINTING CONTENT OF DECODED LINE------*

            ; TODO: PROMPT FOR ADDITIONAL SEARCH, LOOP TO START IF YES
GOAGAIN     LEA         AGAINPROMPT,A1  ; LOAD AGAIN PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT AGAIN PROMPT

            LEA         USERRESPONSE,A1 ; LOAD USER RESPONSE VAR
            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ USER RESPONSE

            JSR         ASCII2HEX       ; CONVERT USER INPUT INTO HEX

            CMP.B       #$59,USERRESPONSE   ; IS USER INPUT 'Y'?
            BEQ         RESETVALUES         ; CONTINUE ANOTHER TIME
            CMP.B       #$79,USERRESPONSE   ; IS USER INPUT 'y'?
            BEQ         RESETVALUES         ; CONTINUE ANOTHER TIME
            ; ELSE USER MEANS NO

            JMP         DONE                ; FINISH

            

DONE        LEA         EXIT_MESS,A1
            MOVE.B      #13,D0
            TRAP        #15
            MOVE.B      #9,D0           ; USING TRAP TASK #9
            TRAP        #15             ; HALT SIMULATOR


RESETVALUES CLR.L       D0                  ; CLEAR ALL VALUES
            CLR.L       D1                  ; NOTE: IN THE FUTURE ANY ADDITIONAL REGISTERS
            CLR.L       D2                  ; USED CAN BE CLEARED HERE TOO
            CLR.L       D3                  ; USED FOR CONVERTING TO HEX
            CLR.L       D4
            CLR.L       D5                  ; USED CAN BE CLEARED HERE TOO
            CLR.L       D6
            CLR.L       D7
            MOVE.L      #0,A1
            MOVE.L      #0,A2
            MOVE.L      #0,A3
            MOVE.L      #0,A4
            MOVE.L      #0,A5
            MOVE.L      #0,A6
           ; ALSO CLEAR SCREEN
            MOVE.W      #$FF00,D1
            MOVE.B      #11,D0
            TRAP        #15
            JMP         WELC                ; GO BACK TO THE START


* ======================== END ======================== *
HEX2BIN_RSLT  EQU     $200




*/////////////////////////////////////////////////////////////////
*
*                        HEX TO BINARY
*
*
*////////////////////////////////////////////////////////////////


* Note for implementation:
*   1. Input:  move data to D2
*   2. Output: located at given addr.
*
*
*   HOW TO USE FROM OTHER SUBROUTINES:
*               MOVE.L      #$1100,A3       ; ADDRESS WHERE CONVERSION TAKES PLACE
*               MOVE.L      D2,(A3)         ; MOVE REGISTER VALUE INTO A3 ADDRESS
*               MOVEA.L     #$2000,A2       ; WHERE CONVERSION WILL SAVE TO
*               JSR         HEX2BIN         ; CONVERTS TWO VALUES OF HEX INTO EIGHT BINARY BITS
*               MOVE.L      $2000,D2        ; MOVES CONVERTED VALUE INTO D2
*

HEX2BIN:
            CLR     D1                  ; reset counter D1 to 0. every 1 hex digit ~ 4 digits in binary

            MOVE.B  D2,D7
            LSR.L   #4,D2               ; get the first digit
            JSR     HCHAR2BIN           ; convert the 1st hex digit  to  binary

            MOVE.B  D7,D2            ; retrieve the given hex value
            AND.B   #$0F,D2

            CLR     D1                  ; reset counter D1
            JSR     HCHAR2BIN           ;convert the 2nd hex digit to binary
            RTS                         ; end of subroutine

*------------ Start of helper subroutines for HEX2BIN ------------*

HCHAR2BIN   MOVE.B  D2,D4
            AND.B   #1,D2
            BEQ     rec_zero            ; if Z flag (zero) is set to 1. which means D2 is an even ==> D2 % 2 =0
            BNE     rec_one             ; otherwise, D2 is an odd ==>  D2 % 2 = 1
isZero      ADD.B   #1,D1               ; record a  new binary is added to D1.
            MOVE.B  D4,D2            ; get the last D2
            ASR.B   #1,D2               ; divide it by 2
            CMP.B   #0,D2               ; stop converting when the division reaches ZERO
            BNE     HCHAR2BIN           ; if not ZERO, keep converting
            JSR     GET_BIN             ; get the binary value
            RTS
rec_zero    LSR.L   #4,D3               ; record 0 as the remainder
            BRA     isZero
rec_one     LSR.L   #4,D3               ; record 1 as the remainder
            ADD.L   #$10000000,D3
            BRA     isZero
GET_BIN                                 ; fill missing zero(s). for example, 2 = 10 ==> 0010 (after filling zero)
fill_zero   CMP.B   #4,D1
            BEQ     doswap
            ADD.B   #1,D1
            LSR.L   #4,D3
            BRA     fill_zero
EOL         RTS
doswap      SWAP    D3
            MOVE.W  D3,(A2)+            ; store output binary to the given addr.
            BRA     EOL                 ; branch to EOL (End Of LooP) to exit the GET_BIN subrountine
*------------ End of helper subroutines for HEX2BIN ------------*

*=========  END OF SUBROUTINE FOR HEX2BIN  =========*






*/////////////////////////////////////////////////////////////////
*
*                        ASCII TO HEX
*
*
*////////////////////////////////////////////////////////////////


* NOTE FOR IMPLEMENTATION:
*       1. Input's location is held by A2.
*       2. Output's location is held by D3.
*       3. Length of the hex value is held by D1. (Input's location + Length = location of the last bit)
*

ASCII2HEX:  LEA         (A1),A2         ; COPY INPUT ADDR TO A2
            JSR         RmLeadZero
            JSR         A2HLOOP         ; START THE LOOP THAT CONVERT EACH STRING CHAR TO HEX
            CLR         D2              ; CLEAR D2 AFTER SUBROUTINE
            RTS
            
RmLeadZero  SUB.B       #1,D1           ; REMOVE LEADING ZERO BEFORE CONVERTING TO HEX
            CMP.B       #$30,(A2)+
            BEQ         RmLeadZero
            MOVE.B      -(A2),D2
            ADD.B       #1,D1
            CLR         D2
            RTS
A2HLOOP     CLR         D2
            MOVE.B      (A2)+,D2
            CMP.B       #$0,D2
            BEQ         EXIT_A2HL       ; $00 END OF STRING. BRANCH TO DISPLAYING RESULT
            CMP.B       #$FF,D2
            BEQ         EXIT_A2HL       ; $FF END OF STRING. BRANCH TO DISPLAYING RESULT
            CMP.B       #$61,D2
            BLT         A2HLOOPNEXT
            SUBI.B      #$20,D2

A2HLOOPNEXT
            CMP.B       #$30,D2         ; CHARACTER NOT IN [1..9] AND [A,Z]
            BLT         A2H_ERR         ; less than $30 ('0') ==> invalid
            CMP.B       #$46,D2         ; CHARACTER NOT IN [1..9] AND [A,Z]
            BGT         A2H_ERR         ; greater than $46 ('F') ==> invalid
            CMP.B       #$39,D2
            BLE         D2H1            ; start converting number in range [$30,$39] ~ ['0'-'9']
            BGT         D2H2            ; start converting number in range [$41,$46] ~ ['A'-'Z']

D2H1        SUB.B       #$30,D2         ; SUBTRACT $30
            ASL.L       #4,D3
            ADD.B       D2,D3
            BRA         NEXT_CHAR

D2H2        CMP.B       #$41,D2
            BLT         A2H_ERR         ; ERR IF $39 < D2 < $41 --> INVALID CHARACTERS
            SUB.B       #$37,D2         ; SUBTRACT $37 IF D2 IS IN [$41,$46] ~ ['A'-'Z']
            LSL.L       #4,D3
            ADD.B       D2,D3
            BRA         NEXT_CHAR

NEXT_CHAR   BRA         A2HLOOP         ; CONTINUE CONVERTING
EXIT_A2HL   RTS                         ; EXIT A2H LOOP

A2H_ERR     
            CLR.L       D3
            MOVE.L      #$0FFFFFFF,D3
            RTS
            
* ================== END OF SUBROUTINE TO CONVERT ASCII TO HEX ================== *





*/////////////////////////////////////////////////////////////////
*
*                        LONG HEX TO ASCII
*
*
*////////////////////////////////////////////////////////////////


* INPUT: D3 REGISTER MUST HAVE THE HEX VALUE
* OUTPUT: A2 REGISTER
* REGISTERS USED: D4 FOR COUNTER
                ; D7 FOR COPY OF D3 INPUT VALUE

L_HEXTOASCII:
            MOVE.B      #$8, D4         ; 8 IS THE COUNTER (LIMIT) SINCE WE OPERATE ON THE LONG
            BRA         L_HEXTOASCII_LOOP   ; EXECUTE LOOP THAT CONVERTS HEX TO ASCII
            RTS                         ; RETURN FROM SUBROUTINE

L_HEXTOASCII_LOOP:
            ROL.L       #4, D3          ; SHIFTS BITS TO LEFT AND ROTATES. FIRST BIT BECOMES LAST
            MOVE.L      D3,D7           ; STORE COPY AT D2 WHICH WILL HAVE BITS SHIFTED
            AND.L       #$0000000F,D7   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST ONE
            CMP.B       #9, D7          ; CHECK IF MORE THAN 9 (10 IS A, ETC)
            BGT         L_ISLETTER      ; CONVERT LETTER BASED ON ASCII TABLE

L_ISDIGIT
            ADD.W       #$30,D7         ; IS A NUMBER, SO ADD #$30 PER ASCII TABLE
            BRA         NEXT_L_H2A      ; CONTINUE AFTER DIGIT CONVERSION

L_ISLETTER
            ADD.W       #$37,D7         ; IS A CHAR (IS AT LEAST 10), SO ADD $37 (65-10=55 IN DECIMAL WHICH IS $37)
            BRA         NEXT_L_H2A      ; CONVERT THE LETTER TO ASCII LETTER

NEXT_L_H2A
            MOVE.B      D7, (A2)+       ; STORE EACH BIT TO A1 IN RIGHT ORDER
            SUBQ        #1, D4          ; DECREMENT COUNTER
            CMP.B       #0, D4          ; CHECK IF END OF LOOP
            BNE         L_HEXTOASCII_LOOP   ; IF NOT, LOOP AGAIN

            MOVE.B      #0, (A2)        ; ASCII IS COMPLETE. PLACES NULL AT THE END OF STRING.
            SUB         #$8, A2         ; RETURNS TO THE START OF THE STRING
            RTS                        ; RETURN FROM SUBROUTINE

* ================== END OF SUBROUTINE TO CONVERT LONG HEX TO ASCII ================== *




*/////////////////////////////////////////////////////////////////
*
*                        DECODE OPCODES
*
*
*////////////////////////////////////////////////////////////////

CHECKOPCODE
            MOVE.W      (A4),D2
            MOVE.L      D2,-(SP)
            MOVE.L      D2,D0   
            LSR.L       #8,D2
            LSR.L       #4,D2          
            
            CMP.L       #$00000000,D2
            BEQ         SPECIAL_GROUP   ; SPECIAL GROUPS 1 HANDLING SPECIAL/INVALID OPCODES
            CMP.L       #$00000005,D2
            BEQ         SPECIAL_GROUP2  ; SPECIAL GROUPS 2 HANDLING SPECIAL/INVALID OPCODES
            CMP.L       #$00000003,D2   ; OPCODE IS GROUP 1
            BLE         GROUP1OPCODE
            CMP.L       #$00000004,D2   ; OPCODE IS GROUP 2
            BEQ         GROUP2OPCODE
            CMP.L       #$00000006,D2   ; OPCODE IS GROUP 3
            BEQ         GROUP3OPCODE
            CMP.L       #$00000008,D2   ; OPCODE IS GROUP 4
            BEQ         GROUP4OPCODE
            CMP.L       #$00000009,D2   ; OPCODE IS GROUP 5
            BEQ         GROUP5OPCODE
            CMP.L       #$0000000C,D2   ; OPCODE IS GROUP 6
            BEQ         GROUP6OPCODE
            CMP.L       #$0000000D,D2   ; OPCODE IS GROUP 7
            BEQ         GROUP7OPCODE
            CMP.L       #$0000000E,D2   ; OPCODE IS GROUP 8
            BEQ         GROUP8OPCODE

            ; OTHERWISE, IT IS BAD OPCODE AND SHOULD BE DISCARDED
            JMP         BAD_OPCODE
            
SPECIAL_GROUP
            MOVE.W      (A4),D2
            LSR.L       #8,D2
            CMP.W       #$4,D2
            BEQ         SPECIAL_SUB_MORETHAN8
            CMP.L       #$02,D2
            BEQ         SPECIAL_AND_IMMDATA
            CMP.L       #$06,D2
            BEQ         SPECIAL_ADD_MORETHAN8
            BRA         BAD_OPCODE
            
SPECIAL_GROUP2
            MOVE.W      (A4),D2
            LSR.L       #8,D2
            CMP.L       #$55,D2
            BEQ         SPECIAL_SUB_1TO8
            BRA         BAD_OPCODE

SPECIAL_ADD_1TO8
            MOVE.B      #'A',(A6)+      ; LOAD OPWORD
            MOVE.B      #'D',(A6)+
            MOVE.B      #'D',(A6)+
            MOVE.W      (A4),D2
            MOVE.L      D2,D0
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #8,D2
            CMP.W       #$0000,D2
            BEQ         SUB_1TO8_B      ; BYTE
            CMP.W       #$0001,D2
            BEQ         SUB_1TO8_W      ; WORD
            CMP.W       #$0010,D2
            BEQ         SUB_1TO8_L      ; LONG
            BRA         BAD_OPCODE

SPECIAL_ADD_MORETHAN8
            MOVE.B      #'A',(A6)+      ; LOAD OPWORD
            MOVE.B      #'D',(A6)+
            MOVE.B      #'D',(A6)+

            MOVE.W      (A4),D2
            MOVE.L      D2,D0
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #8,D2
            CMP.W       #$0000,D2
            BEQ         SUB_MORETHAN8_B ; BYTE
            CMP.W       #$0001,D2
            BEQ         SUB_MORETHAN8_W ; WORD
            CMP.W       #$0010,D2
            BEQ         SUB_MORETHAN8_L ; LONG
            BRA         BAD_OPCODE

SPECIAL_AND_IMMDATA
            MOVE.B      #'A',(A6)+      ; LOAD OPWORD
            MOVE.B      #'N',(A6)+
            MOVE.B      #'D',(A6)+
            MOVE.W      (A4),D2
            MOVE.L      D2,D0
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #8,D2
            CMP.L       #$0000,D2
            BEQ         SPECIAL_AND_B   ; BYTE
            CMP.L       #$0001,D2
            BEQ         SPECIAL_AND_W   ; WORD

            CMP.L       #$0010,D2
            BEQ         SPECIAL_AND_L   ; LONG

            BRA         BAD_OPCODE

SPECIAL_AND_B
            BRA         SUB_MORETHAN8_W

SPECIAL_AND_W
            BRA         SUB_MORETHAN8_W

SPECIAL_AND_L
            BRA         SUB_MORETHAN8_L

SPECIAL_SUB_1TO8                        ; CODE FOR SUBQ
            MOVE.B      #'S',(A6)+      ; LOAD OPWORD
            MOVE.B      #'U',(A6)+
            MOVE.B      #'B',(A6)+
            MOVE.W      (A4),D2
            MOVE.L      D2,D0
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #8,D2
            CMP.W       #$0000,D2
            BEQ         SUB_1TO8_B      ; BYTE
            CMP.W       #$0001,D2
            BEQ         SUB_1TO8_W      ; WORD
            CMP.W       #$0010,D2
            BEQ         SUB_1TO8_L      ; LONG
            BRA         BAD_OPCODE

SPECIAL_SUB_MORETHAN8                   ; CODE FOR SUBI
            MOVE.B      #'S',(A6)+      ; LOAD OPWORD
            MOVE.B      #'U',(A6)+
            MOVE.B      #'B',(A6)+

            MOVE.W      (A4),D2
            MOVE.L      D2,D0
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            LSR.L       #8,D2
            CMP.W       #$0000,D2
            BEQ         SUB_MORETHAN8_B ; BYTE
            CMP.W       #$0001,D2
            BEQ         SUB_MORETHAN8_W ; WORD
            CMP.W       #$0010,D2
            BEQ         SUB_MORETHAN8_L ; LONG
            BRA         BAD_OPCODE

SUB_1TO8_B
            JSR         PRINT_DOT_B
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            JSR         SUB_1TO8_EA
            BRA         GOOD_OPCODE
SUB_1TO8_W
            JSR         PRINT_DOT_W
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            JSR         SUB_1TO8_EA
            BRA         GOOD_OPCODE
SUB_1TO8_L
            JSR         PRINT_DOT_L
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            
            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            JSR         SUB_1TO8_EA
            BRA         GOOD_OPCODE




SUB_1TO8_EA                             ; EA FOR SUBQ
            MOVE.L      D0,D2
            AND.L       #$00000F00,D2
            LSR.L       #8,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2
            JSR         SPECIAL_MEM_GETREGISTER
            JSR         PRINT_COMM
            ; GET MACHINE CODE OF INSTRUCTION
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_DNEA_Dn
            CMP.L       #$0010,D2
            BEQ         GROUP56_DNEA_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_DNEA_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_DNEA_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_DNEA_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE

            CMP.L       #$0000,D2
            BEQ         BAD_OPCODE          ; NO Dn
            CMP.L       #$0001,D2
            BEQ         BAD_OPCODE          ; NO An
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE          ; NOT REQUIRED EA
            RTS


SPECIAL_MEM_GETREGISTER                     ; SUBROUTINE FOR PRINTING REGISTER
            CMP.W       #$0000,D2
            BEQ         PRINT_8             ; EX MOVE.L D2 by this step
            CMP.W       #$0001,D2
            BEQ         PRINT_1
            CMP.W       #$0010,D2
            BEQ         PRINT_2
            CMP.W       #$0011,D2
            BEQ         PRINT_3
            CMP.W       #$0100,D2
            BEQ         PRINT_4
            CMP.W       #$0101,D2
            BEQ         PRINT_5
            CMP.W       #$0110,D2
            BEQ         PRINT_6
            CMP.W       #$0111,D2
            BEQ         PRINT_7
            RTS
SUB_MORETHAN8_B                             
            JSR         PRINT_DOT_B
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+

            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            MOVE.W      (A4)+,D3
            MOVE.W      (A4),D3

            ADD.L       #2,D5
            JSR         L_HEXTOASCII
            JSR         ADDRBYTELOOP
            JSR         PRINT_COMM
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY      ; CONVERT TO BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_DNEA_Dn
            CMP.L       #$0010,D2
            BEQ         GROUP56_DNEA_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_DNEA_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_DNEA_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_DNEA_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE

            CMP.L       #$0000,D2
            BEQ         BAD_OPCODE          ; NO Dn
            CMP.L       #$0001,D2
            BEQ         BAD_OPCODE          ; NO An
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE          ; NOT REQUIRED EA
SUB_MORETHAN8_W
            JSR         PRINT_DOT_W
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            MOVE.W      (A4)+,D3
            MOVE.W      (A4),D3
            ADD.L       #2,D5
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP
            JSR         PRINT_COMM
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY      ; CONVERT TO BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_DNEA_Dn
            CMP.L       #$0010,D2
            BEQ         GROUP56_DNEA_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_DNEA_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_DNEA_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_DNEA_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE

            CMP.L       #$0000,D2
            BEQ         BAD_OPCODE          ; NO Dn
            CMP.L       #$0001,D2
            BEQ         BAD_OPCODE          ; NO An
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE          ; NOT REQUIRED EA

SUB_MORETHAN8_L
            JSR         PRINT_DOT_L
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+

            MOVE.B      #TAB,(A6)+

            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            MOVE.W      (A4)+,D3
            MOVE.L      (A4),D3

            ADD.L       #4,D5
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            JSR         PRINT_COMM
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY      ; CONVERT TO BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_DNEA_Dn
            CMP.L       #$0010,D2
            BEQ         GROUP56_DNEA_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_DNEA_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_DNEA_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_DNEA_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE

            CMP.L       #$0000,D2
            BEQ         BAD_OPCODE          ; NO Dn
            CMP.L       #$0001,D2
            BEQ         BAD_OPCODE          ; NO An
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE          ; NOT REQUIRED EA



; EASY METHOD TO CONVERT $000000XX INTO BINARY
CONVERT2BINARY
            MOVE.L      #$110,A3       ; ADDRESS WHERE CONVERSION TAKES PLACE
            MOVE.L      D2,(A3)         ; MOVE REGISTER VALUE INTO A3 ADDRESS
            MOVEA.L     #$200,A2       ; WHERE CONVERSION WILL SAVE TO

            JSR         HEX2BIN         ; CONVERTS TWO VALUES OF HEX INTO EIGHT BINARY BITS
            MOVE.L      $200,D2         ; MOVES CONVERTED VALUE INTO D2

            RTS

EASTUFF2
            MOVEM.L     D2,-(SP)        ; SAVES BINARY BITS TO STACK FOR EAGROUP1/2
            AND.L       #$00111000,D2   ; CHECK SIZE EA MODE

            CMP.L       #$00100000,D2   ; CHECK 00XXX000 WHERE XXX IS FROM 000 TO 100
            BLE         EAGROUP1        ; EA MODE IS PART OF GROUP 1

            CMP.L       #$00101000,D2   ; BAD EA
            BEQ         BAD_OPCODE

            CMP.L       #$00110000,D2   ; BAD EA
            BEQ         BAD_OPCODE

            CMP.L       #$00111000,D2   ; CHECK 00XXX000 WHERE XXX IS 111
            BEQ         GROUP2_IMMADDR        ; EA MODE IS PART OF GROUP 2
EASTUFF2_FINISH
            RTS


EAGROUP1
            ; DETERMINE WHICH EA MODE IT IS
            CMP.L       #$00000000,D2   ; DIRECT REGISTER Dn
            BEQ         DIRECTREGISTER

            CMP.L       #$00001000,D2   ; ADDRESS REGISTER DIRECT An
            BEQ         ADDRESSREGDIRECT

            CMP.L       #$00010000,D2   ; ADDRESS REGISTER INDIRECT (An)
            BEQ         ADDRESSREGINDIRECT

            CMP.L       #$00011000,D2   ; ADDRESS REGISTER W/POST
            BEQ         ADDRESSREGPOST

            CMP.L       #$00100000,D2   ; ADDRESS REGISTER W/PRE
            BEQ         ADDRESSREGPRE


            CMP.L       #$00101000,D2   ; BAD EA
            BGE         BAD_OPCODE

FINISH_GROUP2
            RTS

GROUP2_IMMADDR                          ; SUBROUTINE FOR HANDLING ABSOLUTE ADDR .W .L AND IMMEDIATE DATA 
            MOVE.L     (SP)+,D2
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         GROUP2_IMMADDR_DOT_W        ; ABSOLUTE .W
            CMP.W       #$001,D2
            BEQ         GROUP2_IMMADDR_DOT_L        ; ABSOLUTE .L
            CMP.W       #$100,D2
            BEQ         GROUP2_IMMADDR_DATA         ; IMMEDIATE DATA

            BRA         BAD_OPCODE

GROUP2_IMMADDR_DATA                                 ; SUBROUTINE FOR GROUP2 IMMEDIATE DATA
            ADD.L       #2,D5
            MOVE.W      (A4),D2                     ; LOAD UNDECODED 4 BITS HEX  
            JSR         PRINT_HASH                  ; PRINT #
            JSR         PRINT_DOLLAR                ; PRINT $
            MOVE.W      (A4)+,D2                    ; SKIP  THE FIRST 4 BITS
            MOVE.W      (A4),D3                     ; GET THE NEXT 4 BIT
            JSR         L_HEXTOASCII                ; SUBROUTINE APPENDING IMMEDIATE DATA TO OUTPUT A6
            JSR         ADDRWORDLOOP
            JSR         PRINT_COMM
            BRA         EASTUFF2_FINISH             ; FINSIH

GROUP2_IMMADDR_DOT_L
            MOVE.B      #' ',(A6)+
            JSR         PRINT_DOLLAR
            ADD.L       #$4,D5
            MOVE.W      (A4)+,D2
            CLR         D2
            ; SUBROUTINE APPENDING IMMEDIATE DATA TO OUTPUT A6
            MOVE.L      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            
            JSR         PRINT_COMM
            BRA         EASTUFF2_FINISH

GROUP2_IMMADDR_DOT_W

            ADD.L       #$2,D5
   
            JSR         PRINT_DOLLAR

            MOVE.W      (A4)+,D2
            CLR         D2
            ; SUBROUTINE APPENDING IMMEDIATE DATA TO OUTPUT A6
            MOVE.W      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP

            JSR         PRINT_COMM
            BRA         EASTUFF2_FINISH


GROUP2_SRC_Dn                           ;  DATA REGITER AS SOURCE FOR GROUP 2
            JSR         PRINT_D
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    D0,
            BRA         GROUP2_DEST_EA   ; GO TO DESTINATION DECODING

GROUP2_SRC_An_VAL                       ; DIRECT ADDRESSING AS SOURCE FOR GROUP2
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0),
            BRA         GROUP2_DEST_EA       ; GO TO DESTINATION DECODING

GROUP2_SRC_An                           ; INDIRECT ADDRESSING AS SOURCE FOR GROUP2
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG  ; GET REGISTER FOR (An)
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0),
            BRA         GROUP2_DEST_EA       ; GO TO DESTINATION DECODING
GROUP2_SRC_An_PLUS                      ; POSINCREMENT (An)+
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG  ; GET REGISTER FOR (An)+
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0)+,
            BRA         GROUP2_DEST_EA       ; GO TO DESTINATION DECODING
GROUP2_SRC_MINUS_An                     ; PREDECREMENT AS SOURCE FOR GROUP2
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG  ; PRINT REGISTER FOR -(An)
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L   -(An),
            BRA         GROUP2_DEST_EA      ; GO TO DESTINATION DECODING


GROUP2_DEST_EA                          ; GENERAL SUBROUTINE HANDLING EA FOR DESTINATION OF GROUP2
            CLR         D2
            MOVE.W      D0,D2

            AND.L       #$00000FF0,D2   ; GET 2nd 3rd HEX BIT
            LSR.L       #4,D2           ; REMOVE THE LSB
            JSR         CONVERT2BINARY  ; GET BINARY BIT 4-11
            AND.L       #$000FFF00,D2   ; RESERVE BIT 6-8
            LSR.L       #8,D2           ; ELIMINATE BIT 4 5
            CMP.L       #$00000000,D2
            BEQ         GROUP2_DEST_Dn  ;  DATA ADDR
            CMP.L       #$00000010,D2
            BEQ         GROUP2_DEST_An  ; INDIRECT ADDR
            CMP.L       #$00000011,D2
            BEQ         GROUP2_DEST_An_PLUS ; POSRINCREMENT
            CMP.L       #$00000100,D2
            BEQ         GROUP2_DEST_MINUS_An    ; PREDECREMENT
            BRA         BAD_OPCODE          ; OTHERWISE, BAD OPCODE. PRINT DATA, RETURN BACK TO THE LOOP
    

GROUP2_DEST_Dn                              ; SUBROUTINE HANDLING DATA REGISTER AS DESTINATION OF GROUP2
            CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_D
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            BRA         FINISH_GROUP2       ;  BRANCH TO END OF GROUP2

GROUP2_DEST_An                              ; SUBROUTINE HANDLING INDIRECT ADDR AS DESTINATION OF GROUP2
            CLR         D2
            MOVE.W      D0,D2               ; GET ORIGINAL UNDECODED 4BITS IN HEX
            MOVE.L      D2,D0
            JSR         PRINT_OPENPAR       ; PRINT (
            JSR         PRINT_A             ; PRINT  A ==> (A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG ; GET  REGISTER FOR (An) ==> I.E: (A1
            JSR         PRINT_CLOSEPAR      ; PRINT ) ==> (A1)
            BRA         FINISH_GROUP2       ; BRANCH TO END OF GROUP2

GROUP2_DEST_An_PLUS                         ; SUBROUTINE HANDLING POST-INCREMENT AS DESTINATION OF GROUP2                
            CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            BRA         FINISH_GROUP2       ;  BRANCH TO END OF GROUP2

GROUP2_DEST_MINUS_An                        ; SUBROUTINE HANDLING PRE-DECREMENT AS DESTINATION OF GROUP2
            CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            BRA         FINISH_GROUP2       ; BRANCH TO END OF GROUP2




;;;;;===============

DIRECTREGISTER          
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER

            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG    ; DETERMINE WHICH REGISTER IT IS
            MOVE.B      #',',(A6)+
            RTS

ADDRESSREGDIRECT
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER

            MOVE.B      #'A',(A6)+
            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #',',(A6)+
            RTS

ADDRESSREGINDIRECT
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER

            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+

            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            MOVE.B      #',',(A6)+
            RTS

ADDRESSREGPOST
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER

            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+

            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            MOVE.B      #'+',(A6)+
            MOVE.B      #',',(A6)+
            RTS

ADDRESSREGPRE
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER

            MOVE.B      #'-',(A6)+
            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+

            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            MOVE.B      #',',(A6)+
            RTS


SETSIZE     ; HELPER SUBROUTINE SIMILAR TO PRINT_B, PRINT_W, PRINT_L TO PRINT OUT SIZE OF OPCODE.
            ; HOWEVER, THEY HAVE DIRRENT EXITING INSTRUCTION TO DIFFRENT SUBROUTINES. 
            CMP.L       #$00000000,D2
            BEQ         SETSIZEBYTE
            CMP.L       #$00000001,D2
            BEQ         SETSIZEWORD
            CMP.L       #$00000010,D2
            BEQ         SETSIZELONG
            CMP.L       #$00000011,D2
            BEQ         BAD_OPCODE
SETSIZE_FINISH
            RTS

SETSIZEBYTE
            MOVE.B      #'.', (A6)+
            MOVE.B      #'B',(A6)+
            BRA         SETSIZE_FINISH
SETSIZEWORD
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            BRA         SETSIZE_FINISH

SETSIZELONG
            MOVE.B      #'.',(A6)+
            MOVE.B      #'L',(A6)+
            BRA         SETSIZE_FINISH



DETERMINEREG
            CMP.L       #$00000000,D2   ; 0
            BEQ         REG0
            CMP.L       #$00000001,D2   ; 1
            BEQ         REG1
            CMP.L       #$00000010,D2    ; 2
            BEQ         REG2
            CMP.L       #$00000011,D2    ; 3
            BEQ         REG3
            CMP.L       #$00000100,D2    ; 4
            BEQ         REG4
            CMP.L       #$00000101,D2    ; 5
            BEQ         REG5
            CMP.L       #$00000110,D2    ; 6
            BEQ         REG6
            CMP.L       #$00000111,D2    ; 7
            BEQ         REG7

            RTS

REG0
            MOVE.B      #'0',(A6)+
            RTS
REG1
            MOVE.B      #'1',(A6)+
            RTS
REG2
            MOVE.B      #'2',(A6)+
            RTS
REG3
            MOVE.B      #'3',(A6)+
            RTS
REG4
            MOVE.B      #'4',(A6)+
            RTS
REG5
            MOVE.B      #'5',(A6)+
            RTS
REG6
            MOVE.B      #'6',(A6)+
            RTS
REG7
            MOVE.B      #'7',(A6)+
            RTS


; SUBROUTINE FOR PRINTING OUT AN OPERATION THAT HAS ALL PARTS SUCCESSFULLY DECODED
GOOD_OPCODE
            ; CLEARCACHEGOOD IS A LOOP THAT CLEANS OUT THE CACHE AND BACK TO $01000000
CLEARCACHEGOOD
            CMP.L       #$01000000,SP   ; $01000000 MEANS STACK IS EMPTY
            ; BNE         CLEANREGISTERS  ; IF REACH THIS POINT, EXIT ; JULIA ADDED THIS commented this out temp
            BEQ         CLEANREGISTERS  ; added this temp
            ; BEQ         CLEANREGISTERS  ; IF REACH THIS POINT, EXIT ; JULIA COMMENTED THIS
            MOVEM.L     (SP)+,D2        ; LOAD MEMORY INTO D1, IRRELEVENT AND CAN BE OVERWRITTEN
            ;JMP         CLEARCACHEBAD commented this out temp
            JMP         CLEARCACHEGOOD  ; added this temp

CLEANREGISTERS
            ; STACK IS NOW CLEAN, WIPE ANY OTHER REGISTERS THAT NEED TO BE CLEANED
            ; AFTER DONE, SHOULD JMP BACK TO ADDRESSLOOP TO CONTINUE DECIPHERING NEXT INSTRUCTION
            ; JMP       ADDRESSLOOP
            BRA         FINISHOUTPUTLINE  ; JULIA ADDED THIS




; SUBROUTINE FOR DEALING WITH BAD INPUT
BAD_OPCODE
            ; CLEARCACHEBAD IS A LOOP THAT CLEANS OUT THE CACHE AND LEAVES ONLY THE ORIGINAL
            ; UNDECIPHERED HEX INSTRUCTION IN D2
            ; FULL HEX INSTRUCTION SHOULD BE STORED IN STACK AT $00FFFFFC

CLEARCACHEBAD
            CMP.L       #$01000000,SP   ; $01000000 MEANS STACK IS EMPTY
            BEQ         PRINTBADINSTR   ; IF REACH THIS POINT, EXIT
            MOVEM.L     (SP)+,D2        ; LOAD MEMORY INTO D1, IRRELEVENT AND CAN BE OVERWRITTEN
            JMP         CLEARCACHEBAD




PRINTBADINSTR
             MOVE.L      D0,D2
             JMP         INVALID_OPCODE
            ; FULL UNDECIPHERED INSTRUCTION IS NOW INSIDE D2
            ; PRINT OUT ERROR MESSAGE

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 1 OPCODES
;
; THESE OPCODES INCLUDE: MOVE
;
GROUP1OPCODE
            ; CATCH MOVEA ==> CHECK FOR An AS DESTINATION
            MOVE.W      (A4),D2
            AND.L       #$00000FF0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            AND.L       #$000FFF00,D2
            CMP.L       #$00000100,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00010100,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00011000,D2   ; CHECK DESTINATION OPMODE
            BEQ         BAD_OPCODE
                        
            CLR.L       D2
            ; CATCH MOVEA ==> CHECK FOR An AS SOURCE
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY   
            AND.L       #$00FFF000,D2
            CMP.L       #$00001000,D2   ; CHECK SOURCE OPMODE
            BEQ         BAD_OPCODE      ; MOVEA
            
            JSR         PRINT_MOVE      ;
            CLR.L       D2
            MOVE.W      (A4),D2
            CLR.L       D0
            MOVE.L      D2,D0
            ; FOLLOWING LINE CHECK FOR SIZE OF MOVE
            LSR.L       #8,D2           ; 1234 ==> 0012
            LSR.L       #4,D2           ; 0012 ==> 0001; GET THE MSB
            JSR         CONVERT2BINARY
            AND.L       #$000000FF,D2   ; CHECK THE  LAST 2 BINARY BIT
            CMP.L       #$00000001,D2
            ; FOLLOWING LINES HANDLING SIZE AND CALL GROUP1_SRC_EA TO DECODE SOURCE'S EA
            BEQ         GROUP1_DOTB     
            CMP.L       #$00000011,D2
            BEQ         GROUP1_DOTW
            CMP.L       #$00000010,D2
            BEQ         GROUP1_DOTL

GROUP1_DOTB JSR         PRINT_DOT_B
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+
            BRA         GROUP1_SRC_EA

GROUP1_DOTW JSR         PRINT_DOT_W
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+
            BRA         GROUP1_SRC_EA

GROUP1_DOTL JSR         PRINT_DOT_L
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+
            BRA         GROUP1_SRC_EA
            ; FOLLOWING LINE DECODE SOURCE EA
GROUP1_SRC_EA                           ; GENERAL SUBROUTINE HANDLING EA AS SOURCE OF GROUP1
            CLR         D2
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2   ; GET THE LAST 2 HEX  BITS
            JSR         CONVERT2BINARY  ; CONVERT TO 8 BITS BINARY
            AND.L       #$00FFFFFF,D2   ; RESERVE BIT 0-5 FOR CHECKING
            LSR.L       #8,D2           ; ELIMINATE BIT 0-1
            LSR.L       #4,D2           ; ELIMATE BIT 2
            CMP.L       #$00000000,D2   ;
            BEQ         SRC_Dn          ; DATA ADDR
            CMP.L       #$00000001,D2
            BEQ         SRC_An_VAL      ; DIRECT ADDR
            CMP.L       #$00000010,D2
            BEQ         SRC_An          ; INDIRECT ADDR 
            CMP.L       #$00000011,D2
            BEQ         SRC_An_PLUS     ; POST_INCREMENT
            CMP.L       #$00000100,D2
            BEQ         SRC_MINUS_An    ; PRE-DECREMENT
            CMP.L       #$00000111,D2
            BEQ         GROUP1_SRC_IMMADDR  ; IMMDEDIATE ADDR
            BRA         BAD_OPCODE          ; OTHERWISE, BAD OPCODE

GROUP1_SRC_IMMADDR                          ; GENERAL SUBROUTINE HANDLING ABSOLUTE .W .L AND IMMEDIATE DATA AS SOURCE FOR GROUP 1
            
            MOVE.W      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         SRC_IMMADDR_DOT_W
            CMP.W       #$001,D2
            BEQ         SRC_IMMADDR_DOT_L
            CMP.W       #$100,D2
            BEQ         SRC_IMMADDR_DATA
            BRA         BAD_OPCODE

SRC_IMMADDR_DATA
            JSR         PRINT_HASH
            JSR         PRINT_DOLLAR
            CLR         D2
            MOVE.L      D0,D2
            LSR.L       #8,D2           ; 1234 ==> 0012
            LSR.L       #4,D2           ; 0012 ==> 0001; GET THE MSB
            JSR         CONVERT2BINARY
            AND.L       #$000000FF,D2   ; CHECK THE  LAST 2 BINARY BIT
            CMP.L       #$00000001,D2
            BEQ         SRC_IMMADDR_DATAB
            CMP.L       #$00000011,D2
            BEQ         SRC_IMMADDR_DATAW
            CMP.L       #$00000010,D2
            BEQ         SRC_IMMADDR_DATAL
            BRA         BAD_OPCODE

SRC_IMMADDR_DATAB
            ADD.L       #$2,D5
            MOVE.W      (A4)+,D2        ; SKIP THE FIRST 4 BIT OF INSTRUCTION
            CLR         D3
            MOVE.W      (A4),D3         ; COPY THE NEXT 4 BITS FOR IMMEDIATE ADDR
            JSR         L_HEXTOASCII
            JSR         ADDRBYTELOOP
            JSR         PRINT_COMM
            MOVE.L      D0,D2
            BRA         GROUP1_DEST_EA

SRC_IMMADDR_DATAW
            ADD.L       #$2,D5
            MOVE.W      (A4)+,D2        ; SKIP THE FIRST 4 BIT OF INSTRUCTION
            CLR         D3
            MOVE.W      (A4),D3         ; COPY THE NEXT 4 BITS FOR IMMEDIATE ADDR
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP
            JSR         PRINT_COMM
            MOVE.L      D0,D2
            BRA         GROUP1_DEST_EA
SRC_IMMADDR_DATAL
            ADD.L       #$4,D5
            MOVE.W      (A4)+,D2        ; SKIP THE FIRST 4 BIT OF INSTRUCTION
            CLR         D3
            MOVE.L      (A4),D3         ; COPY THE NEXT 4 BITS FOR IMMEDIATE ADDR
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            JSR         PRINT_COMM
            MOVE.L      D0,D2
            BRA         GROUP1_DEST_EA

SRC_IMMADDR_DOT_L                       ; ABSOLUTE ADDR .L AS SOURCE OF GROUP1
            
            JSR         PRINT_DOLLAR
            ADD.L       #$4,D5          ; UPDATE POINTER. D5 STORE CURRENT ADDR IN HEX
            MOVE.W      (A4)+,D2        ; SKIP THE FIRST 4 BITS OF INSTRUCTION
            CLR         D2

            MOVE.L      (A4),D3         ; GET THE NEXT 8 BITS OF THE ABSOLUTE ADDR
            ; L_HEXTOASCII CONVERT HEX TO ASCII. TAKING D3 AS INPUT
            ; APPENDING LONG ADDR TO OUTPUT A6 
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP

      
            JSR         PRINT_COMM
            BRA         GROUP1_DEST_EA  ; CONTINUE DECODING DESTINATION

SRC_IMMADDR_DOT_W                       ; ABSOLUTE ADDR .L AS SOURCE OF GROUP1
            ADD.L       #$2,D5          ; UPDATE POINTER. D5 STORE CURRENT ADDR IN HEX
           
            JSR         PRINT_DOLLAR    ; SKIP THE FIRST 4 BITS OF INSTRUCTION
    
            MOVE.W      (A4)+,D2
            CLR         D2
            ; L_HEXTOASCII CONVERT HEX TO ASCII. TAKING D3 AS INPUT
            ; APPENDING LONG ADDR TO OUTPUT A6 
            MOVE.W      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP

        
            JSR         PRINT_COMM
            BRA         GROUP1_DEST_EA  ; CONTINUE DECODING DESTINATION

SRC_Dn      JSR         PRINT_D         ; DATA REGISTER AS SOURCE 
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    D0,
            BRA         GROUP1_DEST_EA   ; GO TO DESTINATION DECODING

SRC_An_VAL
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0),
            BRA         GROUP1_DEST_EA       ; GO TO DESTINATION DECODING

SRC_An      JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0),
            BRA         GROUP1_DEST_EA       ; GO TO DESTINATION DECODING
SRC_An_PLUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0)+,
            BRA         GROUP1_DEST_EA       ; GO TO DESTINATION DECODING
SRC_MINUS_An
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.W      D0,D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L   -(An),
            BRA         GROUP1_DEST_EA      ; GO TO DESTINATION DECODING
SHIFTWORD                                   ; MOVING POINTER TO CORRECT POSITION 
                                            ; BEFORE READING FOR DESTINATION 
                                            ; DEPENDING ONSOURCE IS ALSO ABSOLUTE .L .W OR IMMEDIATE DATA 
            MOVE.W     (A4)+,D2
            BRA         GROUP1_DESTEA_NEXT
SHIFTLONG                                   ; MOVING POINTER TO CORRECT POSITION 
                                            ; BEFORE READING FOR DESTINATION 
                                            ; DEPENDING ON SOURCE IS ALSO ABSOLUTE .L .W OR IMMEDIATE DATA 

            MOVE.L      (A4)+,D2
            BRA         GROUP1_DESTEA_NEXT
SHIFT_IMMDATA                               ; ; MOVING POINTER TO CORRECT POSITION 
                                            ; BEFORE READING FOR DESTINATION DEPENDING ON
                                            ; SOURCE IS ALSO ABSOLUTE .L .W OR IMMEDIATE DATA 
            CLR.L       D2
            MOVE.W      D0,D2
            JSR         CONVERT2BINARY
            AND.L       #$000000FF,D2
            CMP.L       #$00000001,D2
            BEQ         SHIFTWORD           ; SKIP 4 BITS
            CMP.L       #$00000011,D2
            BEQ         SHIFTWORD           ; SKIP 4  BITS
            CMP.L       #$00000010,D2
            BEQ         SHIFTLONG           ; SKIP 8 BITS


            

GROUP1_DEST_EA                              ; GENERAL SUBROUTINE HANDLING EA AS DESTINATION OF GROUP1

            CLR         D2
            MOVE.W      D0,D2

            AND.L       #$00000FF0,D2   ; GET 2nd 3rd HEX BIT
            LSR.L       #4,D2           ; REMOVE THE LSB
            JSR         CONVERT2BINARY  ; GET BINARY BIT 4-11
            AND.L       #$000FFF00,D2   ; RESERVE BIT 6-8
            LSR.L       #8,D2           ; ELIMINATE BIT 4 5
            CMP.L       #$00000000,D2
            BEQ         DEST_Dn
            CMP.L       #$00000010,D2
            BEQ         DEST_An
            CMP.L       #$00000011,D2
            BEQ         DEST_An_PLUS
            CMP.L       #$00000100,D2
            BEQ         DEST_MINUS_An
            CMP.L       #$00000111,D2
            BEQ         DEST_IMMADDR
            
DEST_IMMADDR_DOT_L
      
            JSR         PRINT_DOLLAR
            ADD.L       #$4,D5
            MOVE.W      (A4),D2
            CLR         D2

            MOVE.L      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            BRA         FINISH_GROUP1
            
DEST_IMMADDR_DOT_W
            ADD.L       #$2,D5
           
            JSR         PRINT_DOLLAR

            MOVE.W      (A4),D2
                
            CLR         D2

            MOVE.W      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP
        
            BRA         FINISH_GROUP1
SHIFTIMMDATA
            CLR.L       D2
            MOVE.L      D0,D2
            LSR.L       #8,D2
            LSR.L       #4,D2 
            JSR         CONVERT2BINARY
            AND.L       #$000000FF,D2
            CMP.W       #$01,D2
            BEQ         SHIFTWORD
            CMP.W       #$11,D2
            BEQ         SHIFTWORD
            CMP.L       #$10,D2
            BEQ         SHIFTLONG
                       
DEST_IMMADDR                            ; SUBROUTINE HANDLING ABSOULTE .W .L OR IMMEDIATE DATA
            ; FIRST, CHECK IF SOURCE IS ALSO .L .W OR IMMEDIATE DATA
            ; THAT CASE WE HAVE TO MOVE THE CURRENT POINTER TO CORRECT POSITION BEFORE READING 
            MOVE.L      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$00FFF000,D2
            CMP.L       #$00111000,D2
            BNE         GROUP1_DESTEA_NEXT  ; IF SOURCE IS NOT .W .L NOR IMMEDIATE, THEN SKIP MOVING POINTER
            CLR.L       D2
            MOVE.W      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         SHIFTWORD       
            CMP.W       #$001,D2
            BEQ         SHIFTLONG
            CMP.W       #$100,D2
            BEQ         SHIFTIMMDATA

                        
GROUP1_DESTEA_NEXT
            CLR.L       D2
            MOVE.L      D0,D2
            AND.L       #$00000F00,D2
            LSR.L       #8,D2
            JSR         CONVERT2BINARY
            LSR.L       #4,D2
            CMP.W       #$000,D2
            BEQ         DEST_IMMADDR_DOT_W   
            CMP.W       #$001,D2
            BEQ         DEST_IMMADDR_DOT_L  
            BRA         BAD_OPCODE 
            

DEST_Dn     CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_D
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            BRA         FINISH_GROUP1

DEST_An     CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            BRA         FINISH_GROUP1

DEST_An_PLUS
            CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            BRA         FINISH_GROUP1

DEST_MINUS_An
            CLR         D2
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            BRA         FINISH_GROUP1
FINISH_GROUP1
            BRA         PRINTA6

GET_GROUP1_SRC_REG
            AND.L       #$0000000F,D2   ; RESERVE THE LAST HEX BIT
            JSR         CONVERT2BINARY  ; BIT 0-3
            AND.L       #$00000FFF,D2   ; CLEAR BIT 3
            CMP.W       #$0000,D2
            BEQ         PRINT_0         ; EX MOVE.L D2 by this step
            CMP.W       #$0001,D2
            BEQ         PRINT_1
            CMP.W       #$0010,D2
            BEQ         PRINT_2
            CMP.W       #$0011,D2
            BEQ         PRINT_3
            CMP.W       #$0100,D2
            BEQ         PRINT_4
            CMP.W       #$0101,D2
            BEQ         PRINT_5
            CMP.W       #$0110,D2
            BEQ         PRINT_6
            CMP.W       #$0111,D2
            BEQ         PRINT_7
            RTS

GET_GROUP1_DEST_REG                      ; SUBROUTINE GET REGISTER FOR GROUP1
            AND.L       #$00000F00,D2   ; RESERVE 2nd HEX BIT
            LSR.L       #8,D2           ; ELIMINATE THE LAST 2 BITS
            JSR         CONVERT2BINARY
            LSR.L       #4,D2           ;  ELIMINATE BIT 8
            CMP.L       #$00000000,D2
            BEQ         PRINT_0         ; EX MOVE.L D2,D0 by this step
            CMP.L       #$00000001,D2
            BEQ         PRINT_1
            CMP.L       #$00000010,D2
            BEQ         PRINT_2
            CMP.L       #$00000011,D2
            BEQ         PRINT_3
            CMP.L       #$00000100,D2
            BEQ         PRINT_4
            CMP.L       #$00000101,D2
            BEQ         PRINT_5
            CMP.L       #$00000110,D2
            BEQ         PRINT_6
            CMP.L       #$00000111,D2
            BEQ         PRINT_7
            RTS



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 2 OPCODES
;
; THESE OPCODES INCLUDE: MOVEM, NOT, LEA, JSR, RTS, NOP
;
GROUP2OPCODE
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            CMP.L       #$00004E75,D2   ; RTS
            BEQ         RTSCODE
            CMP.L       #$00004E71,D2   ; NOP
            BEQ         NOPCODE

            LSR.L       #8,D2           ; EX. 0x00004E71 BECOMES 0x0000004E

            CMP.L       #$00000048,D2   ; MOVEM
            BEQ         MOVEMCODE_REG2MEM
            CMP.L       #$0000004C,D2   ; MOVEM
            BEQ         MOVEMCODE_MEM2REG
            CMP.L       #$00000046,D2   ; NOT
            BEQ         NOTCODE
            CMP.L       #$0000004E,D2   ; JSR
            BEQ         JSRCODE

            ANDI.B      #1,D2           ; THE REST IS BETWEEN 41xx - 4Fxx
            BEQ         BAD_OPCODE      ; IS EVEN ==> BAD OPCODE
            BRA         LEACODE         ; OTHERWISE, IS ODD ==> LEA

; RTSCODE
RTSCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'R',(A6)+
            MOVE.B      #'T',(A6)+
            MOVE.B      #'S',(A6)+
            
            ; STEP 2: PRINT IT OUT
            JMP         GOOD_OPCODE



; NOPCODE
NOPCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'N',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'P',(A6)+

            ; STEP 2: PRINT IT OUT
            JMP         GOOD_OPCODE


; NOTCODE
; INSTRUCTION FORMAT: 46XX
NOTCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'N',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'T',(A6)+


            ; STEP 2: DETERMINE SIZE
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            AND.L       #$11000000,D2   ; MASK EVERYTHING EXCEPT FIRST TWO BITS
            LSR.L       #8,D2           ; SHIFT 2 MSB TO LSB
            LSR.L       #8,D2
            LSR.L       #8,D2

            JSR         SETSIZE         ; SETS SIZE OF OPERATION
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
  

            MOVE.B      #TAB,(A6)+      ; TAB SHOULD BE AFTER SETSIZE BUT THAT DOESN'T WORK
           
            ; STEP 3: DETERMINE EA MODE
            ; STEP 4: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST 2 BITS
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS TO STACK


            ; NOT CANNOT BE An, #
            ; An = XX00 1RRR
            ; # = XX11 1100
            AND.L       #$00111000,D2
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            MOVEM.L     D2,-(SP)        ; LOAD BINARY BITS BACK INTO STACK

            AND.L       #$00111111,D2   ; MASKS EVERYTHING EXCEPT 2 MSBs
            CMP.L       #$00111010,D2
            BGE         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; PUT BINARY BITS BACK INTO D2
            JSR         EASTUFF2        ; OTHERWISE GOOD
            MOVE.B      -(A6),D2        ; REMOVE EXTRA COMMA

            ;STEP 4: PRINT IT OUT
            JMP         GOOD_OPCODE


; LEACODE
; INSTRUCTION FORMAT: 4XXX
LEACODE

            ;STEP 1: LOAD OPWORD
            MOVE.B      #'L',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'A',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+


            MOVE.B      #TAB,(A6)+

            ;STEP 2: DETERMINE EA MODE
            ;STEP 3: DETERMINE EA REGISTER
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK

            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST 2 BITS
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS TO STACK

            ; LEA CANNOT BE Dn, An, (An)+, -(An), #
            ; Dn = XX00 0RRR
            ; An = XX00 1RRR
            ; (An)+ = XX01 1RRR
            ; -(An) = XX10 0RRR
            ; # = XX11 1100
            AND.L       #$00111000,D2
            CMP.L       #$00001000,D2
            BLE         BAD_OPCODE
            CMP.L       #$00011000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00100000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00111100,D2
            BEQ         BAD_OPCODE
            MOVEM.L     (SP)+,D2        ; PUT BINARY BITS BACK INTO D2

            JSR         EASTUFF2        ; OTHERWISE GOOD

            ;STEP 4: DETERMINE SOURCE REGISTER
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT SECOND HEX
            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           ; SHIFTS BITS ONE TO THE RIGHT
            AND.L       #$00000111,D2   ; MASKS EVERYTHING EXCEPT 3 LSBs


            MOVE.B      #'A',(A6)+
            JSR         DETERMINEREG


            ;STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE


; JSRCODE
; INSTRUCTION FORMAT: 4EXX
JSRCODE
            ; STEP 1: LOAD OPWROD
            MOVE.B      #'J',(A6)+
            MOVE.B      #'S',(A6)+
            MOVE.B      #'R',(A6)+
            MOVE.B      #' ',(A6)+          
            MOVE.B      #' ',(A6)+   
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            ;STEP 2: DETERMINE EA MODE
            ;STEP 3: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT LAST 2 LSBs
            JSR         CONVERT2BINARY  ; CONVERTS LSBs IN D2 TO BINARY
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS TO STACK

            ; JSR CANNOT BE Dn, An, (An)+, -(An), #
            ; Dn = XX00 0RRR
            ; An = XX00 1RRR
            ; (An)+ = XX01 1RRR
            ; -(An) = XX10 0RRR
            ; # = XX11 1100

            AND.L       #$00111000,D2   ; MASK
            CMP.L       #$00010000,D2
            BLT         BAD_OPCODE
            CMP.L       #$00101000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00110000,D2
            BEQ         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS BACK INTO STACK
            AND.L       #$00111111,D2   ; MASK SIX BITS
            CMP.L       #$00111001,D2
            BGT         BAD_OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK TO D2

            JSR         EASTUFF2        ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER
            MOVE.B      -(A6),D2
            ; STEP 4: PRINT IT OUT
            JMP         GOOD_OPCODE


; MOVEMCODE
; INSTRUCTION FORMAT: 4CXX
MOVEMCODE_MEM2REG
            MOVE.W      (A4),D2
            CLR.L       D0
            MOVE.W      D2,D0

            ; STEP 1: LOAD OPWORD
            MOVE.B      #'M',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'M',(A6)+

            ; STEP 2: DETERMINE SIZE
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT 1 BIT
            LSR.L       #$4,D2          ; SHIFT ALL BITS 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00000100,D2   ; MASK EVERYTHING EXCEPT 1 BIT

            ; SIZE CANNOT BE BYTE
            CMP.L       #$00000000,D2   ; SIZE = WORD
            BEQ         MEM2REG_MOVEMWORDSIZE
            CMP.L       #$00000100,D2   ; SIZE = LONG
            BEQ         MEM2REG_MOVEMLONGSIZE

MOVEM_MEM2REG_FIRSTPART             ; EA --> Dn. SUBROUTINE DECODE SOURCE FOR EA --> Dn
            ADD.L       #2,D5
            MOVE.B      #TAB,(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.L      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$00FFF000,D2
            CMP.L       #$00010000,D2
            BEQ         MOVEM_MEM2REG_An
            CMP.L       #$00011000,D2
            BEQ         MOVEM_MEM2REG_An_PLUS
            CMP.L       #$00111000,D2
            BEQ         MOVEM_MEM2REG_EA
            BRA         BAD_OPCODE

MOVEM_MEM2REG_SECONDPART                ; EA --> Dn. SUBROUTINE DECODE SOURCE FOR EA --> Dn         
            JSR         PRINT_COMM      ; PRINT COMMA AS SEPARATOR
            MOVE.W      (A4)+,D2        ; MOVE POINTER TO BEGINNING OF UNDECODED 4BIT HEX
            MOVE.W      (A4),D2
            BRA         MEM2REG_DETERMINEREGS

            ; TODO: DECODE SECOND PART AFTER COMMA

MOVEM_MEM2REG_FINISH
            CLR.L       D2              
            MOVE.B      -(A6),D2         ; REMOVE REDUNDANT '/'
            BRA         GOOD_OPCODE      ; PRINTING THINGS OUT AND BACK TO THE LOOP

MOVEM_MEM2REG_An                        ; INDIRECT ADDR FOR MOVEM <ea> -> Dn
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            JSR         PRINT_CLOSEPAR
            BRA         MOVEM_MEM2REG_SECONDPART    ; NEXT, DECODE THE DESTINATION FOR EA->Dn
MOVEM_MEM2REG_An_PLUS                               ; DIRECT ADDR FOR MOVEM <ea> -> Dn
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            BRA         MOVEM_MEM2REG_SECONDPART    ; NEXT, DECODE THE DESTINATION FOR EA->Dn

MOVEM_MEM2REG_EA
            ;  FOLLOWING LINES CHECK FOR REGISTER TO DETERMINE .W OR .L
            JSR         PRINT_DOLLAR
            MOVE.L      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.L       #$00000000,D2
            BEQ         MOVEM_MEM2REG_DOT_W
            CMP.L       #$00000001,D2
            BEQ         MOVEM_MEM2REG_DOT_L
            BRA         BAD_OPCODE

MOVEM_MEM2REG_DOT_W
            ADD.L       #2,D5
            MOVE.W      (A4)+,D2        ; SKIP THE 4 BITS OF An-An/Dn-Dn STUFF
            MOVE.W      (A4)+,D2
            CLR.L       D3
            MOVE.W      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP
            MOVE.W      -(A4),D2        ;  RETURN BACK TO THE START OF An-An/Dn-Dn STUFF
            MOVE.W      -(A4),D2
            BRA         MOVEM_MEM2REG_SECONDPART

MOVEM_MEM2REG_DOT_L
            ADD.L       #4,D5
            MOVE.W      (A4)+,D2        ; SKIP THE 4 BITS OF An-An/Dn-Dn STUFF
            MOVE.W      (A4)+,D2
            CLR.L       D3
            MOVE.L      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            MOVE.W      -(A4),D2        ;  RETURN BACK TO THE START OF An-An/Dn-Dn STUFF
            MOVE.W      -(A4),D2
            BRA         MOVEM_MEM2REG_SECONDPART



MEM2REG_DETERMINEREGS                       ; DETERMINE REGISTER FOR MOVEM
            ; WHICH An REGISTERS        
            CMP.L       #$00008000,D2
            BGE         MOVEM_MEM2REG_A7
            CMP.L       #$00004000,D2
            BGE         MOVEM_MEM2REG_A6
            CMP.L       #$00002000,D2
            BGE         MOVEM_MEM2REG_A5
            CMP.L       #$00001000,D2
            BGE         MOVEM_MEM2REG_A4
            CMP.L       #$00000800,D2
            BGE         MOVEM_MEM2REG_A3
            CMP.L       #$00000400,D2
            BGE         MOVEM_MEM2REG_A2
            CMP.L       #$00000200,D2
            BGE         MOVEM_MEM2REG_A1
            CMP.L       #$00000100,D2
            BGE         MOVEM_MEM2REG_A0

            ; WHICH Dn REGISTERS
            CMP.L       #$00000080,D2
            BGE         MOVEM_MEM2REG_D7
            CMP.L       #$00000040,D2
            BGE         MOVEM_MEM2REG_D6
            CMP.L       #$00000020,D2
            BGE         MOVEM_MEM2REG_D5
            CMP.L       #$00000010,D2
            BGE         MOVEM_MEM2REG_D4
            CMP.L       #$00000008,D2
            BGE         MOVEM_MEM2REG_D3
            CMP.L       #$00000004,D2
            BGE         MOVEM_MEM2REG_D2
            CMP.L       #$00000002,D2
            BGE         MOVEM_MEM2REG_D1
            CMP.L       #$00000001,D2
            BGE         MOVEM_MEM2REG_D0

            ; SAFETY CHECK FOR INVALID EA
            CMP.W       #$0000,D2
            BNE         BAD_OPCODE

            BRA         MOVEM_MEM2REG_FINISH    ; RETURN BACK TO THE  END OF MEM2REG LOOP
            ;FOLLOWING SUBROUTINES HELP TO INDENTIFY THE ADDRESS RANGE A0-A7, AND DATA REGISTER RANGE D0-D7
            ; BASED ON GIVEN 4-BIT HEX VALUE
MOVEM_MEM2REG_A7
            SUB.W       #$8000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS    ; CONTINUE UNTIL '0000'. CANNOT DECODE ANYMORE
MOVEM_MEM2REG_A6
            SUB.W       #$4000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A5
            SUB.W       #$2000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A4
            SUB.W       #$1000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A3
            SUB.W       #$0800,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A2
            SUB.W       #$0400,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A1
            SUB.W       #$0200,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_A0
            SUB.W       #$0100,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D7
            SUB.W       #$0080,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D6
            SUB.W       #$0040,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D5
            SUB.W       #$0020,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D4
            SUB.W       #$0010,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D3
            SUB.W       #$0008,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS   
MOVEM_MEM2REG_D2
            SUB.W       #$0004,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D1
            SUB.W       #$0002,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MOVEM_MEM2REG_D0
            SUB.W       #$0001,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         MEM2REG_DETERMINEREGS
MEM2REG_MOVEMWORDSIZE
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            BRA         MOVEM_MEM2REG_FIRSTPART

MEM2REG_MOVEMLONGSIZE
            MOVE.B      #'.',(A6)+
            MOVE.B      #'L',(A6)+
            BRA         MOVEM_MEM2REG_FIRSTPART



; MOVEMCODE
; INSTRUCTION FORMAT: 48XX
MOVEMCODE_REG2MEM
            MOVE.W      (A4),D2         ; MOVES FULL UNCODED INSTRUCTION INTO D2
            CLR.L       D0              ; CLEARS D0
            MOVE.W      D2,D0           ; SAVES FULL UNDECODED INSTRUCTION INTO D0
                                        ; D0 WILL CONTAIN THE FULL INSTRUCTION AND IS TO NOT BE MODIFIED
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'M',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'M',(A6)+

            ; STEP 2: DETERMINE SIZE
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT 1 BIT
            LSR.L       #$4,D2          ; SHIFT ALL BITS 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00000100,D2   ; MASK EVERYTHING EXCEPT 1 BIT

            ; SIZE CANNOT BE BYTE
            CMP.L       #$00000000,D2   ; SIZE = WORD
            BEQ         MOVEMWORDSIZE
            CMP.L       #$00000100,D2   ; SIZE = LONG
            BEQ         MOVEMLONGSIZE

            ; STEP 3: DETERMINE WHICH REGISTERS ARE MOVED TO MEMORY
MOVEMR2M1
            MOVE.B      #TAB,(A6)+
            ; CHECK IF EA MODE IS -(An)
            CLR.L       D2              ; CLEAR D2
            MOVE.W      D0,D2           ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST 2 HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT 3 BITS
            CMP.L       #$00100000,D2   ; -(An)
            BEQ         MOVEMREGISTERS2

            ; OTHERWISE IT'S NORMAL

            BRA         MOVEMREGISTERS  ; DETERMINES WHICH REGISTERS ARE MOVED
MOVEMR2M2
            MOVE.B      -(A6),D2        ; DELETE LAST '/'
            MOVE.B      #',',(A6)+

            ; STEP 4: DETERMINE DESTINATION
            CLR.L       D2              ; CLEAR D2
            MOVE.L      D0,D2           ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT 2 LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00111000,D2   ; MASK 6 BITS

            ; MOVEM CANNOT BE: Dn, An, (An)+, -(An)
            CMP.L       #$00000000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00011000,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00100000,D2
            BEQ         MOVEM_REG2MEM_MINUS_An ; -(An)
            CMP.L       #$00010000,D2   ; (An)
            BEQ         MOVEMANINDIRECT
            CMP.L       #$00111000,D2   ; (XXX).L / (XXX).W
            BEQ         MOVEMEA
MOVEMR2M3
            MOVE.B      #')',(A6)+
            ; STEP 5: PRINT IT OUT
REG2MEM_FINISH
            JMP         GOOD_OPCODE


MOVEMWORDSIZE
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            MOVE.B      #' ',(A6)+      ; SPACE FILLER FOR BETTER PERFORMANCE
            BRA         MOVEMR2M1

MOVEMLONGSIZE
            MOVE.B      #'.',(A6)+
            MOVE.B      #'L',(A6)+
            MOVE.B      #' ',(A6)+
            BRA         MOVEMR2M1

MOVEMREGISTERS
            ; IN ORDER TO FIGURE OUT WHAT REGISTERS ARE BEING REFERENCED IN THIS INSTRUCTION
            ; YOU NEED TO TAKE THE NEXT 4 HEX BITS AFTER THE INSTRUCTION AND START TO SUBTRACT
            ; FROM THEM UNTIL YOU HIT 0000
            ; A0 = 0100     A4 = 1000       D0 = 0001       D4 = 0010
            ; A1 = 0200     A5 = 2000       D1 = 0002       D5 = 0020
            ; A2 = 0400     A6 = 4000       D2 = 0004       D6 = 0040
            ; A3 = 0800     A7 = 8000       D3 = 0008       D7 = 0080
            CLR.L       D2              ; CLEAR D2
            MOVE.W      (A4)+,D2        ; MOVE A4 TO POINT AT 4 HEX BITS FOR REGISTERS
            MOVE.W      (A4),D2         ; LOAD 4 HEX BITS FOR REGISTERS
            ADD.L       #$2,D5          ; INCREMENT ADDRESS

            ; CHECK FOR EDGE CASES
            CMP.W       #$0000,D2
            BEQ         BAD_OPCODE      ; TOO LITTLE VALUE

DETERMINEREGS
            ; WHICH An REGISTERS
            CMP.L       #$00008000,D2
            BGE         MOVEMA7
            CMP.L       #$00004000,D2
            BGE         MOVEMA6
            CMP.L       #$00002000,D2
            BGE         MOVEMA5
            CMP.L       #$00001000,D2
            BGE         MOVEMA4
            CMP.L       #$00000800,D2
            BGE         MOVEMA3
            CMP.L       #$00000400,D2
            BGE         MOVEMA2
            CMP.L       #$00000200,D2
            BGE         MOVEMA1
            CMP.L       #$00000100,D2
            BGE         MOVEMA0

            ; WHICH Dn REGISTERS
            CMP.L       #$00000080,D2
            BGE         MOVEMD7
            CMP.L       #$00000040,D2
            BGE         MOVEMD6
            CMP.L       #$00000020,D2
            BGE         MOVEMD5
            CMP.L       #$00000010,D2
            BGE         MOVEMD4
            CMP.L       #$00000008,D2
            BGE         MOVEMD3
            CMP.L       #$00000004,D2
            BGE         MOVEMD2
            CMP.L       #$00000002,D2
            BGE         MOVEMD1
            CMP.L       #$00000001,D2
            BGE         MOVEMD0

            ; SAFETY CHECK
            CMP.W       #$0000,D2
            BNE         BAD_OPCODE

            BRA         MOVEMR2M2       ; RETURN BACK TO MOVEM LOOP
MOVEMA7
            SUB.W       #$8000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA6
            SUB.W       #$4000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA5
            SUB.W       #$2000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA4
            SUB.W       #$1000,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA3
            SUB.W       #$0800,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA2
            SUB.W       #$0400,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA1
            SUB.W       #$0200,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMA0
            SUB.W       #$0100,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD7
            SUB.W       #$0080,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD6
            SUB.W       #$0040,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD5
            SUB.W       #$0020,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD4
            SUB.W       #$0010,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD3
            SUB.W       #$0008,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD2
            SUB.W       #$0004,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD1
            SUB.W       #$0002,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS
MOVEMD0
            SUB.W       #$0001,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS




MOVEMREGISTERS2
            ; IN ORDER TO FIGURE OUT WHAT REGISTERS ARE BEING REFERENCED IN THIS INSTRUCTION
            ; YOU NEED TO TAKE THE NEXT 4 HEX BITS AFTER THE INSTRUCTION AND START TO SUBTRACT
            ; FROM THEM UNTIL YOU HIT 0000
            ; A0 = 0080     A4 = 0008       D0 = 8000       D4 = 0800
            ; A1 = 0040     A5 = 0004       D1 = 4000       D5 = 0400
            ; A2 = 0020     A6 = 0002       D2 = 2000       D6 = 0200
            ; A3 = 0010     A7 = 0001       D3 = 1000       D7 = 0100
            CLR.L       D2              ; CLEAR D2
            MOVE.W      (A4)+,D2        ; MOVE A4 TO POINT AT 4 HEX BITS FOR REGISTERS
            MOVE.W      (A4),D2         ; LOAD 4 HEX BITS FOR REGISTERS
            ADD.L       #$2,D5          ; INCREMENT ADDRESS

            ; CHECK FOR EDGE CASES
            CMP.W       #$0000,D2
            BEQ         BAD_OPCODE      ; TOO LITTLE VALUE

DETERMINEREGS2
            ; WHICH Dn REGISTERS
            CMP.L       #$00008000,D2
            BGE         MOVEMD0_2
            CMP.L       #$00004000,D2
            BGE         MOVEMD1_2
            CMP.L       #$00002000,D2
            BGE         MOVEMD2_2
            CMP.L       #$00001000,D2
            BGE         MOVEMD3_2
            CMP.L       #$00000800,D2
            BGE         MOVEMD4_2
            CMP.L       #$00000400,D2
            BGE         MOVEMD5_2
            CMP.L       #$00000200,D2
            BGE         MOVEMD6_2
            CMP.L       #$00000100,D2
            BGE         MOVEMD7_2

            ; WHICH An REGISTERS
            CMP.L       #$00000080,D2
            BGE         MOVEMA0_2
            CMP.L       #$00000040,D2
            BGE         MOVEMA1_2
            CMP.L       #$00000020,D2
            BGE         MOVEMA2_2
            CMP.L       #$00000010,D2
            BGE         MOVEMA3_2
            CMP.L       #$00000008,D2
            BGE         MOVEMA4_2
            CMP.L       #$00000004,D2
            BGE         MOVEMA5_2
            CMP.L       #$00000002,D2
            BGE         MOVEMA6_2
            CMP.L       #$00000001,D2
            BGE         MOVEMA7_2

            ; SAFETY CHECK
            CMP.W       #$0000,D2
            BNE         BAD_OPCODE

            BRA         MOVEMR2M2       ; RETURN BACK TO MOVEM LOOP

MOVEMA7_2
            SUB.W       #$0001,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA6_2
            SUB.W       #$0002,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA5_2
            SUB.W       #$0004,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA4_2
            SUB.W       #$0008,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA3_2
            SUB.W       #$0010,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA2_2
            SUB.W       #$0020,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA1_2
            SUB.W       #$0040,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMA0_2
            SUB.W       #$0080,D2
            MOVE.B      #'A',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD7_2
            SUB.W       #$0100,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'7',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD6_2
            SUB.W       #$0200,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'6',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD5_2
            SUB.W       #$0400,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'5',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD4_2
            SUB.W       #$0800,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'4',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD3_2
            SUB.W       #$1000,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'3',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD2_2
            SUB.W       #$2000,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'2',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD1_2
            SUB.W       #$4000,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'1',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2
MOVEMD0_2
            SUB.W       #$8000,D2
            MOVE.B      #'D',(A6)+
            MOVE.B      #'0',(A6)+
            MOVE.B      #'/',(A6)+
            BRA         DETERMINEREGS2

MOVEM_REG2MEM_DOT_W

            MOVE.W      (A4)+,D2
            CLR.L       D3
            MOVE.W      (A4),D3
            ADD.L       #2,D5
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP

            BRA         REG2MEM_FINISH
MOVEM_REG2MEM_DOT_L

            MOVE.W      (A4)+,D2
            CLR.L       D3
            MOVE.L      (A4),D3
            ADD.L       #4,D5
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP
            BRA         REG2MEM_FINISH

MOVEMEA                                     ; GENERAL SUBROUTINE HANDLING EA AS DESTINATION FOR MOVEM    
            JSR         PRINT_DOLLAR
            MOVE.W      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         MOVEM_REG2MEM_DOT_W ; HANDLING ABSOLUTE ADDR .W AS DESTINATION FOR MOVEM
            CMP.W       #$001,D2
            BEQ         MOVEM_REG2MEM_DOT_L ; HANDLING ABSOLUTE ADDR .W AS DESTINATION FOR MOVEM
            BRA         BAD_OPCODE          ; OTHERWISE, BAD OPCODE (UNSUPPORTED EA MODE) OR 
                                            ; TRANSITION TO UNSUPPORTED OPCODE (ie. MOVEA)
MOVEM_REG2MEM_MINUS_An                      
            JSR         PRINT_MINUS
            BRA         MOVEMANINDIRECT
MOVEMANINDIRECT
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2

            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+

            BRA         DETERMINEREG2    ;DETERMINE WHICH REGISTER IT IS



DETERMINEREG2
            CMP.L       #$00000000,D2   ; 0
            BEQ         REG0_2
            CMP.L       #$00000001,D2   ; 1
            BEQ         REG1_2
            CMP.L       #$00000010,D2    ; 2
            BEQ         REG2_2
            CMP.L       #$00000011,D2    ; 3
            BEQ         REG3_2
            CMP.L       #$00000100,D2    ; 4
            BEQ         REG4_2
            CMP.L       #$00000101,D2    ; 5
            BEQ         REG5_2
            CMP.L       #$00000110,D2    ; 6
            BEQ         REG6_2
            CMP.L       #$00000111,D2    ; 7
            BEQ         REG7_2


REG0_2
            MOVE.B      #'0',(A6)+
            BRA MOVEMR2M3
REG1_2
            MOVE.B      #'1',(A6)+
            BRA MOVEMR2M3
REG2_2
            MOVE.B      #'2',(A6)+
            BRA MOVEMR2M3
REG3_2
            MOVE.B      #'3',(A6)+
            BRA MOVEMR2M3
REG4_2
            MOVE.B      #'4',(A6)+
            BRA MOVEMR2M3
REG5_2
            MOVE.B      #'5',(A6)+
            BRA MOVEMR2M3
REG6_2
            MOVE.B      #'6',(A6)+
            BRA MOVEMR2M3
REG7_2
            MOVE.B      #'7',(A6)+
            BRA MOVEMR2M3





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 3 OPCODES
;
; THESE OPCODES INCLUDE: BRA, BEQ, BLT, BGT
;
GROUP3OPCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS. EX: 0x00006E71 BECOMES 0x0000006E
            CMP.L       #$00000060,D2   ; BRA
            BEQ         BRACODE
            CMP.L       #$00000067,D2   ; BEQ
            BEQ         BEQCODE
            CMP.L       #$0000006C,D2
            BEQ         BGECODE        ; BGE
            CMP.L       #$0000006D,D2
            BEQ         BLTCODE        ; BLT
            CMP.L       #$0000006E,D2
            BEQ         BGTCODE        ; BGT
            CMP.L       #$0000006F,D2
            BEQ         BLECODE        ; BLE


            JMP         BAD_OPCODE      ; OTHER CASES ==> BAD OPCODE

BRACODE
            JSR         PRINT_BRA       ; PRINT OPCODE NAME 'BRA'
            MOVE.B      #' ',(A6)+      ; SPACE FILLER FOR ALIGNMENT
            MOVE.B      #' ',(A6)+
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS_BRA      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION_BRA ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH

BGECODE
            MOVE.B      #'B',(A6)+
            MOVE.B      #'G',(A6)+
            MOVE.B      #'E',(A6)+

            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH


BEQCODE
            JSR         PRINT_BEQ

            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH
BLECODE
            JSR         PRINT_BLE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH


BLTCODE
            JSR         PRINT_BLT
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH

BGTCODE
            JSR         PRINT_BGT
            ;MOVE.B      #TAB,(A6)+

            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            BNE         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT.
            BRA         GROUP3_FINISH

GROUP3_FINISH
            BRA         PRINTA6


; REVERSE THE TWO COMPLEMENT: INVERT BITS <== ADD 1
DSPLMCONVERSION
            MOVE.B      #'.',(A6)+     ; SIZE FOR Bcc EXCEPT BRA
            MOVE.B      #'B',(A6)+

   

DSPLMCONVERSION_BRA                     ; SPECIAL STARTING POINT FOR BRA AS IT DOES NOT REQUIRE SIZE LIKE BGT, BLE, ...
            ;FOLLOWING LINES CONVERT HEXVALUE TO DISPLACEMENT
            ; DSPLMCONVERSION IS CALLED WHEN BRANCHING FROM HIGHER ADDR TO LOWER ADDR.
            MOVE.B      #TAB,(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+


    
            JSR         PRINT_DOLLAR
            SUB.L       #%00000001,D2   ; SUBTRACT 1 FROM DISPLACEMENT
            NOT.L       D2              ; FLIP BITS
            SUB.L       #2,D2

            CLR         D3              ; USE IT AS A COUNTER TO REMOVE LEADING F(s)
            BRA         CLEARF          ; REMOVE LEADING F(s). AFTER FLIPPING BITS, DISPLACEMENT = $FFFFxxxx ==> $xxxx0000
RFLZ        JSR         REFILL_ZERO     ; PUSH ZERO TO REPLACE FFFF REMOVED. DISPLACEMENT ==> $0000xxxx
            CLR         D3
            MOVE.L      D5,D3           ; MOVE CURRENT ADDR
            SUB.B       D2,D3           ; NEW ADDR BRANCHING TO



            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING
            JSR         ADDRFLOOP
            BRA         GROUP3_FINISH
ADDRFLOOP                               ; SUBROUTINE PRINTING LONG ADDR TO A6. ie 00009000 ==> 00009000
            MOVE.B      (A2)+,(A6)+
            BNE.S       ADDRFLOOP
            SUBQ        #$1,A6
            RTS
ADDRWORDLOOP ADDQ       #4, A2          ; SUBROUTINE PRINTING WORD ADDR TO A6. ie 00000009 ==> 0009
            BRA         ADDRFLOOP
            RTS
ADDRBYTELOOP ADDQ       #6, A2          ; SUBROUTINE PRINTING BYTE ADDR TO A6. ie 00000009 ==> 09
            BRA         ADDRFLOOP
            RTS

CLEARF
            MOVE.L      D2,-(SP)        ; PUSH D2 TO STACK. AVOID LOSING D2
            AND.L       #$F0000000,D2   ; CHECK THE MSB
            CMP.L       #$F0000000,D2   ; CHECK IF IT IS 'F'
            BNE         Q_CLEARF        ; IF IT IS NOT  'F', STOP REMOVING LEADING F
            ADD         #$1,D3          ; ELSE, RECORD HOW  MANY BITS WILL BE SHIFTED
            MOVE.L      (SP)+,D2        ; POP D2 FROM STACK FOR REMOVING 'F'
            LSL.L       #4,D2           ; SHIFT LEFT TO REMOVE 'F'
            BRA         CLEARF
Q_CLEARF
            MOVE.L      (SP)+,D2
            BRA         RFLZ

REFILL_ZERO                             ; ADD LEADING ZERO. 90 ==> 0000 0090 (IN LONG ADDR)
            LSR.L       #4,D2
            SUB.L       #1,D3
            CMP.L       #0,D3
            BNE         REFILL_ZERO
            RTS

READ_4MOREBITS                          
; SECOND CASE FOR GETTING DISPLACEMENT. WHEN BRANCHING FROM LOWER ADDR TO HIGHER ADDR.
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+



READ_4MOREBITS_BRA                      ; SPECIAL STARTING POINT FOR BRA AS IT DOES NOT REQUIRE  SIZE
            MOVE.B      #TAB,(A6)+
            MOVE.B      #' ',(A6)+      ; SPACE FILLER FOR ALIGNMENT 
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            
            
            JSR         PRINT_DOLLAR    
            
            MOVE.L      D5,-(SP)
            ADD.L       #$2,D5
            MOVE.L      D5,A4
            CLR         D3
            MOVE.W      (A4)+,D3
            ADD.L       (SP)+,D3
            ADD.L       #$2,D3
            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING
            JSR         ADDRFLOOP
            CLR         D3
            BRA         GROUP3_FINISH   ;  BRANCH TO FINISH GROUP 3


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 4 OPCODES
;
; THESE OPCODES INCLUDE: DIVU
;
GROUP4OPCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'D',(A6)+
            MOVE.B      #'I',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'U',(A6)+
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            ; STEP 2: DETERMINE EA MODE
            ; STEP 3: DETERMINE EA REGISTER

            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,D0

            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            ; DIVU CANNOT BE An
            ; An = XX00 1RRR

            MOVEM.L     D2,-(SP)        ; MOVE BINARY BITS INTO STACK
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT THREE BITS
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            JSR         EASTUFF2



            ; STEP 4: DETERMINE DESTINATION REGISTER
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2

            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG

            ; STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 5 OPCODES
;
; THESE OPCODES INCLUDE: SUB
;
;
;
;
GROUP5OPCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'S',(A6)+
            MOVE.B      #'U',(A6)+
            MOVE.B      #'B',(A6)+

            ; STEP 2: DETERMINE SIZE
            MOVE.W     (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            LSR.L       #8,D2
            CMP.W       #$000,D2
            BEQ         PRINT_DOT_B56
            CMP.W       #$001,D2
            BEQ        PRINT_DOT_W56
            CMP.W       #$011,D2
            BEQ        PRINT_DOT_W56
            CMP.W       #$010,D2
            BEQ         PRINT_DOT_L56
            CMP.W       #$111,D2
            BEQ        PRINT_DOT_L56
            BEQ         BAD_OPCODE


GROUP5_NXT                              ; CONTINUE ON AFTER DECODING SIZE
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            MOVE.W      (A4),D2
            MOVE.W      D2,D0
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$000FFF00,D2
            LSR.L       #8,D2
            CMP.L       #$011,D2        ; CATCH MOVEM ==> BAD OPCODE
            BEQ         BAD_OPCODE
            CMP.W       #$111,D2
            BEQ         BAD_OPCODE
            AND.L       #$00000F00,D2
            LSR.L       #8,D2
            CMP.B       #$0,D2
            BEQ         SUBEADN         ; DECODE MOVEM <EA> --> Dn
            CMP.B       #$1,D2
            BEQ         SUBDNEA         ; DECODE MOVEM Dn   --> <EA>

SUBA                                    ; HANDLING SUBA
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.W       #$0000,D2
            BEQ         GROUP56_SUBA_Dn
            CMP.W       #$0001,D2
            BEQ         GROUP56_SUBA_DIR_An
            CMP.W       #$0010,D2
            BEQ         GROUP56_SUBA_INDIR_An
            CMP.W       #$0011,D2
            BEQ         GROUP56_SUBA_An_PLUS
            CMP.W       #$0100,D2
            BEQ         GROUP56_SUBA_MINUS_An
            CMP.W       #$0111,D2
            BEQ         GROUP56_SUBA_IMMADDR
            CMP.W       #$0101,D2
            BEQ         BAD_OPCODE
            CMP.W       #$0110,D2
            BEQ         BAD_OPCODE

SUBA_SECONDPART
            JSR         PRINT_COMM
            JSR         PRINT_A
            MOVE.W      D0,D2
            AND.L       #$00000F00,D2
            LSR.L       #8,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFFF,D2
            LSR.L       #4,D2
            JSR         MEM_GETREGISTER

            BRA         GROUP56_FINISH

SUBEADN
            MOVE.W      D0,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR SOURCE EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_EADN_Dn
            CMP.L       #$0001,D2
            BEQ         GROUP56_EADN_DIR_An
            CMP.L       #$0010,D2
            BEQ         GROUP56_EADN_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_EADN_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_EADN_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_EADN_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE

SUBEADN_SECONDPART                          ; DECODE DESTINATION OF SUB <EA> ==> Dn
            JSR         PRINT_COMM
            JSR         GROUP56_Dn_PART     ; DECODE Dn FOR SUB <EA> ==> Dn

            BRA         GROUP56_FINISH


SUBDNEA                                     ; GENERAL SUBROUTINE HANDLING SUB Dn ==> <EA>
            JSR         GROUP56_Dn_PART     ; DECODE Dn FOR SUB Dn ==> <EA>

            JSR         PRINT_COMM

            MOVE.W      D0,D2
            AND.L       #$000000FF,D2        ; CHECK FOR SOURCE OPMODE
            JSR         CONVERT2BINARY
            AND.L       #$00FFF000,D2

            ; FOLLOWING LINES CHECK FOR EA MODE
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$0000,D2
            BEQ         GROUP56_DNEA_Dn
            CMP.L       #$0001,D2
            BEQ         GROUP56_DNEA_DIR_An

            CMP.L       #$0010,D2
            BEQ         GROUP56_DNEA_INDIR_An
            CMP.L       #$0011,D2
            BEQ         GROUP56_DNEA_An_PLUS
            CMP.L       #$0100,D2
            BEQ         GROUP56_DNEA_MINUS_An
            CMP.L       #$0111,D2
            BEQ         GROUP56_DNEA_IMMADDR
            CMP.L       #$0101,D2
            BEQ         BAD_OPCODE

            CMP.L       #$0000,D2
            BEQ         BAD_OPCODE          ; NO Dn
            CMP.L       #$0001,D2
            BEQ         BAD_OPCODE          ; NO An
            CMP.L       #$0110,D2
            BEQ         BAD_OPCODE          ; NOT REQUIRED EA

SUBDNEA_FINISH                              ; END OF SUBROUTINE FOR SUB
           BRA         GROUP56_FINISH

GROUP56_FINISH
            JSR         PRINTA6
;------
GROUP56_SUBA_IMMADDR
            JSR         GROUP56_IMMADDR
            BRA         SUBA_SECONDPART
GROUP56_IMMADDR                                 ; GENERAL SUBROUTINE HANDLING ABSOLUTE .L .W AND IMMEDIATE DATA FOR GROUP 56
                                                ; INCLUDING SUB + AND
            MOVE.W      D0,D2
            MOVE.L      D2,D0
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         GROUP56_IMMADDR_DOT_W
            CMP.W       #$001,D2
            BEQ         GROUP56_IMMADDR_DOT_L
            CMP.W       #$100,D2
            BEQ         GROUP6_IMMADDR_DATA
            BRA         BAD_OPCODE

GROUP56_IMMADDR_FINISH
            RTS

GROUP6_IMMADDR_DATA
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            LSR.L       #8,D2
            CMP.W       #$000,D2
            BEQ         GROUP56_IMMADDR_DOT_W
            CMP.W       #$001,D2
            BEQ         GROUP56_IMMADDR_DOT_W
            CMP.W       #$010,D2
            BEQ         GROUP56_IMMADDR_DOT_L
            BEQ         BAD_OPCODE

GROUP56_IMMADDR_DOT_W                   ; SUBROUTINE FOR ABSOLUTE WORD ADDR OF GROUP56
            ADD.L       #$2,D5
            MOVE.B      #' ',(A6)+
            JSR         PRINT_DOLLAR
            MOVE.W      (A4)+,D2
            CLR         D2
            MOVE.W      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRWORDLOOP
    
            BRA         GROUP56_IMMADDR_FINISH
GROUP56_IMMADDR_DOT_L                   ; SUBROUTINE FOR ABSOLUTE WORD ADDR OF GROUP56
            ADD.L       #$4,D5
            MOVE.B      #' ',(A6)+
            JSR         PRINT_DOLLAR
            MOVE.W      (A4)+,D2
            CLR         D2
            MOVE.L      (A4),D3
            JSR         L_HEXTOASCII
            JSR         ADDRFLOOP

            BRA         GROUP56_IMMADDR_FINISH



;------

GROUP56_SUBA_Dn
            JSR         GROUP56_Dn          ; DECODE Dn AS SOURCE
            BRA         SUBA_SECONDPART

GROUP56_SUBA_DIR_An
            JSR         GROUP56_DIR_An      ; DECODE An AS SOURCE
            BRA         SUBA_SECONDPART
GROUP56_SUBA_INDIR_An
            JSR         GROUP56_INDIR_An    ; DECODE (An) AS SOURCE
            BRA         SUBA_SECONDPART
GROUP56_SUBA_An_PLUS
            JSR         GROUP56_An_PLUS     ; DECODE (An)+ AS SOURCE
            BRA         SUBA_SECONDPART
GROUP56_SUBA_MINUS_An
            JSR         GROUP56_MINUS_An    ; DECODE -(An) AS SOURCE
            BRA         SUBA_SECONDPART

;------
;FOLLOWING LINES ARE SUBROUTINE FOR TRANSITIONING TO DESTINATION DECODING AFTER SOURCE DECODING OF GROUP 56 <EA> ==> Dn
GROUP56_EADN_Dn
            JSR         GROUP56_Dn
            BRA         SUBEADN_SECONDPART

GROUP56_EADN_DIR_An
            JSR         GROUP56_DIR_An
            BRA         SUBEADN_SECONDPART
GROUP56_EADN_INDIR_An
            JSR         GROUP56_INDIR_An
            BRA         SUBEADN_SECONDPART
GROUP56_EADN_An_PLUS
            JSR         GROUP56_An_PLUS
            BRA         SUBEADN_SECONDPART
GROUP56_EADN_MINUS_An
            JSR         GROUP56_MINUS_An
            BRA         SUBEADN_SECONDPART
GROUP56_EADN_IMMADDR
            JSR         GROUP56_IMMADDR
            BRA         SUBEADN_SECONDPART

;-------
;FOLLOWING LINES ARE SUBROUTINE FOR TRANSITIONING TO DESTINATION DECODING AFTER SOURCE DECODING OF GROUP 56 Dn ==> <EA>
GROUP56_DNEA_Dn
            JSR         GROUP56_Dn
            BRA         SUBDNEA_FINISH

GROUP56_DNEA_DIR_An
            JSR         GROUP56_DIR_An
            BRA         SUBDNEA_FINISH
GROUP56_DNEA_INDIR_An
            JSR         GROUP56_INDIR_An
            BRA         SUBDNEA_FINISH
GROUP56_DNEA_An_PLUS
            JSR         GROUP56_An_PLUS
            BRA         SUBDNEA_FINISH
GROUP56_DNEA_MINUS_An
            JSR         GROUP56_MINUS_An
            BRA         SUBDNEA_FINISH
GROUP56_DNEA_IMMADDR
            MOVE.B      #' ',(A6)+
            JSR         GROUP56_IMMADDR
            BRA         SUBDNEA_FINISH
;------
; FOLLOWING SUBROUTINES HANDLE SPECIFIC ADDRESING MODE FOR GROUP56

PRINT_DOT_B56
            JSR         PRINT_DOT_B
            BRA         GROUP5_NXT
PRINT_DOT_W56
            JSR         PRINT_DOT_W
            BRA         GROUP5_NXT

PRINT_DOT_L56
            JSR         PRINT_DOT_L
            BRA         GROUP5_NXT


GROUP56_MINUS_An
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         GROUP56_DIR_An
            JSR         PRINT_CLOSEPAR
            RTS

GROUP56_An_PLUS
            JSR         PRINT_OPENPAR
            JSR         GROUP56_DIR_An
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            RTS

GROUP56_INDIR_An
            JSR         PRINT_OPENPAR
            JSR         GROUP56_DIR_An
            JSR         PRINT_CLOSEPAR
            RTS

GROUP56_DIR_An
            JSR         PRINT_A
            MOVE.W      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            RTS

GROUP56_Dn
            JSR         PRINT_D
            MOVE.W      D0,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            RTS



GROUP56_Dn_PART
            JSR         PRINT_D
            MOVE.W      D0,D2
            AND.L       #$00000F00,D2
            LSR.L       #8,D2
            JSR         CONVERT2BINARY
            LSR.L       #4,D2
            JSR         MEM_GETREGISTER
            RTS







;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 6 OPCODES
;
; THESE OPCODES INCLUDE: AND, MULS
;
GROUP6OPCODE
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,D0
            AND.L       #$00000FF0,D2   ; GET THE MIDDLE 2 HEX DIGITS
            LSR.L       #4,D2           ; SHIFT ALL HEX VALUES ONE TO THE RIGHT

            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            AND.L       #$00011100,D2   ; MASK EVERYTHING EXCEPT THE THREE BITS TO DETERMINE WHETHER IT'S AND OR MULS
            CMP.L       #$00011100,D2   ; MULS
            BEQ         MULSCODE
            CMP.L       #$00001100,D2   ; AND
            BNE         ANDCODE         ; NOT EQUAL TO BAD CODE

            JMP         BAD_OPCODE      ; OTHERWISE A BAD OPCODE


MULSCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'M',(A6)+
            MOVE.B      #'U',(A6)+
            MOVE.B      #'L',(A6)+
            MOVE.B      #'S',(A6)+

            ; STEP 2: LOAD SIZE
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
                        
            MOVE.B      #TAB,(A6)+

            ; STEP 3: DETERMINE EA MODE
            ; STEP 4: DETERMINE EA REGISTER
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            MOVEM.L     D2,-(SP)        ; MOVE BINARY BITS INTO STACK

            ; MULS CANNOT BE An

            ; An = XX00 1RRR
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT THREE BITS
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            JSR         EASTUFF2
            

            ; STEP 4: DETERMINE DESTINATION REGISTER
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2

            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG

            ; STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE



ANDCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'A',(A6)+
            MOVE.B      #'N',(A6)+
            MOVE.B      #'D',(A6)+


            ; STEP 2: DETERMINE SIZE
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.W      D2,D0

            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            LSR.L       #8,D2           ; SHIFT BITS 2 TO THE RIGHT
            AND.L       #$00000011,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         SETSIZE
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+


            MOVE.B      #TAB,(A6)+
            ; STEP 3: DETERMINE OPMODE (EA -> Dn vs Dn -> EA)
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES
            LSR.L       #4,D2           ; SHIFT HEX VALUES 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00010000,D2
            CMP.L       #$00010000,D2
            BGE         SUBDNEA
            BRA         SUBEADN

ANDEADN
            ; STEP 4: DETERMINE EA MODE
            ; STEP 5: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,D0
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            ; AND CANNOT BE An
            ; An = XX00 1RRR
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT THREE BITS
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE

            MOVE.L      D0,D2        ; MOVE BINARY BITS BACK INTO D2
            JSR         EASTUFF2

            JSR         PRINT_COMM

            ; STEP 6: DETERMINE DESTINATION REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2

            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG

            ; STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE



ANDDNEA
            
            ; STEP 4: DETERMINE SOURCE REGISTER
            MOVE.B      #'D',(A6)+

            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE

            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            AND.L       #$00001110,D2   ; MASK EVERYTHING BUT THREE BITS
            LSR.L       #4,D2           ; SHIFT EVERYTHING 1 TO THE RIGHT

            JSR         DETERMINEREG
            MOVE.B      #',',(A6)+

            ; STEP 5: DETERMINE EA MODE
            ; STEP 6: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS INTO STACK
            
            ; AND CANNOT BE An
            ; An = XX00 1RRR
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT THREE BITS
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE

            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            JSR         EASTUFF2

            ;STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 7 OPCODES
;
; THESE OPCODES INCLUDE: ADD
;
GROUP7OPCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'A',(A6)+
            MOVE.B      #'D',(A6)+
            MOVE.B      #'D',(A6)+


            CLR.L       D2
            CLR.L       D0

            ; STEP 2: DETERMINE SIZE
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,D0

            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            LSR.L       #8,D2           ; SHIFT BITS 2 TO THE RIGHT
            AND.L       #$00000011,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         SETSIZE
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            
            MOVE.B      #TAB,(A6)+
            ; STEP 3: DETERMINE OPMODE (EA -> Dn vs Dn -> EA)
            MOVE.W      D0,D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES
            LSR.L       #4,D2           ; SHIFT HEX VALUES 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00010000,D2
            CMP.L       #$00010000,D2
            BGE         SUBDNEA
            BRA         SUBEADN

ADDEADN
            ; STEP 4: DETERMINE EA MODE
            ; STEP 5: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            JSR         EASTUFF2

            MOVE.B      #',',(A6)+

            ; STEP 6: DETERMINE DESTINATION REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2

            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG

            ; STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE

BADOPCODE_ADDA
            MOVE.B      -(A6),D2
            MOVE.B      -(A6),D2
            MOVE.B      -(A6),D2
            BRA         INVALID_OPCODE


ADDDNEA
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            ; THROW INVALID OPCODE FOR ADDA
            AND.L       #$00FFF000,D2
            CMP.L       #$00001000,D2
            BEQ         BADOPCODE_ADDA
   
            
            ; STEP 4: DETERMINE SOURCE REGISTER
            MOVE.B      #'D',(A6)+

            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE

            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            AND.L       #$00001110,D2   ; MASK EVERYTHING BUT THREE BITS
            LSR.L       #4,D2           ; SHIFT EVERYTHING 1 TO THE RIGHT

            JSR         DETERMINEREG
            MOVE.B      #',',(A6)+

            ; STEP 5: DETERMINE EA MODE
            ; STEP 6: DETERMINE EA REGISTER
            MOVE.W      (A4),D2         ; MOVE FULL UNDECIPHERED INSTRUCTION INTO D2

            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            JSR         EASTUFF2

            ;STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 8 OPCODES
;
; THESE OPCODES INCLUDE: LSL, ASL
;
GROUP8OPCODE
            MOVEM.W     (A4),D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            ;MOVEM.     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK

            LSR.L       #4,D2           ; GET THE 3RD DIGIT. EX: GET 3 FROM E234 ==> E23 (AFTER SHIFT RIGHT)
            AND.L       #$0000000F,D2   ; GET THE LSB
            JSR         CONVERT2BINARY  ; IE: 3 = 0011

            LSR.L       #8,D2           ; CHECK BIT 6-7. SEE THE TABLE
            CMP.L       #$11,D2         ; COMPARE WITH 11
            BEQ         MEMSHIFT        ; MEM ADDR SHIFT
            BNE         REGSHIFT        ; REGISTER SHIFT
            ;JSR         BAD_OPCODE      ;


REGSHIFT                                ; GENERAL SUBROUTINE HANDLING REGISTER SHIFT FOR BITH ASL AND LSL
            MOVE.W      (A4),D2
            AND.L       #$0000FFFF,D2
            ;MOVE.L      D2,-(SP)
            AND.L       #$00000F00,D2   ; GET THE 3RD HEX DIGIT
            LSR.L       #8,D2
            JSR         CONVERT2BINARY
            AND.L       #$0000000F,D2
            CMP.L       #$00000000,D2   ; ONLY DECODE ASL, LSL. ASR AND LSR ARE NOT SUPPORTED
            BEQ         BAD_OPCODE
            ;FOLLOWING LINES CHECK WHETHER ASL OR LSL
            MOVE.W      (A4),D2
            AND.L       #$0000FFFF,D2
            AND.L       #$000000FF,D2
            JSR         CONVERT2BINARY
            AND.L       #$000FF000,D2
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.L       #$01,D2
            BEQ         REG_LSL
            CMP.L       #$00,D2
            BEQ         REG_ASL
            BRA         BAD_OPCODE
REG_LSL                                 ; SUBROUTINE HANDLING REGISTER SHIFT FOR LSL
            JSR         PRINT_LSL
            JSR         REG_DECODE      ; DECODE REGISTER
            BRA         GROUP8_FINISH   ; FINISH GROUP 8

REG_ASL                                 ; SUBROUTINE HANDLING REGISTER SHIFT FOR ASL
            JSR         PRINT_ASL
            JSR         REG_DECODE      ; DECODE REGISTER   
            BRA         GROUP8_FINISH   ; FINISH GROUP 8



GROUP8_FINISH
            BRA         PRINTA6         ; RETURN AS GOOD OPCODE

REG_DECODE                              ; GENERAL SUBROUTINE FOR REGISTER DECODING
            MOVE.W      (A4),D2
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            ;MOVE.L      D2,-(SP)
            LSR.L       #8,D2
            CMP.L       #$00,D2
            BEQ         PRINT_DOT_B8     ; SIZE .B 
            CMP.L       #$01,D2
            BEQ         PRINT_DOT_W8     ; SIZE .W
            CMP.L       #$10,D2
            BEQ         PRINT_DOT_L8     ; SIZE .L
NEXT_1      
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #TAB,(A6)+

            MOVE.W      (A4),D2
            AND.L       #$000000F0,D2       ; CHECK THE 3RD  HEX BIT
            LSR.L       #4,D2
            JSR         CONVERT2BINARY

            ;MOVE.L      (SP)+,D2
            AND.L       #$000000F0,D2       ; 
            LSR.L       #4,D2
            CMP.L       #$00000000,D2          ; IMMEDIATE COUNT
            BEQ         PRINT_HASH8
            JSR         PRINT_D
            ; FOLLLOWING LINES ARE CUSTOMIZED PRINT REGISTER FOR DATA REGISTER Dn OF GROUP 8.
            ; PRINT_08 PRINT THE SAME THING AS PRINT_0 BUT THEY HAVE DIFFERENT EXITING POINT

NEXT_3      MOVE.W      (A4),D2
            AND.L       #$00000F00,D2           ; GET THE 2nd DIGIT
            LSR.L       #8,D2
            JSR         CONVERT2BINARY
            LSR.L       #4,D2
            CMP.L       #$00000000,D2
            BEQ         PRINT_08
            CMP.L       #$00000001,D2
            BEQ         PRINT_18
            CMP.L       #$00000010,D2
            BEQ         PRINT_28
            CMP.L       #$00000011,D2
            BEQ         PRINT_38
            CMP.L       #$00000100,D2
            BEQ         PRINT_48
            CMP.L       #$00000101,D2
            BEQ         PRINT_58
            CMP.L       #$00000110,D2
            BEQ         PRINT_68
            CMP.L       #$00000111,D2
            BEQ         PRINT_78


NEXT_4      JSR         PRINT_COMM
            ; FOLLOWING LINES DECODE REGISTER FOR Dn AS DESTINATION
            JSR         PRINT_D

            MOVE.W      (A4),D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.L       #$00000000,D2
            BEQ         PRINT_0
            CMP.W       #$0001,D2
            BEQ         PRINT_1
            CMP.W       #$0010,D2
            BEQ         PRINT_2
            CMP.W       #$0011,D2
            BEQ         PRINT_3
            CMP.W       #$0100,D2
            BEQ         PRINT_4
            CMP.W       #$0101,D2
            BEQ         PRINT_5
            CMP.W       #$0110,D2
            BEQ         PRINT_6
            CMP.W       #$0111,D2
            BEQ         PRINT_7


DONE8       RTS                     ; FINISH REGISTER DECODING


MEMSHIFT                            ; GENERAL SUBROUTINE FOR MEMORY SHIFT OF ASL AND LSL
            CLR         D2
            MOVE.W      (A4),D2
            ; FOLLOWING LINES GET THE 2nd HEX DIGIT
            AND.L       #$00000F00,D2
            LSR.L       #8,D2

            ; FOLLOWING LINES FILTER MEMSHIFT ASR, LSR
            JSR         CONVERT2BINARY
            MOVE.L      D2,D7
            AND.L       #$0000000F,D2
            CMP.L       #$0,D2
            BEQ         BAD_OPCODE      ; CATCH MEMSHIFT OF ASR, LSR

            ; FOLLOWING LINES CHECK WHETHER MEMSHIFT ASL OR LSL?

            MOVE.L      D7,D2
            LSR.L       #4,D2
            CMP.W       #$000,D2
            BEQ         MEM_ASL         ; ASL WITH MEMORY SHIFT
            CMP.W       #$001,D2
            BEQ         MEM_LSL         ; LSL WITH MEMORY SHIFT
            BRA         BAD_OPCODE      ; OTHERWISE, BAD OPCODE
MEM_ASL
            JSR         PRINT_ASL
            JSR         PRINT_DOT_W     ; PRINT SIZE
            MOVE.B      #' ',(A6)+      ; SPACE FILLER FOR ALIGNMENT
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            
            MOVE.B      #TAB,(A6)+
            BRA         MEM_EA          ; DECODE SOURCE EA. BOTH ASL AND LSL SHARE THE SAME MEM_EA DECODING FOR SOURCE

MEM_LSL
            JSR         PRINT_LSL
            JSR         PRINT_DOT_W
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+
            MOVE.B      #' ',(A6)+

            MOVE.B      #TAB,(A6)+
            BRA         MEM_EA          ; DECODE SOURCE EA. BOTH ASL AND LSL SHARE THE SAME MEM_EA DECODING


MEM_An
            JSR         PRINT_OPENPAR
            MOVE.B      #'A',(A6)+

            MOVE.L      D7,D2
            AND.L       #$00000FFF,D2

            JSR         MEM_GETREGISTER
            JSR         PRINT_CLOSEPAR
            BRA         GROUP8_FINISH
MEM_An_PLUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D7,D2
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            BRA         GROUP8_FINISH
MEM_MINUS_An
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            MOVE.L      D7,D2
            AND.L       #$00000FFF,D2
            JSR         MEM_GETREGISTER
            JSR         PRINT_CLOSEPAR
            BRA         GROUP8_FINISH
MEM_IMMADDR
            MOVE.W      (A4)+,D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         MEM_IMMADDR_DOT_W
            CMP.W       #$001,D2
            BEQ         MEM_IMMADDR_DOT_L
            BRA         BAD_OPCODE

MEM_IMMADDR_DOT_W
            MOVE.W      (A4),D2
            ADD.B       #$2,D5
  
            JSR         PRINT_DOLLAR
            AND.L       #$0000FFFF,D2
            CLR         D3
            MOVE.W      D2,D3
            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING AND APPENDING TO OUTPUT A6
            JSR         ADDRWORDLOOP
     
            BRA         GROUP8_FINISH

MEM_IMMADDR_DOT_L
            MOVE.L      (A4),D2
            ADD.B       #$4,D5
         
            JSR         PRINT_DOLLAR
            MOVE.L      D2,D3
            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING AND APPENDING TO OUTPUT A6
            JSR         ADDRFLOOP
           
            BRA         GROUP8_FINISH   ; FINISH GROUP8

MEM_EA:     MOVE.W      (A4),D2         ; GENERAL SUBROUTINE FOR DECODING <EA> AS SOURCE OF ASL AND LSL MEMORY SHIFT
            AND.L       #$0000FF,D2
            JSR         CONVERT2BINARY
            MOVE.L      D2,D7
            AND.L       #$00FFF000,D2
            LSR.L       #8,D2
            LSR.L       #4,D2
            CMP.W       #$010,D2
            BEQ         MEM_An          ; INDIRECT ADDR
            CMP.W       #$011,D2
            BEQ         MEM_An_PLUS     ; POST-INCREMENT 
            CMP.W       #$100,D2
            BEQ         MEM_MINUS_An    ; PRE-DECREMENT
            CMP.W       #$111,D2
            BEQ         MEM_IMMADDR     ; ABSOLUTE ADDR .L .W AND IMMEDIATE DATA GROUP
            BRA         BAD_OPCODE      ; OTHER CASES ARE BAD
MEM_GETREGISTER                         ; HELPER FUNCTION TO FIGURE OUT REGISTER FOR GROUP8
            CMP.W       #$0000,D2
            BEQ         PRINT_0         ; EX MOVE.L D2 by this step
            CMP.W       #$0001,D2
            BEQ         PRINT_1
            CMP.W       #$0010,D2
            BEQ         PRINT_2
            CMP.W       #$0011,D2
            BEQ         PRINT_3
            CMP.W       #$0100,D2
            BEQ         PRINT_4
            CMP.W       #$0101,D2
            BEQ         PRINT_5
            CMP.W       #$0110,D2
            BEQ         PRINT_6
            CMP.W       #$0111,D2
            BEQ         PRINT_7
            RTS
; HELPER SUBROUTINE PRINTING NUMBERS FROM 0-9, SIZE '.B' --> '.L' AND SPECIAL CHARACTERS LIKE # $ ( ) ....
PRINT_08
            MOVE.B      #'0',(A6)+
            BRA         NEXT_4
PRINT_18
            MOVE.B      #'1',(A6)+
            BRA         NEXT_4

PRINT_28
            MOVE.B      #'2',(A6)+
            BRA         NEXT_4
PRINT_38
            MOVE.B      #'3',(A6)+
            BRA         NEXT_4
PRINT_48
            MOVE.B      #'4',(A6)+
            BRA         NEXT_4
PRINT_58
            MOVE.B      #'5',(A6)+
            BRA         NEXT_4
PRINT_68
            MOVE.B      #'6',(A6)+
            BRA         NEXT_4
PRINT_78
            MOVE.B      #'7',(A6)+
            BRA         NEXT_4

PRINT_DOT_L8
            MOVE.B      #'.',(A6)+
            MOVE.B      #'L',(A6)+
            BRA         NEXT_1
PRINT_DOT_W8
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            BRA         NEXT_1
PRINT_DOT_B8
            MOVE.B      #'.',(A6)+
            MOVE.B      #'B',(A6)+
            BRA         NEXT_1
PRINT_HASH8
            MOVE.B      #'#',(A6)+
            BRA         NEXT_3



*/////////////////////////////////////////////////////////////////
*
*                        OPCODE NAMES
*
*
*////////////////////////////////////////////////////////////////


                *-----HOW TO USE: --------------------------*
                * CALL:   "JMP PRINT_RTS" INSIDE RTSCODE----*
*========= START OF OPCODE LABELS =========*
PRINT_NOP
            MOVE.B      #'N',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'P',(A6)+
            JMP         GOOD_OPCODE

PRINT_MOVE
            MOVE.B      #'M',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'E',(A6)+
            RTS

PRINT_MOVEM
            MOVE.B      #'M',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'M',(A6)+
            JMP         GOOD_OPCODE

PRINT_ADD
            MOVE.B      #'A',(A6)+
            MOVE.B      #'D',(A6)+
            MOVE.B      #'D',(A6)+
            JMP         GOOD_OPCODE

PRINT_SUB
            MOVE.B      #'S',(A6)+
            MOVE.B      #'U',(A6)+
            MOVE.B      #'B',(A6)+
            JMP         GOOD_OPCODE

PRINT_MULS
            MOVE.B      #'M',(A6)+
            MOVE.B      #'U',(A6)+
            MOVE.B      #'L',(A6)+
            MOVE.B      #'S',(A6)+
            JMP         GOOD_OPCODE

PRINT_DIVU
            MOVE.B      #'D',(A6)+
            MOVE.B      #'I',(A6)+
            MOVE.B      #'V',(A6)+
            MOVE.B      #'U',(A6)+
            JMP         GOOD_OPCODE

PRINT_LEA
            MOVE.B      #'L',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'A',(A6)+
            JMP         GOOD_OPCODE

PRINT_AND
            MOVE.B      #'A',(A6)+
            MOVE.B      #'N',(A6)+
            MOVE.B      #'D',(A6)+
            RTS

PRINT_NOT
            MOVE.B      #'N',(A6)+
            MOVE.B      #'O',(A6)+
            MOVE.B      #'T',(A6)+
            RTS

PRINT_ASL
            MOVE.B      #'A',(A6)+
            MOVE.B      #'S',(A6)+
            MOVE.B      #'L',(A6)+
            RTS


PRINT_LSL
            MOVE.B      #'L',(A6)+
            MOVE.B      #'S',(A6)+
            MOVE.B      #'L',(A6)+
            RTS

PRINT_BGT
            MOVE.B      #'B',(A6)+
            MOVE.B      #'G',(A6)+
            MOVE.B      #'T',(A6)+
            RTS

PRINT_BLT   MOVE.B      #'B',(A6)+
            MOVE.B      #'L',(A6)+
            MOVE.B      #'T',(A6)+
            RTS

PRINT_BLE
            MOVE.B      #'B',(A6)+
            MOVE.B      #'L',(A6)+
            MOVE.B      #'E',(A6)+
            RTS

PRINT_BEQ
            MOVE.B      #'B',(A6)+
            MOVE.B      #'E',(A6)+
            MOVE.B      #'Q',(A6)+
            RTS

PRINT_JSR
            MOVE.B      #'J',(A6)+
            MOVE.B      #'S',(A6)+
            MOVE.B      #'R',(A6)+
            JMP         GOOD_OPCODE

PRINT_RTS
            MOVE.B      #'R',(A6)+
            MOVE.B      #'T',(A6)+
            MOVE.B      #'S',(A6)+
            JMP         GOOD_OPCODE

PRINT_BRA
            MOVE.B      #'B',(A6)+
            MOVE.B      #'R',(A6)+
            MOVE.B      #'A',(A6)+
            RTS

*========= END OF OPCODE NAMES=========*

*========= START OF SIZE=========*

PRINT_DOT_B
            MOVE.B      #'.',(A6)+
            MOVE.B      #'B',(A6)+
            RTS

PRINT_DOT_W
            MOVE.B      #'.',(A6)+
            MOVE.B      #'W',(A6)+
            RTS

PRINT_DOT_L
            MOVE.B      #'.',(A6)+
            MOVE.B      #'L',(A6)+
            RTS


*========= END OF SIZE =========*

*========= START OF REGISTERS =========*
PRINT_D     MOVE.B      #'D',(A6)+
            RTS
PRINT_0
            MOVE.B      #'0',(A6)+
            RTS

PRINT_1
            MOVE.B      #'1',(A6)+
            RTS
PRINT_2
            MOVE.B      #'2',(A6)+
            RTS

PRINT_3
            MOVE.B      #'3',(A6)+
            RTS
PRINT_4
            MOVE.B      #'4',(A6)+
            RTS

PRINT_5
            MOVE.B      #'5',(A6)+
            RTS
PRINT_6
            MOVE.B      #'6',(A6)+
            RTS

PRINT_7
            MOVE.B      #'7',(A6)+
            RTS
PRINT_8
            MOVE.B      #'8',(A6)+
            RTS

PRINT_A     MOVE.B      #'A',(A6)+
            RTS
*========= END OF REGISTERS =========*

*========= START OF SPECIAL CHARACTERS =========*
PRINT_OPENPAR
            MOVE.B      #'(',(A6)+
            RTS

PRINT_CLOSEPAR
            MOVE.B      #')',(A6)+
            RTS

PRINT_HASH
            MOVE.B      #'#',(A6)+
            RTS
PRINT_COMM  MOVE.B      #',',(A6)+
            RTS


PRINT_PLUS MOVE.B      #'+',(A6)+
            RTS

PRINT_MINUS MOVE.B      #'-',(A6)+
            RTS

PRINT_DOLLAR MOVE.B      #'$',(A6)+
            RTS

*========= END OF SPECIAL CHARACTERS =========*







* ================= CONSTANTS GO HERE ================= *
SIZEDESTBWL DC.B    '',0    ; THIS FLAG HOLDS 0 OR 1 OR 2, WHERE 0 IS BYTE, 1 IS WORD, 2 IS LONG
EAREGISTER  DC.B    '',0    ; THIS FLAG HOLDS 0-6, WHERE 0 REPRESENTS REG#, 1 IS PROGRAM COUNTER W/ DISPLACEMENT,
                            ; 2 IS PROGRAM COUNTER WITH INDEX, 3 IS PROGRAM COUNTER WITH INDEX, 4 IS ABSOLUTE SHORT,
                            ; 5 IS ABSOLUTE LONG, 6 IS IMMEDIATE
EAMODE  DC.B        '',0    ; THIS FLAG HOLDS 0-7, WHERE 0 REPRESENTS FINISH THIS I'M TOO TIRED



* ======================== END ======================== *
* ================== CONSTANTS GO HERE ================== *

ERRMESS         DC.B        'Error! Invalid address',CR,LF,0
DISP_D2H        DC.B        'String-type addr in hex: ',0

* ================= CONSTANTS GO HERE ================= *

WELCOME     DC.B        'Welcome to the Hexspeak disassembler.',CR,LF,0
STARTADDR   DC.B        'Enter a starting address in hexadecimal: ',0
ENDADDR     DC.B        'Enter an ending address in hexadecimal:  ',0
AGAINPROMPT DC.B        'Would you like to disassemble another memory image? [Y/N] ',0
NEXTLINEPROMPT DC.B     'Press ENTER to continue. Press any key to exit. ',0

OUTOFBOUND      DC.B        'ERROR! Address must  be less than $00FFFFFF',0
TOOLONGADDR     DC.B        'ADDRESS MUST BE BETWEEN $00009000 AND $00FFFFFF',0
ADDR_NOTEVEN    DC.B        'ERROR! Memory address must be even number', 0
INVALID_RANGE   DC.B        'ERROR! Ending address must be greater than or equal to starting address',0

USERRESPONSE    DC.B    '',0
NEWLINERESPONSE    DC.B    '',0
LINES_ON_SCREEN DS.L    1
EXIT_MESS       DC.B    'PROGRAM EXIT!',CR,LF,0

            


* ======================== END ======================== *


            END         START





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~












*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
