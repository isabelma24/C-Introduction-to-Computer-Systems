; 1. multiply.asm

;;; pseudo-code of multiplication algorithm
;
; C = 0 ;
; while ( B > 0 )
; {
;    C = C + A ;
;    B = B - 1 ;
; }

; register allocation: R0=A, R1=B, R2=C
	  
  CONST R0, #2    ; A = 2
  CONST R1, #3    ; B = 3
  CONST R2, #0    ; C = 0
  
LOOP 
  CMPI R1, #0     ; sets  NZP (B-0)
  BRnz END        ; tests NZP (was B-0 neg or zero?, if yes, goto END)
  ADD R2, R2, R0  ; C=C+A
  ADD R1, R1, #-1 ; B=B-1
  BRnzp LOOP      ; always goto LOOP
END


; 2. factorial.asm

;;; pseudo-code of factorial algorithm
;
; A = 5 ;  // example to do 5!
; B = A ;  // B=A! when while loop completes
;
; while (A > 1) {
; 	A = A - 1 ;
; 	B = B * A ;
; }
;

;;; TO-DO: Implement the factorial algorithm above using LC4 Assembly instructions

.CODE
.ADDR x0000 

; register allocation: R0 = A, R1 = B;
	  
  CONST R0, #5      ; A = 5
  AND R1, R1, #0    ; reset B
  ADD R1, R1, R0    ; B = A
  
WHILE               ; while loop
  CMPI R0, #1       ; sets  NZP (A-1)
  BRnz END          ; tests NZP (was A-1 negative or zero?, if yes, goto END)
  ADD R0, R0, #-1   ; A = A - 1
  MUL R1, R1, R0    ; B = B * A
  BRnzp WHILE       ; always goto WHILE
END


; 3. factorial_sub.asm

;;; Additional for Q2

; MAIN

; A = 6 ;
; B = sub_factorial (A) ;

; // your sub_factorial subroutine goes here

;;; TO-DO: Implement the factorial algorithm above using LC4 Assembly instructions

.CODE
.ADDR x0000 

; register allocation: R0 = A, R1 = B, A is a signed number;

CONST R0, #6              ; A = 6
JSR SUB_FACTORIAL         ; jump to subroutine for sub_factorial
END                       ; jump over subroutine
.FALIGN                   ; aligns the subroutine
SUB_FACTORIAL             ; ARGS: R0 = A, R1 = B
    AND R1, R1, #0        ; reset B
    ADD R1, R1, R0        ; B = A
IF                        ; if/else statement for R0
    CMPI R0, 0            ; A is a positive #
    BRnz ELSE             ; if not, goto ELSE
    CMPI R0, 7            ; A <= the largest number assembly allow
    BRp ELSE              ; if not, goto ELSE
    WHILE                 ; while loop
        CMPI R0, #1       ; sets  NZP (A-1)
        BRnz END_WHILE    ; tests NZP (was A-1 negative or zero?, if yes, goto END_WHILE)
        ADD R0, R0, #-1   ; A = A - 1
        MUL R1, R1, R0    ; B = B * A
        BRnzp WHILE       ; continue with WHILE loop
ELSE                      ; else statement for A <= 0 or > the largest number
    CONST R1, #-1         ; B = -1
END_WHILE				  ; end the while loop 
RET                       ; end subroutine


; 4. dmem_fact.asm

;;; Additional for Q3


;;; TO-DO: Implement the factorial algorithm above using LC4 Assembly instructions


	;; This is the data section
	.DATA
	.ADDR x4020		      ; Start the data at address 0x4020
DATA_VALUES		          ; label for the array of data
	.FILL #6	          ; fill each of the 5 rows of data
	.FILL #5	          ; fill each of the 5 rows of data
	.FILL #8	          ; fill each of the 5 rows of data
	.FILL #10	          ; fill each of the 5 rows of data
	.FILL #-5	          ; fill each of the 5 rows of data

	;; This is the code section
	.CODE
	.ADDR x0000		      ; Start the code at address x0000

    LEA R0, DATA_VALUES	  ; R0 contains the address of the data
	CONST R1, 5		      ; R1 is our loop counter init to 5

