/************************************************************************/
/* File Name : lc4_loader.c		 										*/
/* Purpose   : This file implements the loader (ld) from PennSim		*/
/*             It will be called by main()								*/
/*             															*/
/* Author(s) : tjf and you												*/
/************************************************************************/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lc4_memory.h"

/* declarations of functions that must defined in lc4_loader.c */
// Author: Justin Shiah
FILE* open_file(char* file_name)
{
	FILE *filename = fopen(file_name, "rb");

	if(filename == NULL)
	{
		printf("error1: usage: ./lc4 <object_file.obj>");
		return NULL;
	}
	
	return filename;
	
}

// Author: Justin Shiah
int parse_file (FILE* my_obj_file, row_of_memory** memory)
{
/* remember to adjust 16-bit values read from the file for endiannness
 * remember to check return values from fread() and/or fgetc()
 */
	int first_byte, second_byte, contents, address, num;
	int count = 0;

	do
	{
		first_byte = fgetc(my_obj_file);
		second_byte = fgetc(my_obj_file);
		contents = (first_byte << 8) | second_byte;
		if(first_byte == EOF || second_byte == EOF)
		{
			fclose(my_obj_file);
			return 0;

		}

		first_byte = fgetc(my_obj_file);
		second_byte = fgetc(my_obj_file);
		address = (first_byte << 8) | second_byte;
		first_byte = fgetc(my_obj_file) << 8;
		second_byte = fgetc(my_obj_file);
		num = first_byte | second_byte;

		if(contents == 0xCADE || contents == 0xDADA)
		{

			for(int i = 0; i < num; i++)
			{
				first_byte = fgetc(my_obj_file);
				second_byte = fgetc(my_obj_file);
				if(first_byte == EOF || second_byte == EOF)
				{
					fclose(my_obj_file);
					return 0;
				}
				contents = (first_byte << 8) | second_byte;
				add_to_list(memory, address, contents);
				address++;
			}
		}
		else //if contents == C3B7
		{
			char new_label[num+1];

			for(int i = 0; i < num; i++)
			{
				first_byte = fgetc(my_obj_file);
				if(first_byte == EOF)
				{
					fclose(my_obj_file);
					return 0;
				}
				char c = (char) first_byte;
				new_label[i] = (char)first_byte;
			}

			new_label[num] = '\0';

			if(search_address(*memory, address) == NULL)
			{
				add_to_list(memory, address, 0);
			}
			row_of_memory* add_label = search_address(*memory, address);
			if(add_label->label == NULL)
			{
				free(add_label->label);
				add_label->label = malloc(sizeof(new_label));
			}
			strcpy(add_label->label, new_label);
		}
	}
	while(1);

	fclose(my_obj_file);
	return 0;
}
