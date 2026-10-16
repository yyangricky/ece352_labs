	.file	"lab3_all.c"
	.option nopic
	.attribute arch, "rv32i2p0"
	.attribute unaligned_access, 0
	.attribute stack_align, 16
	.text
	.align	2
	.globl	putc
	.type	putc, @function
putc:
	lui	a5,%hi(uartp)
	lw	a4,%lo(uartp)(a5)
	li	a3,65536
.L2:
	lw	a5,4(a4)
	bltu	a5,a3,.L2
	sw	a0,0(a4)
	ret
	.size	putc, .-putc
	.align	2
	.globl	pbuff_insert
	.type	pbuff_insert, @function
pbuff_insert:
	lui	a5,%hi(pbuff_i)
	lw	a4,%lo(pbuff_i)(a5)
	li	a5,256
	beq	a4,a5,.L4
	addi	a3,a4,1
	lui	a5,%hi(pbuff_i)
	sw	a3,%lo(pbuff_i)(a5)
	lui	a5,%hi(.LANCHOR0)
	addi	a5,a5,%lo(.LANCHOR0)
	add	a5,a5,a4
	sb	a0,0(a5)
.L4:
	ret
	.size	pbuff_insert, .-pbuff_insert
	.align	2
	.globl	pbuff_print
	.type	pbuff_print, @function
pbuff_print:
	lui	a5,%hi(pbuff_i)
	lw	a5,%lo(pbuff_i)(a5)
	ble	a5,zero,.L11
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	lui	s1,%hi(.LANCHOR0)
	addi	s0,s1,%lo(.LANCHOR0)
	add	s0,s0,a5
	addi	s1,s1,%lo(.LANCHOR0)
	lui	s2,%hi(pbuff_i)
.L8:
	sub	a5,s0,s1
	addi	a5,a5,-1
	sw	a5,%lo(pbuff_i)(s2)
	lbu	a0,-1(s0)
	call	putc
	addi	s0,s0,-1
	bne	s0,s1,.L8
	lui	a5,%hi(pbuff_i)
	sw	zero,%lo(pbuff_i)(a5)
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L11:
	lui	a5,%hi(pbuff_i)
	sw	zero,%lo(pbuff_i)(a5)
	ret
	.size	pbuff_print, .-pbuff_print
	.align	2
	.globl	printOct
	.type	printOct, @function
printOct:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	mv	s0,a0
	li	a0,10
	call	pbuff_insert
	beq	s0,zero,.L20
.L15:
	andi	a0,s0,7
	srai	s0,s0,3
	addi	a0,a0,48
	call	pbuff_insert
	bne	s0,zero,.L15
.L16:
	call	pbuff_print
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
.L20:
	li	a0,48
	call	pbuff_insert
	j	.L16
	.size	printOct, .-printOct
	.align	2
	.globl	printHex
	.type	printHex, @function
printHex:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	mv	s0,a0
	li	a0,10
	call	pbuff_insert
	li	s1,9
	beq	s0,zero,.L29
.L22:
	andi	a0,s0,15
	srai	s0,s0,4
	sgt	a5,a0,s1
	neg	a5,a5
	andi	a5,a5,7
	addi	a5,a5,48
	add	a0,a5,a0
	call	pbuff_insert
	bne	s0,zero,.L22
.L23:
	li	a0,120
	call	pbuff_insert
	li	a0,48
	call	pbuff_insert
	call	pbuff_print
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	addi	sp,sp,16
	jr	ra
.L29:
	li	a0,48
	call	pbuff_insert
	j	.L23
	.size	printHex, .-printHex
	.align	2
	.globl	modulo10
	.type	modulo10, @function
modulo10:
	li	a5,9
	ble	a0,a5,.L31
.L32:
	addi	a0,a0,-10
	bgt	a0,a5,.L32
.L31:
	ret
	.size	modulo10, .-modulo10
	.align	2
	.globl	divide10
	.type	divide10, @function
divide10:
	mv	a5,a0
	li	a4,9
	ble	a0,a4,.L37
	li	a0,0
