;
; Snake.asm
;
; Created: 2018-05-02 14:32:57
; Author : Hampus Österlund, Rickardh Forslund
;

.DEF rRandomXY = r2
.DEF rAppleXY = r3
.DEF rHead = r4

.DEF rTemp = r16
.DEF rTemp2 = r17
.DEF rJoyX = r18
.DEF rJoyY = r19
.DEF rTime = r20
.DEF rCurrentTime = r21
.DEF rDirection = r22
.DEF rLength = r23
.DEF rTemp3 = r24
.DEF rTemp4 = r25


//Time for timer0
.EQU STARTTIME = 10
.EQU MAXLENGTH = 15

.DSEG
matrix:	.BYTE 8
snake: .BYTE MAXLENGTH

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

	//Initiate stuff.
	ldi rDirection, 0b00000100
	rcall clear_matrix
	rcall snake_create
	rcall random
	rcall apple_create

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
		//USE Z REGISTER AS POINTER TO MATRIX, IF USED IN GAME UPDATE TO PREVENT ERRORS.

		game_update:
			rcall clear_matrix
			rcall apple_check
			rcall snake_check
			rcall snake_move
			rcall apple_update
			rcall snake_render

		//Pop SREG and rTemp from stack and restore them.
		pop rTemp
		out SREG, rTemp
		pop rTemp
		reti

main:
	rcall input_x
	rcall input_y
	rcall random
	rcall move_direction
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
		rjmp ad_doneY
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
		rjmp ad_doneX
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

	move_done:

	ret

	// Joystick up
	y_greater:
		cpi rDirection, 0b00000010
		breq move_done
		ldi rDirection, 0b00000001
		ret
	// Joystick down
	y_lower:
		cpi rDirection, 0b00000001
		breq move_done
		ldi rDirection, 0b00000010
		ret
	// Joystick left
	x_greater:
		cpi rDirection, 0b00000100
		breq move_done
		ldi rDirection, 0b00000011
		ret
	// Joystick right
	x_lower:
		cpi rDirection, 0b00000011
		breq move_done
		ldi rDirection, 0b00000100
		ret

screen_update:
	//Updates the screen with data from the 8 byte Matrix.
	//
	//The instructions: Resets columns, activates row, activates columns and finally deactivates the row.
	//rcalling light columns several times to increase the time they get energized. (Increased light level)

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

random:
	//Generate a random X value.
	add rRandomXY, rJoyX
	add rRandomXY, rJoyY
	clr rTemp
	subi rTemp, -5
	sub rRandomXY, rTemp

	ret

apple_create:
	//Create an apple for the matrix.

	//Copy random values to the new apple position and remove bits.
	mov rAppleXY, rRandomXY
	ldi rTemp, 0b01110111
	and rAppleXY, rTemp

	ret

apple_update:
	//Load pointer to matrix.
	ldi ZH, HIGH(matrix)
	ldi ZL, LOW(matrix)

	apple_Y:
		//rTemp = Row, rTemp2 = i
		ldi rTemp, 0b01110000
		and rTemp, rAppleXY
		clr rTemp2

		clc
		lsr rTemp
		clc
		lsr rTemp
		clc
		lsr rTemp
		clc
		lsr rTemp

		apple_convert_Y:
			cp rTemp, rTemp2
			breq apple_X
			ld rTemp3, Z+
			inc rTemp2
			rjmp apple_convert_y

	apple_X:
	//rTemp = Row, rTemp2 = i, rTemp3 = Current column
	ldi rTemp, 0b00000111
	and rTemp, rAppleXY
	clr rTemp2
	ldi rTemp3, 0b00000001

		apple_convert_X:
			cp rTemp, rTemp2
			breq apple_valid_position
			clc
			lsl rTemp3
			inc rTemp2
			rjmp apple_convert_X
			
			apple_valid_position:

	apple_set:
	ld rTemp, Z
	or rTemp, rTemp3
	st Z, rTemp

	ret

snake_check:
	//Check for snake collision.
	//rTemp = Current segment in snake, rTemp2 = i
	ldi ZH, HIGH(snake)
	ldi ZL, LOW(snake)

	//Skip head, increase rTemp2
	clr rTemp2
	ld rTemp, Z+
	inc rTemp2

	snake_compare:
	//Compare Head with current segment of the snake.
	ld rTemp, Z+
	cp rHead, rTemp
	breq snake_collision

	//Compare if there is another segment in the snake
	cp rLength, rTemp2
	brlt snake_compare
	ret

	snake_collision:
		rcall reset

	ret

