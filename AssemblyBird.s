#####################################################################
#
# CSC258H5S Winter 2020 Assembly Programming Project
# University of Toronto Mississauga
#
# Group members:
# - Student 1: Abtin Ghajarieh Sepanlou, 1005294584
# - Student 2 (if any): Abner Jesse Evasco, 1005491362
#
# Bitmap Display Configuration:
# - Unit width in pixels: 8					     
# - Unit height in pixels: 8
# - Display width in pixels: 256
# - Display height in pixels: 256
# - Base Address for Display: 0x10008000 ($gp)
#
# Which milestone is reached in this submission?
# (See the assignment handout for descriptions of the milestones)
# - Milestone 5 (choose the one the applies)
#
# Which approved additional features have been implemented?
# (See the assignment handout for the list of additional features)
# 1. Fading Day and night cycle in the background
# 2. Difficulty increase for every pipe passed, by increasinng speed of pipe approach and rate of gravity
# 3. Added a red pickup that freezes time but continues to let the player move up and down
# ... (add more if necessary)
#
# Any additional information that the TA needs to know:
# - The day and night cycle is a little bit slow because we didn't want it to be too hard on the eyes, but you'll notice the pixels fade after each pipe passed, 
# then they start to fade back to blue after reaching full black
# - The amount of time freezed by the powerup decreases as difficulty increases, so choose when you go for the powerup wisely :3

#####################################################################
.data
	birdColor:	.word	0xdeed32
	skyColor: 	.word	0x0064c8
	pipeColor:	.word	0x36ba2d
	pickupColor:	.word	0xff0000
	lastPixel:	.word	4096		#Final pixel of pipe construction
	startPixel:	.word	108
	randomPipe:	.word	0
	randomPickup:	.word	0
	birdStartPixel: .word	2072
	startSpeed:	.word	250
	fadeDirection:	.word	0
	Pickup:		.word	1
	pickupDuration:	.word	20
	previousPickup:	.word	1

.text
	li $t0, 0x10008000
Repaint:
	li $v0, 32
	lw $a0, startSpeed
	syscall
	
	li $t5, 0
	li $t3, 0
	
BACKGROUND:
	lw $t1, skyColor
	beq $t5, 4096, DoneBackground
	add $t6, $t5, $t0
	sw $t1, ($t6)	  
	addi $t5, $t5, 4 
	j BACKGROUND
DoneBackground:
	li $t5, 0
	lw $t6, startPixel
	add $t6, $t6, $t0
	
	lw $t2 , randomPipe
	beqz $t2, SetRandomBreakInPipe
	j Pipe
SetRandomBreakInPipe:
	li $v0, 42
	li $a0, 7
	li $a1, 21
	syscall
	move $t2, $a0
	addi $t2, $t2, 2
	sw $t2, randomPipe

	lw $t8, randomPickup
	beqz $t8, SetRandomPointForPickup
	j Pipe
SetRandomPointForPickup:
	li $v0, 42
	li $a0, 7
	li $a1, 21
	syscall
	move $t8, $a0
	addi $t8, $t8, 2
	sw $t8, randomPickup
Pipe:
	lw $t1, pipeColor
	lw $t7, lastPixel
	add $t7, $t7, $t0
	beq $t6, $t7, DonePipe
	beq $t5, 20, DonePipeRow
	beq $t3, 8, dontcheck
	beqz $t2, PipeBreak
	dontcheck:
	sw  $t1, ($t6)
	addi $t6, $t6, 4
	addi $t5, $t5, 4
	j Pipe
DonePipeRow:
	addi $t6, $t6, 108
	li $t5, 0
	subi $t2, $t2, 1
	j Pipe

PipeBreak:
	addi $t6, $t6, 128
	addi $t3, $t3, 1
	beq $t3, 8, Pipe
	j PipeBreak
	

DonePipe:
	IFnotatend:
	lw $t6, startPixel
	beqz $t6, atend
	subi $t8, $t6, 16
	beqz $t8, dontDrawPickup
	
	lw $t9, randomPickup
	add $t8, $t8, $t0
	WHILE:
	addi $t8, $t8, 128
	subi $t9, $t9, 1
	bnez $t9, WHILE
	lw $t1, Pickup
	beqz $t1, freezeTime
	lw $t1, previousPickup
	beqz $t1, dontDrawPickup
	lw $t1, pickupColor
	sw $t1, ($t8)
	
	dontDrawPickup:
	lw $t7, lastPixel
	subi $t7, $t7, 4
	subi $t6, $t6, 4
	sw $t6, startPixel
	sw $t7, lastPixel
	j drawBird
	
	freezeTime:
	lw $t1, pickupDuration
	beqz $t1, reset
	subi $t1, $t1, 1
	sw $t1, pickupDuration
	li $t1, 0
	sw $t1, previousPickup
	j drawBird
	atend:
	li $t6, 108
	sw $t6, startPixel
	li $t7, 4096
	sw $t7, lastPixel
	li $t2, 0
	sw $t2, randomPipe
	sw $t2, randomPickup
	li $t2, 1
	sw $t2, previousPickup
	lw $t2, startSpeed
	beq $t2, 50, fading
	subi $t2, $t2, 10
	sw $t2, startSpeed
	fading:
	lw $t2, fadeDirection
	beq $t2, 1, fadeUp
	fadeDown:
	lw $t2, skyColor
	subi $t2, $t2, 0x000a14
	sw $t2, skyColor
	beq $t2, 0x000000, fadeChangeUp
		
