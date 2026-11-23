.global _start

.data
line_buffer:
    .fill 50, 1, 32     # Allocates 50 elements, each 1 byte, initialized to 32 (ASCII space)
game_over_str:
    .asciz "\nGAME OVER\n"       # Null-terminated string (adds trailing 0x00)
BIT_CODES:                       # 7-segment patterns for 0-F
    .byte 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07
    .byte 0x7F, 0x67, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

/*    Subroutine to display a four-bit quantity as a hex digits (from 0 to F) 
      on one of the six HEX 7-segment displays on the DE1_SoC.
*
 *    Parameters: the low-order 4 bits of register a0 contain the digit to be displayed
		  if bit 4 of a0 is a one, then the display should be blanked
 *    		  a1 says which HEX display number 0-5 to put the digit on
 *    Returns: a0 = bit pattern that is written to HEX display
 */

 #Updated to Nios V by Jonathan Schneider, July, 2024

.equ HEX_BASE1, 0xff200020
.equ HEX_BASE2, 0xff200030
#uart constants
.equ JTAG_UART_BASE, 0xff201000#base address of uart
.equ JTAG_UART_RR, 0#rr register at 0(base)
.equ JTAG_UART_TR, 0#tr register also at 0(base)
.equ JTAG_UART_CSR, 4#csr at 4(base)
#timer constants
.equ  TIMER0_BASE,      0xFF202000
.equ  TIMER0_STATUS,    0
.equ  TIMER0_CONTROL,   4
.equ  TIMER0_PERIODL,   8
.equ  TIMER0_PERIODH,   12
.equ  TIMER0_SNAPL,     16
.equ  TIMER0_SNAPH,     20
.equ  TICKSPERSEC,      100000000
.equ  TICKSPERSECHIGH, (TICKSPERSEC >> 16)         # these calculations are done at assembly time – this is a constant
.equ  TICKSPERSECLOW, (TICKSPERSEC & 0x0000FFFF)

.text
	.align	2

#Your code Here:
_start:
init:#initialize the setup
	li sp, 0x20000
	li s3, JTAG_UART_BASE #Notetoself: dont touch s3 or s6, as they contain base adresses
	li s6, TIMER0_BASE
	li s7, 0 #raw score (only the scroll branch changes it)
	jal set_up_timer
	jal print_score #show the initial score
mloop: #main loop - checks key press and timer update
		lw s0, JTAG_UART_RR(s3) #checks the receiver register
		srli s1, s0, 15
		andi s1, s1, 0x1 #s1 countains the 15th bit of s0, which ==1 if any char is received
		beqz s1, no_char_received #if a char is not recieved, jump past the jal clear_number
		andi a0, s0, 0xff #load the argument to clear number as the character received
		jal clear_number
		jal print_line #show the updated line on the terminal
	no_char_received:
		lw s4, TIMER0_STATUS(s6) #isolate for the T0 bit
		andi s4, s4, 0x1
		beqz s4, mloop#check if the flag has been raised, if not go back and poll again
		sw x0, TIMER0_STATUS(s6) #lower flag
		jal scroll
		li t0, 32 #ascii space
		bne a0, t0, game_over # if the last leftmost element was not 32, then game over
		jal print_line #show the scrolled line on the terminal
		addi s7, s7, 1 #score goes up every successful scroll
		jal print_score #show the new score on the hex displays
		j mloop
		
game_over:#display game is over :(
	jal print_game_over
iloop: j iloop

clear_number: #subroutine to clear all the a0's on the screen
    la   t0, line_buffer     # t0 = current pointer into line_buffer
    addi t1, t0, 50          # t1 = end pointer (base address + 50 bytes)
    li   t2, 32              # t2 = ASCII space (0x20)

clear_loop:
    beq  t0, t1, clear_done  # Exit loop once all 50 bytes have been checked
    lbu  t3, 0(t0)           # Load current character (unsigned byte)
    bne  t3, a0, next_char   # If it doesn't match a0, skip replacement
    sb   t2, 0(t0)           # Overwrite matching character with space (32)

next_char:
    addi t0, t0, 1           # Advance pointer to the next byte
    j    clear_loop          # Repeat

clear_done:
    ret