FOR_LOOP
	CMPI R1, #0		      ; check if the loop counter is zero yet
	BRnz END		      ; if yes, goto END
	LDR R2, R0, #0		  ; Load the data value into R2 = A  
    JSR SUB_FACTORIAL     ; jump to subroutine for sub_factorial
	STR R3, R0, #0		  ; store output B of #'s factorial into data memeory and replace the origianl #
	ADD R0, R0, #1		  ; increment the address to point for next data
	ADD R1, R1, #-1		  ; decrement the loop counter
	BRnzp FOR_LOOP		  ; continue the for loop

END                       ; end program

.FALIGN                   ; aligns the subroutine
SUB_FACTORIAL             ; ARGS: R2 = A, R3 = B
    AND R3, R3, #0        ; reset B
    ADD R3, R3, R2        ; B = A
IF                        ; if/else statement for R2
    CMPI R2, 0            ; A is a positive #
    BRnz ELSE             ; if not, goto ELSE
    CMPI R2, 7            ; A <= the largest number assembly allow
    BRp ELSE              ; if not, goto ELSE
    WHILE                 ; while loop
        CMPI R2, #1       ; sets  NZP (A-1)
        BRnz END_WHILE    ; tests NZP (was A-1 negative or zero?, if yes, goto END_WHILE)
        ADD R2, R2, #-1   ; A = A - 1
        MUL R3, R3, R2    ; B = B * A
        BRnzp WHILE       ; continue with WHILE loop 
ELSE                      ; else statement for A <= 0 or > the largest number
    CONST R3, #-1         ; B = -1
END_WHILE				  ; end the while loop 
RET                       ; end subroutine


; 5. dmem_fact_ec.asm

;;; Additional for Q3


;;; TO-DO: Implement the factorial algorithm above using LC4 Assembly instructions


	;; This is the data section
	.DATA
	.ADDR x4020		      ; Start the data at address 0x4020
DATA_VALUES		          ; label for the array of data
	.FILL #6	          ; fill each of the 5 rows of data
	.FILL #5	          ; fill each of the 5 rows of data
	.FILL #8	          ; fill each of the 5 rows of data
	.FILL #10	          ; fill each of the 5 rows of data
	.FILL #-5	          ; fill each of the 5 rows of data

	;; This is the code section
	.CODE
	.ADDR x0000		      ; Start the code at address x0000

    LEA R0, DATA_VALUES	  ; R0 contains the address of the data
	CONST R1, 5		      ; R1 is our loop counter init to 5

FOR_LOOP
	CMPI R1, #0		      ; check if the loop counter is zero yet
	BRnz END		      ; if yes, goto END

    JSR SUB_FACTORIAL     ; jump to subroutine for sub_factorial	

	ADD R0, R0, #1		  ; increment the address to point for next data
	ADD R1, R1, #-1		  ; decrement the loop counter
	BRnzp FOR_LOOP		  ; continue the for loop

END                       ; end program

.FALIGN                   ; aligns the subroutine
SUB_FACTORIAL             ; ARGS: R2 = A, R3 = B
	LDR R2, R0, #0		  ; Load the data value into R2 = A
    AND R3, R3, #0        ; reset B
    ADD R3, R3, R2        ; B = A
IF                        ; if/else statement for R2
    CMPI R2, 0            ; A is a positive #
    BRnz ELSE             ; if not, goto ELSE
    CMPI R2, 7            ; A <= the largest number assembly allow
    BRp ELSE              ; if not, goto ELSE
    WHILE                 ; while loop
        CMPI R2, #1       ; sets  NZP (A-1)
        BRnz END_WHILE    ; tests NZP (was A-1 negative or zero?, if yes, goto END_WHILE)
        ADD R2, R2, #-1   ; A = A - 1
        MUL R3, R3, R2    ; B = B * A
        BRnzp WHILE       ; continue with WHILE loop 
ELSE                      ; else statement for A <= 0 or > the largest number
    CONST R3, #-1         ; B = -1
END_WHILE				  ; end the while loop 
	STR R3, R0, #0		  ; store output B of #'s factorial into data memeory and replace the origianl #

RET                       ; end subroutine