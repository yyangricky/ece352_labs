.global _start

.data
line_buffer:
    .fill 50, 1, 32          # 50 bytes, each initialized to ASCII space
game_over_str:
    .asciz "\nGAME OVER\n"
BIT_CODES:                   # 7-segment patterns for 0-F
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71
    .align 2
score:
    .word 0                  # raw score lives in memory (the ISR changes it)

.equ HEX_BASE1,      0xff200020
.equ HEX_BASE2,      0xff200030
# UART constants
.equ JTAG_UART_BASE, 0xff201000
.equ JTAG_UART_RR,   0
.equ JTAG_UART_TR,   0
.equ JTAG_UART_CSR,  4
# timer constants
.equ TIMER0_BASE,      0xFF202000
.equ TIMER0_STATUS,    0
.equ TIMER0_CONTROL,   4
.equ TIMER0_PERIODL,   8
.equ TIMER0_PERIODH,   12
.equ TICKSPERSEC,      100000000
.equ TICKSPERSECHIGH,  (TICKSPERSEC >> 16)
.equ TICKSPERSECLOW,   (TICKSPERSEC & 0x0000FFFF)

.text
.align 2

_start:
    li   sp, 0x20000
    jal  print_score # show initial score (before interrupts are on)

   # device side
    # UART: interrupt when characters are received (REI = bit 0 of CSR)
    li   a0, JTAG_UART_BASE
    li   a1, 0x1
    sw   a1, JTAG_UART_CSR(a0)

    # Timer: set period, then START + CONT + ITO
    li   a0, TIMER0_BASE
    li   a1, 0x8  # stop while configuring
    sw   a1, TIMER0_CONTROL(a0)
    li   a1, TICKSPERSECLOW
    sw   a1, TIMER0_PERIODL(a0)
    li   a1, TICKSPERSECHIGH
    sw   a1, TIMER0_PERIODH(a0)
    li   a1, 0x7   # bit2 START, bit1 CONT, bit0 ITO
    sw   a1, TIMER0_CONTROL(a0)

    # processor side
    la   a1, handler
    csrrw x0, mtvec, a1

    li   a1, 0x01010000 # IRQ24 (UART) | IRQ16 (timer)
    csrrs x0, mie, a1

    li   a1, 0x8  # MIE bit of mstatus
    csrrs x0, mstatus, a1

mloop:  # everything happens in the ISR
    j    mloop

game_over:   # entered from inside the trap: MIE stays 0,
    jal  print_game_over  # so no more interrupts fire
iloop:
    j    iloop

# Interrupt handler: saves every register it (or anything it
# calls) may change, restores them before mret.
    .align 2
handler:
    addi sp, sp, -48#save every register it or anything it calls uses
    sw   ra, 0(sp)
    sw   t0, 4(sp)
    sw   t1, 8(sp)
    sw   t2, 12(sp)
    sw   t3, 16(sp)
    sw   t4, 20(sp)
    sw   t5, 24(sp)
    sw   t6, 28(sp)
    sw   a0, 32(sp)
    sw   a1, 36(sp)
    sw   a2, 40(sp)
    sw   a5, 44(sp)

    csrr t0, mcause#check mcause, which contains which device caused the interrupt
    li   t1, 0x80000010 # interrupt bit + IRQ16 = timer. 0x10 = 16
    beq  t0, t1, timer_isr
    li   t1, 0x80000018 # interrupt bit + IRQ24 = UART. 0x18 = 24
    beq  t0, t1, uart_isr
    j    handler_exit

timer_isr:#if the timer caused the interupt
    li   t0, TIMER0_BASE
    sw   x0, TIMER0_STATUS(t0) # clear TO, or it re-fires forever
    jal  scroll # returns old leftmost char in a0
    li   t0, 32
    bne  a0, t0, game_over # if a0 is not a space, game over
    jal  print_line#displays new configuration
    la   t0, score  # score += 1
    lw   t1, 0(t0)
    addi t1, t1, 1
    sw   t1, 0(t0)
    jal  print_score#displays score
    j    handler_exit

uart_isr:
    li   t0, JTAG_UART_BASE
    lw   t1, JTAG_UART_RR(t0) # reading pops the FIFO and drops the request
    srli t2, t1, 15
    andi t2, t2, 1 # RVALID bit
    beqz t2, handler_exit #if no byte is recieved than exit the handler
    andi a0, t1, 0xff  # a0 = received ASCII char
    jal  clear_number 
    jal  print_line
    j    handler_exit

handler_exit:
    lw   ra, 0(sp)#restore every register from the stack
    lw   t0, 4(sp)
    lw   t1, 8(sp)
    lw   t2, 12(sp)
    lw   t3, 16(sp)
    lw   t4, 20(sp)
    lw   t5, 24(sp)
    lw   t6, 28(sp)
    lw   a0, 32(sp)
    lw   a1, 36(sp)
    lw   a2, 40(sp)
    lw   a5, 44(sp)
    addi sp, sp, 48
    mret

# clear_number: a0 = ASCII char; replace every match with space
clear_number:
    la   t0, line_buffer#load line_buffer
    addi t1, t0, 50#t1 points to the end of line_buffer
    li   t2, 32#whitespace
