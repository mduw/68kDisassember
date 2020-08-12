*------------------------------------------------------------------------
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
WELC        LEA         WELCOME,A1      ; LOAD WELCOME PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT WELCOME PROMPT
                    
STADDR      LEA         STARTADDR,A1    ; LOAD START PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT START PROMPT
            MOVEA.L     #0,A1
            
            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ START ADDRESS
            
            ; TODO: ERROR HANDLING/INPUT VALIDATION


STORESTARTADD
            JSR         ASCII2HEX	    ; Convert starting address to hex. Stored at D3
            MOVE.L      D3, D5          ; STORES START ADDRESS IN HEX INTO D5
            CLR         D3              ; CLEAR D3 AFTER USING IT
            MOVE.L      D5, A4          ; SAVE START ADDRESS IN A4 REGISTER 
       
EADDR       LEA         ENDADDR,A1      ; LOAD END PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT END PROMPT
            MOVEA.L     #0,A1

            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ END ADDRESS   

            ; TODO: ERROR HANDLING/INPUT VALIDATION
            
STOREENDADD            
            JSR         ASCII2HEX	    ; Convert starting address to hex. Stored at D3
            MOVE.L      D3, D6          ; STORES END ADDRESS IN HEX INTO D6
            CLR         D3              ; CLEAR D3 AFTER USING IT
            
            ; TODO: PRINT (ADDRESS INCREMENTED), OPCODE AND REGISTERS
*--- EXPECTED TO PRINT "(ADDRESS)(TAB)(DECODED OPCODE)(TAB)(EAS IF APPLICABLE)(NEW LINE)(#0)----*
*--- RIGHT NOW PRINTS INCREMENTED FROM START ADDRESS ADDRESSES----*

STARTNEWLINE MOVE.B  #0, LINES_ON_SCREEN ; START COUNTING LINES ON SCREEN

ADDRESSLOOP 
            CMP.L      D5,D6       ; COMPARE START/CURRENT AND END ADDRESSES 
            BLT        GOAGAIN     ; GIVE OPTION TO RESTART IF START IS MORE THAN END ADDRESS
            
LIMITLINESONSCREEN
            
            CMP.B   #20, LINES_ON_SCREEN ; LIMIT OF 20 LINES PER SCREEN/PAGE
            BNE FILLOUTPUTLINE  ; IF UNDER 20, FILL AND PRINT LINES 
            JSR     ASKIFPRINTNEXTLINE   ; IF MORE - ASK IF PRINTING MORE IS NEEDED          
                  
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
            ;NEED TO PUT 4 HEX VALUES INTO D2 FOR PROCESSING ->
            ; SO SAY AT LOCATION $9000 WE HAVE '4E71' SO NEED TO MOVE IT TO D2
            ; 9000 IS INCREMENTED WITH EACH LOOP AND SAVED IN D5 AND A4
            ; the code below works, but need to have the confirmation from the opcodes before calling it

ISOPCODEVALID:
            MOVE.W  (A4),D2      ; MOVE CONTENTS OF CURRENT LOCATION TO DECOdE THE OPCODE
            AND.L   #$0000FFFF,D2 ; ENSURE THAT ONLY SEND 4 HEX DIGITS AT A TIME
            CMP.W   #$0000FFFF,D2   ; IF $FFFF IS PRESENT IN .S68 FILE MEANS IT IS END OF FILE OR INVALID IF ON ITS OWN
            BEQ     INVALID_OPCODE ; INVALID SINCE $FFFF
            BNE     VALID_OPCODE ; NOT $FFFF, SO POTENTIALLY VALID ->SEND FOR PROCESSING
                      

VALID_OPCODE:  
            BRA SENDTOOPCODES
SENDTOOPCODES:  
            CLR      D0
            CLR      D1
            CLR         D3              ; CLEAR D3 AFTER USING IT     
            MOVE.L   #$00000000, A2
            ; D2 IS FILLED WITH DATA TO DECODE   
            JMP      CHECKOPCODE ; GO TO DECODE THE 4 HEX VALUES GIVEN TO IT      
           
           
PRINTA6     BRA      FINISHOUTPUTLINE ; IF VALID, SKIP INVALID MESSAGE

INVALID_OPCODE:
            ; PRINT ERROR MESSAGE AND MOVE TO NEXT LINE
            MOVE.B      #'E',(A6)+   ; ERROR MESSAGE  
            MOVE.B      #'r',(A6)+   ; ERROR MESSAGE  
            MOVE.B      #'r',(A6)+   ; ERROR MESSAGE 
            MOVE.B      #'o',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'r',(A6)+   ; ERROR MESSAGE
            MOVE.B      #':',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'I',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'n',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'v',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'a',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'l',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'i',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'d',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'o',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'p',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'c',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'o',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'d',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'e',(A6)+   ; ERROR MESSAGE
            MOVE.B      #',',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'p',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'r',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'i',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'n',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'t',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'i',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'n',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'g',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'o',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'u',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'t',(A6)+   ; ERROR MESSAGE
            MOVE.B      #' ',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'d',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'a',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'t',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'a',(A6)+   ; ERROR MESSAGE
            MOVE.B      #':',(A6)+   ; ERROR MESSAGE
            MOVE.B      #CR,(A6)+    ; ERROR MESSAGE
            MOVE.B      #LF,(A6)+    ; ERROR MESSAGE
            MOVE.B      #'D',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'A',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'T',(A6)+   ; ERROR MESSAGE
            MOVE.B      #'A',(A6)+   ; ERROR MESSAGE
            MOVE.B      #TAB,(A6)+   ; ERROR MESSAGE
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
            CMP.B       #$59,NEWLINERESPONSE ; IS USER INPUT 'Y'?
            BEQ         PREPFORNEWLINE ; CONTINUE ANOTHER TIME
            CMP.B       #$79,NEWLINERESPONSE ; IS USER INPUT 'y'?
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
            
             

DONE        MOVE.B      #9,D0           ; USING TRAP TASK #9
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
            JMP         WELC                ; GO BACK TO THE START     
            

* ======================== END ======================== *
HEX2BIN_RSLT  EQU     $2000




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
          
