*------------------------------------------------------------------------
* Title      :  Hexspeak Disassembler
* Written by :  Taylor Eyler, Mitchell Dang, Julia Brosseau, Andrew Goupinets 
* Date       :  July 19 - August 6, 2020
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
            ;LEA         START_ADDRESS, A2   ; START_ADDRESS WILL TO BE ASSOCIATED WITH A2
            ;JSR         L_HEXTOASCII    ; CONVERTS HEX IN D3 TO ASCII INTO A2           
            ;LEA         START_ADDRESS, A2   ; SAVES START ADDRESS IN ASCII FORMAT
       
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
            MOVE.L      D6, A5           ; STORE END ADDRESS INTO THE A5 REGISTER 
            ;LEA         END_ADDRESS, A2   ; START_ADDRESS WILL TO BE ASSOCIATED WITH A2
            ;JSR         L_HEXTOASCII    ; CONVERTS HEX IN D3 TO ASCII INTO A2 AND L_HEX2ASCII_RESULT                  
            ;LEA         END_ADDRESS, A2   ; SAVES END ADDRESS IN ASCII 
            
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
            MOVE.B   #$FF, (A6) ; PUT FF IN CURRENT LOCATION OF A6 
            
CLEANOUTPUTBEFOREFILLING:
           ; A6 WILL POINT TO THE END OF PREVIOUS OUTPUT ; replace previous line with F's
            MOVE.L #$FFFFFFFF, -(A6)       ; CLEAR OUT THE CONTENTS OF OUTPUT LOCATION IN PREP FOR NEW LINE 
            CMP.B #$FF, (OUTPUTLINE_LOCATION)
            BNE CLEANOUTPUTBEFOREFILLING
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
           
           
           BRA      FINISHOUTPUTLINE ; IF VALID, SKIP INVALID MESSAGE

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
                        
           ; MOVE.B      #'F',(A6)+   ; ERROR MESSAGE
           ; MOVE.B      #'F',(A6)+   ; ERROR MESSAGE
           ; MOVE.B      #'F',(A6)+   ; ERROR MESSAGE
           ; MOVE.B      #'F',(A6)+   ; ERROR MESSAGE
            CLR.L       D2      ; ENSURE THAT D2 USED IS CLEAN                   
            
FINISHOUTPUTLINE:
            MOVE.B      #0, (A6)  ; EVERY LINE WILL NEED TO HAVE A NULL TERMINATOR TO BE PRINTED
            ;LEA     OUTPUTLINE_LOCATION, A6 ; SAVE OUTPUT_LOCATION 
            BRA     PRINTOUTPUTLINE


PRINTOUTPUTLINE:
            LEA     OUTPUTLINE_LOCATION, A1 ;USED TO PRINT RESULT OF 
            MOVE.L  #13,D0  ; PRINT CONTENT OF LINE
            TRAP    #15 
            
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
            MOVE.L      #0,A1
            MOVE.L      #0,A2
            MOVE.L      #0,A3   
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

HEX2BIN:    MOVE.B  D2,-(SP)        
            CLR     D1                  ; reset counter D1 to 0. every 1 hex digit ~ 4 digits in binary   
            MOVE.B  (SP),D2               ;
            LSR.L   #4,D2               ; get the first digit
            JSR     HCHAR2BIN           ; convert the 1st hex digit  to  binary
            
            MOVE.B  (SP)+,D2            ; retrieve the given hex value
            LSL.L   #4,D2               ; get the 2nd hex digit starting from this line
            MOVE.B  D2,-(SP)             
            CLR     D2                  ; reset D2
            MOVE.B  (SP)+,D2            ; retrieve D2 from stack
            LSR.L   #4,D2               ; get the second hex digit
            CLR     D1                  ; reset counter D1
            JSR     HCHAR2BIN           ;convert the 2nd hex digit to binary
            RTS                         ; end of subroutine
            
*------------ Start of helper subroutines for HEX2BIN ------------*
               
HCHAR2BIN   MOVE.B  D2,-(SP)            ; store a copy of d2 
            AND.B   #1,D2               
            BEQ     rec_zero            ; if Z flag (zero) is set to 1. which means D2 is an even ==> D2 % 2 =0
            BNE     rec_one             ; otherwise, D2 is an odd ==>  D2 % 2 = 1
isZero      ADD.B   #1,D1               ; record a  new binary is added to D1. 
            MOVE.B  (SP)+,D2            ; get the last D2 
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
fill_zero   CMP.B   #4,d1       
            BEQ     doswap
            ADD.B   #1,d1
            LSR.L   #4,d3    
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
                ; D2 FOR COPY OF D3 INPUT VALUE
 
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
            MOVE.L      D3,D2           ; STORE COPY AT D2 WHICH WILL HAVE BITS SHIFTED
            AND.L       #$0000000F,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST ONE
            CMP.B       #9, D2          ; CHECK IF MORE THAN 9 (10 IS A, ETC)
            BGT         L_ISLETTER      ; CONVERT LETTER BASED ON ASCII TABLE
            
L_ISDIGIT     
            ADD.W       #$30,D2         ; IS A NUMBER, SO ADD #$30 PER ASCII TABLE
            BRA         NEXT_L_H2A      ; CONTINUE AFTER DIGIT CONVERSION
            
L_ISLETTER    
            ADD.W       #$37,D2         ; IS A CHAR (IS AT LEAST 10), SO ADD $37 (65-10=55 IN DECIMAL WHICH IS $37)
            BRA         NEXT_L_H2A      ; CONVERT THE LETTER TO ASCII LETTER             
            
NEXT_L_H2A  
            MOVE.B      D2, (A2)+       ; STORE EACH BIT TO A1 IN RIGHT ORDER
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


EAGROUP1




EAGROUP2



SETSIZE
            CMP.L       #$00000000,D2
            BEQ         SETSIZEBYTE
            CMP.L       #$00000001,D2
            BEQ         SETSIZEWORD
            CMP.L       #$00000010,D2
            BEQ         SETSIZELONG
            
            RTS

SETSIZEBYTE

SETSIZEWORD

SETSIZELONG





