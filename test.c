#include <stdio.h>

unsigned int value = 0x01020304;

 

int main ()

{

 

  unsigned char *byte_address = (unsigned char *) &value;

  int i;

 

  printf ("The value as a 32-bit quantity is in hex: 0x%08x\n", value);

  printf ("The value is stored starting in memory location in hex: 0x%08x\n", byte_address);

 

  for (i = 0; i < 4; i++)

  {

     printf ("The value stored in the byte at memory location 0x%08lx (hex) is in hex 0x%02x\n", byte_address, *byte_address);

     byte_address++;

  }

}