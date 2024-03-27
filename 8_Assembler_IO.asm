;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;  file name   : os.asm                                 ;
;  author      : Isabel Ma
;  description : LC4 Assembly program to serve as an OS ;
;                TRAPS will be implemented in this file ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;   OS - TRAP VECTOR TABLE   ;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.OS
.CODE
.ADDR x8000
  ; TRAP vector table
  JMP TRAP_GETC           ; x00
  JMP TRAP_PUTC           ; x01
  JMP TRAP_GETS           ; x02
  JMP TRAP_PUTS           ; x03
  JMP TRAP_TIMER          ; x04
  JMP TRAP_GETC_TIMER     ; x05
  JMP TRAP_RESET_VMEM	  ; x06
  JMP TRAP_BLT_VMEM	      ; x07
  JMP TRAP_DRAW_PIXEL     ; x08
  JMP TRAP_DRAW_RECT      ; x09
;  JMP TRAP_DRAW_SPRITE    ; x0A

  ;
  ; TO DO - add additional vectors as described in homework 
  ;
  
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;   OS - MEMORY ADDRESSES & CONSTANTS   ;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

  ;; these handy alias' will be used in the TRAPs that follow
  USER_CODE_ADDR .UCONST x0000	; start of USER code
  OS_CODE_ADDR 	 .UCONST x8000	; start of OS code

  OS_GLOBALS_ADDR .UCONST xA000	; start of OS global mem
  OS_STACK_ADDR   .UCONST xBFFF	; start of OS stack mem

  OS_KBSR_ADDR .UCONST xFE00  	; alias for keyboard status reg
  OS_KBDR_ADDR .UCONST xFE02  	; alias for keyboard data reg

  OS_ADSR_ADDR .UCONST xFE04  	; alias for display status register
  OS_ADDR_ADDR .UCONST xFE06  	; alias for display data register

  OS_TSR_ADDR .UCONST xFE08 	  ; alias for timer status register
  OS_TIR_ADDR .UCONST xFE0A 	  ; alias for timer interval register

  OS_VDCR_ADDR	.UCONST xFE0C	  ; video display control register
  OS_MCR_ADDR	.UCONST xFFEE	    ; machine control register
  OS_VIDEO_NUM_COLS .UCONST #128
  OS_VIDEO_NUM_ROWS .UCONST #124


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS DATA MEMORY RESERVATIONS ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xA000
OS_GLOBALS_MEM	.BLKW x1000
;;;  LFSR value used by lfsr code
LFSR .FILL 0x0001

;;; Labels to be used in TRAP_DRAW_RECT

OS_GLOBALS_MEM_X .UCONST xA000
OS_GLOBALS_MEM_Y .UCONST xA001
OS_GLOBALS_MEM_L .UCONST xA002
OS_GLOBALS_MEM_W .UCONST xA003
OS_GLOBALS_MEM_C .UCONST xA004
OS_GLOBALS_MEM_R7 .UCONST xA005
OS_GLOBALS_MEM_V .UCONST xA006
OS_GLOBALS_MEM_ROW .UCONST xA007
OS_GLOBALS_MEM_COL .UCONST xA008




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;; OS VIDEO MEMORY RESERVATION ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.DATA
.ADDR xC000
OS_VIDEO_MEM .BLKW x3E00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;   OS & TRAP IMPLEMENTATIONS BEGIN HERE   ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
.ADDR x8200
.FALIGN
  ;; first job of OS is to return PennSim to x0000 & downgrade privledge
  CONST R7, #0   ; R7 = 0
  RTI            ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - none
;;; Outputs          - R0 = ASCII character from ASCII keyboard

.CODE
TRAP_GETC
    LC R0, OS_KBSR_ADDR  ; R0 = address of keyboard status reg
    LDR R0, R0, #0       ; R0 = value of keyboard status reg
    BRzp TRAP_GETC       ; if R0[15]=1, data is waiting!
                             ; else, loop and check again...

    ; reaching here, means data is waiting in keyboard data reg

    LC R0, OS_KBDR_ADDR  ; R0 = address of keyboard data reg
    LDR R0, R0, #0       ; R0 = value of keyboard data reg
    RTI                  ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTC   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a single character out to ASCII display
;;; Inputs           - R0 = ASCII character to write to ASCII display
;;; Outputs          - none

.CODE
TRAP_PUTC
  LC R1, OS_ADSR_ADDR ; R1 = address of display status reg
  LDR R1, R1, #0    	; R1 = value of display status reg
  BRzp TRAP_PUTC    	; if R1[15]=1, display is ready to write!
		    	    ; else, loop and check again...

  ; reaching here, means console is ready to display next char

  LC R1, OS_ADDR_ADDR 	; R1 = address of display data reg
  STR R0, R1, #0    	; R1 = value of keyboard data reg (R0)
  RTI			; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a string of characters from the ASCII keyboard
