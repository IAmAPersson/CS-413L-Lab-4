.data
.balign 4
invarr:
gum:
	.word 2
peanuts:
	.word 2
crackers:
	.word 2
mandms:
	.word 2
delayLong:
	.word 5000
welcome:
	.asciz "Welcome to Phil's Vending Machine!\n"
costs:
	.asciz "Costs: Gum is $0.50, Peanuts is $0.55, Cheese Crackers is $0.65, and M&Ms are $1.00.\n"
select:
	.asciz "Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):\n"
selectdone:
	.asciz "You selected %s. Is this correct? (Y/N)\n"
gumstr:
	.asciz "Gum"
peanutstr:
	.asciz "Peanuts"
crackerstr:
	.asciz "Cheese Crackers"
mandmstr:
	.asciz "M&Ms"
moneyprompt:
	.asciz "Enter at least %d cents for selection.\n"
moneyinp:
	.asciz "Dimes (D), Quarters (Q), and Dollar Bills (B):\n"
moneyprog:
	.asciz "%d cents remaining...\n"
moneydone:
	.asciz "Enough money entered.\n"
disp:
	.asciz "%s has been dispensed.\n"
change:
	.asciz "Change of %d cents has been returned.\n"
perc:
	.asciz " %c"
wrongitem:
	.asciz "You inputted a key for an invalid item. Returning to selection...\n"
inventory:
	.asciz "Current Inventory:\nGum: %d\nPeanuts: %d\nCheese Crackers: %d\nM&Ms: %d\n"
empty:
	.asciz "We're sorry, we are out of %s!\n"
gpioerrstr:
	.asciz "There has been a problem with the GPIO LEDs!\n"

.text
.global main
.global printf
.global scanf
.global abs
.global wiringPiSetup
.global digitalWrite
.global delay

.equ gumcost, 50
.equ peanutcost, 55
.equ crackercost, 65
.equ mandmcost, 100
.equ red, 5
.equ yellow, 4
.equ green, 3
.equ blue, 2
.equ delayMs, 1000
.equ OUTPUT, 1

main:
gpiosetup:
	BL wiringPiSetup @attempt to set up wiringPi
	CMP R0, #-1
	BEQ gpioerr @if failed, exit the program
	MOV R0, #blue
	MOV R1, #OUTPUT
	BL pinMode
	MOV R0, #green
	MOV R1, #OUTPUT
	BL pinMode
	MOV R0, #yellow
	MOV R1, #OUTPUT
	BL pinMode
	MOV R0, #red
	MOV R1, #OUTPUT
	BL pinMode

	MOV R0, #red
	MOV R1, #1
	BL digitalWrite
	LDR R0, =delayLong
	LDR R0, [R0]
	BL delay
	MOV R0, #red
	MOV R1, #0
	BL digitalWrite

beginoutp:
	PUSH { FP }
	MOV FP, SP
	LDR R0, =welcome
	BL printf
	LDR R0, =costs
	BL printf @output the welcome message and costs of each item
	SUB SP, #4 @allocate a word for reading in character input
