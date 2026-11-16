

.data
LINE_BUF: .space 50 # Reserves 50 consecutive bytes in RAM for the scrolling line
GAME_OVER: .asciz "\r\nGAME OVER\r\n"


.equ TIMER_BASE, 0xff202000
.equ ONE_SEC, 100000000 # 100 MHz clock -> 100,000,000 ticks = 1 sec

.equ JTAG_BASE, 0xFF201000

.text
	.align	2
	.globl	myrandom

.global _start
_start:

# initialize peripherals
init_timer:
    li t0, TIMER_BASE
    sw zero, 0(t0) # clear existing TO flags
    li t1, ONE_SEC
    li t3, 0xFFFF # mask for lower 16 bits
    and t2, t1, t3 # lower 16 bits
    sw t2, 8(t0) # set lower 16 bits of timer
    srli t1, t1, 16 # shift to get upper 16 bits
    sw t1, 12(t0) # set upper 16 bits of timer

    li t2, 0x6 # enable timer, continuous mode
    sw t2, 4(t0) # write control register to start countdown

    li t0, 0 # index counter
    li t1, 50 # buffer length
    li t2, 0x20 # ASCII for space

# fill buffer initially with spaces
init_buf_loop:
    beq t0, t1, poll_loop # done initializing buffer
    la t3, LINE_BUF
    add t3, t3, t0 # pointer to current byte
    sb t2, 0(t3) # fill with space
    addi t0, t0, 1
    j init_buf_loop

poll_loop:
    # check for key pressed
    li t0, JTAG_BASE
    lw t1, 0(t0) # read status register
    li t3, 0x8000 # mask for bit 15 (RVALID)
    and t2, t1, t3 # check bit 15 for key pressed
    beq t2, zero, check_timeout # if no key pressed, check for timeout
    
    andi t3, t1, 0xFF # lower 8 bits for ASCII 


    li t4, 0
    li t5, 50

# go through buffer to eliminate characters that are the same
char_elim_loop:
    beq t4, t5, done_elim # if t4 == 50, done eliminating
    la t6, LINE_BUF
    add t6, t6, t4 # pointer to current character
    lbu t0, 0(t6)
    bne t0, t3, next_char # if current character not pressed, skip to next character
    li t2, 0x20
    sb t2, 0(t6) # replace with space if same character

next_char:
    addi t4, t4, 1
    j char_elim_loop

done_elim:
    call print_line # update terminal after removing characters

# check for 1 second timeout
check_timeout:
    li t0, TIMER_BASE
    lw t1, 0(t0) # read status register
    andi t1, t1, 0x1 # check TO flag by isolating bit 0
    beq t1, zero, poll_loop # if TO flag is not set, keep polling

    # If timeout occurs
    sw zero, 0(t0) # clear TO flag
    la t1, LINE_BUF
    lbu t0, 0(t1) # load first character of buffer
    li t2, 0x20
    bne t0, t2, game_over

    li t2, 0 # shift index
    li t3, 49 # stop at index 48

# shift the whole buffer left by one character
shift_loop:
    beq t2, t3, gen_char # done shifting all 49 bytes left
    add t4, t1, t2 # pointer to LINE_BUF[i]
    lbu t5, 1(t4) # load LINE_BUF[i + 1]
    sb t5, 0(t4) # store into LINE_BUF[i]
    addi t2, t2, 1
    j shift_loop


# generate the new character to be added to the end of the buffer
gen_char:
    call myrandom
    andi a0, a0, 0xF # get range from 0 to 15
    li t0, 10
    remu a0, a0, t0 # if a0 >= 10, take remainder 
    addi a0, a0, 48 # convert to ASCII for 0-9

    la t1, LINE_BUF
    sb a0, 49(t1) # save new character at the end of the buffer
    call print_line # display updated scrolling line

    j poll_loop # repeat the polling loop

# mechanism to print "GAME OVER"
game_over:
    li t0, 0x8
    li t1, TIMER_BASE
    sw t0, 4(t1) # stop timer by writing 1 to bit 3 (STOP)

    li t0, JTAG_BASE
    la t1, GAME_OVER # Pointer to "\r\nGAME OVER\r\n"

print_go_loop:
    lbu t2, 0(t1) # Load next character
    beq t2, zero, end_game # Stop at null terminator ('\0')

wait_jtag_go:
    lw t3, 4(t0) # Read JTAG Control register (offset 0x4)
    srli t3, t3, 16 # Upper 16 bits = available write FIFO space (WSPACE)
    beq t3, zero, wait_jtag_go # Wait until space > 0

    sw t2, 0(t0) # Write character to JTAG Data register (offset 0x0)
    addi t1, t1, 1 # Advance string pointer
    j print_go_loop

end_game:
    j end_game # Stop the game cleanly


# print_line subroutine to print the current contents of LINE_BUF
print_line:
    li t0, JTAG_BASE

# 0x0D is \r, carriage return. This will overwrite the current line in the terminal
wait_cr:
    lw t1, 4(t0) # read JTAG control register
    srli t1, t1, 16 # check available write space
    beq t1, zero, wait_cr
    li t2, 0x0D # carriage return to overwrite line in place
    sw t2, 0(t0)

    li t3, 0 # character index
    li t4, 50 # buffer length

print_buf_loop:
    beq t3, t4, done_print # finished printing 50 characters
    la t5, LINE_BUF
    add t5, t5, t3 # pointer to current character
    lbu t2, 0(t5)

wait_char:
    lw t1, 4(t0) # read JTAG control register
    srli t1, t1, 16 # check available write space
    beq t1, zero, wait_char

    sw t2, 0(t0) # send character to terminal
    addi t3, t3, 1
    j print_buf_loop

done_print:
    ret


myrandom:
	li	a5,-14671872
	lw	a0,256(a5)
	srai	a5,a0,8
	andi	a5,a5,255
	xor	a0,a5,a0
	ret