apple_check:
	//Check for an apple collision.

	cp rHead, rAppleXY
	breq apple_collision
	ret
	apple_collision:
	inc rLength
	rcall apple_create

	ret


clear_matrix:
	//Clear the matrix.

	ldi ZH, HIGH(matrix)
	ldi ZL, LOW(matrix)

	clr rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z+, rTemp
	st Z, rTemp

	ret

snake_move:
	ldi YH, HIGH(snake)
	ldi YL, LOW(snake)

	snake_head:
		ld rTemp, Y
		mov rTemp2, rTemp

		cpi rDirection, 0b00000011
		breq snake_move_left

		cpi rDirection, 0b00000100
		breq snake_move_right

		cbr rTemp, 0b00001111
		clc
		lsr rTemp
		lsr rTemp
		lsr rTemp
		lsr rTemp

		cpi rDirection, 0b00000001
		breq snake_move_up

		cpi rDirection, 0b00000010
		breq snake_move_down

	snake_head_moved:
	ldi rTemp2, 0b00000000
	ld rTemp, Y
	st Y+, rHead

	snake_loop:
		ld rTemp3, Y
		st Y+, rTemp
		mov rTemp, rTemp3
		
		inc rTemp2
		cp rTemp2, rLength
		brlo snake_loop
	ret

snake_move_right:
	cbr rTemp, 0b11110000
	cpi rTemp, 0b00000111
	brne right_no_teleport
		ldi rTemp, 0b11111111
	right_no_teleport:
	inc rTemp

	cbr rTemp2, 0b00001111
	or rTemp2, rTemp
	mov rHead, rTemp2

	rjmp snake_head_moved

snake_move_up:
	cpi rTemp, 0b00000000
	brne up_no_teleport
		ldi rTemp, 0b00001000
	up_no_teleport:
	dec rTemp
	clc
	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp

	cbr rTemp2, 0b11110000
	or rTemp2, rTemp
	mov rHead, rTemp2

	rjmp snake_head_moved

snake_move_down:
	cpi rTemp, 0b00000111
	brne down_no_teleport
		ldi rTemp, 0b11111111
	down_no_teleport:
	inc rTemp
	clc
	lsl rTemp
	lsl rTemp
	lsl rTemp
	lsl rTemp

	cbr rTemp2, 0b11110000
	or rTemp2, rTemp
	mov rHead, rTemp2

	rjmp snake_head_moved

snake_move_left:
	cbr rTemp, 0b11110000
	cpi rTemp, 0b00000000
	brne left_no_teleport
		ldi rTemp, 0b00001000
	left_no_teleport:
	dec rTemp

	cbr rTemp2, 0b00001111
	or rTemp2, rTemp
	mov rHead, rTemp2

	rjmp snake_head_moved

snake_render:
	ldi XH, HIGH(matrix)
	ldi XL, LOW(matrix)

	ldi rTemp4, 0b00000000

	render_loop:
		ldi YH, HIGH(snake)
		ldi YL, LOW(snake)

		ldi rTemp2, 0b00000000

		snake_row_point_finder:
			ld rTemp, Y+
			mov rTemp3, rTemp
			
			cbr rTemp, 0b00001111
			clc
			lsr rTemp
			lsr rTemp
			lsr rTemp
			lsr rTemp

			cp rTemp, rTemp4
			brne point_not_row

			mov rTemp, rTemp3
			cbr rTemp, 0b11111000
			ldi rTemp3, 0b00000001
			
			decrease_loop:
				cpi rTemp, 0b00000000
				breq end_decrease_loop
				nop
				clc
				dec rTemp
				lsl rTemp3
				rjmp decrease_loop
				nop
			end_decrease_loop:
			ld rTemp, X
			or rTemp, rTemp3
			st X, rTemp

			point_not_row:

			inc rTemp2
			cp rTemp2, rLength
			brlo snake_row_point_finder
			nop
		inc rTemp4
		ld rTemp2, X+
		cpi rTemp4, 0b00001000
		brlo render_loop
		nop
	//End render_loop
	ret

snake_create:
	ldi rLength, 0b00000011

	ldi YH, HIGH(snake)
	ldi YL, LOW(snake)

	ldi rTemp, 0b00000000
	st Y+, rTemp
	ldi rTemp, 0b00000001
	st Y+, rTemp
	ldi rTemp, 0b00000010
	st Y, rTemp

	ret
