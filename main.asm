;
; Snake.asm
;
; Created: 2018-05-02 14:32:57
; Author : Hampus Österlund, Rickardh Forslund
;

.DEF rApple = r2
.DEF rTemp = r16
.DEF rRandomX = r17
.DEF rRandomY = r18
.DEF rTime = r19
.DEF rJoyX = r20
.DEF rJoyY = r21
.DEF rCurrentTime = r22
.DEF rDirection = r23

//Time for timer0
.EQU STARTTIME = 3
.EQU DEADZONEHIGH = 0x89
.EQU DEADZONELOW = 0x75

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

	// Ledjoy A/D setup
	lds rTemp, ADMUX
	ori rTemp, 0b01000000
	sts ADMUX, rTemp

	lds rTemp, ADCSRA
	ori rTemp, 0b10000111
	sts ADCSRA, rTemp

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
	
	//Initialize random byte to rRandom

	rjmp main

timer0:
	//Timer0 has been overflowed, start ISR.
	//This ISR is where we have put our game code.

	//Compare with rTime register.
	cp rTime, rCurrentTime
	brlt timer0_continue
	inc rCurrentTime
	reti

	timer0_continue:
		clr rCurrentTime

		//Push rTemp and SREG to stack to be able to restore them once we exit the interrupt.
		push rTemp
		in rTemp, SREG
		push rTemp

		//GAME LOGIC HERE

		//Initiating Z-Pointer to matrix.
		ldi ZH, HIGH(matrix)
		ldi ZL, LOW(matrix)

		create_apple:
		//Creates a position for the apple.


		//Pop SREG and rTemp from stack and restore them.
		pop rTemp
		out SREG, rTemp
		pop rTemp
		reti

main:
	rcall input_x
	rcall input_y
<<<<<<< HEAD
=======
	rcall move_direction
	rcall screen_update
>>>>>>> 88a6e77905c666b3b128dbf789b1e07c9f53fc1f
	rcall random_generate
	rcall screen_update
	rjmp main

input_y:
	// Y input
	lds rTemp, ADMUX
	cbr rTemp, 1
	ori rTemp, 0b00100100
	sts ADMUX, rTemp

	lds rTemp, ADCSRA
	ori rTemp, (1<<ADSC)
	sts ADCSRA, rTemp

	ad_doneY: 
		lds rTemp, ADCSRA
		sbrc rTemp, 6
		jmp ad_doneY
	lds rJoyY, ADCH
	ret

input_x:
	lds rTemp, ADMUX
	ori rTemp, 0b00100101
	sts ADMUX, rTemp

	lds rTemp, ADCSRA
	ori rTemp, (1<<ADSC)
	sts ADCSRA, rTemp

	ad_doneX: 
		lds rTemp, ADCSRA
		sbrc rTemp, 6
		jmp ad_doneX
	lds rJoyX, ADCH
	ret

move_direction:
	cpi rJoyY, 197
	brsh y_greater

	cpi rJoyY, 62
	brlo y_lower

	cpi rJoyX, 137
	brsh x_greater

	cpi rJoyX, 100
	brlo x_lower

	ret

	// Joystick up
	y_greater:
		lds rDirection, 0x1
		ret
	// Joystick down
	y_lower:
		lds rDirection, 0x2
		ret
	// Joystick left
	x_greater:
		lds rDirection, 0x3
		ret
	// Joystick right
	x_lower:
		lds rDirection, 0x4
		ret

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

random_generate:
	//Generate a random X value.
	add rRandomX, rJoyX
	subi rRandomX, -5

	//Generate a random Y value.
	add rRandomY, rJoyY
	subi rRandomY, -5

	ret