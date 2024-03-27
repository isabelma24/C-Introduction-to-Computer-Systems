/************************************************************************/
/* File Name : lc4_disassembler.c 										*/
/* Purpose   : This file implements the reverse assembler 				*/
/*             for LC4 assembly.  It will be called by main()			*/
/*             															*/
/* Author(s) : tjf and you												*/
/************************************************************************/

#include <stdio.h>
#include "lc4_memory.h"
#include <stdlib.h>
#include <string.h>

int reverse_assemble (row_of_memory* memory)
{
  /* binary constants should be proceeded by a 0b as in 0b011 for decimal 3 */
  row_of_memory* node;
	char* assembly;

	int Rd;
  int Rs;
  int Rt;

  int label;
	short unsigned int IMM5; 	
	short unsigned int holder;

	// seperate input to rd, rs, rt, imm by using holder temprarily
	while ((node = search_opcode(memory, 0x0001)) != NULL) {

		assembly = malloc(17 * sizeof(char));
		node -> assembly = malloc(17 * sizeof(char));

		//check for edge
		if (assembly == NULL) return -1;
		
		holder = node -> contents << 4;
		Rd = holder >> 13;
		holder = node -> contents << 7;
		Rs = holder >> 13;

		holder = node -> contents << 10;
		label = holder >> 13;
		holder = node -> contents << 10;
		IMM5 = holder >> 15;
    
    holder = node -> contents << 13;
		Rt = holder >> 13;

	// dealing with imm in 2's complement positive & negative
		if (IMM5 == 1) {

			holder = node -> contents << 11;
			IMM5 = holder >> 11;

			//positive
			if (IMM5 <= 15) {
        sprintf(assembly, "ADD R%d, R%d, #%d", Rd, Rs, IMM5);
        strcpy(node -> assembly, assembly);
        free(assembly);
        continue;
			}
      
      //negative
			IMM5 = (IMM5 ^ 0b0000000000011111) + 0b1;
      sprintf(assembly, "ADD R%d, R%d, #-%d", Rd, Rs, IMM5);
      strcpy(node -> assembly, assembly);
      free(assembly);
      continue;

		}

	//the subopcode
		switch(label) {
			//000
			case 0:
				sprintf(assembly, "ADD R%d, R%d, R%d", Rd, Rs, Rt);
				strcpy(node -> assembly, assembly);
				break;

			//001
			case 1:
				sprintf(assembly, "MUL R%d, R%d, R%d", Rd, Rs, Rt);
 				strcpy(node -> assembly, assembly);
				break;

			//010
			case 2:
				sprintf(assembly, "SUB R%d, R%d, R%d", Rd, Rs, Rt);
				strcpy(node -> assembly, assembly);
				break;

			//011
			case 3:
				sprintf(assembly, "DIV R%d, R%d, R%d", Rd, Rs, Rt);
				strcpy(node -> assembly, assembly);
				break;

		}
		// free(node -> assembly);
		free(assembly);

	}

	return 0 ;
}
