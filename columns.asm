################# CSC258 Assembly Final Project ###################
# This file contains our implementation of Columns.
#
# Student 1: Eric Guo 1008084911
# Student 2: Name, Student Number (if applicable)
#
# We assert that the code submitted here is entirely our own 
# creation, and will indicate otherwise when it is not.
#
######################## Bitmap Display Configuration ########################
# - Unit width in pixels:       8
# - Unit height in pixels:      8
# - Display width in pixels:    256
# - Display height in pixels:   256
# - Base Address for Display:   0x10008000 ($gp)
##############################################################################

    .data
##############################################################################
# Immutable Data
##############################################################################
# The address of the bitmap display. Don't forget to connect it!
ADDR_DSPL:
    .word 0x10008000
# The address of the keyboard. Don't forget to connect it!
ADDR_KBRD:
    .word 0xffff0000

##############################################################################
# Mutable Data
##############################################################################

# The number of bytes allocated for the playing field (8 x 15) ints (4 bytes long)
PLAYING_FIELD:
    .space 480 

# The number of bytes to display the upcoming column (3 x 1) ints (4 bytes long) 
NEXT_COLUMN:
    .space 12
    
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    addi $sp, $sp, -20
    li $a0, 6 #x coord
    li $a1, 6 # y coord
    li $a3, 6 #x coord OFFSET
    li $t9, 6 # y coord OFFSET
    li $a2, 0x808080#set the color
    
    sw $a3, 0($sp)
    sw $t9, 4($sp)
    sw $a2, 8($sp)
    sw $a0, 12($sp)
    sw $a1, 16($sp)
    
    jal draw_pixel_board
    
    li $v0, 10
    syscall

game_loop:
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
	# 3. Draw the screen
	# 4. Sleep

    # 5. Go back to Step 1
    j game_loop

# Draw the initial game (
setup_game:

    lw $t0, ADDR_DSPL #Load Bitmap address into t0
    addi $t1, $t0, 16 #Move starting corner of game border 4 pixels to the right

#I want this to take in 5 parameters;
# 1 and 2: (x, y) offset used by store_in_playing_field to map to 0 indexed memory address
# 3 color 
# 4 and 5: (x, y) coordinate 
#These will all be in the stack when I call it so pop 5 times total (pop 2 in store_in_playing_field (pop last 3 again in draw_pixel)
draw_pixel_board:
    #-----
    # LOAD PARAMETER VALUES PASSED IN
    #----
    lw $t3, 0($sp) #This will be the x coordinate OFFSET
    lw $t4, 4($sp) #This will be the y coordinate OFFSET
    lw $t0, 8($sp) #This will be the color
    lw $t1, 12($sp) #This will be the x coordinate
    lw $t2, 16($sp) #This will be the y coordinate
    
    #-----
    # SAVE PARAMETER VALUES ONTO STACK FOR STORE_IN_PLAYING_FIELD (RA FOR OUR FUNCTION RETURN ADDRESS)
    #----
    addiu $sp, $sp, -24 #make 4 * 6 bytes of space on the stack
    sw $t3, 0($sp) #This will be the x coordinate OFFSET
    sw $t4, 4($sp) #This will be the y coordinate OFFSET
    sw $t0, 8($sp) #This will be the color
    sw $t1, 12($sp) #This will be the x coordinate
    sw $t2, 16($sp) #This will be the y coordinate
    sw $ra, 20($sp) #Save return address to stack
    
    jal store_in_playing_field #Store the pixel in the PLAYING_FIELD first
    
    #-----
    # LOAD PARAMETER VALUES FROM WHAT WAS PASSED IN
    #----
    lw $t7, ADDR_DSPL #Load Bitmap address into t0
    lw $ra, 0($sp) #RETURN ADDRESS SHOULD BE AT THE TOP
    lw $t0, 12($sp) #This will be the color
    lw $t1, 16($sp) #This will be the x coordinate
    lw $t2, 20($sp) #This will be the y coordinate
    
    addi $sp, $sp 24 #move stack pointer down after popping 5 elems (ignoring first 2)
    
    mul $t2, $t2, 128 # skip (128 * y) or (4 * 32 (each address is 4 bytes and 32 addresses in a row))
    mul $t1, $t1, 4 # x offset (multiply by 4 bytes)
    
    # add the row and column offsets to the base address
    add $t7, $t7, $t1
    add $t7, $t7, $t2
    
    # store the color at the computed address
    sw $t0, 0($t7)
    
    #return to caller
    jr $ra

store_in_playing_field:
    la $t7, PLAYING_FIELD
    
    lw $t3, 0($sp) #This will be the x coordinate OFFSET
    lw $t4, 4($sp) #This will be the y coordinate OFFSET
    lw $t0, 8($sp) #This will be the color
    lw $t1, 12($sp) #This will be the x coordinate
    lw $t2, 16($sp) #This will be the y coordinate
    # ONLY MOVE THE STACK POINTER  8 AS WE WILL READ THE SAME AREAS IN STACK IN DRAW_PIXEL
    addi $sp, $sp 20
    
    sub $t1, $t1, $t3
    sub $t2, $t2, $t4
    
    mul $t2, $t2, 32 # skip (32 * y) or (4 * 8 (each address is 4 bytes and 8 addresses in a row in the playable space))
    mul $t1, $t1, 4 # x offset (multiply by 4 bytes)
    
    # add the row and column offsets to the base address
    add $t7, $t7, $t1
    add $t7, $t7, $t2
    
    lw $t0, 0($t7) #Load color into PLAYING_FIELD
    jr $ra #RETURN TO CALLER FUNCTION (DRAW_PIXEL_BOARD)

draw_line:


draw_wall:
    
