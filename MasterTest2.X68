*-----------------------------------------------------------
* Title      : Master test 2
* Written by : Hexspeak
* Date       : Last update Aug. 18, 2020
* Description: Mixture of tests for various groups. More complicated than
*              MasterTest.X68 
*-----------------------------------------------------------
        ORG         $9000
;ADDR1 EQU       $5000
START:                  ; first instruction of program
        MOVE.L      $12345678,$87654321
        SUB.L       D1,A1
        MULS.W      $12,D7
        MULS.W      D2,D5
        SUB.W       #$2300,D5
        MOVEA.L    D0,A0
        move.l      d0,D0
        MOVEA.L    A0,A0
        MOVE.l      A0,D0
        MOVEA.L    (A0),A0
        move.l      (A0),D0
        MOVEA.L    (A0)+,A0
        move.l      (A0)+,D0
        MOVEA.L    -(A0),A0 
        move.l      -(A0),D0
        
        move.l      d1,d4
        NOT.B       D1
        divu.w      #$12,d1
        SUB.W       #$12,D0
        SUB.L       #$12,D0
        SUB.B       #$12,D0

        SUB.W       D0,D2
        divu.w      (A1),d2
        divu.w      #$1234,d3
        DIVU.W      $366,D4
        DIVU.W      -(A2),D4
        DIVU.W      (A2)+,D4
        DIVU.W      D7,D4

        ADDA.L        (A1)+,A2
        ADD.L       (A1)+,D1
        ;bra        label2 
        BLE         LABEL2
        BGE         LABEL2

        bgt.b      label2   
         bgt.w    label2
         
         bgt.b    label2
         MOVEM.W      A7-A2/D1-D2,$12345678
         MOVEM.W      D2,$135
         MOVEM.W      $135,A5-A7/D5-D6
         MOVEM.L    D6,(A1)
label2
         MOVEM.W     $12345678,A6
         MOVEM.L    A7-A2/D1-D7,(A2)

         MOVEM.L   D1-D7,-(A3) 
  
         MOVEM.W   A0/A0,-(A4)
         MOVEM.W   D7,(A4)
         bra        label2

         
         MOVEM.W   D7,-(A5)
         MOVEM.W   A0/A1,-(A6)
         MOVEM.W   A0/A2,-(A7)
*
*         
*         MOVEM.w   A0-A7,-(A1)
*         MOVEM.w   A1-A7,-(A1)
*         MOVEM.W   A2-A7,-(A1)
*         MOVEM.W   A3-A7,-(A1)
*         MOVEM.W   A4-A7,-(A1)
*         MOVEM.W   A5-A7,-(A1)
*         MOVEM.W   A6-A7,-(A1)
*         MOVEM.W   A7-A7,-(A1)
*         MOVEM.L   D0-D7,-(A1)