;;; Inputs           - R0 = Address to place characters from keyboard
;;; Outputs          - R1 = Lenght of the string without the NULL

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; 1) This purpose of this function is to read characters from the keyboard until the “enter” key is pressed
; store them in user data memory as a string in a location requested by the caller
; then return the length of the string to the caller.
; 2) When the trap is called, the caller must pass as an argument R0. 
; R0 must contain an address in User Data Memory where the string that will be read from the keyboard will be stored
; 3) The trap should check to ensure R0 contains a valid address in USER data memory.
; 4) The TRAP must then read in characters one by one. 
; As it reads in each character, it must store them in data memory consecutively starting from the address passed in by the caller. 
; Once the “enter” key is pressed, which is HEX x0A, the trap must “NULL” terminate the string in data memory and 
; return the length of the string (without including the NULL or enter) to the caller.
; 5) The TRAP should return the length of the string in R1.
;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
TRAP_GETS

TG_WHILE
TG_IF 
  CONST R3, x00         ; smallest address in user data memory
  HICONST R3, x20       ; smallest address in user data memory
  CMP R0, R3            ; if R0 >= x2000
  BRn TG_ELSE            ; if not valid, goto ELSE

  CONST R3, xFF         ; largest address in user data memory
  HICONST R3, x7F       ; largest address in user data memory 
  CMP R0, R3            ; A <= x7FFF
  BRp TG_ELSE           ; if not valid, goto ELSE

TG_STATUS
  LC R2, OS_KBSR_ADDR   ; R2 = address of keyboard status reg
  LDR R2, R2, #0        ; R2 = value of keyboard status reg
  BRzp TG_STATUS        ; if R4[15]=1, data is waiting!
                           ; else, loop and check again...

  ; reaching here, means data is waiting in keyboard data reg

  LC R2, OS_KBDR_ADDR   ; R2 = address of keyboard data reg
  LDR R2, R2, #0        ; R2 = value of keyboard data reg

  CMPI R2, x0A          ; sets NZP, check if "enter"
  BRz TG_END_WHILE      ; tests NZP, if == enter, goto END

  STR R2, R0, #0        ; store readIn R2 into data memory and replace the origianl #
  ADD R0, R0, #1        ; move to the next data memory address
  ADD R1, R1, #1        ; count the length for output
  BRnzp TG_WHILE        ; continue while loop, to load the next ASCII char

  TG_END_WHILE
  CONST R4, #0          ; set NULL terminate
  STR R4, R0, #0        ; add NULL to the string in data memory

TG_ELSE
  RTI		                ; PC = R7 ; PSR[15]=0

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_PUTS   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Put a string of characters out to ASCII display
;;; Inputs           - R0 = Address for first character
;;; Outputs          - none

;;;;;;;;;;;;;;;;;;;;;;;;;;;
; This purpose of this function is to output a NULL terminated string to the ASCII display.
; When TRAP_PUTS is called register R0 should contain the address of the first character of the string where the caller has stored the string in DATA memory. 
; R0 is considered the argument to the TRAP.
; This trap will not return anything to the caller
; The last character in the string should be zero

; Pseudocode for this TRAP:
; TRAP_PUTS (R0) {
; 	check the value of R0, is it a valid address in User Data memory?
; 		if it is, continue, if not, return to caller
; 	load the ASCII character from the address held in R0
; 	while (ASCII character != NULL) {
; 		check status register for ASCII Display
; 			if it’s free, continue, if not, keep checking until its free
; 		write ASCII character to ASCII Display’s data register
; 		load the next ASCII character from data memory
; 	} return to caller
; }
;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
TRAP_PUTS

TP_IF 
  CONST R3, x00         ; smallest address in user data memory
  HICONST R3, x20       ; smallest address in user data memory
  CMP R0, R3            ; if R0 >= x2000
  BRn TP_ELSE             ; if not valid, goto ELSE

  CONST R3, xFF         ; largest address in user data memory
  HICONST R3, x7F       ; largest address in user data memory 
  CMP R0, R3            ; A <= x7FFF
  BRp TP_ELSE              ; if not valid, goto ELSE

;   LDR R2, R0, #0        ; load the ASCII character from the address held in R0

TP_WHILE 
  LDR R2, R0, #0        ; load the ASCII character from the address held in R0
  CMPI R2, #0           ; is ASCII character NULL? 
  BRz TP_END_WHILE         ; if null, goto END_WHILE

