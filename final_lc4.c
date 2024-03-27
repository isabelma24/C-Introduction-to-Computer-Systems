/************************************************************************/
/* File Name : lc4.c 													*/
/* Purpose   : This file contains the main() for this project			*/
/*             main() will call the loader and disassembler functions	*/
/*             															*/
/* Author(s) : tjf and you												*/
/************************************************************************/

#include <stdio.h>
#include "lc4_memory.h"
#include "lc4_loader.h"
#include "lc4_disassembler.h"

/* program to mimic pennsim loader and disassemble object files */

// Author: Justin Shiah & Isabel Ma
int main (int argc, char** argv) {
  
/* leave plenty of room for the filename */
  
  // char filename[100];
	char* filename=NULL;
	FILE* infile;

	/**
	 * main() holds the linked list &
	 * only calls functions in other files
	 */

	/* step 1: create head pointer to linked list: memory 	*/
	/* do not change this line - there should no be malloc calls in main() */
	row_of_memory* memory = NULL ;

	/* step 2: determine filename, then open it		*/
	/*   TODO: extract filename from argv, pass it to open_file() */
	if (argc != 2 || argv[1] == NULL) {
		printf("error1: usage:./lc4 <object_file.obj>\n");
		return -1;
	} 

	filename = argv[1];
	infile = open_file(filename);

	if (infile == NULL){
			printf("error1: usage: ./lc4 <object_file.obj>\n");
			return -1;
	}	

	/* step 3: call function: parse_file() in lc4_loader.c 	*/
	/*   TODO: call function & check for errors		*/

	if (parse_file(infile, &memory) != 0) {
		printf("error2: parse_file() failed\n");
		return -1;
	}

	/* step 4: call function: reverse_assemble() in lc4_disassembler.c */
	/*   TODO: call function & check for errors		*/

	if (reverse_assemble(memory) != 0) {
		printf("error3: reverse_assemble() failed\n");
		return -1;
	}

	/* step 5: call function: print_list() in lc4_memory.c 	*/
	/*   TODO: call function 				*/
	print_list(memory);

	/* step 6: call function: delete_list() in lc4_memory.c */
	/*   TODO: call function & check for errors		*/

	if (delete_list(&memory) != 0) {
		printf("error4: delete_list() failed\n");
		return -1;
	}

	/* only return 0 if everything works properly */
	return 0 ;
}