mainloop: @primary loop, loops until inventory is empty
	LDR R0, =invarr @load the inventory array
	LDR R1, [R0]
	CMP R1, #0
	LDREQ R1, [R0, #4]
	CMPEQ R1, #0
	LDREQ R1, [R0, #8]
	CMPEQ R1, #0
	LDREQ R1, [R0, #12]
	CMPEQ R1, #0 @compare each element to 0
	BEQ ret @if inventory is empty, exit program
	LDR R0, =select
	BL printf @print the selection menu
	MOV R1, FP
	SUB R1, #4 @get address of TOS
	LDR R0, =perc
	BL scanf @scanf the item to choose

cmpsec:
	MOV R0, FP
	SUB R0, #4
	MOV R1, #0
	LDRB R1, [R0]
	MOV R0, R1 @load the inputted character
	MOV R4, #0 @move in a 0, will be overwritten iff a valid input has been given
	CMP R0, #'G'
	MOVEQ R4, #gumcost
	LDREQ R5, =gumstr
	MOVEQ R6, #0
	MOVEQ R7, #red @if inputted G, set up registers for gum
	CMP R0, #'P'
	MOVEQ R4, #peanutcost
	LDREQ R5, =peanutstr
	MOVEQ R6, #4
	MOVEQ R7, #yellow @if inputted P, set up registers for peanuts
	CMP R0, #'C'
	MOVEQ R4, #crackercost
	LDREQ R5, =crackerstr
	MOVEQ R6, #8
	MOVEQ R7, #green @if inputted C, set up registers for crackers
	CMP R0, #'M'
	MOVEQ R4, #mandmcost
	LDREQ R5, =mandmstr
	MOVEQ R6, #12
	MOVEQ R7, #blue @if inputted M, set up registers for M&Ms
	CMP R0, #'i'
	BLEQ dispinv @if inputted i, display inventory and branch back to the mainloop
	BEQ mainloop
	CMP R4, #0
	BEQ err @if no registers have been changed, branch to the error handling code
	LDR R1, =invarr
	LDR R0, [R1, R6]
	CMP R0, #0
	BEQ emptyselec @if selected inventory item is out of stock, branch to the empty selection handling code

verifyinp:
	LDR R0, =selectdone
	MOV R1, R5
	BL printf @prompt if input is correct
	MOV R1, FP
	SUB R1, #4
	LDR R0, =perc
	BL scanf @get character input
	MOV R0, FP
	SUB R0, #4
	MOV R1, #0
	LDRB R1, [R0]
	MOV R0, R1
	CMP R0, #'Y' @compare character input to Y
	BNE mainloop @if not Y, go back to the main loop

countcoins:
	LDR R0, =moneyprompt
	MOV R1, R4
	BL printf @prompt how much money is owed
	LDR R0, =moneyinp
	BL printf @show what kinds of monetary inputs are valid
countcoinsloop: @count coins loop, loops until all money has been entered
	LDR R0, =perc
	MOV R1, FP
	SUB R1, #4
	BL scanf @scanf a char
	MOV R0, FP
	SUB R0, #4
	MOV R1, #0
	LDRB R1, [R0]
	MOV R0, R1
	CMP R0, #'D'
	SUBEQ R4, #10 @if inputted D, subtract 10 from owed money
	CMP R0, #'Q'
	SUBEQ R4, #25 @if inputted Q, subtract 25 from owed money
	CMP R0, #'B'
	SUBEQ R4, #100 @if inputted B, subtract 100 from owed money
	CMP R4, #0
	BLE moneydonesec @if payed money is greater than or equal to amount owed, branch to the money done section
	MOV R1, R4
	LDR R0, =moneyprog
	BL printf @print how much money is still owed
	B countcoinsloop @branch back to the loop

moneydonesec:
	LDR R0, =moneydone
	BL printf @print that you're done inputting money
	MOV R0, R4
	BL abs @the current owed money is negative at this point, get the absolute value so we know what the change should be
	MOV R4, R0
	LDR R0, =disp
	MOV R1, R5
	BL printf @print that the item has been dispensed
	LDR R0, =change
	MOV R1, R4
	BL printf @print the change returned
	LDR R1, =invarr
	LDR R0, [R1, R6]
	SUB R0, #1
	STR R0, [R1, R6] @subtract one from the inventory

handleLED:
	MOV R0, R7
	MOV R1, #1
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #0
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #1
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #0
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #1
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #0
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	MOV R0, R7
	MOV R1, #1
	BL digitalWrite
	LDR R0, =delayLong
	LDR R0, [R0]
	BL delay
	MOV R0, R7
	MOV R1, #0
	BL digitalWrite
	MOV R0, #delayMs
	BL delay
	B mainloop @branch back to the main loop

err:
	LDR R0, =wrongitem
	BL printf @print that a wrong item has been entered
	B mainloop @branch to the main loop

emptyselec:
	LDR R0, =empty
	MOV R1, R5
	BL printf @print that %s item is out of stock
	B mainloop @branch to the main loop

ret:
	MOV R0, #red
	MOV R1, #1
	BL digitalWrite
	LDR R0, =delayLong
	LDR R0, [R0]
	BL delay
	MOV R0, #red
	MOV R1, #0
	BL digitalWrite

	ADD SP, #4 @free the word on stack for reading in char input
	POP { FP } @pop frame pointer
	MOV R7, #1
	SVC 0 @exit program safely

dispinv:
	PUSH { LR }
	STMFD SP, { FP }^ @create stack frame, also storing CCR
	SUB SP, #8 @adjust stack pointer to accomodate for STMFD
	MOV FP, SP @create stack frame
	LDR R0, =inventory
	LDR R1, =gum
	LDR R1, [R1]
	LDR R2, =peanuts
	LDR R2, [R2]
	LDR R3, =crackers
	LDR R3, [R3]
	LDR R4, =mandms
	LDR R4, [R4]
	PUSH { R4 }
	BL printf @print current inventory
	ADD SP, #4 @free argument off stack
	LDMFD SP, { FP }^ @pop off FP and CCR
	ADD SP, #8 @adjust stack pointer to accomodate for LDMFD
	POP { PC } @return

gpioerr:
	LDR R0, =gpioerrstr
	BL printf
	B ret

@Welcome to Phil's Vending Machine!
@Costs: Gum is $0.50, Peanuts is $0.55, Cheese Crackers is $0.65, and M&Ms are $1.00.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@G
@You selected Gum. Is this correct? (Y/N)
@Y
@Enter at least 50 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Gum has been dispensed.
@Change of 50 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@i
@Current Inventory:
@Gum: 1
@Peanuts: 2
@Cheese Crackers: 2
@M&Ms: 2
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@P
@You selected Peanuts. Is this correct? (Y/N)
@Y
@Enter at least 55 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Peanuts has been dispensed.
@Change of 45 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@C
@You selected Cheese Crackers. Is this correct? (Y/N)
@Y
@Enter at least 65 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Cheese Crackers has been dispensed.
@Change of 35 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@M
@You selected M&Ms. Is this correct? (Y/N)
@Y
@Enter at least 100 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@M&Ms has been dispensed.
@Change of 0 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@i
@Current Inventory:
@Gum: 1
@Peanuts: 1
@Cheese Crackers: 1
@M&Ms: 1
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@G
@You selected Gum. Is this correct? (Y/N)
@Y
@Enter at least 50 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Gum has been dispensed.
@Change of 50 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@G
@We're sorry, we are out of Gum!
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@P
@You selected Peanuts. Is this correct? (Y/N)
@Y
@Enter at least 55 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Peanuts has been dispensed.
@Change of 45 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@C
@You selected Cheese Crackers. Is this correct? (Y/N)
@Y
@Enter at least 65 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@Cheese Crackers has been dispensed.
@Change of 35 cents has been returned.
@Enter item selection: Gum (G), Peanuts (P), Cheese Crackers (C), or M&Ms (M):
@M
@You selected M&Ms. Is this correct? (Y/N)
@Y
@Enter at least 100 cents for selection.
@Dimes (D), Quarters (Q), and Dollar Bills (B):
@B
@Enough money entered.
@M&Ms has been dispensed.
@Change of 0 cents has been returned.