*         MOVEM.L   D1-D7,-(A1)
*         MOVEM.L   D2-D7,-(A1)
*         MOVEM.L   D3-D7,-(A1)
*         MOVEM.L   D4-D7,-(A1)
*         MOVEM.L   D5-D7,-(A1)
*         MOVEM.L   D6-D7,-(A1)
*         MOVEM.L   D7-D7,-(A1)
*         MOVEM.L   D0-D6,-(A1)
*         MOVEM.L   D0-D6,-(A1)
*         MOVEM.L   D0-D6,-(A1)
*         MOVEM.L   D0-D6,-(A1)
*         MOVEM.L   D0-D6,-(A1)
*         MOVEM.L   D0-D0,-(A1)
*         MOVEM.L   D0-D1,-(A1)
*         MOVEM.L   D0-D2,-(A1)
  

         
         MOVE.L     #$12345678,D7
         MOVE.L     D2,A6
         MOVE.L     D2,-(A2)
         MOVE.W     -(A3),A5
         
         MOVE.W     $1234,D1
         MOVE.B     $7,-(A2)
         MOVE.L     $12345678,D3
         MOVE.B     D3,D4
         MOVE.L     $12345678,(A3)
         

         


         MOVE.B     #14,D2
         ADD.L      #10,D5
       
         ADD.W      #10000,D6
         ADD.W      $900,D0
         SUB.L        #4,D0
         MOVE.L     #$12345678,D7
         MOVE.L     D2,A6
         MOVE.L     D2,-(A2)
         MOVE.W     -(A3),A5
         not        (a1)
         MOVE.W     $1234,D1
         MOVE.B     $7,-(A2)
         MOVE.L     $12345678,D3
         MOVE.B     D3,D4
         MOVE.L     $12345678,(A3)
         
        
        MOVE.B      #102,D6
        MOVE.B      #9,D5
        MOVE.L      #123455,D2
        MOVE.W      #$12EA,D6
        MOVE.W      $800,D0
        lea         $124,a1
        and.l       #$678,d2
        and.l       d2,$678
    
    MULS.W    $12,D7
    MULS.W    $1234,D1
    MULS.W    $12345678,D5
    MULS.W    #$1234,D1
    DIVU.W    $12,D1
    DIVU.W    $1234,D1
    DIVU.W    $12345678,D1
    DIVU.W    #$1234,D1

    MULS.W    D0,D1
    MULS.W    (A0),D1
    MULS.W    -(A0),D1
    MULS.W    (A0)+,D1
    MULS.W    #2,D7
    MULS.W    $2000,D6
    MULS.W    $12345678,D5
    DIVU.W    D0,D1
    DIVU.W    (A0),D1
    DIVU.W    -(A0),D1
    DIVU.W    (A0)+,D1   
    DIVU.W    $12,D1
    DIVU.W    #8,D2
    SUB.W     $9000,D0
    SUB.W     #2,(A2)
    DIVU.W    #2000,D3
    DIVU.W    $1234,D1
    DIVU.W    $12345678,D1
    DIVU.W    #$1234,D1
    DIVU.W    D0,D1
    DIVU.W    (A0),D1
    DIVU.W    -(A0),D1
    DIVU.W    (A0)+,D1
    SUB.B     D1,D2
    SUB.B     D1,(A1)
    SUB.B     D1,(A1)+
    SUB.B     D1,-(A1)
    SUB.B     (A1),D1
    SUB.B     (A1)+,D1
    SUB.B     -(A1),D1
    SUB.W     D1,D2
    SUB.W     D1,A1
    SUB.W     D1,(A1)
    SUB.W     D1,(A1)+
    SUB.W     D1,-(A1)
    SUB.W     A1,D1
    SUB.W     (A1),D1
    SUB.W     (A1)+,D1
    SUB.W     -(A1),D1
    SUB.L     D1,D2
    SUB.L     D1,A1
    SUB.L     D1,(A1)
    SUB.L     D1,(A1)+
    SUB.L     D1,-(A1)
    SUB.L     A1,D1
    SUB.L     (A1),D1
    SUB.L     (A1)+,D1
    SUB.L     -(A1),D1 

    ADD.B     D1,D2
    ADD.B     D1,(A1)
    ADD.B     D1,(A1)+
    ADD.B     D1,-(A1)
    ADD.B     (A1),D1
    ADD.B     (A1)+,D1
    ADD.B     -(A1),D1
    ADD.W     D1,D2
    ADD.W     D1,(A1)
    ADD.W     D1,(A1)+
    ADD.W     D1,-(A1)
    ADD.W     (A1),D1
    ADD.W     (A1)+,D1
    ADD.W     -(A1),D1
    ADD.L     D1,D2
    ADD.L     D1,(A1)
    ADD.L     D1,(A1)+
    ADD.L     D1,-(A1)
    ADD.L     (A1),D1
    ADD.L     (A1)+,D1
    ADD.L     -(A1),D1
    

         MOVE.B     #14,D2
         ADD.L      #10,D5
       
         ADD.W      #10000,D6
         ADD.W      $900,D0
         SUB.L        #4,D0
         MOVE.L     #$12345678,D7
         MOVE.L     D2,A6
         MOVE.L     D2,-(A2)
         MOVE.W     -(A3),A5
         
         MOVE.W     $1234,D1
         MOVE.B     $7,-(A2)
         MOVE.L     $12345678,D3
         MOVE.B     D3,D4
         MOVE.L     $12345678,(A3)
         
        
        MOVE.B      #102,D6
        MOVE.B      #9,D5
        MOVE.L      #123455,D2
        MOVE.W      #$12EA,D6
        MOVE.W      $800,D0
        ASL.W       (a1)
        ASL.W       $00000900

        LEA     (A0),A0
    LEA     (A5),A0
    LEA     (A7),A0
    LEA     (A0),A7
    LEA     (A5),A7
    LEA     (A7),A7

    LEA         $134,A6
    NOT.W       $1234
    LEA         $134,A6
    ADD.L       $123,D3
    ADD.B       D1,$123456
    MOVE.B      #2,D6
    ADD.L       D3,(A1)
    ADD.B       -(A1),D3
    ADD.L       D0,D3
    ADD.W       D5,D7
    ADD.B       (A7)+,D3
    ADD.W       D5,-(A6)
    ;MULS.W      #4,D0
    
    AND.L       D0, $900
    AND.B       #4,$4235
    AND.L       #4000000,$4235

    
    AND.L       (A0)+, D5
    AND.L       D0,(A4)
    AND.L       #$12345678,d0
    AND.B      #$89,D3
    AND.W      #$890,D5
    AND.W      -(A4),D2
    AND.L       #2,D6
    
    

    sub.b       #2,d0
    SUB.B      #$89,$900
    SUB.W      #$890,$9000
    SUB.L       #8,D5
    SUB.L     $9000,d2
    SUB.W     $90,A4
    SUB.W     $90,D5
    SUB.W     D5,$90
    SUB.W     D5,$90000
    SUB.W     A6,A7
  
    SUB.B     D1,D2
    SUB.B     D1,(A1)
    SUB.B     D1,(A1)+
    SUB.B     D1,-(A1)
    SUB.B     (A1),D1
    SUB.B     (A1)+,D1
    SUB.B     -(A1),D1
    SUB.W     D1,D2
    SUB.W     D1,A1
    SUB.W     D1,(A1)
    SUB.W     D1,(A1)+
    SUB.W     D1,-(A1)
    SUB.W     A1,D1
    SUB.W     (A1),D1
    SUB.W     (A1)+,D1
    SUB.W     -(A1),D1
    SUB.L     D1,D2
    SUB.L     D1,A1
    SUB.L     D1,(A1)
    SUB.L     D1,(A1)+
    SUB.L     D1,-(A1)
    SUB.L     A1,D1
    SUB.L     (A1),D1
    SUB.L     (A1)+,D1
    SUB.L     -(A1),D1 
    

        LEA         $1234,A0
        NOT         $9000
        LEA         $123,A6
        NOT         D2
        NOT         (A0)
        NOT         $1234567
        NOT         (A1)+
        NOT         -(A1)
        MOVE.B      #$2,D5
        MOVE.B     D0,D5
        MOVE.W     (A0),D2
        MOVE.L     (A1)+,(A2)+
        MOVE.L     -(A3),(A4)
         
        ASL.W     #$2,D0
        MOVE.W     #$234,D6
        MOVE.L     #$123A47,D7
        MOVE.L     D2,-(A5)
        jsr         Testjsr
        bra         next