drawBird:
	lw $t1, birdColor	
	lw $t5, birdStartPixel
	beq $t5, 3864, Exit
	beq $t5, 24, Exit
	add $t6, $zero, $t0
	add $t6, $t6, $t5
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
	addi $t6, $t6, 12
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
	addi $t6, $t6, 128
	subi $t6, $t6, 4
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
	subi $t6, $t6, 4
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
	subi $t6, $t6, 4
	addi $t6, $t6, 128
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
	addi $t6, $t6, 12
	lw $t3, ($t6)
	jal checkCollision
	sw $t1, ($t6)
checkInput:
	li $t4, 0xffff0004
	li $t7, 0xffff0000
	lw $t3, ($t7)
	beqz $t3, noInput
givenInput:
	lw $t3, ($t4)
	beq $t3, 102, properInput
	j noInput
properInput:
	lw $t5, birdStartPixel
	subi $t5, $t5, 256
	sw $t5, birdStartPixel
	j Repaint
noInput:
	lw $t5, birdStartPixel
	addi $t5, $t5, 128
	sw $t5, birdStartPixel
	j Repaint
checkCollision:
	lw $t2, pipeColor
	beq $t2, $t3, Exit
	lw $t2, pickupColor
	beq $t2, $t3, pickedUp
	jr $ra	
fadeChangeUp:
	lw $t2, fadeDirection
	addi $t2, $t2, 1
	sw $t2, fadeDirection
	j drawBird
fadeChangeDown:
	lw $t2, fadeDirection
	subi $t2, $t2, 1
	j drawBird

fadeUp:
	lw $t2, skyColor
	addi $t2, $t2, 0x000a14
	sw $t2, skyColor
	beq $t2, 0x0064c8, fadeChangeDown
	j drawBird
pickedUp:
	li $a0, 0
	sw $a0, Pickup
	jr $ra
reset:
	li $a0, 1
	sw $a0, Pickup
	li $a0, 7
	sw $a0, pickupDuration
	j drawBird	
Exit:	
	li $t5, 0
	li $t3, 0
EndScreen:
	lw $t1, skyColor
	beq $t5, 4096, DoneEndScreen
	add $t6, $t5, $t0
	sw $t1, ($t6)	  
	addi $t5, $t5, 4 
	j EndScreen
DoneEndScreen:
	lw $a1, birdColor
	
		#B PIXELS
	
	#B floor pixels
	li $a0, 2072
	jal pixelPainter
	li $a0, 2076
	jal pixelPainter
	li $a0, 2080
	jal pixelPainter
	li $a0, 2084
	jal pixelPainter
	
	#B right pixels
	li $a0, 1956
	jal pixelPainter
	li $a0, 1828
	jal pixelPainter
	li $a0, 1700
	jal pixelPainter
	li $a0, 1696
	jal pixelPainter
	
	li $a0, 1568
	jal pixelPainter
	li $a0, 1440
	jal pixelPainter
	li $a0, 1312
	jal pixelPainter
	
	#B middle pixels
	li $a0, 1692
	jal pixelPainter
	
	#B top pixels
	li $a0, 1308
	jal pixelPainter
	li $a0, 1304
	jal pixelPainter
	
	#B Left pixels
	li $a0, 1432
	jal pixelPainter
	li $a0, 1560
	jal pixelPainter
	li $a0, 1688
	jal pixelPainter
	li $a0, 1816
	jal pixelPainter
	li $a0, 1944
	jal pixelPainter
	
	#Y PIXELS
	
	#Y bottom line
	li $a0, 2104
	jal pixelPainter
	li $a0, 1976
	jal pixelPainter
	li $a0, 1848
	jal pixelPainter
	
	#Y Diagonals
	li $a0, 1716
	jal pixelPainter
	li $a0, 1724
	jal pixelPainter
	
	#Y Left line
	li $a0, 1584
	jal pixelPainter
	li $a0, 1456
	jal pixelPainter
	li $a0, 1328
	jal pixelPainter
	
	#Y Right line
	li $a0, 1600
	jal pixelPainter
	li $a0, 1472
	jal pixelPainter
	li $a0, 1344
	jal pixelPainter
	
	#E PIXELS
	
	#E Right line
	li $a0, 1356
	jal pixelPainter
	li $a0, 1484
	jal pixelPainter
	li $a0, 1612
	jal pixelPainter
	li $a0, 1740
	jal pixelPainter
	li $a0, 1868
	jal pixelPainter
	li $a0, 1996
	jal pixelPainter
	li $a0, 2124
	jal pixelPainter

	#E line 1
	li $a0, 1360
	jal pixelPainter
	li $a0, 1364
	jal pixelPainter
	li $a0, 1368
	jal pixelPainter
	
	#E line 2
	li $a0, 1744
	jal pixelPainter
	li $a0, 1748
	jal pixelPainter
	li $a0, 1752
	jal pixelPainter
	
	#E line 3
	li $a0, 2128
	jal pixelPainter
	li $a0, 2132
	jal pixelPainter
	li $a0, 2136
	jal pixelPainter
	
	#! PIXELS
	li $a0, 2148
	jal pixelPainter
	li $a0, 1892
	jal pixelPainter
	li $a0, 1764
	jal pixelPainter
	li $a0, 1636
	jal pixelPainter
	li $a0, 1508
	jal pixelPainter
	li $a0, 1380
	jal pixelPainter
	
	
	li $v0, 10 # terminate the program gracefully
	syscall

pixelPainter:
	add $t6, $a0, $t0
	sw $a1, ($t6)
	jr $ra
