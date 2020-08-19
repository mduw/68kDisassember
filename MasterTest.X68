*-----------------------------------------------------------
* Title      : Master test
* Written by : Hexspeak
* Date       : Last update Aug. 18, 2020
* Description: Extra  tests for program
*-----------------------------------------------------------
    ORG    $9000
START:                  ; first instruction of program

* Put program code here
    NOP
    NOP
    NOP
    
    NOT.B   D1
    NOT.W   -(A2)
    NOT.L   (A7)+

    LEA     (A1),A2
    LEA     (A3),A4
    
    JSR     (A2)
    
    MULS.W      D7,D3
    MULS.W      (A5)+,D4
    
    AND.L   D1,D2
    AND.L   D1,-(A2)
    AND.W   -(A2),D3
    
    SUB.L   D1,D2
    SUB.W   (A2),D5
    
    ADD.L   D2,D3
    ADD.W   (A2),D4
    
    BEQ     TESTLABEL
    BGT     TESTLABEL
    
    RTS
    
    ; invalid
    BCHG.L    D1,D3
    BCLR.L    D1,D2
    
    
TESTLABEL
    
    
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
