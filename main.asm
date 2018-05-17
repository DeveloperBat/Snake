;
; Snake.asm
;
; Created: 2018-05-02 14:32:57
; Author : Hampus Österlund, Rickardh Forslund
;

.DEF rTemp = r16
.DEF rDirection = r23

.DEF rRow = r17

.DSEG
matrix:	.BYTE 8

.CSEG
// Interrupt vector table.
.ORG 0x0000
	jmp init // Reset vector.
.ORG INT_VECTORS_SIZE

init:
    // Set stackpointer to highest memory address.
    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp

	//Sätt portarna C,D och B på LED-JOY till outputläge.
	ldi rTemp, 0b00001111
	out DDRC, rTemp
	ldi rTemp, 0b11111100
	out DDRD, rTemp
	ldi rTemp, 0b00111111
	out DDRB, rTemp

	//Clear I/O ports.
	ldi rTemp, 0b00000000
	out PORTC, rTemp
	ldi rTemp, 0b00000000
	out PORTD, rTemp
	ldi rTemp, 0b00000000
	out PORTB, rTemp

	//Make a pointer to Matrix and store it in Y.
	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)

	ldi rTemp, 0b00111100
	st Y+, rTemp
	ldi rTemp, 0b01000010
	st Y+, rTemp
	ldi rTemp, 0b10100101
	st Y+, rTemp
	ldi rTemp, 0b10100101
	st Y+, rTemp
	ldi rTemp, 0b10100101
	st Y+, rTemp
	ldi rTemp, 0b10011001
	st Y+, rTemp
	ldi rTemp, 0b01000010
	st Y+, rTemp
	ldi rTemp, 0b00111100
	st Y, rTemp

main:
	call screen_update
	jmp main

screen_update:
	
	//Reset pointer to Matrix.
	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)

	//Matrix 1
	ld rRow, Y+
	call reset_columns
	sbi PORTC, 0
	call light_columns
	cbi PORTC, 0
	
	//Matrix 2
	ld rRow, Y+
	call reset_columns
	sbi PORTC, 1
	call light_columns
	cbi PORTC, 1

	//Matrix 3
	ld rRow, Y+
	call reset_columns
	sbi PORTC, 2
	call light_columns
	cbi PORTC, 2

	//Matrix 4
	ld rRow, Y+
	call reset_columns
	sbi PORTC, 3
	call light_columns
	cbi PORTC, 3

	//Matrix 5
	ld rRow, Y+
	call reset_columns
	sbi PORTD, 2
	call light_columns
	cbi PORTD, 2

	//Matrix 6
	ld rRow, Y+
	call reset_columns
	sbi PORTD, 3
	call light_columns
	cbi PORTD, 3

	//Matrix 7
	ld rRow, Y+
	call reset_columns
	sbi PORTD, 4
	call light_columns
	cbi PORTD, 4

	//Matrix 8
	ld rRow, Y
	call reset_columns
	sbi PORTD, 5
	call light_columns
	cbi PORTD, 5

	ret
reset_columns:
	cbi PORTD, 6
	cbi PORTD, 7
	cbi PORTB, 0
	cbi PORTB, 1
	cbi PORTB, 2
	cbi PORTB, 3
	cbi PORTB, 4
	cbi PORTB, 5

light_columns:

	//Light 1
	sbrc rRow, 0
	sbi PORTD, 6
	sbrs rRow, 0
	cbi PORTD, 6

	//Light 2 if set.
	sbrc rRow, 1
	sbi PORTD, 7
	sbrs rRow, 1
	cbi PORTD, 7

	//Light 3 if set.
	sbrc rRow, 2
	sbi PORTB, 0
	sbrs rRow, 2
	cbi PORTB, 0

	//Light 4 if set.
	sbrc rRow, 3
	sbi PORTB, 1
	sbrs rRow, 3
	cbi PORTB, 1

	//Light 5 if set.
	sbrc rRow, 4
	sbi PORTB, 2
	sbrs rRow, 4
	cbi PORTB, 2

	//Light 6 if set.
	sbrc rRow, 5
	sbi PORTB, 3
	sbrs rRow, 5
	cbi PORTB, 3

	//Light 7 if set.
	sbrc rRow, 6
	sbi PORTB, 4
	sbrs rRow, 6
	cbi PORTB, 4

	//Light 8 if set.
	sbrc rRow, 7
	sbi PORTB, 5
	sbrs rRow, 7
	cbi PORTB, 5

	ret






























/*light_one:
	ldi	rTemp, 0b00000001
	out PORTC, rTemp
	ldi	rTemp, 0b01000000
	out PORTD, rTemp*/

/*light_row:
	ldi rTemp, 0b00000001
	out PORTC, rTemp
	ldi rTemp, 0b11000000
	out PORTD, rTemp
	ldi rTemp, 0b00111111
	out PORTB, rTemp*/

/*light_all:
	//Light row one
	ldi rTemp, 0b00000001
	out PORTC, rTemp
	ldi rTemp, 0b11000000
	out PORTD, rTemp
	ldi rTemp, 0b00111111
	out PORTB, rTemp

	ldi rTemp, 0b00000010
	out PORTC, rTemp

	//light row three
	ldi rTemp, 0b00000100
	out PORTC, rTemp

	//light row 4
	ldi rTemp, 0b00001000
	out PORTC, rTemp

	//light row 5
	ldi rTemp, 0b00000000
	out PORTC, rTemp
	ldi rTemp, 0b11000100
	out PORTD, rTemp

	//light row 6
	ldi rTemp, 0b11001000
	out PORTD, rTemp

	//light row 7
	ldi rTemp, 0b11010000
	out PORTD, rTemp

	//light row 8
	ldi rTemp, 0b11100000
	out PORTD, rTemp

	jmp light_all*/


//GAME LOGIC