scroll: #subroutine to shift all the numbers over by 1, and replace
#the rightmost space by a randomly generated number. a0 is the previous leftmost num
    addi sp, sp, -4
    sw   ra, 0(sp)            # we call myrandom, so save ra
    jal  myrandom
    addi a2, a0, 48           # convert the 0-9 into ASCII '0'-'9'

    la   t0, line_buffer      # t0 = current write pointer (starts at index 0)
    lbu  a0, 0(t0)            # Save original first element into a0
    addi t1, t0, 49           # t1 = stop address (index 49, the last element)

shift_loop:
    beq  t0, t1, shift_end    # Stop once t0 reaches index 49
    lbu  t2, 1(t0)            # Load byte from next position (i + 1)
    sb   t2, 0(t0)            # Store it into current position (i)
    addi t0, t0, 1            # Advance pointer by 1 byte
    j    shift_loop

shift_end:
    sb   a2, 0(t0)           # Place random char at the last element (index 49)
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

set_up_timer: #sets up timer initalizing period to 1s and have it run until zero
la    t0, TIMER0_BASE
li    t1, 0x8
sw    t1, TIMER0_CONTROL(t0)
# Set the period registers to 10^7
li    t1, TICKSPERSECLOW
sw    t1, TIMER0_PERIODL(t0)
li    t1, TICKSPERSECHIGH
sw    t1, TIMER0_PERIODH(t0)
# tell the counter to start over automatically and start counting
li    t1, 0x6                       # 0x6 = 0110 so we write 1 to START and to CONT
sw    t1, TIMER0_CONTROL(t0)
ret

putchar: #a0 = char to send, waits until the uart has room
    li   t5, JTAG_UART_BASE
putchar_wait:
    lw   t6, 4(t5)
    srli t6, t6, 16           # Shift upper 16 bits (WSPACE) down to bits 15:0
    beqz t6, putchar_wait     # Wait until write FIFO space > 0
    sb   a0, 0(t5)            # Write character to Data register (offset +0)
    ret

print_line: #prints the 50 chars followed by a carriage return so the next print overwrites the line
    addi sp, sp, -4
    sw   ra, 0(sp)
    la   t0, line_buffer
    addi t1, t0, 50
pl_loop:
    beq  t0, t1, pl_done
    lbu  a0, 0(t0)
    jal  putchar              # only clobbers t5, t6
    addi t0, t0, 1
    j    pl_loop
pl_done:
    li   a0, 13               # '\r' (use 10 if your terminal ignores carriage return)
    jal  putchar
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

print_score: #shows s7 / 100 in decimal on HEX5..HEX0, leading zeros blanked
    addi sp, sp, -4
    sw   ra, 0(sp)
    li   t0, 100
    divu t1, s7, t0           # t1 = raw score / 100
    li   t2, 0                # display index, 0 = rightmost
    li   t3, 10
    li   t4, 6                # number of displays
ps_loop:
    remu a0, t1, t3           # a0 = lowest remaining digit
    divu t1, t1, t3           # drop that digit
    bnez t1, ps_show          # more digits to the left -> show it
    bnez a0, ps_show          # nonzero digit -> show it
    beqz t2, ps_show          # HEX0 always shows (even 0)
    li   a0, 0x10             # leading zero -> blank
ps_show:
    mv   a1, t2
    jal  HEX_DISP
    addi t2, t2, 1
    blt  t2, t4, ps_loop
    lw   ra, 0(sp)
    addi sp, sp, 4
    ret

#Subroutine is here:

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

print_game_over:
    li   t0, JTAG_UART_BASE      # t0 = base address of JTAG UART
    la   t1, game_over_str       # t1 = pointer to current character in string

print_loop:
    lbu  t2, 0(t1)               # Load next ASCII character
    beqz t2, print_done          # If null terminator (0x00), we are finished

wait_uart_tx:
    lw   t3, 4(t0)               # Read Control register (offset +4)
    srli t3, t3, 16              # Shift upper 16 bits (WSPACE) down to bits 15:0
    beqz t3, wait_uart_tx        # Wait until write FIFO space > 0

    sb   t2, 0(t0)               # Write character to Data register (offset +0)
    addi t1, t1, 1               # Advance to next character
    j    print_loop

print_done:
    ret

	.align	2
	.globl	myrandom
myrandom:
	li	a5,-14671872
	lw	a0,256(a5)
	srai	a5,a0,8
	andi	a5,a5,255
	xor	a0,a5,a0
	
	li a5, 10
	remu a0, a0, a5 # ans = ans %10, such that the number generated stays between zero and 9
	
	ret