ANDEST
            CMP.L       #$00000000,D2   ; A0
            BEQ         ANDEST0
            CMP.L       #$00000001,D2   ; A1
            BEQ         ANDEST1
            CMP.L       $00000010,D2   ; A2
            BEQ         ANDEST2
            CMP.L       $00000011,D2   ; A3
            BEQ         ANDEST3
            CMP.L       $00000100,D2   ; A4
            BEQ         ANDEST4
            CMP.L       $00000101,D2   ; A5
            BEQ         ANDEST5
            CMP.L       $00000110,D2   ; A6
            BEQ         ANDEST6
            CMP.L       $00000111,D2   ; A7
            BEQ         ANDEST7
            
            RTS

ANDEST0

ANDEST1

ANDEST2

ANDEST3

ANDEST4

ANDEST5

ANDEST6

ANDEST7


DNDEST
            CMP.L       #$00000000,D2   ; D0
            BEQ         DNDEST0
            CMP.L       #$00000001,D2   ; D1
            BEQ         DNDEST1
            CMP.L       $00000010,D2    ; D2
            BEQ         DNDEST2
            CMP.L       $00000011,D2    ; D3
            BEQ         DNDEST3
            CMP.L       $00000100,D2    ; D4
            BEQ         DNDEST4
            CMP.L       $00000101,D2    ; D5
            BEQ         DNDEST5
            CMP.L       $00000110,D2    ; D6
            BEQ         DNDEST6
            CMP.L       $00000111,D2    ; D7
            BEQ         DNDEST7
            
            RTS
            
DNDEST0

DNDEST1

DNDEST2

DNDEST3

DNDEST4

DNDEST5

DNDEST6

DNDEST7



; SUBROUTINE FOR PRINTING OUT AN OPERATION THAT HAS ALL PARTS SUCCESSFULLY DECODED
GOOD_OPCODE
            ; CLEARCACHEGOOD IS A LOOP THAT CLEANS OUT THE CACHE AND BACK TO $01000000
CLEARCACHEGOOD
            CMP.L       #$01000000,SP   ; $01000000 MEANS STACK IS EMPTY
            BNE         CLEANREGISTERS  ; IF REACH THIS POINT, EXIT ; JULIA ADDED THIS 
           ; BEQ         CLEANREGISTERS  ; IF REACH THIS POINT, EXIT ; JULIA COMMENTED THIS
            MOVEM.L     (SP)+,D2        ; LOAD MEMORY INTO D1, IRRELEVENT AND CAN BE OVERWRITTEN
            JMP         CLEARCACHEBAD

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
GROUP1OPCODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 2 OPCODES
;
; THESE OPCODES INCLUDE: MOVEM, NOT, LEA, JSR, RTS, NOP
;
GROUP2OPCODE
            MOVEM.L     (SP)+,D2        ; MOVES THE ENTIRE OPCODE BACK INTO D2 FOR FURTHER ANALYSIS
            MOVEM.L     D2,-(SP)        ; SAVES ENTIRE UNDECIPHERED OPCODE BACK INTO STACK
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
            ; SAVE OPWORD
            JMP         PRINT_RTS



; NOPCODE
NOPCODE
            ;PRINT OUT NOP
            MOVE.B      #'N',(A6)+   ; ERROR MESSAGE  
            MOVE.B      #'O',(A6)+   ; ERROR MESSAGE  
            MOVE.B      #'P',(A6)+   ; ERROR MESSAGE 
            JMP         GOOD_OPCODE     ; PRINT SUCCESSFUL, CLEAR STACK AND REGISTERS
            
            
            
; NOTCODE
; INSTRUCTION FORMAT: 46XX
NOTCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            ; CONVERT REMAINING TWO BITS INTO BINARY
            JSR         CONVERT2BINARY
            
            MOVEM.L     D2,-(SP)        ; SAVES 2 LSBs BINARY BITS TO STACK
            
            AND.L       #$11000000,D2   ; CHECK SIZE FOR DESTINATION MODE
            
            LSR.L       #8,D2           ; SHIFT THE TWO BITS MSBs TO THE LSB
            LSR.L       #8,D2
            LSR.L       #8,D2
            
            CMP.L       #$00000011,D2
            BEQ         BAD_OPCODE      ; CANNOT BE 11, BAD OPCODE
            JSR         SETSIZE         ; SET SIZE OF OPERATION
            
                        
            MOVEM.L     (SP)+,D2        ; POPS 2 LSBs BINARY BITS BACK INTO D2
            JMP         EASTUFF         ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER
            
            


; LEACODE
; INSTRUCTION FORMAT: 4XXX
LEACODE
            ; DETERMINES An VALUE
            AND.L       #$00001110,D2   ; DETERMINE An DESTINATION REGISTER
            LSR.L       #4,D2           ; SHIFT EACH HEX VALUE ONE TO THE RIGHT
            
            JSR         ANDEST          ; DETERMINES WHAT THE DESTINATION REGISTER IS (An)
            

            
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            
            AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT LAST 2 LSBs
            JSR         CONVERT2BINARY  ; CONVERTS LSBs IN D2 TO BINARY
            
            JMP         EASTUFF         ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER
       
            
; JSRCODE
; INSTRUCTION FORMAT: 4EXX
JSRCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            
            AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT LAST 2 LSBs
            JSR         CONVERT2BINARY  ; CONVERTS LSBs IN D2 TO BINARY
            
            JMP         EASTUFF         ; FIGURE OUT SOURCE MODE AND SOURCE REGISTER



; MOVEMCODE
; INSTRUCTION FORMAT: 48XX OR 4CXX
MOVEMCODE
            JSR         CONVERT2BINARY  ; CONVERTS 2 MSBs TO BINARY IN D2
            AND.L       #$00000100,D2   ; MASKS EVERYTHING EXCEPT 3RD LAST BIT
            CMP.L       #$00000000,D2   ; REG->MEM
            ; BEQ         REG2MEMFLAG
            CMP.L       #$00000100,D2   ; MEM->REG
            ; BEQ         MEM2REGFLAG
            
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; SAVES FULL UNDECIPHERED INSTRUCTION INTO STACK
            
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
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS. EX: 0x00006E71 BECOMES 0x0000006E
            CMP.L       #$00000060,D2   ; BRA
            ;BEQ         BRACODE
            CMP.L       #$00000067,D2   ; BEQ
            ;BEQ         BEQCODE  
            CMP.L       #$0000006D,D2   
            ;BEQ         BLTCODE        ; BLT
            CMP.L       #$0000006E,D2
            ;BEQ         BGTCODE        ; BGT
            
            JMP         BAD_OPCODE      ; OTHER CASES ==> BAD OPCODE
            
BRACODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            ;BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            ;BEQ         OUTPUT         ; BRA   NEW_ADDR_BRANCHING_TO (STORED AT D3)

            
BEQCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            ;BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            ;BEQ         OUTPUT         ; BEQ   NEW_ADDR_BRANCHING_TO (STORED AT D3)
            
            
BLTCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            ;BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            ;BEQ         OUTPUT         ; BLT   NEW_ADDR_BRANCHING_TO (STORED AT D3)
      
BGTCODE
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVE.L      D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            AND.L       #$000000FF,D2      ; BITMASK TO GET THE LAST 2 DIGITS. EX:  $6034 ==> $0034 
            CMP.L       #$00000000,D2   ; CHECK IF THE LAST 2 IS ZERO
            ;BEQ         READ_4MOREBITS      ; HEX ADDR HAS 2 TYPE: 4 DIGITS (60xx) OR 8 DIGITS (6000 xxxx)
            JSR         DSPLMCONVERSION ; FOR 4 DIGITS TYPE ==> THE LAST 2 DIGITS = DISPLACEMENT. 
            ;BEQ         OUTPUT         ; BGT   NEW_ADDR_BRANCHING_TO (STORED AT D3)     
            

            
            
; REVERSE THE TWO COMPLEMENT: INVERT BITS <== ADD 1    
DSPLMCONVERSION 
            MOVE.L      #$EE,D2         ; DISPLACEMENT
            SUB.L       #%00000001,D2   ; SUBTRACT 1 FROM DISPLACEMENT
            NOT.L       D2              ; FLIP BITS
            SUB.L       #2,D2    

            CLR         D3              ; USE IT AS A COUNTER TO REMOVE LEADING F(s)         
            BRA         CLEARF          ; REMOVE LEADING F(s). AFTER FLIPPING BITS, DISPLACEMENT = $FFFFxxxx ==> $xxxx0000
RFLZ        JSR         REFILL_ZERO     ; PUSH ZERO TO REPLACE FFFF REMOVED. DISPLACEMENT ==> $0000xxxx      
            CLR         D3
            MOVE.L      D5,D3           ; MOVE CURRENT ADDR
            SUB.L       D2,D3           ; NEW ADDR BRANCHING TO
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


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 4 OPCODES
;
; THESE OPCODES INCLUDE: DIVU
;
GROUP4OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED INSTRUCTION BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED INSTRUCTION BACK INTO STACK
            LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS
            
            JSR         CONVERT2BINARY  ; CONVERTS TWO MSBs INTO BINARY
            AND.L       #$00001110,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE REGISTER #
            LSR.L       #4,D2           ; SHIFT ALL HEX VALUES ONE TO THE RIGHT
            
            JSR         DNDEST
            
            MOVEM.L     (SP)+,D2        ; POPS OFF FULL UNDECIPHERED INSTRUCTION INTO D2
            MOVEM.L     D2,-(SP)        ; TEMPORARILY MOVES D2 INTO STACK
            
            AND.L       #$000000FF,D2   ; GET LAST TWO HEX VALUES
            JSR         CONVERT2BINARY  ; CONVERT THEM TO BINARY
            
            JMP         EASTUFF
            



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 5 OPCODES
;
; THESE OPCODES INCLUDE: SUB
;
; NOT TESTED YET NOT TESTED YET NOT TESTED YET NOT TESTED YET!!!!!!!!!!!
;
;
GROUP5OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            
            AND.L       #$00000FF0,D2   ; GET THE MIDDLE 2 HEX DIGITS
            LSR.L       #4,D2           ; SHIFT ALL VALUES ONE TO THE RIGHT
            
            
            JSR         CONVERT2BINARY  ; CONVERT THEM INTO BINARY
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS INTO STACK TEMPORARILY
            AND.L       #$11100000,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE REGISTER #
            
            CMP.L       #$00000000,D2   ; D0
            ;BEQ         D0FLAG
            CMP.L       #$00100000,D2   ; D1
            ;BEQ         D1FLAG
            CMP.L       #$01000000,D2   ; D2
            ;BEQ         D2FLAG
            CMP.L       #$01100000,D2   ; D3
            ;BEQ         D3FLAG
            CMP.L       #$10000000,D2   ; D4
            ;BEQ         D4FLAG
            CMP.L       #$10100000,D2   ; D5
            ;BEQ         D5FLAG
            CMP.L       #$11000000,D2   ; D6
            ;BEQ         D6FLAG
            CMP.L       #$11100000,D2   ; D7
            ;BEQ         D7FLAG
            
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            AND.L       #$00011100,D2   ; MASKS EVERYTHING EXCEPT 3 BITS TO DETERMINE OPMODE
            
            CMP.L       #$00000000,D2   ; En^Dn BYTE
            ;BEQ        ENDNBYTEFLAG
            CMP.L       #$00000100,D2   ; En^Dn WORD
            ;BEQ        ENDNWORDFLAG
            CMP.L       #$00001000,D2   ; En^Dn LONG
            ;BEQ        ENDNLONGFLAG
            CMP.L       #$00010000,D2   ; Dn^En BYTE
            ;BEQ        DNENBYTEFLAG
            CMP.L       #$00010100,D2   ; Dn^En WORD
            ;BEQ        DNENWORDFLAG
            CMP.L       #$00011000,D2   ; Dn^En LONG
            
            ;BAD INPUT
            CMP.L       #$00001100,D2
            BEQ         BAD_OPCODE
            CMP.L       #$00011100,D2
            BEQ         BAD_OPCODE
            
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE INTO STACK
            
            LSL.L       #8,D2           ; THIS CAN PROBABLY BE SIMPLIFIED
            LSL.L       #8,D2
            LSL.L       #8,D2
            LSR.L       #8,D2
            LSR.L       #8,D2
            LSR.L       #8,D2           ; GET THE FIRST 2 HEX DIGITS
            JSR         CONVERT2BINARY  ; CONVERT THEM TO BINARY
            
            JMP         EASTUFF
            
            



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 6 OPCODES
;
; THESE OPCODES INCLUDE: AND, MULS
;
GROUP6OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            
            AND.L       #$00000FF0,D2   ; GET THE MIDDLE 2 HEX DIGITS
            LSR.L       #4,D2           ; SHIFT ALL HEX VALUES ONE TO THE RIGHT

            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            MOVEM.L     D2,-(SP)        ; SAVE BINARY BITS TO THE STACK
            AND.L       #$00011100,D2   ; MASK EVERYTHING EXCEPT THE THREE BITS TO DETERMINE WHETHER IT'S AND OR MULS
            CMP.L       #$00011100,D2   ; MULS
            BEQ         MULSCODE
            CMP.L       #$00001100,D2   ; AND
            BNE         ANDCODE        ; NOT EQUAL TO BAD CODE
            
            JMP         BAD_OPCODE      ; OTHERWISE A BAD OPCODE


