/*
Author: Benjamin Warren
Date: 10/8/2022
Title: Lab2.c
Description:
This code will cause a TekBot connected to the AVR board to
move forward and when it touches an obstacle, it will reverse
and turn away from the obstacle and resume forward motion.

PORT MAP
Port B, Pin 5 -> Output -> Right Motor Enable
Port B, Pin 4 -> Output -> Right Motor Direction
Port B, Pin 6 -> Output -> Left Motor Enable
Port B, Pin 7 -> Output -> Left Motor Direction
Port D, Pin 5 -> Input -> Left Whisker
Port D, Pin 4 -> Input -> Right Whisker

References: 
-provided ece375-L2_skeleton.c
-provided Makefile.txt
-provided ece375-lab2.pdf
-provided ece375-lab2.ppt
-provided DanceBot.c
*/

#define F_CPU 16000000
#include <avr/io.h>
#include <util/delay.h>
#include <stdio.h>

void hitRight(){
	PORTB = 0b11110000;	//Halt TekBot before changing direction
	_delay_ms(500);		//Wait
	PORTB = 0b00000000;	//Make TekBot go backward
	_delay_ms(1000);	//Continue backwards for 1000 ms
	PORTB = 0b10000000;	//Make TekBot turn left
	_delay_ms(1000);	//Continue turning left for 1000 ms
	PORTB = 0b11110000; //Halt TekBot before changing direction
	_delay_ms(500);
	return;
}

void hitLeft(){
	PORTB = 0b11110000;	//Halt TekBot before changing direction
	_delay_ms(500);		//Wait
	PORTB = 0b00000000; //Make TekBot go backward
	_delay_ms(1000);    //Continue backwards for 500 ms
	PORTB = 0b00010000; //Make TekBot turn right
	_delay_ms(1000);    //Continue turning left for 1000 ms
	PORTB = 0b11110000; //Halt TekBot before changing direction
	_delay_ms(500);
	return;
}

int main(void){
	
	//INIT routine////
	DDRB = 0b11111111;	// configure Port B pins for input/output
	PORTB = 0b11110000; // set initial value for Port B outputs
						// (initially, disable both motors)
	DDRD = 0b00000000;	// configure Port D pins for input/output
	PORTD = 0b11110000; // set initial value for Port D inputs
	//////////////////
	
	while (1) {								// loop forever
		
		PORTB = 0b10010000;					//Make TekBot go forward
	
		uint8_t mpr = PIND & 0b00110000;	//Check for whisker hit
		if (mpr == 0b00010000){				//If right whisker hit
			hitRight();
		}
		if (mpr == 0b00100000){				//If left whisker hit
			hitLeft();
		}
	}
}
