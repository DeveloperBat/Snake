;
; Snake.asm
;
; Created: 2018-05-02 14:32:57
; Author : Hampus Österlund, Rickardh Forslund
;

.DEF rTemp = r16
.DEF rDirection = r23

.DEF rTime = r18
.DEF rCurrentTime = r19

//Time for timer0
.EQU STARTTIME = 3

.DSEG
matrix:	.BYTE 8

.CSEG
//Interrupt vector table.
.ORG 0x0000	//Reset vector.
	rjmp reset
.ORG 0x0020 //Timer0 overflow
	rjmp timer0
.ORG INT_VECTORS_SIZE

reset:
    //Set stackpointer to highest memory address.
    ldi rTemp, HIGH(RAMEND)
    out SPH, rTemp
    ldi rTemp, LOW(RAMEND)
    out SPL, rTemp

	//Set rTime
	ldi rTime, STARTTIME
	//Set rCurrentTime
	ldi rCurrentTime, 0
	//Prescaling = 1024
	ldi rTemp, 5
	out TCCR0B, rTemp
	//Global interrupt enable
	sei
	//Enable Overflow Interrupt
	ldi rTemp, 1
	sts TIMSK0, rTemp
	//Set timer counter to 0
	ldi rTemp, 0
	out TCNT0, rTemp

	//Set ports C,D och B on LED-JOY to output.
	ldi rTemp, 0b00001111
	out DDRC, rTemp
	ldi rTemp, 0b11111100
	out DDRD, rTemp
	ldi rTemp, 0b00111111
	out DDRB, rTemp

	//Make a pointer to Matrix and store it in Y.
	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)

	//Save some good stuff to Matrix
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000000
	st Y, rTemp

	rjmp main

timer0:
	//Timer0 has been overflowed, start ISR.

	//Compare with rTime register.
	cp rTime, rCurrentTime
	brlt timer0_continue
	inc rCurrentTime
	reti

	timer0_continue:
		clr rCurrentTime

		//Push rTemp and SREG to stack.
		push rTemp
		in rTemp, SREG
		push rTemp

		//Execute code
		ldi ZH, HIGH(matrix)
		ldi ZL, LOW(matrix)

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		ld rTemp, Z
		inc rTemp
		st Z+, rTemp

		rcall screen_update

		//Pop SREG and rTemp from stack.
		pop rTemp
		out SREG, rTemp
		pop rTemp
		reti

main:
	rcall screen_update
	rjmp main

screen_update:
	//Updates the screen with data from the 8 byte Matrix.
	//
	//The instructions: Resets columns, activates row, activates columns and finally deactivates the row.
	//Calling light columns several times to increase the time they get energized. (Increased light level)

	//Reset pointer to Matrix.
	ldi YH, HIGH(matrix)
	ldi YL, LOW(matrix)

	//Matrix 1
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTC, 0
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTC, 0
	
	//Matrix 2
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTC, 1
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTC, 1

	//Matrix 3
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTC, 2
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTC, 2

	//Matrix 4
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTC, 3
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTC, 3

	//Matrix 5
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTD, 2
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTD, 2

	//Matrix 6
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTD, 3
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTD, 3

	//Matrix 7
	ld rTemp, Y+
	rcall reset_columns
	sbi PORTD, 4
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	cbi PORTD, 4

	//Matrix 8
	ld rTemp, Y
	rcall reset_columns
	sbi PORTD, 5
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
	rcall light_columns
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
	ret

light_columns:

	//Light 1
	sbrc rTemp, 0
	sbi PORTD, 6
	sbrs rTemp, 0
	cbi PORTD, 6

	//Light 2 if set.
	sbrc rTemp, 1
	sbi PORTD, 7
	sbrs rTemp, 1
	cbi PORTD, 7

	//Light 3 if set.
	sbrc rTemp, 2
	sbi PORTB, 0
	sbrs rTemp, 2
	cbi PORTB, 0

	//Light 4 if set.
	sbrc rTemp, 3
	sbi PORTB, 1
	sbrs rTemp, 3
	cbi PORTB, 1

	//Light 5 if set.
	sbrc rTemp, 4
	sbi PORTB, 2
	sbrs rTemp, 4
	cbi PORTB, 2

	//Light 6 if set.
	sbrc rTemp, 5
	sbi PORTB, 3
	sbrs rTemp, 5
	cbi PORTB, 3

	//Light 7 if set.
	sbrc rTemp, 6
	sbi PORTB, 4
	sbrs rTemp, 6
	cbi PORTB, 4

	//Light 8 if set.
	sbrc rTemp, 7
	sbi PORTB, 5
	sbrs rTemp, 7
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