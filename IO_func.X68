*-----------------------------------------------------------
* Title      :  Subroutines for I/O : ASCII to HEX, HEX (WORD) to ASCII, and HEX (LONG) to ASCII
* Written by :  Mitchell, Julia
* Date       :  07/28/2020 - 08/02/2020
* Description:  This file contains subroutines that support I/O process
*-----------------------------------------------------------



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



* ================== START OF SUBROUTINE TO CONVERT LONG HEX TO ASCII ================== * 
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


* ================== START OF SUBROUTINE TO CONVERT WORD HEX TO ASCII ================== * 
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


* ================== CONSTANTS GO HERE ================== *

ERRMESS         DC.B        'Error! Invalid address',CR,LF,0
DISP_D2H        DC.B        'String-type addr in hex: ',0









*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
