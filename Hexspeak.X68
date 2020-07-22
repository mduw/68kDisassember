*------------------------------------------------------------------------
* Title      :  Hexspeak Disassembler
* Written by :  Taylor Eyler, Mitchell Dang, Isabel Giang, Julia Brosseau
* Date       :  July 19, 2020
* Description:  This is the reverse assembler for the Motorola MC68000
*               Microprocessor created as a group project for CSS 422:
*               Hardware and Computer Organization at University of 
*               Washington Bothell taught by Professor Yang Peng.
*------------------------------------------------------------------------
CR          EQU         $0D
LF          EQU         $0A

START       ORG         $1000

* ----------------------- WELCOME SCREEN PROMPT ----------------------- *

            LEA         WELCOME,A1      ; LOAD WELCOME PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT WELCOME PROMPT
            
            LEA         STARTADDR,A1    ; LOAD START PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT START PROMPT
            
            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ START ADDRESS
            
            ; TODO: ERROR HANDLING/INPUT VALIDATION
            ; TODO: STORE INPUT AND CONVERT ASCII TO HEX

            LEA         ENDADDR,A1      ; LOAD END PROMPT
            MOVE.B      #14,D0          ; USING TRAP TASK #14
            TRAP        #15             ; OUTPUT END PROMPT

            MOVE.B      #2,D0           ; USING TRAP TASK #2
            TRAP        #15             ; READ END ADDRESS   

            ; TODO: ERROR HANDLING/INPUT VALIDATION
            ; TODO: STORE INPUT AND CONVERT ASCII TO HEX         
        
            MOVE.B      #9,D0           ; USING TRAP TASK #9
            TRAP        #15             ; HALT SIMULATOR
        
WELCOME     DC.B        'Welcome to the Hexspeak disassembler.',CR,LF,0
STARTADDR   DC.B        'Enter a starting address in hexadecimal: ',0
ENDADDR     DC.B        'Enter an ending address in hexadecimal: ',0

            END         START
         



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
