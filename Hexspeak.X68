*------------------------------------------------------------------------
* Title      :  Hexspeak Disassembler
* Written by :  Taylor Eyler, Mitchell Dang, Julia Brosseau, Andrew Goupinets
* Date       :  July 28, 2020
* Description:  This is the reverse assembler for the Motorola MC68000
*               Microprocessor created as a group project for CSS 422:
*               Hardware and Computer Organization at University of 
*               Washington Bothell taught by Professor Yang Peng.
*------------------------------------------------------------------------
CR          EQU         $0D
LF          EQU         $0A



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
            ; TODO: STORE INPUT AND CONVERT ASCII TO HEX

EADDR       LEA         ENDADDR,A1      ; LOAD END PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT END PROMPT
            MOVEA.L     #0,A1

            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ END ADDRESS   

            ; TODO: ERROR HANDLING/INPUT VALIDATION
            ; TODO: STORE INPUT AND CONVERT ASCII TO HEX


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
            
            
RESETVALUES CLR.L   D0                  ; CLEAR ALL VALUES
            CLR.L   D1                  ; NOTE: IN THE FUTURE ANY ADDITIONAL REGISTERS
            CLR.L   D2                  ;       USED CAN BE CLEARED HERE TOO
            MOVE.L  #0,A1
            MOVE.L  #0,A2
            MOVE.L  #0,A3   
            JMP WELC                    ; GO BACK TO THE START     
            
* ================== INCLUDE MODULES ================== *
            INCLUDE     'IO_func.X68'

* ======================== END ======================== *

* ================= CONSTANTS GO HERE ================= *

WELCOME     DC.B        'Welcome to the Hexspeak disassembler.',CR,LF,0
STARTADDR   DC.B        'Enter a starting address in hexadecimal: ',0
ENDADDR     DC.B        'Enter an ending address in hexadecimal: ',0
AGAINPROMPT DC.B        'Would you like to search again? (Y/N) ',0
USERRESPONSE    DC.B    '',0
* ======================== END ======================== *


            END         START
         





*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
