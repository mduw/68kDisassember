*------------------------------------------------------------------------
* Title      :  Hexspeak Disassembler
* Written by :  Taylor Eyler, Mitchell Dang, Julia Brosseau, Andrew Goupinets 
* Date       :  July 19 - August 3, 2020
* Description:  This is the reverse assembler for the Motorola MC68000
*               Microprocessor created as a group project for CSS 422:
*               Hardware and Computer Organization at University of 
*               Washington Bothell taught by Professor Yang Peng.
*------------------------------------------------------------------------
CR          EQU         $0D
LF          EQU         $0A
DOLLAR      EQU         $24


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
            LEA         START_ADDRESS, A2   ; START_ADDRESS WILL TO BE ASSOCIATED WITH A2
            JSR         L_HEXTOASCII    ; CONVERTS HEX IN D3 TO ASCII INTO A2           
            LEA         START_ADDRESS, A2   ; SAVES START ADDRESS IN ASCII FORMAT
       
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
            LEA         END_ADDRESS, A2   ; START_ADDRESS WILL TO BE ASSOCIATED WITH A2
            JSR         L_HEXTOASCII    ; CONVERTS HEX IN D3 TO ASCII INTO A2 AND L_HEX2ASCII_RESULT                  
            LEA         END_ADDRESS, A2   ; SAVES END ADDRESS IN ASCII 
            
            ; TODO: PRINT $,ADDRESS INCREMENTED, OPCODE AND REGISTERS
           
*--- EXPECTED TO PRINT "$(ADDRESS)(TAB)(DECODED OPCODE)(TAB)(EAS IF APPLICABLE)(NEW LINE)(#0)----*
*--- RIGHT NOW PRINTS $ + START ADDRESS----*
PRINTDECODEDLINE
            CLR         (A6)            ; CLEAR CONTENTS OF A6 IN PREP (IN CASE STORED PREVIOUS LINE)
            MOVE.B      #DOLLAR,(A6)+  ; ADD $ AT THE BEGINNING OF THE LINE 
            
ADDADDRESSTOLINE
            ADDQ        #$8, D7          ; ADDRESS WILL ALWAYS NEED TO BE LONG, SO ADD 8 TO CHAR COUN
                      
ADDADDRESSLOOP           
            MOVE.B      (A2)+, (A6)+    ; CARRY OVER ONE CHAR AT A TIME FROM A4 TO A6
            BNE.S       ADDADDRESSLOOP   ; TEST FOR END OF STRING, CONTINUE IF NOT
                       
            MOVE.B      #0, (A6)        ; MUST HAVE 0 AT THE END OF THE STRING
 
            SUBQ        #$1,A6          ; GET BACK TO THE START OF A6 BY SUBBTRACTING THE $ CHAR
            SUB         #$9, A6         ; GET BACK TO THE START OF A6 BY SUBTRACTING THE LONG ADDRESS SPACE + NULL TERMINATOR
           
            LEA         (A6),A1         ; PRINT CONTENTS OF A6 
            MOVE.L      #13, D0
            TRAP        #15     

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
ENDADDR     DC.B        'Enter an ending address in hexadecimal: ',0
AGAINPROMPT DC.B        'Would you like to search again? (Y/N) ',0
USERRESPONSE    DC.B    '',0
START_ADDRESS   DS.L    1
END_ADDRESS     DS.L    1
* ======================== END ======================== *


            END         START
         






*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