clear_loop:
    beq  t0, t1, clear_done
    lbu  t3, 0(t0)#read byte
    bne  t3, a0, next_char#if its not the desired charactor, skip to the next
    sb   t2, 0(t0)#overwrite the byte with whitespace
next_char:
    addi t0, t0, 1
    j    clear_loop
clear_done:
    ret


# scroll: shift line left by one, append random ASCII digit.
# Returns a0 = the char that was at index 0 before the shift.
scroll:
    addi sp, sp, -4#store return address as we need to call myrandom to generate random
    sw   ra, 0(sp)
    jal  myrandom#a0 is now a rando num from 0-9
    addi a2, a0, 48              # 0-9 -> '0'-'9'
    la   t0, line_buffer
    lbu  a0, 0(t0) # old leftmost char (return value)
    addi t1, t0, 49#end of line_buffer (second last char)
shift_loop:
    beq  t0, t1, shift_end
    lbu  t2, 1(t0)#take the byte to the right and
    sb   t2, 0(t0)#place it to the current byte
    addi t0, t0, 1#loop'em!
    j    shift_loop
shift_end:
    sb   a2, 0(t0)#random value to the end. note that t0 is now the end
    lw   ra, 0(sp)#restore ra
    addi sp, sp, 4
    ret


putchar: # putchar: a0 = char to send (waits for FIFO space). Leaf.
    li   t5, JTAG_UART_BASE
putchar_wait:
    lw   t6, JTAG_UART_CSR(t5) #read csr
    srli t6, t6, 16 # keep only the upper 16 bits
    beqz t6, putchar_wait #as long as the upper 16 bits are zero (no space available) keep trying
    sb   a0, JTAG_UART_TR(t5) #write a0 into tr register
    ret


# print_line: print the 50 chars followed by '\r'
print_line:
    addi sp, sp, -4
    sw   ra, 0(sp)#store ra as we need to call putchar
    la   t0, line_buffer
    addi t1, t0, 50#last byte (end of buffer)
pl_loop:
    beq  t0, t1, pl_done
    lbu  a0, 0(t0)
    jal  putchar#prints that char
    addi t0, t0, 1
    j    pl_loop
pl_done:
    li   a0, 13#'\r' charactor
    jal  putchar
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

print_game_over:
    li   t0, JTAG_UART_BASE
    la   t1, game_over_str
print_loop:
    lbu  t2, 0(t1)
    beqz t2, print_done
wait_uart_tx:
    lw   t3, 4(t0)
    srli t3, t3, 16
    beqz t3, wait_uart_tx
    sb   t2, 0(t0)
    addi t1, t1, 1
    j    print_loop
print_done:
    ret

# myrandom (provided): returns a0 in 0..9. Clobbers a5.
    .globl myrandom
myrandom:
    li   a5, -14671872
    lw   a0, 256(a5)
    srai a5, a0, 8
    andi a5, a5, 255
    xor  a0, a5, a0
    li   a5, 10
    remu a0, a0, a5
    ret


# HEX_DISP: a0 low 4 bits = digit (bit 4 set = blank),
#           a1 = display number 0-5. Returns a0 = pattern.

HEX_DISP:
    addi sp, sp, -16
    sw   s0, 0(sp)
    sw   s1, 4(sp)
    sw   s2, 8(sp)
    sw   s3, 12(sp)

    la   s0, BIT_CODES
    andi s1, a0, 0x10
    beq  s1, zero, not_blank
    mv   s2, zero
    j    DO_DISP
not_blank:
    andi a0, a0, 0x0f
    add  a0, a0, s0
    lb   s2, 0(a0)
DO_DISP:
    la   s0, HEX_BASE1
    li   s1, 4
    blt  a1, s1, FIRST_SET
    sub  a1, a1, s1
    addi s0, s0, 0x10
FIRST_SET:
    slli a1, a1, 3
    addi s3, zero, 0xff
    sll  s3, s3, a1
    li   a0, -1
    xor  s3, s3, a0
    sll  a0, s2, a1
    lw   a1, 0(s0)
    and  a1, a1, s3
    or   a1, a1, a0
    sw   a1, 0(s0)
END:
    mv   a0, s2
    lw   s0, 0(sp)
    lw   s1, 4(sp)
    lw   s2, 8(sp)
    lw   s3, 12(sp)
    addi sp, sp, 16
    ret


# print_score: shows score / 100 in decimal on HEX5..HEX0.
# Leading zeros blanked (HEX0 always shows a digit).
# Clobbers t0-t4, a0, a1.

print_score:
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, score
    lw   t0, 0(t0)               # raw score from memory
    li   t1, 100
    divu t1, t0, t1              # t1 = raw score / 100
    li   t2, 0                   # display index, 0 = rightmost
    li   t3, 10
    li   t4, 6
ps_loop:
    remu a0, t1, t3
    divu t1, t1, t3
    bnez t1, ps_show
    bnez a0, ps_show
    beqz t2, ps_show
    li   a0, 0x10                # leading zero -> blank
ps_show:
    mv   a1, t2
    jal  HEX_DISP
    addi t2, t2, 1
    blt  t2, t4, ps_loop
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret