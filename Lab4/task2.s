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
_start:
	li sp, 0x10000
##########################################
# ADD YOUR CODE STARTING FROM HERE ###########################################	

    addi sp, sp, -16 # allocate space for 4 registers
    sw ra, 12(sp)
    sw a0, 0(sp)
LOOP:
    li a0, 0xfab
    call HEXDISPLAY

    li a0, 2
    call waithalfasec

    li a0, 0xbad
    call HEXDISPLAY

    li a0, 2
    call waithalfasec

    j LOOP

