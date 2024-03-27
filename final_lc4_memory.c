/************************************************************************/
/* File Name : lc4_memory.c		 										*/
/* Purpose   : This file implements the linked_list helper functions	*/
/* 			   to manage the LC4 memory									*/
/*             															*/
/* Author(s) : tjf and you												*/
/************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include "lc4_memory.h"


/*
 * adds a new node to a linked list pointed to by head
 */

int add_to_list (row_of_memory** head, short unsigned int address, short unsigned int contents)
{
    /* check to see if there is already an entry for this address and update the contents.  no additional steps required in this case */
    row_of_memory* temp = *head;
    while(*head != NULL)
    {
      if((*head)->address == address)
      {
        (*head)->contents = contents;
        *head = temp;
        return 0;
      }
      *head = (*head)->next;
    }
    *head = temp;
    /* allocate memory for a single node */
    row_of_memory* new_row = malloc(sizeof(row_of_memory));
    memset(new_row, 0, sizeof(row_of_memory));

	/* populate fields in newly allocated node w/ address&contents, NULL for label and assembly */
	/* do not malloc() storage for label and assembly here - do it in parse_file() and reverse_assemble() */
  new_row->address = address;
  new_row->label = NULL;
  new_row->assembly = NULL;
  new_row->contents = contents;

	/* if *head is NULL, node created is the new head of the list! */
  if(*head == NULL)
  {
    *head = new_row;
    //(*head)->next = NULL;
  }

	/* otherwise, insert node into the list in address ascending order */
  else if (new_row->address < (*head)->address)
  {
    temp = *head;
    *head = new_row;
    (*head)->next = temp;
  }
  else
  {
    row_of_memory* temp2 = *head;    
    while((*head)->next != NULL && new_row->address > ((*head)->next)->address)
    {
      *head = (*head)->next;
    }
    if((*head)->next == NULL)
      (*head)->next = new_row;
    else
    {
      temp = (*head)->next;
      (*head)->next = new_row;
      new_row->next = temp;
    }
    *head = temp2;
  }
	/* return 0 for success, -1 if malloc fails */
	return 0 ;
}



/*
 * search linked list by address field, returns node if found
 */

row_of_memory* search_address (row_of_memory* head,
			       short unsigned int address )
{
  //printf("val: %x", head->address);
	/* traverse linked list, searching each node for "address"  */
  while((head != NULL) && (head->address != address))
  {
    head = head->next;
  }
	/* return pointer to node in the list if item is found */

	/* return NULL if list is empty or if "address" isn't found */
	return head;
}

/*
 * search linked list by opcode field, returns node if found
 */
 // Author: Justin Shiah
row_of_memory* search_opcode  (row_of_memory* head,
				      short unsigned int opcode  )
{

    /* opcode parameter is in the least significant 4 bits of the short int and ranges from 0-15 */
		/* see assignment instructions for a detailed description */
    opcode = opcode << 12 & 0xF000;

    /* traverse linked list until node is found with matching opcode in the most significant 4 bits
	   AND "assembly" field of node is NULL */
    while(head != NULL)
    {
      short unsigned int val = head->contents & 0xF000;
      if(val == opcode && head->assembly == NULL)
        return head;
      head = head->next;
    }
	/* return pointer to node in the list if item is found */

	/* return NULL if list is empty or if no matching nodes */

	return NULL ;
}


void print_list (row_of_memory* head )
{
	/* make sure head isn't NULL */
  if(head == NULL)
    return;
	/* print out a header */
  printf("<label>              <address>            <contents>           <assembly>\n");
    /* don't print assembly directives for non opcode 1 instructions if you are doing extra credit */

	/* traverse linked list, print contents of each node */
  while(head != NULL)
  {
    printf("%-20s %-20.04X %-20.04X %-20s\n", head->label, head->address, head->contents, head->assembly);
    head = head->next;
  }
}

/*
 * delete entire linked list
 */

int delete_list (row_of_memory** head )
{
	/* delete entire list node by node */
	/* set the list head pointer to NULL upon deletion */
  while(*head != NULL)
  {
    row_of_memory* temp = (*head)->next;
    free((*head)->assembly);
    free((*head)->label);
    free(*head);
    *head = temp;
  }

  *head = NULL;
	return 0 ;
}
