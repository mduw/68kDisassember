*-----------------------------------------------------------
* Title      :  Subroutines for I/O
* Written by :  Mitchell, Julia
* Date       :  07/27/2020
* Description:  This file contains subroutines that support I/O process
*-----------------------------------------------------------

A2H_RESULT  EQU         $2000   ; OUTPUT'S ADDR FOR THE ASCII-TO-HEX CONVERSION



* ------------------ START OF SAMPLE FOR ASCII-TO-HEX CONVERSION (TO BE REMOVED ONCE COMPLETE)------------------*
* MOVE INPUT ADDRESS TO A1 BEFORE IMPLEMENTING THESE LINES
                       
*            JSR         ASCII2HEX       ; ASCII2HEX CONVERTS THE ANY VALUE AT A1 TO HEX (since task #2 store input at A1)
*            JSR         DISP            ; DISPLAY OUTPUT (OPTIONAL) FOR TESTING ONLY
*            MOVEA.L     #0,A1           ; RESET A1
*            MOVE.L      #0,D0           ; RESET D0
*            BRA         STADDR

* ------------------ END OF SAMPLE FOR ASCII-TO-HEX CONVERSION (TO BE REMOVED ONCE COMPLETE)------------------*



* ================== START OF SUBROUTINE TO CONVERT ASCII TO HEX ================== *
* NOTE FOR IMPLEMENTATION: 
*       1. Input's location is held by A2. 
*       2. Output's location is held by A3.
*       3. Length of the hex value is held by D1. (Input's location + Length = location of the last bit)
*
ASCII2HEX:  MOVE.L      A1,A2           ; COPY INPUT ADDR TO A2
            LEA         A2H_RESULT,A3   ; ADDR WHERE RESULT WILL BE STORED 
            JSR         A2HLOOP         ; START THE LOOP THAT CONVERT EACH STRING CHAR TO HEX
            LEA         A2H_RESULT,A3   ; ADDR WHERE RESULT WILL BE STORED        
            RTS  
                       
A2HLOOP     CLR.B       D2
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
            MOVE.B      D2,(A3)+        ; MOVE CONVERTED VALUE TO RESULT
            BRA         NEXT_CHAR 

D2H2        CMP.B       #$41,D2
            BLT         A2H_ERR         ; ERR IF $39 < D2 < $41 --> INVALID CHARACTERS
            SUB.B       #$37,D2         ; SUBTRACT $37 IF D2 IS IN [$41,$46] ~ ['A'-'Z']
            MOVE.B      D2,(A3)+        ; MOVE CONVERTED VALUE TO RESULT
            BRA         NEXT_CHAR             
     
NEXT_CHAR   BRA         A2HLOOP         ; CONTINUE CONVERTING  
EXIT_A2HL   RTS                         ; EXIT A2H LOOP
               
A2H_ERR     LEA         ERRMESS,A1      ; DISPLAY  ERR MESSAGE. CHARACTER NOT IN [1..9] AND [A,Z]
            *MOVE.B      #14,D0
            *TRAP        #15
            RTS
            
DISP        MOVE.B      (A3),D0 ; OUTPUT STRING IN HEX   
            MOVE.B      #13,D0
            TRAP        #15
            RTS

* ================== END OF SUBROUTINE TO CONVERT ASCII TO HEX ================== *


* ================== START OF SUBROUTINE TO CONVERT HEX TO ASCII ================== *   
* INSTUCTION: PUT VALUE IN HEX INTO D3 REGISTER AND IT WILL PROCESS IT TO ASCII 
* FINAL RESULT IN ASCII IS STORED IN A1 AND HEXTOASCII1   
* USES D4 FOR ITS COUNTER 
            MOVE.B      #$4, D4         ; 4 IS THE COUNTER SINCE WE OPERATE ON THE WORD                
                    
            LEA         ASCIIFROMHEX,A1 ; LOAD ADDRESS OF ASCIIFROMHEX TO A1
            MOVE.L      #$A2F2,D3       ; TEST VALUE OF $ACF2 IS USED 
            JSR         HEXTOASCII      ; JUMP TO SUBROUTINE THAT CONVERTS WORD IN HEX TO ASCII VALUE
        
HEXTOASCII: ROL.W       #4, D3          ; SHIFTS BITS TO LEFT AND ROTATES. FIRST BIT BECOMES LAST
            MOVE.W      D3,D2           ; STORE COPY AT D2 WHICH WILL HAVE BITS SHIFTED
            AND.L       #$0000000F,D2   ; UPDATE ADD BITS TO 0 EXCEPT FOR LAST ONE
            CMP.B       #9, D2          ; CHECK IF MORE THAN 9 
            BGT         ISLETTER
            
ISDIGIT     ADD.W       #$30,D2         ; IS A NUMBER, SO ADD #$30 PER ASCII TABLE
            BRA         NEXT
            
ISLETTER    ADD.W       #$37,D2
            BRA         NEXT            ; CONVERT THE LETTER TO ASCII LETTER             
            
NEXT        MOVE.B      D2, (A1)+
            SUBQ        #1, D4
            CMP.B       #0, D4
            BNE         HEXTOASCII  
            
            MOVE.B      #0, (A1)        ; ASCII IS COMPLETE. PLACES NULL AT THE END OF STRING.             
           ; RTS                        ; RETURN FROM SUBROUTINE
            
*------ TEST CASE 1 OF CONVERTING WORD TO ASCII ------*
            LEA         ASCIIFROMHEX, A1    ; WILL DISPLAY THE ASCII VALUE 
            MOVE.L      #13, D0
            TRAP        #15 
                        
* ================== END OF SUBROUTINE TO CONVERT HEX TO ASCII ================== * 



* ================== CONSTANTS GO HERE ================== *

ERRMESS         DC.B        'Error! Invalid address',CR,LF,0
ASCIIFROMHEX    DS.B        10 
DISP_D2H        DC.B        'String-type addr in hex: ',0







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