* ------------------ START OF SAMPLE FOR ASCII-TO-HEX CONVERSION (TO BE REMOVED ONCE COMPLETE)------------------*
* MOVE INPUT ADDRESS TO A1 BEFORE IMPLEMENTING THESE LINES
                       
*            JSR         ASCII2HEX       ; ASCII2HEX CONVERTS THE ANY VALUE AT A1 TO HEX (since task #2 store input at A1)
*            JSR         DISP            ; DISPLAY OUTPUT (OPTIONAL) FOR TESTING ONLY
*            MOVEA.L     #0,A1           ; RESET A1
*            MOVE.L      #0,D0           ; RESET D0
*            BRA         STADDR

* ------------------ END OF SAMPLE FOR ASCII-TO-HEX CONVERSION (TO BE REMOVED ONCE COMPLETE)------------------*





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
            LSL.W       #4,D3
            ADD.B       D2,D3
            BRA         NEXT_CHAR             
     
NEXT_CHAR   BRA         A2HLOOP         ; CONTINUE CONVERTING  
EXIT_A2HL   RTS                         ; EXIT A2H LOOP
               
A2H_ERR     LEA         ERRMESS,A1      ; DISPLAY  ERR MESSAGE. CHARACTER NOT IN [1..9] AND [A,Z]
            *MOVE.B      #14,D0
            *TRAP        #15
            RTS
DISP        LEA         (A3),A1 ; OUTPUT STRING IN HEX   
            MOVE.B      #13,D0
            TRAP        #15
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

*------ DEMO OF TEST SAMPLE (TO BE REMOVED BEFORE PROJECT SUBMISSION)----------------------*
*            LEA         <yourVariable>, A2        ; LOAD ADDRESS OF your variable TO A2
*            MOVE.L      #$92FC04BF,D3             ; TEST VALUE OF '92FC04BF' IN HEX IS USED
*            JSR         L_HEXTOASCII              ; JUMP TO SUBROUTINE THAT CONVERTS LONG IN HEX TO ASCII VALUE
*            LEA         <yourVariable>, A1        ; WILL DISPLAY THE ASCII VALUE
*            MOVE.L      #13, D0                   ; USED FOR TRAP #15
*            TRAP        #15                       ; PRINT VALUE IN A1
*------ END OF DEMO OF SAMPLE (TO BE REMOVED BEFORE PROJECT SUBMISSION) -----------------*

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
*                        WORD HEX TO ASCII
*
*
*////////////////////////////////////////////////////////////////

 
* INPUT: D3 REGISTER MUST HAVE THE HEX VALUE
* OUTPUT: A2 REGISTER    
* REGISTERS USED: D4 FOR COUNTER
                ; D2 FOR COPY OF D3 INPUT VALUE
 
*------ DEMO OF TEST SAMPLE (TO BE REMOVED BEFORE PROJECT SUBMISSION)----------------------*  
*            LEA         <yourVariable>, A2        ; LOAD ADDRESS OF your variable TO A2
*            MOVE.L      #$A2FC,D3                 ; TEST VALUE OF 'A2FC' IN HEX IS USED 
*            JSR         W_HEXTOASCII              ; JUMP TO SUBROUTINE THAT CONVERTS WORD IN HEX TO ASCII VALUE            
*            LEA         <yourVariable>, A1        ; WILL DISPLAY THE ASCII VALUE 
*            MOVE.L      #13, D0                   ; USED FOR TRAP #15
*            TRAP        #15                       ; PRINT VALUE IN A1 
*------ END OF DEMO OF SAMPLE (TO BE REMOVED BEFORE PROJECT SUBMISSION) -----------------*   
          
W_HEXTOASCII:
            CLR         D2
            CLR         D4
            MOVE.B      #$4, D4         ; 4 IS THE COUNTER (LIMIT) SINCE WE OPERATE ON THE WORD                
            BRA         W_HEXTOASCII_LOOP   ; EXECUTE LOOP THAT CONVERTS HEX TO ASCII
            RTS                         ; RETURN FROM SUBROUTINE 
 
W_HEXTOASCII_LOOP:    
            ROL.L       #4, D3          ; SHIFTS BITS TO LEFT AND ROTATES. FIRST BIT BECOMES LAST
            MOVE.W      D3,D2           ; STORE COPY AT D2 WHICH WILL HAVE BITS SHIFTED
            AND.L       #$0000000F,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST ONE
            CMP.B       #9, D2          ; CHECK IF MORE THAN 9 (10 IS A, ETC)
            BGT         ISLETTER        ; CONVERT LETTER BASED ON ASCII TABLE
            
ISDIGIT     ADD.W       #$30,D2         ; IS A NUMBER, SO ADD #$30 PER ASCII TABLE
            BRA         NEXT_W_H2A      ; CONTINUE AFTER DIGIT CONVERSION
            
ISLETTER    ADD.W       #$37,D2         ; IS A CHAR (IS AT LEAST 10), SO ADD $37 (65-10=55 IN DECIMAL WHICH IS $37)
            BRA         NEXT_W_H2A      ; CONVERT THE LETTER TO ASCII LETTER             
            
NEXT_W_H2A  MOVE.B      D2, (A2)+       ; STORE EACH BIT TO A1 IN RIGHT ORDER
            SUBQ        #1, D4          ; DECREMENT COUNTER
            CMP.B       #0, D4          ; CHECK IF END OF LOOP
            BNE         W_HEXTOASCII_LOOP   ; IF NOT, LOOP AGAIN
            
            MOVE.B      #0, (A2)        ; ASCII IS COMPLETE. PLACES NULL AT THE END OF STRING. 
            SUB         #$4,A2          ; RETURNS TO THE START OF THE STRING 
            RTS                        ; RETURN FROM SUBROUTINE
            
                                
* ================== END OF SUBROUTINE TO CONVERT WORD HEX TO ASCII ================== * 





*/////////////////////////////////////////////////////////////////
*
*                        DECODE OPCODES
*
*
*////////////////////////////////////////////////////////////////

; ASSUMPTION: THE OPCODE IS STORED IN D2 AND CONTAINS THE ENTIRE THING
; (ALL 4 HEX VALUES, so for example D2 would be 0x00004E71 (NOP))
; FOR FUTURE DEVELOPMENTS, WHENEVER DECODING AN OPCODE, ALWAYS HAVE THE
; FIRST THING INSIDE THE STACK BE THE FULL UNDECIPHERED OPCODE. THIS IS
; NECESSARY FOR DEALING WITH BAD OPCODES
; STACK SHOULD NOT BE USED PRIOR TO THIS! SHOULD BE AT $01000000 WITH NOTHING IN IT
CHECKOPCODE           
            MOVEM.L     D2,-(SP)        ; MOVE OPCODE TO STACK
            LSR.L       #8,D2           
            LSR.L       #4,D2           ; EX. 0x00004E71 BECOMES 0x00000004

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
            


; EASY METHOD TO CONVERT $000000XX INTO BINARY
CONVERT2BINARY
            MOVE.L      #$1100,A3       ; ADDRESS WHERE CONVERSION TAKES PLACE
            MOVE.L      D2,(A3)         ; MOVE REGISTER VALUE INTO A3 ADDRESS
            MOVEA.L     #$2000,A2       ; WHERE CONVERSION WILL SAVE TO
            
            JSR         HEX2BIN         ; CONVERTS TWO VALUES OF HEX INTO EIGHT BINARY BITS
            MOVE.L      $2000,D2         ; MOVES CONVERTED VALUE INTO D2
            
            RTS


; SUBROUTINE TO CALCULATE AND TRIGGER FLAGS FOR SOURCE MODE AND SOURCE REGISTER
; ACCEPTS INPUT AS BINARY BITS OF LAST TWO HEX VALUES OF INSTRUCTION. EXAMPLE:
; $00008EC0 -> $000000C0 -> %11000000
EASTUFF
            MOVEM.L     D2,-(SP)        ; SAVES BINARY BITS TO STACK FOR EAGROUP1/2
            AND.L       #$00111000,D2   ; CHECK SIZE EA MODE
            CMP.L       #$00100000,D2   ; CHECK 00XXX000 WHERE XXX IS FROM 000 TO 100
            ; BLE         EAGROUP1        ; EA MODE IS PART OF GROUP 1
            CMP.L       #$00111000,D2   ; CHECK 00XXX000 WHERE XXX IS 111
            ; BEQ         EAGROUP2        ; EA MODE IS PART OF GROUP 2
            
            JMP         BAD_OPCODE      ; INCORRECT EA 
            
            ; AND.L       #$00000111,D6     THIS WILL BE DONE INSIDE EAGROUP1 AND EAGROUP2
            
            ; RTS NOT NECESSARY, DO NOT NEED TO RETURN TO DECIPHERING OPCODE


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
            BEQ         EAGROUP2        ; EA MODE IS PART OF GROUP 2
            
            
            
            
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

            RTS

DIRECTREGISTER
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER
            
            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG    ; DETERMINE WHICH REGISTER IT IS
            
            RTS
            
ADDRESSREGDIRECT
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER
            
            MOVE.B      #'A',(A6)+
            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            
            RTS
            
ADDRESSREGINDIRECT
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER
            
            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+
            
            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            
            RTS           

ADDRESSREGPOST
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER
            
            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+
            
            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            MOVE.B      #'+',(A6)+
            
            RTS
            
ADDRESSREGPRE
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS FOR REGISTER
            
            MOVE.B      #'-',(A6)+
            MOVE.B      #'(',(A6)+
            MOVE.B      #'A',(A6)+
            
            JSR         DETERMINEREG    ;DETERMINE WHICH REGISTER IT IS
            MOVE.B      #')',(A6)+
            
            RTS


EAGROUP2
            MOVEM.L     (SP)+,D2        ; LOAD BINARY BITS BACK INTO D2
            AND.L       #$00000111,D2   ; MASK EVERYTHING EXCEPT LAST THREE BITS
            
            ; DETERMINE WHICH EA MODE IT IS
            CMP.L       #$00000000,D2   ; ABSOLUTE WORD
            ;BEQ         ABSOLUTEWORD
            
            CMP.L       #$00000001,D2   ; ABSOLUTE LONG
            ;BEQ         ABSOLUTELONG
            
            CMP.L       #$00000100,D2   ; IMMEDIATE
            ;BEQ         IMMEDIATE
            
            ; TEST FOR BAD INPUTS
            
            RTS
            
            

SETSIZE
            CMP.L       #$00000000,D2
            BEQ         SETSIZEBYTE
            CMP.L       #$00000001,D2
            BEQ         SETSIZEWORD
            CMP.L       #$00000010,D2
            BEQ         SETSIZELONG
            CMP.L       #$00000011,D2
            BEQ         BAD_OPCODE
            RTS

SETSIZEBYTE
            MOVE.B      #'.', (A6)+
            MOVE.W      #'B ',(A6)+ 
            RTS
SETSIZEWORD
            MOVE.B      #'.',(A6)+
            MOVE.W      #'W ',(A6)+
            RTS
SETSIZELONG
            MOVE.B      #'.',(A6)+
            MOVE.W      #'L ',(A6)+ 
            RTS


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
            ; FULL UNDECIPHERED INSTRUCTION IS NOW INSIDE D2
            ; PRINT OUT ERROR MESSAGE, FOLLOWED BY:
            ; ADDROFDATA    DATA    $0000XXXX
            ; NOTES:
            ; - ADDROFDATA IS THE ADDRESS IN LOADED CODE WHERE THE INSTRUCTION WAS HELD
            ; - DATA IS JUST A KEYWORD AND DOESN'T CHANGE
            ; - $0000XXXX IS LITERALLY WHAT'S INSIDE D2, JUST NEED TO PRINT OUT ADDRESS
            ; AFTER ALL OF THIS IS DONE, YOU HAVE PRINTED OUT THE MESSAGE AND YOUR STACK
            ; IS EMPTY. YOU WANT TO CLEAN ANY REGISTERS LEFT TO CLEAN AND THEN JUMP BACK TO ADDRESSLOOP
            ; TO READ NEXT INSTRUCTION
            ; JMP       CLEANREGISTERS

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 1 OPCODES
;
; THESE OPCODES INCLUDE: MOVE
;
; GROUP 1 OPCODES
;
; THESE OPCODES INCLUDE: MOVE
;
GROUP1OPCODE
            JSR         PRINT_MOVE      ; 
            MOVE.W      (A4),D2
            
            ; FOLLOWING LINE CHECK FOR SIZE OF MOVE 
            LSR.L       #8,D2           ; 1234 ==> 0012
            LSR.L       #4,D2           ; 0012 ==> 0001; GET THE MSB
            JSR         CONVERT2BINARY
            AND.L       #$000000FF,D2   ; CHECK THE  LAST 2 BINARY BIT 
            CMP.L       #$00000001,D2
            BEQ         GROUP1_DOTB
            CMP.L       #$00000011,D2
            BEQ         GROUP1_DOTW
            CMP.L       #$00000010,D2
            BEQ         GROUP1_DOTL
            
GROUP1_DOTB JSR         PRINT_DOT_B
            JSR         PRINT_SPACE
            BRA         GROUP1_SRC_EA
            
GROUP1_DOTW JSR         PRINT_DOT_W
            JSR         PRINT_SPACE
            BRA         GROUP1_SRC_EA   
   
GROUP1_DOTL JSR         PRINT_DOT_L
            JSR         PRINT_SPACE
            BRA         GROUP1_SRC_EA            
            ; FOLLOWING LINE DECODE SOURCE EA
GROUP1_SRC_EA
            CLR         D2
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2   ; GET THE LAST 2 HEX  BITS
            JSR         CONVERT2BINARY  ; CONVERT TO 8 BITS BINARY
            AND.L       #$00FFFFFF,D2   ; RESERVE BIT 0-5 FOR CHECKING
            LSR.L       #8,D2           ; ELIMINATE BIT 0-1
            LSR.L       #4,D2           ; ELIMATE BIT 2
            CMP.L       #$00000000,D2   ;
            BEQ         SRC_Dn
            CMP.L       #$00000010,D2
            BEQ         SRC_An
            CMP.L       #$00000011,D2
            BEQ         SRC_An_PLUS
            CMP.L       #$00000100,D2
            BEQ         SRC_MINUS_An
            
SRC_Dn      JSR         PRINT_D  
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_SRC_REG            
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    D0,
            BRA         GROUP1_DEST_EA   ; GO TO DESTINATION DECODING
            
SRC_An      JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L    (A0),
            BRA         GROUP1_DEST_EA       ; GO TO DESTINATION DECODING
SRC_An_PLUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.L      (A4),D2
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
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_SRC_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_COMM      ; PRINT COMMA IE. MOVE.L   -(An),
            BRA         GROUP1_DEST_EA      ; GO TO DESTINATION DECODING
                           
GROUP1_DEST_EA
            CLR         D2
            MOVE.L      (A4),D2
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
            
DEST_Dn     JSR         PRINT_D
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_DEST_REG
            BRA         FINISH_GROUP1
DEST_An     JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            BRA         FINISH_GROUP1

DEST_An_PLUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            JSR         PRINT_PLUS
            BRA         FINISH_GROUP1           

DEST_MINUS_An
            JSR         PRINT_MINUS
            JSR         PRINT_OPENPAR
            JSR         PRINT_A
            CLR         D2
            MOVE.L      (A4),D2
            JSR         GET_GROUP1_DEST_REG
            JSR         PRINT_CLOSEPAR
            BRA         FINISH_GROUP1  
FINISH_GROUP1
            BRA         PRINTA6
             
GET_GROUP1_SRC_REG
            AND.L       #$0000000F,D2   ; RESERVE THE LAST HEX BIT
            JSR         CONVERT2BINARY  ; BIT 0-3
            AND.L       #$00000FFF,D2   ; CLEAR BIT 3
            CMP.L       #$00000000,D2
            BEQ         PRINT_0         ; EX MOVE.L D2 by this step
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
            
GET_GROUP1_DEST_REG
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
            ;MOVEM.L     (SP)+,D2        ; MOVES THE ENTIRE OPCODE BACK INTO D2 FOR FURTHER ANALYSIS
            ;MOVEM.L     D2,-(SP)        ; SAVES ENTIRE UNDECIPHERED OPCODE BACK INTO STACK
            MOVE.W      (A4),D2
            CMP.L       #$00004E75,D2   ; RTS 
            BEQ         RTSCODE
            CMP.L       #$00004E71,D2   ; NOP
            BEQ         NOPCODE

            LSR.L       #8,D2           ; EX. 0x00004E71 BECOMES 0x0000004E
            
            CMP.L       #$00000048,D2   ; MOVEM
            BEQ         MOVEMCODE
            CMP.L       #$0000004C,D2   ; MOVEM
            BEQ         MOVEMCODE
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
            MOVE.B      #TAB,(A6)+      ; TAB SHOULD BE AFTER SETSIZE BUT THAT DOESN'T WORK
            
            
            ; STEP 2: DETERMINE SIZE
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY

            AND.L       #$11000000,D2   ; MASK EVERYTHING EXCEPT FIRST TWO BITS
            LSR.L       #8,D2            ; SHIFT 2 MSB TO LSB
            LSR.L       #8,D2
            LSR.L       #8,D2           

            JSR         SETSIZE         ; SETS SIZE OF OPERATION
            
            ; STEP 3: DETERMINE EA MODE
            ; STEP 4: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
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
            
            ;STEP 4: PRINT IT OUT
            JMP         GOOD_OPCODE






            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            ;AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            ; CONVERT REMAINING TWO BITS INTO BINARY
            ;JSR         CONVERT2BINARY
            
            ;MOVEM.L     D2,-(SP)        ; SAVES 2 LSBs BINARY BITS TO STACK
            
            ;AND.L       #$11000000,D2   ; CHECK SIZE FOR DESTINATION MODE
            
            ;LSR.L       #8,D2           ; SHIFT THE TWO BITS MSBs TO THE LSB
            ;LSR.L       #8,D2
            ;LSR.L       #8,D2
            
            ;CMP.L       #$00000011,D2
            ;BEQ         BAD_OPCODE      ; CANNOT BE 11, BAD OPCODE
            ;JSR         SETSIZE         ; SET SIZE OF OPERATION
            
                        
            ;MOVEM.L     (SP)+,D2        ; POPS 2 LSBs BINARY BITS BACK INTO D2
            ;JMP         EASTUFF         ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER
            
            


; LEACODE
; INSTRUCTION FORMAT: 4XXX
LEACODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'L',(A6)+ 
            MOVE.B      #'E',(A6)+ 
            MOVE.B      #'A',(A6)+
            MOVE.B      #TAB,(A6)+
            
            ; STEP 2: DETERMINE EA MODE
            ; STEP 3: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
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
            
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVR BINARY BITS BACK INTO STACK
            AND.L       #$00111111,D2   ; MASK EVERYTHING EXCEPT SIX BITS
            CMP.L       #$00111100,D2
            BGE         BAD_OPCODE
            
            MOVEM.L     (SP)+,D2        ; PUT BINARY BITS BACK INTO D2            
            JSR         EASTUFF2        ; OTHERWISE GOOD
            MOVE.B      #',',(A6)+
            
            ;STEP 4: DETERMINE SOURCE REGISTER
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT SECOND HEX
            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           ; SHIFTS BITS ONE TO THE RIGHT
            AND.L       #$00000111,D2   ; MASKS EVERYTHING EXCEPT 3 LSBs
            
            
            MOVE.B      #'A',(A6)+
            JSR         DETERMINEREG
            
            
            ;STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE





            ; DETERMINES An VALUE
            ;AND.L       #$00001110,D2   ; DETERMINE An DESTINATION REGISTER
            ;LSR.L       #4,D2           ; SHIFT EACH HEX VALUE ONE TO THE RIGHT
            
            ;JSR         ANDEST          ; DETERMINES WHAT THE DESTINATION REGISTER IS (An)
            

            
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            
            ;AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT LAST 2 LSBs
            ;JSR         CONVERT2BINARY  ; CONVERTS LSBs IN D2 TO BINARY
            
            ;JMP         EASTUFF         ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER
       
            
; JSRCODE
; INSTRUCTION FORMAT: 4EXX
JSRCODE
            ; STEP 1: LOAD OPWROD
            MOVE.B      #'J',(A6)+
            MOVE.B      #'S',(A6)+
            MOVE.B      #'R',(A6)+
            MOVE.B      #TAB,(A6)+
            
            ;STEP 2: DETERMINE EA MODE
            ;STEP 3: DETERMINE EA REGISTER 
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
            
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
            
            ; STEP 4: PRINT IT OUT
            JMP         GOOD_OPCODE


; MOVEMCODE
; INSTRUCTION FORMAT: 48XX OR 4CXX
MOVEMCODE
            JSR         CONVERT2BINARY  ; CONVERTS 2 MSBs TO BINARY IN D2
            AND.L       #$00000100,D2   ; MASKS EVERYTHING EXCEPT 3RD LAST BIT
            CMP.L       #$00000000,D2   ; REG->MEM
            ; BEQ         REG2MEMFLAG
            CMP.L       #$00000100,D2   ; MEM->REG
            ; BEQ         MEM2REGFLAG
            
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000011,D2   ; MASKS EVERYTHING EXCEPT LAST TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT THOSE TWO HEX VALUES INTO BINARY IN D2
            
            MOVEM.L     D2,-(SP)        ; PUSH BINARY BITS ONTO STACK
            AND.L       #$01000000,D2   ; MASKS EVERYTHING EXCEPT SECOND MSB
            CMP.L       #$00000000,D2   ; SIZE = WORD
            ;BEQ         WORDFLAG
            CMP.L       #$01000000,D2   ; SIZE = LONG
            ;BEQ         LONGFLAG
            MOVEM.L     (SP)+,D2        ; POP BINARY BITS OUT OF STACK BACK INTO D2
            JMP         EASTUFF
            
            
            
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 3 OPCODES
;
; THESE OPCODES INCLUDE: BRA, BEQ, BLT, BGT
;
GROUP3OPCODE
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            MOVE.W      (A4),D2
            LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS. EX: 0x00006E71 BECOMES 0x0000006E
            CMP.L       #$00000060,D2   ; BRA
            BEQ         BRACODE
            CMP.L       #$00000067,D2   ; BEQ
            BEQ         BEQCODE  
            CMP.L       #$0000006D,D2   
            BEQ         BLTCODE        ; BLT
            CMP.L       #$0000006E,D2
            BEQ         BGTCODE        ; BGT
            
            JMP         BAD_OPCODE      ; OTHER CASES ==> BAD OPCODE
            
BRACODE
            JSR         PRINT_BRA
            JSR         PRINT_SPACE
            JSR         PRINT_DOLLAR
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            BRA         GROUP3_FINISH
            
            
BEQCODE
            JSR         PRINT_BEQ
            JSR         PRINT_SPACE
            JSR         PRINT_DOLLAR
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            BRA         GROUP3_FINISH
            
            
BLTCODE
            JSR         PRINT_BLT
            JSR         PRINT_SPACE
            JSR         PRINT_DOLLAR
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            BRA         GROUP3_FINISH
      
BGTCODE
            JSR         PRINT_BGT
            JSR         PRINT_SPACE
            JSR         PRINT_DOLLAR
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            BNE         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            BRA         GROUP3_FINISH     
            
GROUP3_FINISH
            BRA         PRINTA6           
            
            
; REVERSE THE TWO COMPLEMENT: INVERT BITS <== ADD 1    
DSPLMCONVERSION 
            SUB.L       #%00000001,D2   ; SUBTRACT 1 FROM DISPLACEMENT
            NOT.L       D2              ; FLIP BITS
            SUB.L       #2,D2    

            CLR         D3              ; USE IT AS A COUNTER TO REMOVE LEADING F(s)         
            BRA         CLEARF          ; REMOVE LEADING F(s). AFTER FLIPPING BITS, DISPLACEMENT = $FFFFxxxx ==> $xxxx0000
RFLZ        JSR         REFILL_ZERO     ; PUSH ZERO TO REPLACE FFFF REMOVED. DISPLACEMENT ==> $0000xxxx      
            CLR         D3
            MOVE.L      D5,D3           ; MOVE CURRENT ADDR
            SUB.L       D2,D3           ; NEW ADDR BRANCHING TO
            
            
            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING
            JSR         ADDRFLOOP            
            RTS
ADDRFLOOP   
            MOVE.B      (A2)+,(A6)+
            BNE.S       ADDRFLOOP
            SUBQ        #$1,A6
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
  
REFILL_ZERO
            LSR.L       #4,D2
            SUB.L       #1,D3
            CMP.L       #0,D3
            BNE         REFILL_ZERO
            RTS 

READ_4MOREBITS
            MOVE.L      D5,-(SP)
            ADD.L       #$2,D5
            MOVE.L      D5,A4
            CLR         D3
            MOVE.W      (A4)+,D3
            ADD.L       (SP)+,D3
            JSR         L_HEXTOASCII    ; CONVERT ADDR TO STRING
            JSR         ADDRFLOOP   
            CLR         D3
            BRA         GROUP3_FINISH    
 


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
            MOVE.B      #TAB,(A6)+
        
            ; STEP 2: DETERMINE EA MODE
            ; STEP 3: DETERMINE EA REGISTER
            
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE IT BACK INTO STACK
            MOVE.W      (A4),D2
            
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
            
            MOVE.B      #',',(A6)+
            
            ; STEP 4: DETERMINE DESTINATION REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION IN STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           
            
            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG
            
            ; STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE










            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED INSTRUCTION BACK INTO STACK
            ;LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS
            
            ;JSR         CONVERT2BINARY  ; CONVERTS TWO MSBs INTO BINARY
            ;AND.L       #$00001110,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE REGISTER #
            ;LSR.L       #4,D2           ; SHIFT ALL HEX VALUES ONE TO THE RIGHT
            
            ;JSR         DNDEST
            
            ;MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            
            ;AND.L       #$000000FF,D2   ; GET LAST TWO HEX VALUES
            ;JSR         CONVERT2BINARY  ; CONVERT THEM TO BINARY
            
            ;JMP         EASTUFF
            



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
            MOVE.B      #TAB,(A6)+
            
            ; STEP 2: DETERMINE SIZE
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION BACK INTO STACK
            MOVEM.W     (A4),D2
            
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            LSR.L       #8,D2           ; SHIFT BITS 2 TO THE RIGHT
            AND.L       #$00000011,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         SETSIZE
            
            ; STEP 3: DETERMINE OPMODE (EA -> Dn vs Dn -> EA)
            ;MOVEM.L     (SP)+,D2        ; POP OFF FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES
            LSR.L       #4,D2           ; SHIFT HEX VALUES 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00010000,D2
            CMP.L       #$00010000,D2
            BGE         SUBDNEA
            ; OTHERWISE IT'S SUNEADN

SUBEADN
            ; STEP 4: DETERMINE EA MODE
            ; STEP 5: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            JSR         EASTUFF2
            
            MOVE.B      #',',(A6)+
            
            ; STEP 6: DETERMINE DESTINATION REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION IN STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           
            
            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG
            
            ; STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE


                                    
SUBDNEA
            ; STEP 4: DETERMINE SOURCE REGISTER
            MOVE.B      #'D',(A6)+
            
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            
            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            AND.L       #$00001110,D2   ; MASK EVERYTHING BUT THREE BITS
            LSR.L       #4,D2           ; SHIFT EVERYTHING 1 TO THE RIGHT
            
            JSR         DETERMINEREG
            MOVE.B      #',',(A6)+
            
            ; STEP 5: DETERMINE EA MODE
            ; STEP 6: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO D2
            ;MOVEM.      D2,(SP)-        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            JSR         EASTUFF2

            ;STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE













            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            
            ;AND.L       #$00000FF0,D2   ; GET THE MIDDLE 2 HEX DIGITS
            ;LSR.L       #4,D2           ; SHIFT ALL VALUES ONE TO THE RIGHT
            
            
            ;JSR         CONVERT2BINARY  ; CONVERT THEM INTO BINARY
            ;MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS INTO STACK TEMPORARILY
            ;AND.L       #$11100000,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE REGISTER #
            
            ;CMP.L       #$00000000,D2   ; D0
            ;BEQ         D0FLAG
            ;CMP.L       #$00100000,D2   ; D1
            ;BEQ         D1FLAG
            ;CMP.L       #$01000000,D2   ; D2
            ;BEQ         D2FLAG
            ;CMP.L       #$01100000,D2   ; D3
            ;BEQ         D3FLAG
            ;CMP.L       #$10000000,D2   ; D4
            ;BEQ         D4FLAG
            ;CMP.L       #$10100000,D2   ; D5
            ;BEQ         D5FLAG
            ;CMP.L       #$11000000,D2   ; D6
            ;BEQ         D6FLAG
            ;CMP.L       #$11100000,D2   ; D7
            ;BEQ         D7FLAG
            
            ;MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            ;AND.L       #$00011100,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE OPMODE
            
            ;CMP.L       #$00000000,D2   ; En^Dn BYTE
            ;BEQ        ENDNBYTEFLAG
            ;CMP.L       #$00000100,D2   ; En^Dn WORD
            ;BEQ        ENDNWORDFLAG
            ;CMP.L       #$00001000,D2   ; En^Dn LONG
            ;BEQ        ENDNLONGFLAG
            ;CMP.L       #$00010000,D2   ; Dn^En BYTE
            ;BEQ        DNENBYTEFLAG
            ;CMP.L       #$00010100,D2   ; Dn^En WORD
            ;BEQ        DNENWORDFLAG
            ;CMP.L       #$00011000,D2   ; Dn^En LONG
            
            ;BAD INPUT
            ;CMP.L       #$00001100,D2
            ;BEQ         BAD_OPCODE
            ;CMP.L       #$00011100,D2
            ;BEQ         BAD_OPCODE
            
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE INTO STACK
            
            ;LSL.L       #8,D2           ; THIS CAN PROBABLY BE SIMPLIFIED
            ;LSL.L       #8,D2
            ;LSL.L       #8,D2
            ;LSR.L       #8,D2
            ;LSR.L       #8,D2
            ;LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS
            ;JSR         CONVERT2BINARY  ; CONVERT THEM TO BINARY
            
            ;JMP         EASTUFF
            
            



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 6 OPCODES
;
; THESE OPCODES INCLUDE: AND, MULS
;
GROUP6OPCODE
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            MOVE.W      (A4),D2
            
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
            MOVE.B      #TAB,(A6)+
            
            ; STEP 3: DETERMINE EA MODE
            ; STEP 4: DETERMINE EA REGISTER

            ;MOVEM.L     (SP)+,D2        ; LOAD UNDECIPHERED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE IT BACK INTO STACK
            MOVE.W      (A4),D2
            
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
            
            MOVE.B      #',',(A6)+
            
            ; STEP 4: DETERMINE DESTINATION REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION IN STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           
            
            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG
            
            ; STEP 5: PRINT IT OUT
            JMP         GOOD_OPCODE


            ;MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            ;AND.L       #$11100000,D2   ; MASK THREE MSBs TO FIGURE OUT REGISTER

            ;LSR.L       #8,D2           ; SHIFT THREE MSBs TO LSB
            ;LSR.L       #8,D2
            ;LSR.L       #4,D2
            
            ;JSR         DNDEST    
            
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            ;AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            ;JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            ;JMP         EASTUFF
            
            
ANDCODE
            ; STEP 1: LOAD OPWORD
            MOVE.B      #'A',(A6)+
            MOVE.B      #'N',(A6)+
            MOVE.B      #'D',(A6)+
            MOVE.B      #TAB,(A6)+
            
            ; STEP 2: DETERMINE SIZE
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            LSR.L       #8,D2           ; SHIFT BITS 2 TO THE RIGHT
            AND.L       #$00000011,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         SETSIZE
            
            ; STEP 3: DETERMINE OPMODE (EA -> Dn vs Dn -> EA)
            ;MOVEM.L     (SP)+,D2        ; POP OFF FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES
            LSR.L       #4,D2           ; SHIFT HEX VALUES 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00010000,D2
            CMP.L       #$00010000,D2
            BGE         ANDDNEA
            ; OTHERWISE IT'S ANDEADN

ANDEADN
            ; STEP 4: DETERMINE EA MODE
            ; STEP 5: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            MOVEM.L     D2,-(SP)        ; MOVE BINARY BITS INTO STACK
            
            ; AND CANNOT BE An
            ; An = XX00 1RRR
            AND.L       #$00111000,D2   ; MASK EVERYTHING EXCEPT THREE BITS
            CMP.L       #$00001000,D2
            BEQ         BAD_OPCODE
            
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            JSR         EASTUFF2
            
            MOVE.B      #',',(A6)+
            
            ; STEP 6: DETERMINE DESTINATION REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION IN STACK
            MOVE.W      (A4),D2
            
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
            
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            
            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            AND.L       #$00001110,D2   ; MASK EVERYTHING BUT THREE BITS
            LSR.L       #4,D2           ; SHIFT EVERYTHING 1 TO THE RIGHT
            
            JSR         DETERMINEREG
            MOVE.B      #',',(A6)+
            
            ; STEP 5: DETERMINE EA MODE
            ; STEP 6: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
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

            ;MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            ;AND.L       #$00011100,D2   ; MASK EVERYTHING EXCEPT THREE BITS TO CHECK FOR OPMODE
            ;CMP.L       #$00000000,D2      ; EA + Dn BYTE
            ;BEQ        EADNBYTEFLAG
            ;CMP.L       #$00000100,D2      ; EA + Dn WORD
            ;BEQ        EADNWORDFLAG
            ;CMP.L       #$00001000,D2      ; EA + Dn LONG
            ;BEQ        EADNLONGFLAG
            ;CMP.L       #$00010000,D2      ; Dn + EA BYTE
            ;BEQ        DNEABYTEFLAG
            ;CMP.L       #$00010100,D2      ; Dn + EA WORD
            ;BEQ        DNEAWORDFLAG
            ;CMP.L       #$00011000,D2      ; Dn + EA LONG
            ;BEQ        DNEALONGFLAG
            
            ; #$00001100 DOES NOT NEED TO BE CHECKED AS IT WAS CHECKED IN GROUP6OPCODE
            
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            ;AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            ;JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            ;JMP         EASTUFF
            

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
            MOVE.B      #TAB,(A6)+
            
            ; STEP 2: DETERMINE SIZE
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$000000F0,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            LSR.L       #4,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            LSR.L       #8,D2           ; SHIFT BITS 2 TO THE RIGHT
            AND.L       #$00000011,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         SETSIZE
            
            ; STEP 3: DETERMINE OPMODE (EA -> Dn vs Dn -> EA)
            ;MOVEM.L     (SP)+,D2        ; POP OFF FULL INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES
            LSR.L       #4,D2           ; SHIFT HEX VALUES 1 TO THE RIGHT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            AND.L       #$00010000,D2
            CMP.L       #$00010000,D2
            BGE         ADDDNEA
            ; OTHERWISE IT'S ADDEADN

ADDEADN
            ; STEP 4: DETERMINE EA MODE
            ; STEP 5: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            JSR         EASTUFF2
            
            MOVE.B      #',',(A6)+
            
            ; STEP 6: DETERMINE DESTINATION REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE INSTRUCTION IN STACK
            MOVE.W      (A4),D2
            
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT 1 VALUE
            LSR.L       #8,D2           ; SHIFT VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            LSR.L       #4,D2           
            
            MOVE.B      #'D',(A6)+
            JSR         DETERMINEREG
            
            ; STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE


                                    
ADDDNEA
            ; STEP 4: DETERMINE SOURCE REGISTER
            MOVE.B      #'D',(A6)+
            
            ;MOVEM.L     (SP)+,D2        ; MOVE ENTIRE UNDECODED INSTRUCTION INTO D2
            ;MOVEM.L     D2,-(SP)        ; MOVE ENTIRE UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            AND.L       #$00000F00,D2   ; MASK EVERYTHING EXCEPT ONE HEX VALUE
            
            LSR.L       #8,D2           ; SHIFT HEX VALUE TO LSB
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            AND.L       #$00001110,D2   ; MASK EVERYTHING BUT THREE BITS
            LSR.L       #4,D2           ; SHIFT EVERYTHING 1 TO THE RIGHT
            
            JSR         DETERMINEREG
            MOVE.B      #',',(A6)+
            
            ; STEP 5: DETERMINE EA MODE
            ; STEP 6: DETERMINE EA REGISTER
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO D2
            ;MOVEM.      D2,(SP)-        ; MOVE FULL UNDECODED INSTRUCTION BACK INTO STACK
            MOVE.W      (A4),D2
            
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            JSR         EASTUFF2

            ;STEP 7: PRINT IT OUT
            JMP         GOOD_OPCODE

            






            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            ;AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES TO DETERMINE REGISTER AND OPMODE
            ;LSR.L       #4,D2           ; SHIFTS THESE TWO BITS ONE SPACE TO THE RIGHT
            ;AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT TWO LSBs
            ;JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            ;MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            ;AND.L       #$00011100,D2      ; MASK EVERYTHING EXCEPT THREE BITS TO CHECK FOR OPMODE
            ;CMP.L       #$00000000,D2      ; EA + Dn BYTE
            ;BEQ        EADNBYTEFLAG
            ;CMP.L       #$00000100,D2      ; EA + Dn WORD
            ;BEQ        EADNWORDFLAG
            ;CMP.L       #$00001000,D2      ; EA + Dn LONG
            ;BEQ        EADNLONGFLAG
            ;CMP.L       #$00010000,D2      ; Dn + EA BYTE
            ;BEQ        DNEABYTEFLAG
            ;CMP.L       #$00010100,D2      ; Dn + EA WORD
            ;BEQ        DNEAWORDFLAG
            ;CMP.L       #$00011000,D2      ; Dn + EA LONG
            ;BEQ        DNEALONGFLAG
            ;CMP.L       #$00011100,D2      ; BAD OPCODE
            ;BEQ         BAD_OPCODE
            
            ;MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            ;MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            ;AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT THE TWO LSBs
            
            ;JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            ;JMP         EASTUFF





CONVERT2BINARY8            
            JSR         CONVERT2BINARY
            RTS
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
            
     



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 8 OPCODES
;
; THESE OPCODES INCLUDE: LSL, LSR, ASL, ASR, LSL, LSR, ASL, ASR
;
GROUP8OPCODE
            MOVEM.W     (A4),D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            ;MOVEM.     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            
            LSR.L       #4,D2           ; GET THE 3RD DIGIT. EX: GET 3 FROM E234 ==> E23 (AFTER SHIFT RIGHT)
            AND.L       #$0000000F,D2   ; GET THE LSB
            JSR         CONVERT2BINARY8  ; IE: 3 = 0011
     
            LSR.L       #8,D2           ; CHECK BIT 6-7. SEE THE TABLE
            CMP.L       #$11,D2         ; COMPARE WITH 11
            BEQ         MEMSHIFT        ; MEM ADDR SHIFT
            BNE         REGSHIFT        ; REGISTER SHIFT
            ;JSR         BAD_OPCODE      ;
            
            
REGSHIFT
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
REG_LSL
            JSR         PRINT_LSL
            JSR         REG_DECODE
            BRA         GROUP8_FINISH

REG_ASL
            JSR         PRINT_ASL
            JSR         REG_DECODE
            BRA         GROUP8_FINISH



MEMSHIFT



GROUP8_FINISH
            BRA         PRINTA6
            
REG_DECODE
            MOVE.W      (A4),D2
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY
            ;MOVE.L      D2,-(SP)
            LSR.L       #8,D2
            CMP.L       #$00,D2
            BEQ         PRINT_DOT_B8
            CMP.L       #$01,D2
            BEQ         PRINT_DOT_W8
            CMP.L       #$10,D2
            BEQ         PRINT_DOT_L8
NEXT_1      JSR         PRINT_SPACE

            MOVE.W      (A4),D2
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            JSR         CONVERT2BINARY

            ;MOVE.L      (SP)+,D2
            AND.L       #$000000F0,D2
            LSR.L       #4,D2
            CMP.L       #$00000000,D2          ; IMMEDIATE COUNT
            BEQ         PRINT_HASH8
            JSR         PRINT_D            
            
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
            JSR         PRINT_D
            
            MOVE.W      (A4),D2
            AND.L       #$0000000F,D2
            JSR         CONVERT2BINARY
            AND.L       #$00000FFF,D2
            CMP.W       #$000,D2
            BEQ         PRINT_0
            CMP.W       #$001,D2
            BEQ         PRINT_1
            CMP.W       #$010,D2
            BEQ         PRINT_2
            CMP.W       #$011,D2
            BEQ         PRINT_3
            CMP.W       #$100,D2
            BEQ         PRINT_4
            CMP.W       #$101,D2
            BEQ         PRINT_5
            CMP.W       #$110,D2
            BEQ         PRINT_6
            CMP.W       #$111,D2
            BEQ         PRINT_7
DONE8       RTS

       
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
            
PRINT_SPACE MOVE.B      #' ',(A6)+
            RTS
            
PRINT_PLUS MOVE.B      #'+',(A6)+
            RTS
            
PRINT_MINUS MOVE.B      #'-',(A6)+
            RTS
            
PRINT_DOLLAR MOVE.B      #'$',(A6)+
            RTS

*========= END OF SPECIAL CHARACTERS =========*  

* ================= OPERATION VARIABLES ================= *
OPWORD      EQU     $6000
OPSIZE      EQU     $6100
OPSOURCE    EQU     $6200
OPDEST      EQU     $6300



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
AGAINPROMPT DC.B        'Would you like to search again? (Y/N) ',0
NEXTLINEPROMPT DC.B        'Would you like to print the next page? (Y/N) ',0
USERRESPONSE    DC.B    '',0
NEWLINERESPONSE    DC.B    '',0 
START_ADDRESS   DS.L    1
END_ADDRESS     DS.L    1
LINES_ON_SCREEN DS.L    1
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
