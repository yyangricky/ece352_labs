/*********
 * A simple program which integrate C and Assembly codes. The main program
 * calls the printn function, written in assembly. The printn function then
 * determines the number format (i.e. octal, hex, or decimal) and prints it
 * through JTAG UART terminal.
 *
 * (1) assembly function(s)
 *     printn ( char * , ... ) ;
 * (2) C function(s)
 *     printHex ( int ) ;
 *     printOct ( int ) ;
 *     printDec ( int ) ;
 *
 * July 21 2007: Supakorn Komthong
 *
 * July 25 2007: Peter Yiannacouras
 * 
 * August 14, 2024: Jonathan Schneider
 *********/

// Using Inline Assembly instead of the big file they gave

void printn(char*, ...);  // Function prototype for an assembly function

void checkRegisters1();
void checkRegisters2();

int main() {
  char* text = "DDDDDDDOOOOOOOHHHHHHH";

  checkRegisters1();  // Debugging: Save callee-saved registers to memory. All
                      // red LEDs should turn on.
  printn(text, 10, 11, 12, 13, 14, 15, 16, 10, 11, 12, 13, 14, 15, 16, 10, 11,
         12, 13, 14, 15, 16);
  checkRegisters2();  // Debugging: Check that callee-saved registers did not
                      // change. Red LEDs turn on if mismatch.

  return 0;
}

void printn(char*, ...){
	__asm__(
		"  addi sp, sp, -16\n" // Allocate stack frame
		"  sw ra, 12(sp)\n" // Save return address
		"  sw s0, 8(sp)\n" // Save original s0
		"  sw s1, 4(sp)\n" // Save original s1
		
		
		"  mv s0, a0\n" // Store char in a0 to s0
		"  mv s1, zero\n" // index tracker
		
		"  li t0, '\0'\n" // load characters for comparison
		"  li t1, 'D'\n"
		"  li t2, 'H'\n"
		"  li t3, 'O'\n"
		
		"LOOP:\n"
		"  addi t4, s0, s1\n" // address of current character
		"  lbu t5, 0(t4)\n"
		"  beq t5, t0, END\n"
		"  beq t5, t1, DEC\n"
		"  beq t5, t2, HEX\n"
		"  beq t5, t3, OCT\n"

		"OCT:\n" 
		"  call printOct\n"
		"  j AFTER\n"

		"HEX:\n" 
		"  call printHex\n"
		"  j AFTER\n"

		"DEC:\n" 
		"  call printDec\n"
		"  j AFTER\n"
		
		"AFTER:\n"
		"  addi s1, s1, 1\n" // Increment index
		"  j LOOP\n"

		"END:"
		"  lw ra, 12(sp)\n" // Restore return address
		"  lw s0, 8(sp)\n" // Restore s0
		"  lw s1, 4(sp)\n" // Restore s1
		"  addi sp, sp, 16\n" // Deallocate stack frame
		"  ret\n");
	return;
}

// The code below is used to verify that registers that should be preserved are
// indeed preserved.

unsigned int regs[10];
void checkRegisters1() {
  // Record current value of callee-saved registers.
  // Assumes main routine won't change these before calling printn(), which is
  // currently true.
  __asm__(
      "la a0, regs\n"
      "sw t0,0x0(a0)\n"
      "sw t1,0x4(a0)\n"
      "sw t2,0x8(a0)\n"
      "sw t3,0xc(a0)\n"
      "sw t4,0x10(a0)\n"
      "sw t5,0x14(a0)\n"
      "sw t6,0x18(a0)\n"
      "sw sp,0x1c(a0)\n");
  return;
}
void checkRegisters2() {
  // Check that the callee-saved registers still have the same value as before.
  // Turn on red LED for each mismatched register. There are 10 registers
  // checked.
  __asm__(
      "li a2, 0\n"
      "la a0, regs\n"
      "lw a1, 0(a0)\n"
      "beq a1, t0, t0Break\n"
      "ori a2, a2, 0b1\n"
      "t0Break:\n"
      "lw a1, 4(a0)\n"
      "beq a1, t1, t1Break\n"
      "ori a2, a2, 0b10\n"
      "t1Break:\n"
      "lw a1, 8(a0)\n"
      "beq a1, t2, t2Break\n"
      "ori a2, a2, 0b100\n"
      "t2Break:\n"
      "lw a1, 12(a0)\n"
      "beq a1, t3, t3Break\n"
      "ori a2, a2, 0b1000\n"
      "t3Break:\n"
      "lw a1, 16(a0)\n"
      "beq a1, t4, t4Break\n"
      "ori a2, a2, 0b10000\n"
      "t4Break:\n"
      "lw a1, 20(a0)\n"
      "beq a1, t5, t5Break\n"
      "ori a2, a2, 0b100000\n"
      "t5Break:\n"
      "lw a1, 24(a0)\n"
      "beq a1, t6, t6Break\n"
      "ori a2, a2, 0b1000000\n"
      "t6Break:\n"
      "li a0, 0xff200000\n"  // Red LEDs
      "sw a2, 0(a0)\n");
  return;
}