.L36:
	addi	a5,a5,-10
	addi	a0,a0,1
	bgt	a5,a4,.L36
	ret
.L37:
	li	a0,0
	ret
	.size	divide10, .-divide10
	.align	2
	.globl	printDec
	.type	printDec, @function
printDec:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	sw	s1,4(sp)
	sw	s2,0(sp)
	mv	s2,a0
	li	a0,10
	call	pbuff_insert
	li	s1,9
	bne	s2,zero,.L40
	li	a0,48
	call	pbuff_insert
.L41:
	call	pbuff_print
	lw	ra,12(sp)
	lw	s0,8(sp)
	lw	s1,4(sp)
	lw	s2,0(sp)
	addi	sp,sp,16
	jr	ra
.L42:
	addi	s0,s0,-10
	bgt	s0,s1,.L42
.L43:
	mv	a0,s2
	call	divide10
	mv	s2,a0
	addi	a0,s0,48
	call	pbuff_insert
	beq	s2,zero,.L41
.L40:
	mv	s0,s2
	bgt	s2,s1,.L42
	j	.L43
	.size	printDec, .-printDec
	.align	2
	.globl	checkRegisters1
	.type	checkRegisters1, @function
checkRegisters1:
 #APP
# 140 "lab3_all.c" 1
	la a0, regs
sw s0,0x0(a0)
sw s1,0x4(a0)
sw s2,0x8(a0)
sw s3,0xc(a0)
sw s4,0x10(a0)
sw s5,0x14(a0)
sw s6,0x18(a0)
sw s7,0x1c(a0)
sw s8,0x20(a0)
sw s9,0x24(a0)
sw s10,0x28(a0)
sw s11,0x2c(a0)
sw gp,0x30(a0)
sw tp,0x34(a0)
sw sp,0x38(a0)

# 0 "" 2
 #NO_APP
	ret
	.size	checkRegisters1, .-checkRegisters1
	.align	2
	.globl	checkRegisters2
	.type	checkRegisters2, @function
checkRegisters2:
 #APP
# 164 "lab3_all.c" 1
	li a2, 0
la a0, regs
lw a1, 0(a0)
beq a1, s0, s0Break
ori a2, a2, 0b1
s0Break:
lw a1, 4(a0)
beq a1, s1, s1Break
ori a2, a2, 0b10
s1Break:
lw a1, 8(a0)
beq a1, s2, s2Break
ori a2, a2, 0b100
s2Break:
lw a1, 12(a0)
beq a1, s3, s3Break
ori a2, a2, 0b1000
s3Break:
lw a1, 16(a0)
beq a1, s4, s4Break
ori a2, a2, 0b10000
s4Break:
lw a1, 20(a0)
beq a1, s5, s5Break
ori a2, a2, 0b100000
s5Break:
lw a1, 24(a0)
beq a1, s6, s6Break
ori a2, a2, 0b1000000
s6Break:
lw a1, 28(a0)
beq a1, s7, s7Break
ori a2, a2, 0b1000011
s7Break:
lw a1, 32(a0)
beq a1, s8, s8Break
ori a2, a2, 0b1000111
s8Break:
lw a1, 36(a0)
beq a1, s9, s9Break
ori a2, a2, 0b1001111
s9Break:
lw a1, 40(a0)
beq a1, s10, s10Break
ori a2, a2, 0b1011111
s10Break:
lw a1, 44(a0)
beq a1, s11, s11Break
ori a2, a2, 0b1111111
s11Break:
lw a1, 48(a0)
beq a1, gp, gpBreak
ori a2, a2, 0b1111111
gpBreak:
lw a1, 52(a0)
beq a1, tp, tpBreak
ori a2, a2, 0b1111111
tpBreak:
lw a1, 56(a0)
beq a1, sp, spBreak
ori a2, a2, 0b1111111
spBreak:
li a0, 0xff200000
sw a2, 0(a0)

