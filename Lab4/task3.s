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


_start:
	li sp, 0x10000
##########################################
# ADD YOUR CODE STARTING FROM HERE ###########################################	



.globl main

main: 

    li s0, 1 # index up until 5

    

    li s2, 5 

    MAIN_LOOP:
    beq s0, s2, END_LOOP # if s0 == 5, exit loop

    la a0, seq_in # pointer to seq_in
    mv a1, s0 # seq_n

    call SimonGenerate 

    li s1, 0 # index up to seq_n

    DISPLAY_LOOP:
    beq s1, s0, END_DISPLAY_LOOP # if s1 == seq_n, exit loop

    la t3, seq_in # pointer to seq_in
    add t3, t3, s1
    lbu a0, 0(t3) # load current number to a0 for function call
    call HEXDISPLAY

    li a0, 1
    call waithalfasec # wait for half a second

    addi s1, s1, 1 # increment index s1
    j DISPLAY_LOOP

    END_DISPLAY_LOOP:
    addi s0, s0, 1 # increment index s0 for next loop

    j MAIN_LOOP

END_LOOP:

	j END_LOOP

