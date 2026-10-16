#include <stdio.h>

void printOct ( int val ) { printf ("%o\n", val); }
void printHex ( int val ) { printf ("%X\n", val); } 
void printDec ( int val ) { printf ("%u\n", val); }

// Inline assembly for CPUlator

__asm__(
    ".global main\n"
    "main:\n"
    "  addi sp, sp, -16\n" // allocate stack frame
    "  sw ra, 12(sp)\n" // save return address

    "  li a0, 10\n" // Load argument for printOct
    "  call printOct\n"

    "  li a0, 10\n" // Reload argument for printHex since a0 is now likely garbage data
    "  call printHex\n"

    "  li a0, 10\n" // Reload argument for printDec
    "  call printDec\n"

    "  lw ra, 12(sp)\n" // Restore return address
    "  addi sp, sp, 16\n" // Deallocate stack frame
    "  ret\n"
);