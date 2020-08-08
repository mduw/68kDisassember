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
            CMP.L      D5,D6       ; COMPARE START AND END ADDRESSES 
            BLT        GOAGAIN     ; GIVE OPTION TO RESTART IF START IS MORE THAN END ADDRESS
            
LIMITLINESONSCREEN
            
            CMP.B   #20, LINES_ON_SCREEN ; LIMIT OF 20 LINES PER SCREEN/PAGE
            BNE FILLOUTPUTLINE  ; IF UNDER 20, FILL AND PRINT LINES 
            JSR     ASKIFPRINTNEXTLINE   ; IF MORE - ASK IF PRINTING MORE IS NEEDED          
                  
FILLOUTPUTLINE:
            ADD.B   #1, LINES_ON_SCREEN ; COUNT THE LINE THAT IS ABOUT TO BE PRINTED           
            CLR     (A6)               ; ENSURE THAT A6 IS EMPTY
            LEA     OUTPUTLINE_LOCATION, A6 ; ASSOCIATE OUTPUT_LOCATION AND A6
           ; MOVE.B      #DOLLAR,(A6)+   ; KEEP ON ADDING WHAT YOU WANT TO PRINT (CAN PRINT $ HERE IF NEEDED)
            
ADDADDRINTOLINE:
            MOVE.L  D5,D3   ; COPY CURRENT ADDRESS INTO D3 FOR CONVERSION
            JSR L_HEXTOASCII    ; FIRST CONVERT ADDRESS STORED IN HEX INTO ASCII 
            
ADDRTOLINELOOP:        
            MOVE.B      (A2)+, (A6)+    ; CARRY OVER ONE CHAR AT A TIME FROM A2 TO A6
            BNE.S       ADDRTOLINELOOP  ; TEST FOR END OF STRING, CONTINUE IF NOT   
            SUBQ        #$1, A6         ; REMOVE THE NULL TERMINATOR FROM CARRIED OVER ADDRESS
            MOVE.B      #TAB,(A6)+      ; KEEP ON ADDING WHAT YOU WANT TO PRINT 
            
            ; CHECK IF CONTENT OF (A4) IS NOT #$0000FFFF (WHICH INDICATES THAT IT IS END OF FILE OR INVALID OPCODE)

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
           ; JSR CHECKOPCODE ; GO TO DECODE THE 4 HEX VALUES GIVEN TO IT      
           BRA FINISHOUTPUTLINE ; IF VALID, SKIP INVALID MESSAGE

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
            
            ; ADDRESS DISPLAYED MUST BE 8 DIGIT HEX VALUE PER SPECS
            
ADDRFORERROR:
            MOVE.L  D2,D3   ; COPY CURRENT ADDRESS INTO D3 FOR CONVERSION
            JSR L_HEXTOASCII    ; FIRST CONVERT ADDRESS STORED IN HEX INTO ASCII -> A2 HAS RESULT
            
ADDRFORERRORLOOP:                        
            MOVE.B      (A2)+, (A6)+    ; CARRY OVER ONE CHAR AT A TIME FROM A2 TO A6
            BNE.S       ADDRFORERRORLOOP ; TEST FOR END OF STRING, CONTINUE IF NOT   
            SUBQ        #$1, A6          ; REMOVE THE NULL TERMINATOR FROM CARRIEVED OVER ADDRESS
            CLR.L       D2      ; ENSURE THAT D2 USED IS CLEAN             
            
FINISHOUTPUTLINE:
            MOVE.B      #0, (A6)  ; EVERY LINE WILL NEED TO HAVE A NULL TERMINATOR TO BE PRINTED
            LEA     OUTPUTLINE_LOCATION, A6 ; SAVE OUTPUT_LOCATION 
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

CLRSCRN     MOVE.W      #$FF00,D1 ; CLEAN SCREEN TO DISPLAY NEXT PAGE OF DECODED OP-CODES WITH THEIR ADDRESSES 
            MOVE.B      #11,D0 
            TRAP        #15
            JMP         STARTNEWLINE               

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
            
* ================== INCLUDE MODULES ================== *
            INCLUDE     'IO_func.X68'

* ======================== END ======================== *

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