MULSCODE
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            AND.L       #$11100000,D2   ; MASK THREE MSBs TO FIGURE OUT REGISTER

            LSR.L       #8,D2           ; SHIFT THREE MSBs TO LSB
            LSR.L       #8,D2
            LSR.L       #4,D2
            
            JSR         DNDEST    
            
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            JMP         EASTUFF
            
            
ANDCODE
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            AND.L       #$00011100,D2   ; MASK EVERYTHING EXCEPT THREE BITS TO CHECK FOR OPMODE
            CMP.L       #$00000000,D2      ; EA + Dn BYTE
            ;BEQ        EADNBYTEFLAG
            CMP.L       #$00000100,D2      ; EA + Dn WORD
            ;BEQ        EADNWORDFLAG
            CMP.L       #$00001000,D2      ; EA + Dn LONG
            ;BEQ        EADNLONGFLAG
            CMP.L       #$00010000,D2      ; Dn + EA BYTE
            ;BEQ        DNEABYTEFLAG
            CMP.L       #$00010100,D2      ; Dn + EA WORD
            ;BEQ        DNEAWORDFLAG
            CMP.L       #$00011000,D2      ; Dn + EA LONG
            ;BEQ        DNEALONGFLAG
            
            ; #$00001100 DOES NOT NEED TO BE CHECKED AS IT WAS CHECKED IN GROUP6OPCODE
            
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT TWO LSBs
            
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            JMP         EASTUFF
            


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 7 OPCODES
;
; THESE OPCODES INCLUDE: ADD
;
GROUP7OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            AND.L       #$00000FF0,D2   ; MASK EVERYTHING EXCEPT TWO HEX VALUES TO DETERMINE REGISTER AND OPMODE
            LSR.L       #4,D2           ; SHIFTS THESE TWO BITS ONE SPACE TO THE RIGHT
            AND.L       #$000000FF,D2   ; MASKS EVERYTHING EXCEPT TWO LSBs
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            MOVEM.L     (SP)+,D2        ; MOVE BINARY BITS BACK INTO D2
            AND.L       #$00011100,D2      ; MASK EVERYTHING EXCEPT THREE BITS TO CHECK FOR OPMODE
            CMP.L       #$00000000,D2      ; EA + Dn BYTE
            ;BEQ        EADNBYTEFLAG
            CMP.L       #$00000100,D2      ; EA + Dn WORD
            ;BEQ        EADNWORDFLAG
            CMP.L       #$00001000,D2      ; EA + Dn LONG
            ;BEQ        EADNLONGFLAG
            CMP.L       #$00010000,D2      ; Dn + EA BYTE
            ;BEQ        DNEABYTEFLAG
            CMP.L       #$00010100,D2      ; Dn + EA WORD
            ;BEQ        DNEAWORDFLAG
            CMP.L       #$00011000,D2      ; Dn + EA LONG
            ;BEQ        DNEALONGFLAG
            CMP.L       #$00011100,D2      ; BAD OPCODE
            BEQ         BAD_OPCODE
            
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED HEX INSTRUCTION BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED HEX INSTRUCTION INTO STACK
            
            AND.L       #$000000FF,D2   ; MASK EVERYTHING EXCEPT THE TWO LSBs
            
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY
            
            JMP         EASTUFF


            
     



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; GROUP 8 OPCODES
;
; THESE OPCODES INCLUDE: LSL, LSR, ASL, ASR, LSL, LSR, ASL, ASR
;
GROUP8OPCODE
            MOVEM.L     (SP)+,D2        ; MOVE FULL UNDECIPHERED OPCODE BACK INTO D2
            MOVEM.L     D2,-(SP)        ; SAVE FULL UNDECIPHERED OPCODE BACK INTO STACK
            
            LSR.L       #4,D2           ; GET THE 3RD DIGIT. EX: GET 3 FROM E234 ==> E23 (AFTER SHIFT RIGHT)
            AND.L       #$0000000F,D2   ; GET THE LSB
            JSR         CONVERT2BINARY  ; IE: 3 = 0011
     
            LSR.W       #8,D2           ; CHECK BIT 6-7. SEE THE TABLE
            CMP.L       #$11,D2         ; COMPARE WITH 11
            BEQ         MEMSHIFT        ; MEM ADDR SHIFT
            BNE         REGSHIFT        ; REGISTER SHIFT
            ;JSR         BAD_OPCODE      ;
            
MEMSHIFT    CLR         D2
            MOVE.L      (SP)+,D2        ; POP D2 FROM STACK
            ; FOLLOWING CODE CHECK BITS 8-11
            LSR.W       #8,D2           ; EX E234 ==> E2
            AND.L       #$0000000F,D2   ; 000000E2 ==> 00000002
            JSR         CONVERT2BINARY
            MOVE.L      D2,-(SP)        ; PUSH THE BINARY TO SP 
            LSR.W       #4,D2           ; GET BIT 9-11. SHIFT 2 = 0000 0010 ==> 0000 0001
            CMP.L       #$000,D2        ; COMPARE BIT 9-11. SEE THE TABLE
            BEQ         MEM_ASxCODE     ;
            CMP.L       #$001,D2
            BEQ         MEM_LSxCODE     ;
            ;JSR         BAD_OPCODE      

MEM_ASxCODE CLR         D2
            MOVE.L      (SP)+,D2        ; POP 4BIT BINARY FROM STACK
            AND.L       #$0000000F,D2   ; CHECK THE LSB. BIT 8 IN THE TABLE OF ASL/ASR MEM SHIFT
            CMP.L       #$00000001,D2   
            BEQ         MEM_ASLCODE
            CMP.L       #$00000000,D2
            BEQ         MEM_ASRCODE
            