# 0 "" 2
 #NO_APP
	ret
	.size	checkRegisters2, .-checkRegisters2
	.section	.rodata.str1.4,"aMS",@progbits,1
	.align	2
.LC0:
	.string	"DDDDDDDOOOOOOOHHHHHHH"
	.text
	.align	2
	.globl	main
	.type	main, @function
main:
	addi	sp,sp,-80
	sw	ra,76(sp)
	call	checkRegisters1
	li	a6,16
	sw	a6,52(sp)
	li	a0,15
	sw	a0,48(sp)
	li	a1,14
	sw	a1,44(sp)
	li	a2,13
	sw	a2,40(sp)
	li	a3,12
	sw	a3,36(sp)
	li	a4,11
	sw	a4,32(sp)
	li	a5,10
	sw	a5,28(sp)
	sw	a6,24(sp)
	sw	a0,20(sp)
	sw	a1,16(sp)
	sw	a2,12(sp)
	sw	a3,8(sp)
	sw	a4,4(sp)
	sw	a5,0(sp)
	li	a7,16
	li	a6,15
	li	a5,14
	li	a4,13
	li	a2,11
	li	a1,10
	lui	a0,%hi(.LC0)
	addi	a0,a0,%lo(.LC0)
	call	printn
	call	checkRegisters2
	li	a0,0
	lw	ra,76(sp)
	addi	sp,sp,80
	jr	ra
	.size	main, .-main
	.globl	regs
	.globl	uartp
	.bss
	.align	2
	.set	.LANCHOR0,. + 0
	.type	pbuff, @object
	.size	pbuff, 256
pbuff:
	.zero	256
	.type	regs, @object
	.size	regs, 64
regs:
	.zero	64
	.section	.sbss,"aw",@nobits
	.align	2
	.type	pbuff_i, @object
	.size	pbuff_i, 4
pbuff_i:
	.zero	4
	.section	.sdata,"aw"
	.align	2
	.type	uartp, @object
	.size	uartp, 4
uartp:
	.word	-14675968
	.ident	"GCC: (GNU) 12.1.0"
#######################
##### ENTRY POINT #####
#######################
	.text
	.align 2
	.global _start
_start:
	li sp, 0x10000
	call main
fever: j fever
#####################################
###### YOUR CODE GOES BELOW HERE ####
#####################################

	    .global printn
    .type printn, @function
printn:
    addi sp, sp, -48 # Allocate stack frame

	sw a7, 44(sp) # save first 7 numbers which are in a registers into the stack frame
	sw a6, 40(sp)
	sw a5, 36(sp)
	sw a4, 32(sp)
	sw a3, 28(sp)
	sw a2, 24(sp)
	sw a1, 20(sp)

    sw ra, 12(sp) # save return address
    sw s0, 8(sp) # save s registers
    sw s1, 4(sp)
	sw s2, 0(sp)

    mv s0, a0 # Store char in a0 to s0
    mv s1, zero # index tracker
	addi s2, sp, 20 # array pointer

    li t0, 0 # load characters for comparison
    li t1, 'D'
    li t2, 'H'
    li t3, 'O'

LOOP:
    add t4, s0, s1 # load current index for character
    lbu t5, 0(t4) # load current character

	beq t5, t0, END # check for null terminator, if so exit loop


	slli t6, s1, 2 # multiply index by 4 to get the correct offset for the number array
	add t6, s2, t6 # load current index for number
	lw a0, 0(t6) # load current number to a0 for function call

    
    beq t5, t1, DEC # check against each of the three cases
    beq t5, t2, HEX
    beq t5, t3, OCT

OCT:
    call printOct
    j AFTER

HEX:
    call printHex
    j AFTER

DEC:
    call printDec
    j AFTER

AFTER:
    addi s1, s1, 1 # increment index
    j LOOP

END:
    lw ra, 12(sp) # restore registers
    lw s0, 8(sp)
    lw s1, 4(sp)
    lw s2, 0(sp)
    addi sp, sp, 48 # deallocate stack frame
    ret

    .size printn, .-printn