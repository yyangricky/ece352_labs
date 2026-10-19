.equ PIT_buttons, 0xff200050
.equ PIT_LEDs, 0xff200000


.text
	.align	2
	.globl	myrandom
myrandom:
	li	a5,-14671872
	lw	a0,256(a5)
	srai	a5,a0,8
	andi	a5,a5,255
	xor	a0,a5,a0
	ret
	.globl	waithalfasec
waithalfasec:
	slli	a5,a0,1
	add	a5,a5,a0
	slli	a5,a5,6
	sub	a5,a5,a0
	slli	a5,a5,2
	sub	a5,a5,a0
	slli	a5,a5,4
	sub	a5,a5,a0
	slli	a5,a5,5
	add	a5,a5,a0
	slli	a5,a5,7
	li	a4,-14671872
	li	a3,8
	sw	a3,4(a4)
	sw	zero,0(a4)
	li	a3,65536
	addi	a3,a3,-1
	and	a3,a5,a3
	sw	a3,8(a4)
	srli	a5,a5,16
	sw	a5,12(a4)
	li	a5,4
	sw	a5,4(a4)
.L3:
	lw	a5,0(a4)
	andi	a5,a5,1
	beq	a5,zero,.L3
	li	a5,-14671872
	sw	zero,0(a5)
	ret
.data
	.align	2
seq_in:
    .space	11 # 11 consecutive bytes
hexseg7:
	.ascii	"?\006[Ofm}\007\177gw|9^yq"
.text
	.align 2
	.globl	HEXDISPLAY
HEXDISPLAY:
	lui	a4,%hi(hexseg7)
	addi	a4,a4,%lo(hexseg7)
	srli	a5,a0,8
	add	a5,a4,a5
	lbu	a5,0(a5)
	slli	a5,a5,16
	andi	a3,a0,15
	add	a3,a4,a3
	lbu	a3,0(a3)
	or	a5,a5,a3
	srli	a0,a0,4
	andi	a0,a0,15
	add	a4,a4,a0
	lbu	a4,0(a4)
	slli	a4,a4,8
	or	a5,a5,a4
	li	a4,-14680064
	sw	a5,32(a4)
	ret

	.global _start

SimonGenerate:

    addi sp, sp, -16
    sw ra, 12(sp) # save return address


    mv t0, a0 # pointer to start of string seq_in
    mv t1, a1 # number seq_n

    li t2, 0 # index i

    SIMON_GENERATE_LOOP:
    beq t2, t1, SIMON_GENERATE_END # if i == seq_n, exit loop
    call myrandom # generate random number
    andi t3, a0, 3 # get random number between 0 and 3

    sb t3, 0(t0)
    addi t0, t0, 1 # increment pointer
    addi t2, t2, 1 # increment index i

    
    j SIMON_GENERATE_LOOP

    SIMON_GENERATE_END:

    lw ra, 12(sp) # restore return address
    addi sp, sp, 16 # deallocate stack frame

    ret


WaitForButton:
    li t0, PIT_buttons # address of buttons

    li t1, 0xf
    sw t1, 12(t0) # clear the EDGE register before polling

    POLL_LOOP:
        lw t1, 12(t0) # read EDGE register
        andi t1, t1, 0xf # isolate lower 4 bits

        beqz t1, POLL_LOOP # if no button pressed, keep polling

        sw t1, 12(t0) # clear the EDGE register by writing back the value

        srl t1, t1, a0 # shift right by button number
        andi a0, t1, 1 # isolate the bit for the button and save to a0 for return

        ret

SimonMain: # a0 = seq_in, a1 = seq_n


    addi sp, sp, -16
    sw ra, 12(sp) # save return address
    sw s0, 8(sp) # save s registers
    sw s1, 4(sp)
    sw s2, 0(sp)

    mv s0, a0 # pointer to seq_in
    mv s1, a1 # number seq_n
    li s2, 0 # index
    

    LED_LOOP:
    beq s2, s1, LED_LOOP_END # if index == seq_n, exit loop
    add t3, s0, s2 # load current address for character
    lbu t4, 0(t3) # load current number to t4 

    li t5, PIT_LEDs # address of LEDs
    li t6, 1
    sll t4, t6, t4 # turn sequence value 0-3 into a one-hot LED
    sw t4, 0(t5) # output to LEDs

    li a0, 2
    call waithalfasec # wait for 1 second

    addi s2, s2, 1 # increment index
    j LED_LOOP

    LED_LOOP_END:
    li t4, 0
    li t5, PIT_LEDs # address of LEDs
    sw t4, 0(t5) # turn off LEDs
    li s2, 0 # reset index

    BUTTON_LOOP:
    beq s2, s1, SUCCESS # if index == seq_n, exit loop
    add t3, s0, s2 # load current address for character
    lbu a0, 0(t3) # load current number to a0

    call WaitForButton # wait for button press
    beqz a0, FAIL

    addi s2, s2, 1 # increment index
    j BUTTON_LOOP

    FAIL:
    li a0, 0xBAD
    call HEXDISPLAY # display BAD on HEX display for game over

    call scream

    li a0, 6
    call waithalfasec # wait for 3 seconds

    li a0, 0 # return 0 for failure
    j SIMON_MAIN_END

    SUCCESS:
    li a0, 0xFAB
    call HEXDISPLAY # display FAB on HEX display for successful round

    call moo

    li a0, 6
    call waithalfasec # wait for 3 seconds

    li a0, 1 # return 1 for success
    j SIMON_MAIN_END

    SIMON_MAIN_END:
    lw ra, 12(sp) # restore return address
    lw s0, 8(sp) # restore s registers
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 16 # deallocate stack frame

    ret



_start:
	li sp, 0x10000
##########################################
# ADD YOUR CODE STARTING FROM HERE ###########################################	



.globl main

main: 

    
    li s0, 1 # index up until 10
    li s2, 10 # victory condition

    MAIN_LOOP:
    beq s0, s2, END # if s0 == 10, exit loop

    la a0, seq_in # pointer to seq_in
    mv a1, s0 # seq_n
    call SimonGenerate 

    mv a0, s0 # store seq_n in a0 for display
    call HEXDISPLAY # display current seq_n


    la a0, seq_in # pointer to seq_in
    mv a1, s0 # seq_n
    call SimonMain # play the game

    beqz a0, main # if return value is 0, game failed, restart the game

    addi s0, s0, 1 # increment index s0 for next round
    j MAIN_LOOP

END:
    li a0, 0xFABFAB
    call HEXDISPLAY # display FABFAB on HEX display for victory

    call moo

    li a0, 2
    call waithalfasec # wait for 1 seconds

    call moo

    li a0, 2
    call waithalfasec # wait for 1 seconds

    call moo

    li a0, 2
    call waithalfasec # wait for 1 seconds

    call moo

    li a0, 2
    call waithalfasec # wait for 1 seconds

    call moo

    li a0, 2
    call waithalfasec # wait for 1 seconds

    j main # restart the game after victory