MEM_LSxCODE CLR         D2
            MOVE.L      (SP)+,D2        ; POP 4BIT BINARY FROM STACK
            AND.L       #$0000000F,D2   ; CHECK THE LSB. BIT 8 IN THE TABLE OF LSL/LSR MEM SHIFT
            CMP.L       #$00000001,D2   ; CHECK dr. IF 1==> SHIFT LEFT. 0==> SHIFT RIGHT
            BEQ         MEM_LSLCODE
            CMP.L       #$00000000,D2   ; CHECK dr. IF 1==> SHIFT LEFT. 0==> SHIFT RIGHT
            BEQ         MEM_LSRCODE

            
MEM_ASLCODE CLR         D2
            MOVE.L      (SP)+,D2        ; POP HEX FROM SP
            AND.L       #$000000FF,D2   ; KEEP THE LAST 2HEX BIT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY FOR BIT 0-7  IN THE TABLE.
            AND.L       #$00FFFFFF,D2   ; IGNORE/CLEAR OUT 2 BITS 6-7. EX: 11ab cdef ==> 00ab cdef
            MOVE.L      D2,-(SP)        ; MOVE 00ab cdef TO STACK
            LSL.W       #8,D2           ; 00ab cdef ==> 0000 abcd
            LSR         #4,D2           ; 0000 abcd ==> 0000 0abc
            JSR         CHECK_EAMODE
            ;BRA         OUTPUT
            
MEM_ASRCODE
            CLR         D2
            MOVE.L      (SP)+,D2        ; POP HEX FROM SP
            AND.L       #$000000FF,D2   ; KEEP THE LAST 2HEX BIT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY FOR BIT 0-7  IN THE TABLE.
            AND.L       #$00FFFFFF,D2   ; IGNORE/CLEAR OUT 2 BITS 6-7. EX: 11ab cdef ==> 00ab cdef
            MOVE.L      D2,-(SP)        ; MOVE 00ab cdef TO STACK
            LSL.W       #8,D2           ; 00ab cdef ==> 0000 abcd
            LSR         #4,D2           ; 0000 abcd ==> 0000 0abc
            JSR         CHECK_EAMODE
            ;BRA         OUTPUT


MEM_LSLCODE
            CLR         D2
            MOVE.L      (SP)+,D2        ; POP HEX FROM SP
            AND.L       #$000000FF,D2   ; KEEP THE LAST 2HEX BIT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY FOR BIT 0-7  IN THE TABLE.
            AND.L       #$00FFFFFF,D2   ; IGNORE/CLEAR OUT 2 BITS 6-7. EX: 11ab cdef ==> 00ab cdef
            MOVE.L      D2,-(SP)        ; MOVE 00ab cdef TO STACK
            LSL.W       #8,D2           ; 00ab cdef ==> 0000 abcd
            LSR         #4,D2           ; 0000 abcd ==> 0000 0abc
            JSR         CHECK_EAMODE
            ;BRA         OUTPUT

MEM_LSRCODE
            CLR         D2
            MOVE.L      (SP)+,D2        ; POP HEX FROM SP
            AND.L       #$000000FF,D2   ; KEEP THE LAST 2HEX BIT
            JSR         CONVERT2BINARY  ; CONVERT TO BINARY FOR BIT 0-7  IN THE TABLE.
            AND.L       #$00FFFFFF,D2   ; IGNORE/CLEAR OUT 2 BITS 6-7. EX: 11ab cdef ==> 00ab cdef
            MOVE.L      D2,-(SP)        ; MOVE 00ab cdef TO STACK
            LSL.W       #8,D2           ; 00ab cdef ==> 0000 abcd
            LSR         #4,D2           ; 0000 abcd ==> 0000 0abc
            JSR         CHECK_EAMODE
            ;BRA         OUTPUT
     
            ; FOLLOWING CODE CHECK FOR EA MODE
CHECK_EAMODE
MEMS_An         CMP.L       #$010,D2
                BNE         MEM_An_PLUS
                ;BEQ         
                BRA         MEM_DONE

MEM_An_PLUS     CMP.L       #$011,D2
                BNE         MEM_MINUS_An
                ;BEQ
                BRA         MEM_DONE

MEM_MINUS_An    CMP.L       #$100,D2
                BNE         MEM_d16_An
                ;BEQ
                BRA         MEM_DONE

MEM_d16_An      CMP.L       #$101,D2
                BNE         MEM_d8_AnXn
                ;BEQ 
                BRA         MEM_DONE
MEM_d8_AnXn     CMP.L       #$110,D2
                BNE         MEM_DOT_WL
                ;BEQ
                BRA         MEM_DONE
                
MEM_DOT_WL      CMP.L       #$111,D2
                ;BNE         BAD_EA
                CLR         D2
                MOVE.L      (SP)+,D2
                AND.L       #$00000FFF,D2   ; CHECK BIT 0-2 
                CMP.L       #$000,D2
                BNE         MEM_DOT_L
                ;BEQ         FLAG_DOT_W
                BRA         MEM_DONE
                
MEM_DOT_L       CMP.L       #$111,D2
                ;BNE         BAD_EA
                ;BEQ         FLAG_DOT_L
                BRA         MEM_DONE       
                
MEM_DONE        RTS
       

REGSHIFT        CLR         D2
                MOVE.L      (SP)+,D2        ; POP HEX FROM STACK. EX: E234 ==> D2
                MOVE.L      D2,-(SP)
                AND.L       #$000000FF,D2   ; GET THE LAST 2 HEX BIT. OR BIT 0-7 IN BINARY
                JSR         CONVERT2BINARY  
                AND.L       #$000FF000,D2   ; FOLLOWING LINE TO GET BIT 3-4
                LSR.L       #8,D2
                LSR.L       #4,D2 
          
                CMP.L       #$01,D2
                BEQ         REG_LSx
                CMP.L       #$00,D2
                BEQ         REG_ASx
                ;BRA         BAD_EA
                
REG_LSx         CLR         D2              ; POP 4 BIT HEX DIGITS FROM STACK 
                MOVE.L      (SP)+,D2        
                MOVE.L      D2,-(SP)        
                AND.L       #$00000F00,D2   ; KEEP 3RD DIGITS AND ZERO OUT OTHERS
                LSR.W       #8,D2           ; $0000 0F00 ==> $0000 000F
                MOVE.L      D2,-(SP)
                AND.B       #1,D2           ; CHECK BIT 8 TO  FIND OUT  THE SHIFTING  DIRECTION
                BEQ.S       REG_LSR         ; IF  ZERO ==> SHIFT  RIGHT
                BNE         REG_LSL         ; OTHERWISE, SHIFT LEFT                  
                


