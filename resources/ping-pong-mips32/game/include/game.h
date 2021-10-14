#ifndef GAME_H
#define GAME_H

#define SPVR_STACK_INIT 0x807E0000
#define GAME_STACK_INIT 0x807F0000
#define SEG7            0xBFAFF010
#define SWITCH          0xBFD0F020
#define BUTTON          0xBFD0F028
#define UART0           0xBFE40000
#define UART1           0xBFE40010

#define KB_UP     0xFFFFFFCB
#define KB_DOWN   0xFFFFFFCF
#define KB_PAUSE  0xFFFFFFD3
#define KB_RESUME 0xFFFFFFD7
#define KB_SCORE  0xFFFFFFEB
#define KB_RESET  0xFFFFFFF3

#define fps       60

#define x_sp0     3         // 2s
#define x_sp1     5
#define x_sp2     6         // 4s
#define x_sp3     7
#define x_sp4     8
#define x_sp5     9         // 6s
#define x_sp6     10
#define x_sp7     12        // 8s

#define y_sp0     -1
#define y_sp1     10        // 2s
#define y_sp2     15
#define y_sp3     20        // 4s
#define y_sp4     25
#define y_sp5     30        // 6s
#define y_sp6     35
#define y_sp7     40        // 8s

#define WIDTH     81
#define HEIGHT    25
#define center_x  40
#define center_y  13

#define player1_x 5
#define player2_x (WIDTH - player1_x + 1)

#define random    $15
#define player1_y $16
#define player2_y $17
#define ball_x    $18
#define ball_y    $19
#define ball_cntx $20
#define ball_cnty $21
#define ball_spx  $22
#define ball_spy  $23
#define ball_dx   $24
#define ball_dy   $25

#endif