TP_STATUS
  LC R1, OS_ADSR_ADDR   ; R1 = address of display status reg
  LDR R1, R1, #0    	  ; R1 = value of display status reg
  BRzp TP_STATUS       	; if R1[15]=1, display is ready to write
                        ; else, loop and check again...

  ; reaching here, means console is ready to display next char

  LC R1, OS_ADDR_ADDR 	; R1 = address of display data reg
  STR R2, R1, #0    	  ; R1 = value of keyboard data reg (R0)
  
  ADD R0, R0, #1        ; Move onto the next ASCII char from data memory
;   LDR R2, R0, #0        ; load the ASCII character from the address held in R0  
  BRnzp TP_WHILE        ; continue while loop, to load the next ASCII char

TP_ELSE
TP_END_WHILE
  RTI			              ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function:
;;; Inputs           - R0 = time to wait in milliseconds
;;; Outputs          - none

.CODE
TRAP_TIMER
  LC R1, OS_TIR_ADDR 	; R1 = address of timer interval reg
  STR R0, R1, #0    	; Store R0 in timer interval register

COUNT
  LC R1, OS_TSR_ADDR  	; Save timer status register in R1
  LDR R1, R1, #0    	; Load the contents of TSR in R1
  BRzp COUNT    	; If R1[15]=1, timer has gone off!

  ; reaching this line means we've finished counting R0

  RTI       		; PC = R7 ; PSR[15]=0



;;;;;;;;;;;;;;;;;;;;;;;   TRAP_GETC_TIMER   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Get a single character from keyboard
;;; Inputs           - R0 = time to wait
;;; Outputs          - R0 = ASCII character from keyboard (or NULL)

.CODE
TRAP_GETC_TIMER

  ;;
  ;; TO DO: complete this trap
  ;;

  RTI                  ; PC = R7 ; PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_RESET_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; In double-buffered video mode, resets the video display
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE	
TRAP_RESET_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #1
  STR R5, R4, #0
  RTI


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; TRAP_BLT_VMEM ;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TRAP_BLT_VMEM - In double-buffered video mode, copies the contents
;;; of video memory to the video display.
;;; DO NOT MODIFY this trap, it's for future HWs
;;; Inputs - none
;;; Outputs - none
.CODE
TRAP_BLT_VMEM
  LC R4, OS_VDCR_ADDR
  CONST R5, #2
  STR R5, R4, #0
  RTI


;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_PIXEL   ;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: Draw point on video display
;;; Inputs           - R0 = row to draw on (y)
;;;                  - R1 = column to draw on (x)
;;;                  - R2 = color to draw with
;;; Outputs          - none

.CODE
TRAP_DRAW_PIXEL
  LEA R3, OS_VIDEO_MEM       ; R3=start address of video memory
  LC  R4, OS_VIDEO_NUM_COLS  ; R4=number of columns

  CMPIU R1, #0    	         ; Checks if x coord from input is > 0
  BRn END_PIXEL
  CMPIU R1, #127    	     ; Checks if x coord from input is < 127
  BRp END_PIXEL
  CMPIU R0, #0    	         ; Checks if y coord from input is > 0
  BRn END_PIXEL
  CMPIU R0, #123    	     ; Checks if y coord from input is < 123
  BRp END_PIXEL

  MUL R4, R0, R4      	     ; R4= (row * NUM_COLS)
  ADD R4, R4, R1      	     ; R4= (row * NUM_COLS) + col
  ADD R4, R4, R3      	     ; Add the offset to the start of video memory
  STR R2, R4, #0      	     ; Fill in the pixel with color from user (R2)

END_PIXEL
  RTI       		         ; PC = R7 ; PSR[15]=0
  

;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_RECT   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: draw a rectangle whose location and dimensions will be set by the user
;;;            The color of the rectangle will also be an argument passed in by the caller
;;; Inputs          R0 – “x coordinate” of upper-left corner of the rectangle.
;;;                 R1 – “y coordinate” of upper-left corner of the rectangle.
;;;                 R2 – length of the rectangle (in number of pixels across the display).
;;;                 R3 – width of the side of the rectangle (in number of pixels down the display).
;;;                 R4 – the color of the rectangle
;;; Outputs   draw rectangle in the display

;;;;;;;;;;;;;;;;;;;;;;;;;;;Boundary Checking
;;; 1)The trap should check to see if the length/width are valid from the starting location of the box
;;; 	If invalid, return without drawing the box
;;;;;;;;;;;;;;;;;;;;;;;;;;;