REG_ASx         CLR         D2              ; POP 4 BIT HEX DIGITS FROM STACK 
                MOVE.L      (SP)+,D2        
                MOVE.L      D2,-(SP)        
                AND.L       #$00000F00,D2   ; KEEP 3RD DIGITS AND ZERO OUT OTHERS
                LSR.W       #8,D2           ; $0000 0F00 ==> $0000 000F

                AND.L       #1,D2           ; CHECK BIT 8 TO FIND OUT THE SHIFTING DIRECTION
                BEQ         REG_ASR         ; IF ZERO ==> SHIFT RIGHT
                BNE         REG_ASL         ; OTHERWISE, SHIFT LEFT

REG_LSR         MOVE.L      (SP)+,D2        ; POP D2 FROM THE STACK
                MOVE.L      D2,-(SP)
                
                AND.L       #$0000000F,D2   ; GET THE LSB
                JSR         CONVERT2BINARY
                AND.L       #$00000FFF,D2      ; BIT MASK TO RESERVE THE LAST 3 BINARY DIGITS
                ; FOLLOWING LINES CHECK  FOR DESTINATION REGISTER
                CMP.L       #$00000000,D2
                ;BEQ         FLAGD0
                CMP.L       #$00000001,D2
                ;BEQ         FLAGD1
                CMP.L       #$00000010,D2
                ;BEQ         FLAGD2
                CMP.L       #$00000011,D2
                ;BEQ         FLAGD3
                CMP.L       #$00000100,D2
                ;BEQ         FLAGD4
                CMP.L       #$00000101,D2
                ;BEQ         FLAGD5
                CMP.L       #$00000110,D2
                ;BEQ         FLAGD6
                CMP.L       #$00000111,D2
                ;BEQ         FLAGD7
                
                ; FOLLOWING LINES CHECK  FOR SIZE, i/r
                MOVE.L      (SP)+,D2
                MOVE.L      D2,-(SP)
                
                AND.L       #$00000F00,D2       ; GET THE 3RD HEX DIGIT
                LSR.L       #8,D2               ; $00000F00 ==> $0000 000F
                JSR         CONVERT2BINARY
                MOVE.L      D2,-(SP)            ; CONVERT TO 4 BIT BINARY. 
                LSR.L       #8,D2               ; CHECK BIT  6-7
                CMP.L       #$00,D2
                ;BEQ         FLAGBYTE
                CMP.L       #$01,D2
                ;BEQ         FLAGWORD
                CMP.L       #$10,D2
                ;BEQ         FLAGLONG
                CLR         D2
                MOVE.L      (SP)+,D2
                AND.L       #$000000F0,D2       ; CHECK BIT 5  FOR i/r
                CMP.L       #$0,D2        
                ;BEQ         GET_IMMEDIATE_ADDR  ; IF i/r = 1 ==> READ IMMEDIATE ADDR BY .B .W .L BYTES. 
                CLR         D2
                MOVE.L      (SP)+,D2            ; OTHERWISE, GET THE SHIFT COUNT #
                MOVE.L      D2,-(SP)
                AND.L       #$00000F00,D2
                LSR.L       #8,D2
                JSR         CONVERT2BINARY      ; GET BINARY BITS 8-11
                LSR.L       #4,D2               ; ONLY GET THE FIRST 3 BINARY  BITS FOR REGISTER (9-11)
                
                CMP.L       #$000,D2
                ;BEQ         FLAG_SHIFT0         ; SHIFT #0 
                CMP.L       #$001,D2
                ;BEQ         FLAG_SHIFT1         ; SHIFT #1
                CMP.L       #$010,D2
                ;BEQ         FLAG_SHIFT2         ; SHIFT #2
                CMP.L       #$011,D2
                ;BEQ         FLAG_SHIFT3         ; SHIFT #3
                CMP.L       #$100,D2
                ;BEQ         FLAG_SHIFT4         ; SHIFT #4
                CMP.L       #$101,D2
                ;BEQ         FLAG_SHIFT5         ; SHIFT #5 
                CMP.L       #$110,D2
                ;BEQ         FLAG_SHIFT6         ; SHIFT #6 
                CMP.L       #$111,D2
                ;BEQ         FLAG_SHIFT7         ; SHIFT #7
                
                RTS


REG_LSL         MOVE.L      (SP)+,D2        ; POP D2 FROM THE STACK
                MOVE.L      D2,-(SP)
                
                AND.L       #$0000000F,D2   ; GET THE LSB
                JSR         CONVERT2BINARY
                AND.L       #$00000FFF,D2      ; BIT MASK TO RESERVE THE LAST 3 BINARY DIGITS
                ; FOLLOWING LINES CHECK  FOR DESTINATION REGISTER
                CMP.L       #$00000000,D2
                ;BEQ         FLAGD0
                CMP.L       #$00000001,D2
                ;BEQ         FLAGD1
                CMP.L       #$00000010,D2
                ;BEQ         FLAGD2
                CMP.L       #$00000011,D2
                ;BEQ         FLAGD3
                CMP.L       #$00000100,D2
                ;BEQ         FLAGD4
                CMP.L       #$00000101,D2
                ;BEQ         FLAGD5
                CMP.L       #$00000110,D2
                ;BEQ         FLAGD6
                CMP.L       #$00000111,D2
                ;BEQ         FLAGD7
                
                ; FOLLOWING LINES CHECK  FOR SIZE, i/r
                MOVE.L      (SP)+,D2
                MOVE.L      D2,-(SP)
                
                AND.L       #$00000F00,D2       ; GET THE 3RD HEX DIGIT
                LSR.L       #8,D2               ; $00000F00 ==> $0000 000F
                JSR         CONVERT2BINARY
                MOVE.L      D2,-(SP)            ; CONVERT TO 4 BIT BINARY. 
                LSR.L       #8,D2               ; CHECK BIT  6-7
                CMP.L       #$00,D2
                ;BEQ         FLAGBYTE
                CMP.L       #$01,D2
                ;BEQ         FLAGWORD
                CMP.L       #$10,D2
                ;BEQ         FLAGLONG
                CLR         D2
                MOVE.L      (SP)+,D2
                AND.L       #$000000F0,D2       ; CHECK BIT 5  FOR i/r
                CMP.L       #$0,D2        
                ;BEQ         GET_IMMEDIATE_ADDR  ; IF i/r = 1 ==> READ IMMEDIATE ADDR BY .B .W .L BYTES. 
                CLR         D2
                MOVE.L      (SP)+,D2            ; OTHERWISE, GET THE SHIFT COUNT #
                MOVE.L      D2,-(SP)
                AND.L       #$00000F00,D2
                LSR.L       #8,D2
                JSR         CONVERT2BINARY      ; GET BINARY BITS 8-11
                LSR.L       #4,D2               ; ONLY GET THE FIRST 3 BINARY  BITS FOR REGISTER (9-11)
                
                CMP.L       #$000,D2
                ;BEQ         FLAG_SHIFT0         ; SHIFT #0 
                CMP.L       #$001,D2
                ;BEQ         FLAG_SHIFT1         ; SHIFT #1
                CMP.L       #$010,D2
                ;BEQ         FLAG_SHIFT2         ; SHIFT #2
                CMP.L       #$011,D2
                ;BEQ         FLAG_SHIFT3         ; SHIFT #3
                CMP.L       #$100,D2
                ;BEQ         FLAG_SHIFT4         ; SHIFT #4
                CMP.L       #$101,D2
                ;BEQ         FLAG_SHIFT5         ; SHIFT #5 
                CMP.L       #$110,D2
                ;BEQ         FLAG_SHIFT6         ; SHIFT #6 
                CMP.L       #$111,D2
                ;BEQ         FLAG_SHIFT7         ; SHIFT #7
                
                RTS

