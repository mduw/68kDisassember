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

            ; TODO: PROMPT FOR ADDITIONAL SEARCH, LOOP TO START IF YES         
        

* ------------------ SUBROUTINE TO CONVERT HEX TO ASCII --------------- *    
* INSTUCTION: PUT VALUE IN HEX INTO D3 REGISTER AND IT WILL PROCESS IT TO ASCII 
* FINAL RESULT IN ASCII IS STORED IN A1 AND HEXTOASCII1   
* USES D4 FOR ITS COUNTER 
            MOVE.B  #$4, D4             ; 4 IS THE COUNTER SINCE WE OPERATE ON THE WORD                
                    
            LEA     ASCIIFROMHEX,A1     ; LOAD ADDRESS OF ASCIIFROMHEX TO A1
            MOVE.L  #$A2F2,D3           ; TEST VALUE OF $ACF2 IS USED 
            JSR     HEXTOASCII          ; JUMP TO SUBROUTINE THAT CONVERTS WORD IN HEX TO ASCII VALUE
        
HEXTOASCII  ROL.W   #4, D3              ; SHIFTS BITS TO LEFT AND ROTATES. FIRST BIT BECOMES LAST
            MOVE.W  D3,D2               ; STORE COPY AT D2 WHICH WILL HAVE BITS SHIFTED
            AND.L   #$0000000F,D2       ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST ONE
            CMP.B   #9, D2              ; CHECK IF MORE THAN 9 
            BGT     ISLETTER
            
ISDIGIT     ADD.W   #$30,D2             ; IS A NUMBER, SO ADD #$30 PER ASCII TABLE
            BRA     NEXT
            
ISLETTER    ADD.W   #$37,D2
            BRA     NEXT                ; CONVERT THE LETTER TO ASCII LETTER             
            
NEXT        MOVE.B  D2, (A1)+
            SUBQ    #1, D4
            CMP.B   #0, D4
            BNE     HEXTOASCII  
            
            MOVE.B  #0, (A1)            ; ASCII IS COMPLETE. PLACES NULL AT THE END OF STRING.             
           ; RTS                        ; RETURN FROM SUBROUTINE
            
            *------ TEST CASE 1 OF CONVERTING WORD TO ASCII ------*
            LEA     ASCIIFROMHEX, A1    ; WILL DISPLAY THE ASCII VALUE 
            MOVE.L  #13, D0
            TRAP    #15 
            
* ----------- END OF SUBROUTINE TO CONVERT HEX TO ASCII --------------- * 

            MOVE.B      #9,D0           ; USING TRAP TASK #9
            TRAP        #15             ; HALT SIMULATOR

ASCIIFROMHEX    DS.B        10

        
WELCOME         DC.B        'Welcome to the Hexspeak disassembler.',CR,LF,0
STARTADDR       DC.B        'Enter a starting address in hexadecimal: ',0
ENDADDR         DC.B        'Enter an ending address in hexadecimal: ',0

            END         START
         

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
