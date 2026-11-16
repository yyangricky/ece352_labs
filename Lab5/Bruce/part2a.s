/*    Subroutine to display a four-bit quantity as a hex digits (from 0 to F) 
      on one of the six HEX 7-segment displays on the DE1_SoC.
*
 *    Parameters: the low-order 4 bits of register a0 contain the digit to be displayed
		  if bit 4 of a1 is a one, then the display should be blanked
 *    		  the low order 3 bits of a0 say which HEX display number 0-5 to put the digit on
 *    Returns: a0 = bit patterm that is written to HEX display
 */

 #Updated to Nios V by Jonathan Schneider, July, 2024

.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030

.equ TIMER_BASE, 0xff202000
.equ ONE_SEC, 100000000 # 100 MHz clock -> 100,000,000 ticks = 1 sec

.equ JTAG_BASE, 0xFF201000

li sp, 0x20000

.global _start
_start:

#Your code Here:

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

	li s0, 0 # counter for hex display

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
    bne t0, t3, next_char
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
    beq t1, zero, end_poll_loop # if TO flag is not set, finish loop iteration

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

# extra epilogue since we need to increment s0 each time
end_poll_loop:
    addi s0, s0, 1 # increment counter after polling UART and Timer
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
    beq t2, zero, display_score # Stop at null terminator ('\0'). Go to display_score instead of end_game

wait_jtag_go:
    lw t3, 4(t0) # Read JTAG Control register (offset 0x4)
    srli t3, t3, 16 # Upper 16 bits = available write FIFO space (WSPACE)
    beq t3, zero, wait_jtag_go # Wait until space > 0

    sw t2, 0(t0) # Write character to JTAG Data register (offset 0x0)
    addi t1, t1, 1 # Advance string pointer
    j print_go_loop

# mechanism to display the score on the HEX displays
display_score:
    li s2, 0 # quotient (s0 / 100)
    li t0, 100 # divisor

div_100_loop:
    bltu s0, t0, done_div # if remainder < 100, division is done
    sub s0, s0, t0 # remainder -= 100
    addi s2, s2, 1 # quotient += 1
    j div_100_loop

done_div:
    li s1, 0 # HEX display index (0 to 5)
    li s3, 6 # total number of HEX displays

hex_loop:
    beq s1, s3, iloop # stop after updating HEX0 through HEX5
    andi a0, s2, 0xF # extract lowest 4-bit hex digit
    mv a1, s1 # target HEX display number (0-5)
    call HEX_DISP # write digit to 7-segment display
    srli s2, s2, 4 # shift to next hex digit
    addi s1, s1, 1 # move to next HEX display
    j hex_loop

iloop: j iloop

#Subroutine is here:

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


HEX_DISP:   
		addi sp, sp, -16
		sw s0,0(sp)
		sw s1,0x4(sp)
		sw s2,0x8(sp)
		sw s3,0xC(sp)
	
		la   s0, BIT_CODES         # starting address of the bit codes
	    andi     s1, a0, 0x10	       # get bit 4 of the input into r6
	    beq      s1, zero, not_blank 
	    mv      s2, zero
	    j       DO_DISP
not_blank:  andi     a0, a0, 0x0f	   # r4 is only 4-bit
            add      a0, a0, s0        # add the offset to the bit codes
            lb      s2, 0(a0)         # index into the bit codes

#Display it on the target HEX display
DO_DISP:    
			la       s0, HEX_BASE1         # load address
			li       s1,  4
			blt      a1,s1, FIRST_SET      # hex4 and hex 5 are on 0xff200030
			sub      a1, a1, s1            # if hex4 or hex5, we need to adjust the shift
			addi     s0, s0, 0x0010        # we also need to adjust the address
FIRST_SET:
			slli     a1, a1, 3             # hex*8 shift is needed
			addi     s3, zero, 0xff        # create bit mask so other values are not corrupted
			sll      s3, s3, a1 
			li     	 a0, -1
			xor      s3, s3, a0  
    		sll      a0, s2, a1            # shift the hex code we want to write
			lw    	 a1, 0(s0)             # read current value       
			and      a1, a1, s3            # and it with the mask to clear the target hex
			or       a1, a1, a0	           # or with the hex code
			sw    	 a1, 0(s0)		       # store back
END:			
			mv 		 a0, s2				   # put bit pattern on return register
			
			
			lw s0,0(sp)
			lw s1,0x4(sp)
			lw s2,0x8(sp)
			lw s3,0xC(sp)
			addi sp, sp, 16
			ret


.data
LINE_BUF:   .space 50 # Reserves 50 consecutive bytes in RAM for the scrolling line
GAME_OVER:  .asciz "\r\nGAME OVER\r\n"
            .align 2
BIT_CODES:  .byte     0b00111111, 0b00000110, 0b01011011, 0b01001111
			.byte     0b01100110, 0b01101101, 0b01111101, 0b00000111
			.byte     0b01111111, 0b01100111, 0b01110111, 0b01111100
			.byte     0b00111001, 0b01011110, 0b01111001, 0b01110001

            .end
			