.CODE
TRAP_DRAW_RECT

  ADD R5, R2, R0            ; total length
  ADD R5, R5, #-1           ; total length -1 becuase pixel is 0-indexed
  CMPIU R5, #0    	        ; is length valid?
  BRnz END_CHECK            ; if <= 0, not valid
  CMPIU R5, #127    	      ; is length valid?
  BRp END_CHECK             ; if > 127, not valid
  
  ADD R5, R3, R1            ; total width
  ADD R5, R5, #-1           ; total width -1 becuase pixel is 0-indexed
  CMPIU R5, #0    	        ; is width valid?
  BRnz END_CHECK            ; if <= 0, not valid
  CMPIU R5, #123    	      ; width
  BRp END_CHECK             ; if > 123, not valid

; STORE
  LEA R5, OS_GLOBALS_MEM    ; R5 = address of os global mem
  STR R0, R5, #0            ; store R0-X into os global mem
  ADD R5, R5, #1            ; go to the next os global mem addr
  STR R1, R5, #0            ; store R1-Y into os global mem
  ADD R5, R5, #1            ; go to the next os global mem addr
  STR R2, R5, #0            ; store R2-L into os global mem
  ADD R5, R5, #1            ; repeat 
  STR R3, R5, #0            ; store R3-W
  ADD R5, R5, #1            ; repeat
  STR R4, R5, #0            ; store R4-C
  ADD R5, R5, #1            ; repeat
  STR R7, R5, #0            ; store R7-PC

  ADD R5, R5, #1            ; go to the next os global mem addr

  LEA R0, OS_VIDEO_MEM      ; R0 = address of video memory
  STR R0, R5, #0            ; store R0-os video mem into os global mem
  ADD R5, R5, #1            ; repeat
  LC R0, OS_VIDEO_NUM_ROWS  ; value of number of rows #124
  STR R0, R5, #0            ; store R0-num rows into os global mem
  ADD R5, R5, #1            ; repeat
  LC R0, OS_VIDEO_NUM_COLS  ; value of number of columns #128
  STR R0, R5, #0            ; store R0-num cols into os global mem
  ADD R5, R5, #1            ; repeat
  
; LOAD    
  LC R0, OS_GLOBALS_MEM_Y                 ; load Y from os global mem
  LDR R0, R0, #0                          ; restore R0-Y
  LC R1, OS_GLOBALS_MEM_COL               ; number of columns from os global mem
  LDR R1, R1, #0                          ; restore R1-COL
  LC R2, OS_GLOBALS_MEM_X                 ; load X from os global mem
  LDR R2, R2, #0                          ; restore R2-X
  LC R3, OS_GLOBALS_MEM_V                 ; video memory FROM os global mem
  LDR R3, R3, #0                          ; restore R2-MEM
  LC R4, OS_GLOBALS_MEM_C                 ; load C from os global mem
  LDR R4, R4, #0                          ; restore R4-C
  
  LC R6, OS_GLOBALS_MEM_L                 ; load L from os global mem
  LDR R6, R6, #0                          ; restore R6-L
  ADD R6, R6, R2                          ; total length
  ADD R6, R6, #-1                         ; total length -1 becuase pixel is 0-indexed
  
  LC R7, OS_GLOBALS_MEM_W                 ; load W from os global mem
  LDR R7, R7, #0                          ; restore R7-W
  ADD R7, R7, R0                          ; total width
  ADD R7, R7, #-1                         ; total width -1 becuase pixel is 0-indexed
  
LOOP_L     
  MUL R5, R0, R1      	                  ; from TRAP_DRAW_PIXEL
  ADD R5, R5, R2      	                  ; from TRAP_DRAW_PIXEL
  ADD R5, R5, R3      	                  ; from TRAP_DRAW_PIXEL
  STR R4, R5, #0      	                  ; from TRAP_DRAW_PIXEL to R4

  ADD R2, R2, #1                          ; continue to the next line
  CMPU R6, R2                             ; Check if needs continue
  BRzp LOOP_L                             ; if not, continue with the next row

  LC R2, OS_GLOBALS_MEM_X                 ; reset R2
  LDR R2, R2, #0                          ; reset R2  
  ADD R0, R0, #1                          ; continue to the next line
  CMPU R7, R0                             ; Check if needs continue
  BRzp LOOP_L                             ; return back loop

  LC R7, OS_GLOBALS_MEM_R7                ; load R7-PC
  LDR R7, R7, #0                          ; load R7-PC
  
  END_CHECK
  RTI                                     ; end program, PC = R7 , PSR[15]=0


;;;;;;;;;;;;;;;;;;;;;;;;;;;   TRAP_DRAW_SPRITE   ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Function: EDIT ME!
;;; Inputs    EDIT ME!
;;; Outputs   EDIT ME!

; .CODE
; TRAP_DRAW_SPRITE

  ;;
  ;; TO DO: complete this trap
  ;;

;   RTI


;; TO DO: Add TRAPs in HW