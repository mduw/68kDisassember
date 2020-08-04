*-----------------------------------------------------------
* Title      : Hex-to-binary conversion subroutine
* Written by : Mitchell Dang
* Date       : 8/1/2020
* Description: This subroutine is part of opcode decoding
*-----------------------------------------------------------

HEX2BIN_RSLT  EQU     $2000

*    ORG    $1000 			; uncomment for debugging
*START:      				; uncomment for debugging

*=========  START OF TEST FOR HEX2BIN (TO BE REMOVED) =========*   
            ; convert every 2 hex bits. Each bit in hex = 4 bits in binary         
*            MOVE.L  #$1100,A3
*            MOVE.W  #$13B2,(A3)
*            LEA     HEX2BIN_RSLT,A2     ; addr where output is located
            
*            MOVE.B  (A3)+,D2            ; convert every 2 hex bits.           
*            JSR     HEX2BIN             ; convert to binary
*            MOVE.B  (A3)+,D2
*            JSR     HEX2BIN
*            BRA     DONE                ; finish
*=========  END OF TEST FOR HEX2BIN =========*   

*=========  START OF SUBROUTINE FOR HEX2BIN  =========*   
* Note for implementation:
*   1. Input:  move data to D2
*   2. Output: located at given addr.
*
*
*   EXTRA DOCUMENTATION:
*               MOVE.L      #$1100,A3       ; ADDRESS WHERE CONVERSION TAKES PLACE
*               MOVE.L      D2,(A3)         ; MOVE REGISTER VALUE INTO A3 ADDRESS
*               MOVEA.L     #$2000,A2       ; WHERE CONVERSION WILL SAVE TO
*               JSR         HEX2BIN         ; CONVERTS TWO VALUES OF HEX INTO EIGHT BINARY BITS
*               MOVE.L      $2000,D2        ; MOVES CONVERTED VALUE INTO D2
*
*           Make sure you include similar logic prior to entering into HEX2BIN

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
          
    
*DONE        SIMHALT             ; uncomment for debugging if needed


      	     *END    START        ; uncomment for debugging if needed
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