Testjsr lea       $12,a0
        rts
        
next        MOVE.L     D2,-(A5)









         divu.w     #$A032,d0
         divu.w     $332,d0
         divu.w     $12345678,d0

         MOVE.L     #$80,D0
         ADD.L      #$40,D0
         ADD.L      #$40,D0

         
        
        MOVE.B      #102,D6
        MOVE.B      #9,D5
        MOVE.L      #123455,D2
        MOVE.W      #$12EA,D6
        MOVE.W      $800,D0
        ASL.W       (a1)
        ASL.W       $00000900

        MOVE.B      $9000,D7
        MOVE.B      D0,D1
        BRA         BRACMD
        LSL.B       #1,D0
        LSL.L       #7,D3
        MOVE.B      D2,D0
BRACMD  MOVE.W      (A0)+,D2
        MOVE.L      -(A0),D3
        BRA         BRACMD
        LEA         (A2),A1        
        LSL.L       #4,D2
        LSL.W       #6,D1
        ASL.B       #4,D5
        asl.w       -(a4)
        ASL.W       D6,D5
        lea         (A6),A4
        asl.w       (a4)
        asl.w       (a4)+

        ASL.L       #2,D4
        MOVE.L      D3,D7
        lsl.W       $8000
        LSL.W       (A7)
        asl.w       $1234567
        MOVE.W      (A0)+,D2
        MOVE.L      -(A0),D3
        LSL.W       (A7)+
        asl.w       $1234567

        
    

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source







































*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