REG_ASR         MOVE.L      (SP)+,D2        ; POP D2 FROM THE STACK
                MOVE.L      D2,-(SP)
                
                AND.L       #$0000000F,D2   ; GET THE LSB
                JSR         CONVERT2BINARY
                AND.L       #$00000FFF,D2      ; BIT MASK TO RESERVE THE LAST 3 BINARY DIGITS
                ; FOLLOWING LINES CHECK  FOR DESTINATION REGISTER
                CMP.L       #$00000000,D2
                ;BEQ         FLAGD0
                CMP.L       #$00000001,D2
                ;BEQ         FLAGD1
                CMP.L       #$00000010,D2
                ;BEQ         FLAGD2
                CMP.L       #$00000011,D2
                ;BEQ         FLAGD3
                CMP.L       #$00000100,D2
                ;BEQ         FLAGD4
                CMP.L       #$00000101,D2
                ;BEQ         FLAGD5
                CMP.L       #$00000110,D2
                ;BEQ         FLAGD6
                CMP.L       #$00000111,D2
                ;BEQ         FLAGD7
                
                ; FOLLOWING LINES CHECK  FOR SIZE, i/r
                MOVE.L      (SP)+,D2
                MOVE.L      D2,-(SP)
                
                AND.L       #$00000F00,D2       ; GET THE 3RD HEX DIGIT
                LSR.L       #8,D2               ; $00000F00 ==> $0000 000F
                JSR         CONVERT2BINARY
                MOVE.L      D2,-(SP)            ; CONVERT TO 4 BIT BINARY. 
                LSR.L       #8,D2               ; CHECK BIT  6-7
                CMP.L       #$00,D2
                ;BEQ         FLAGBYTE
                CMP.L       #$01,D2
                ;BEQ         FLAGWORD
                CMP.L       #$10,D2
                ;BEQ         FLAGLONG
                CLR         D2
                MOVE.L      (SP)+,D2
                AND.L       #$000000F0,D2       ; CHECK BIT 5  FOR i/r
                CMP.L       #$0,D2        
                ;BEQ         GET_IMMEDIATE_ADDR  ; IF i/r = 1 ==> READ IMMEDIATE ADDR BY .B .W .L BYTES. 
                CLR         D2
                MOVE.L      (SP)+,D2            ; OTHERWISE, GET THE SHIFT COUNT #
                MOVE.L      D2,-(SP)
                AND.L       #$00000F00,D2
                LSR.L       #8,D2
                JSR         CONVERT2BINARY      ; GET BINARY BITS 8-11
                LSR.L       #4,D2               ; ONLY GET THE FIRST 3 BINARY  BITS FOR REGISTER (9-11)
                
                CMP.L       #$000,D2
                ;BEQ         FLAG_SHIFT0         ; SHIFT #0 
                CMP.L       #$001,D2
                ;BEQ         FLAG_SHIFT1         ; SHIFT #1
                CMP.L       #$010,D2
                ;BEQ         FLAG_SHIFT2         ; SHIFT #2
                CMP.L       #$011,D2
                ;BEQ         FLAG_SHIFT3         ; SHIFT #3
                CMP.L       #$100,D2
                ;BEQ         FLAG_SHIFT4         ; SHIFT #4
                CMP.L       #$101,D2
                ;BEQ         FLAG_SHIFT5         ; SHIFT #5 
                CMP.L       #$110,D2
                ;BEQ         FLAG_SHIFT6         ; SHIFT #6 
                CMP.L       #$111,D2
                ;BEQ         FLAG_SHIFT7         ; SHIFT #7
                
                RTS
                

