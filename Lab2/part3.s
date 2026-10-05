.equ RED_LEDS, 0xFF200000 	   # (From DESL website > NIOS II > devices)


  .data                              # "data" section for input and output lists
  
  
  IN_LIST:                  	   # List of 10 signed halfwords starting at address IN_LIST
      .hword 1
      .hword -1
      .hword -2
      .hword 2
      .hword 0
      .hword -3
      .hword 100
      .hword 0xff9c
      .hword 0b1111
  LAST:			 	    # These 2 bytes are the last halfword in IN_LIST
      .byte  0x01		  	    # address LAST
      .byte  0x02		  	    # address LAST+1
      
  IN_LINKED_LIST:                     # Used only in Part 3
      A: .word 1
         .word B
      B: .word -1
         .word C
      C: .word -2
         .word E + 8
      D: .word 2
         .word C
      E: .word 0
         .word K
      F: .word -3
         .word G
      G: .word 100
         .word J
      H: .word 0xffffff9c
         .word E
      I: .word 0xff9c
         .word H
      J: .word 0b1111
         .word IN_LINKED_LIST + 0x40
      K: .byte 0x01		    # address K
         .byte 0x02		    # address K+1
         .byte 0x03		    # address K+2
         .byte 0x04		    # address K+3
         .word 0
      
  OUT_NEGATIVE:
      .skip                          # Reserve space for 10 output words
      
  OUT_POSITIVE:
      .skip                          # Reserve space for 10 output words
  
  #-----------------------------------------
  .text                  # "text" section for code
  
      # Register allocation:
      #   "zero register" is zero
      #   s0  Holds the number of negative numbers in the list
      #   s2  Holds the number of positive numbers in the list
      #   s_  A pointer to ___
      #   s_  loop counter for ___
      #   t0, t1 Short-lived temporary values.
      #   etc...
  
  .global _start
  _start:
      
      # Your program here. Pseudocode and some code done for you:
      
      # Begin loop to process each number
      
          # Process a number here:
          #    if (number is negative) { 
          #        insert number in OUT_NEGATIVE list
          #        increment count of negative values (r2)?????? r2 is not a valid register!!
          #    } else if (number is positive) { 
          #        insert number in OUT_POSITIVE list
          #        increment count of positive values (r3) niether is r3!!!! -ricky
          #    }
          # Done processing.
		  la t0, IN_LINKED_LIST
		  addi s2, x0, 0
		  addi s0, x0, 0
LOOP:

		  lw t1, (t0)
		  beqz t1, EPI
		  bge t1, x0, IS_POSITIVE

		  
IS_NEGATIVE: 
		  la t2, OUT_NEGATIVE
		  slli t3, s0, 2
		  add t2, t2, t3
		  sw t1, (t2)
		  addi s0, s0, 1
		  j EPI
		  
IS_POSITIVE:
		  la t2, OUT_POSITIVE
		  slli t3, s2, 2
		  add t2, t2, t3
		  sw t1, (t2)
		  addi s2, s2, 1
		  j EPI

EPI:
		  addi t0, t0, 4
		  lw t0, (t0)
		  beqz t0, LOOP_FOREVER
		  j LOOP
          # (You'll learn more about I/O in Lab 4.)
          la  t0, RED_LEDS          # t0 and t1 are temporary values
          lw  t1, 0(t0)
          addi   t1, t1, 1
          sw  t2, 0(t0)
          # Finished output to LEDs.
      # End loop
  
  
LOOP_FOREVER:
      j LOOP_FOREVER                   # Loop forever