*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:                  ; first instruction of program

* Put program code here
    ;NOP
    ;NOP
    ;NOP
    
    ;NOT.B   D1
    ;NOT.W   -(A2)
    ;NOT.L   (A7)+

    ;LEA     (A1),A2
    ;LEA     (A3),A4
    
    ;JSR     (A2)
    
    ;MULS.W      D7,D3
    ;MULS.W      (A5)+,D4
    
    ;AND.L   D1,D2
    ;AND.L   D1,-(A2)
    ;AND.W   -(A2),D3
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