REG_ASL         MOVE.L      (SP)+,D2        ; POP D2 FROM THE STACK
                MOVE.L      D2,-(SP)
                
                AND.L       #$0000000F,D2   ; GET THE LSB
                JSR         CONVERT2BINARY
                AND.L       #$00000FFF,D2      ; BIT MASK TO RESERVE THE LAST 3 BINARY DIGITS
                ; FOLLOWING LINES CHECK  FOR DESTINATION REGISTER
                CMP.L       #$00000000,D2
                ;BEQ         FLAGD0
                CMP.L       #$00000001,D2
                ;BEQ         FLAGD1
                CMP.L       #$00000010,D2
                ;BEQ         FLAGD2
                CMP.L       #$00000011,D2
                ;BEQ         FLAGD3
                CMP.L       #$00000100,D2
                ;BEQ         FLAGD4
                CMP.L       #$00000101,D2
                ;BEQ         FLAGD5
                CMP.L       #$00000110,D2
                ;BEQ         FLAGD6
                CMP.L       #$00000111,D2
                ;BEQ         FLAGD7
                
                ; FOLLOWING LINES CHECK  FOR SIZE, i/r
                MOVE.L      (SP)+,D2
                MOVE.L      D2,-(SP)
                
                AND.L       #$00000F00,D2       ; GET THE 3RD HEX DIGIT
                LSR.L       #8,D2               ; $00000F00 ==> $0000 000F
                JSR         CONVERT2BINARY
                MOVE.L      D2,-(SP)            ; CONVERT TO 4 BIT BINARY. 
                LSR.L       #8,D2               ; CHECK BIT  6-7
                CMP.L       #$00,D2
                ;BEQ         FLAGBYTE
                CMP.L       #$01,D2
                ;BEQ         FLAGWORD
                CMP.L       #$10,D2
                ;BEQ         FLAGLONG
                CLR         D2
                MOVE.L      (SP)+,D2
                AND.L       #$000000F0,D2       ; CHECK BIT 5  FOR i/r
                CMP.L       #$0,D2        
                ;BEQ         GET_IMMEDIATE_ADDR  ; IF i/r = 1 ==> READ IMMEDIATE ADDR BY .B .W .L BYTES. 
                CLR         D2
                MOVE.L      (SP)+,D2            ; OTHERWISE, GET THE SHIFT COUNT #
                MOVE.L      D2,-(SP)
                AND.L       #$00000F00,D2
                LSR.L       #8,D2
                JSR         CONVERT2BINARY      ; GET BINARY BITS 8-11
                LSR.L       #4,D2               ; ONLY GET THE FIRST 3 BINARY  BITS FOR REGISTER (9-11)
                
                CMP.L       #$000,D2
                ;BEQ         FLAG_SHIFT0         ; SHIFT #0 
                CMP.L       #$001,D2
                ;BEQ         FLAG_SHIFT1         ; SHIFT #1
                CMP.L       #$010,D2
                ;BEQ         FLAG_SHIFT2         ; SHIFT #2
                CMP.L       #$011,D2
                ;BEQ         FLAG_SHIFT3         ; SHIFT #3
                CMP.L       #$100,D2
                ;BEQ         FLAG_SHIFT4         ; SHIFT #4
                CMP.L       #$101,D2
                ;BEQ         FLAG_SHIFT5         ; SHIFT #5 
                CMP.L       #$110,D2
                ;BEQ         FLAG_SHIFT6         ; SHIFT #6 
                CMP.L       #$111,D2
                ;BEQ         FLAG_SHIFT7         ; SHIFT #7
                
                RTS                         




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
            JMP         GOOD_OPCODE 
            
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
            JMP         GOOD_OPCODE   

PRINT_NOT
            MOVE.B      #'N',(A6)+     
            MOVE.B      #'O',(A6)+     
            MOVE.B      #'T',(A6)+  
            JMP         GOOD_OPCODE   

PRINT_ASL
            MOVE.B      #'L',(A6)+     
            MOVE.B      #'S',(A6)+     
            MOVE.B      #'L',(A6)+  
            JMP         GOOD_OPCODE   

PRINT_LSL
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'S',(A6)+     
            MOVE.B      #'L',(A6)+  
            JMP         GOOD_OPCODE   

PRINT_BGT
            MOVE.B      #'B',(A6)+     
            MOVE.B      #'G',(A6)+     
            MOVE.B      #'T',(A6)+  
            JMP         GOOD_OPCODE 
            
PRINT_BLE
            MOVE.B      #'B',(A6)+     
            MOVE.B      #'L',(A6)+     
            MOVE.B      #'E',(A6)+  
            JMP         GOOD_OPCODE             

PRINT_BEQ
            MOVE.B      #'B',(A6)+     
            MOVE.B      #'E',(A6)+     
            MOVE.B      #'Q',(A6)+  
            JMP         GOOD_OPCODE   
            
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
            JMP         GOOD_OPCODE  
            
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
PRINT_D0
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'0',(A6)+     
            RTS
            
PRINT_D1
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'1',(A6)+     
            RTS            
PRINT_D2
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'2',(A6)+     
            RTS
            
PRINT_D3
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'3',(A6)+     
            RTS  
PRINT_D4
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'4',(A6)+     
            RTS
            
PRINT_D5
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'5',(A6)+     
            RTS            
PRINT_D6
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'6',(A6)+     
            RTS
            
PRINT_D7
            MOVE.B      #'D',(A6)+     
            MOVE.B      #'7',(A6)+     
            RTS             
PRINT_A0
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'0',(A6)+     
            RTS
            
PRINT_A1
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'1',(A6)+     
            RTS            
PRINT_A2
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'2',(A6)+     
            RTS
            
PRINT_A3
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'3',(A6)+     
            RTS  
PRINT_A4
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'4',(A6)+     
            RTS
            
PRINT_A5
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'5',(A6)+     
            RTS            
PRINT_A6
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'6',(A6)+     
            RTS
            
PRINT_A7
            MOVE.B      #'A',(A6)+     
            MOVE.B      #'7',(A6)+     
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
           

*========= END OF SPECIAL CHARACTERS =========*









* ================= OPCODE WORDS ================= *
MOVEWORD    DC.B    'MOVE',0
MOVEMWORD   DC.B    'MOVEM',0
NOTWORD     DC.B    'NOT',0
LEAWORD     DC.B    'LEA',0
JSRWORD     DC.B    'JSR',0
RTSWORD     DC.B    'RTS',0
NOPWORD     DC.B    'NOP',0
BRAWORD     DC.B    'BRA',0
BEQWORD     DC.B    'BEQ',0
BLTWORD     DC.B    'BLT',0
BGTWORD     DC.B    'BGT',0
DIVUWORD    DC.B    'DIVU',0
SUBWORD     DC.B    'SUB',0
ANDWORD     DC.B    'AND',0
MULSWORD    DC.B    'MULS',0
ADDWORD     DC.B    'ADD',0
LSLWORD     DC.B    'LSL',0
LSRWORD     DC.B    'LSR',0
ASLWORD     DC.B    'ASL',0
ASRWORD     DC.B    'ASR',0

* ================= SYMBOLS ================= *
LONGSIZE    DC.B    '.L',0
WORDSIZE    DC.B    '.W',0
BYTESIZE    DC.B    '.B',0

IMMEDIATE   DC.B    '#',0
HEX         DC.B    '$',0
BINARY      DC.B    '%',0

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
