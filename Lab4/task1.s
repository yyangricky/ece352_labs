.equ PIT_buttons, 0xff200050


.globl main

main: 
    li a0, 3
    call WaitForButton
	
END_LOOP:

	j END_LOOP

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