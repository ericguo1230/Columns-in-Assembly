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

#How far off the screen the game board will be x coordinate wise
GAMEBOARD_OFFSET_X:
    .word 0x00000008

#How far off the screen the game board will be y coordinate wise
GAMEBOARD_OFFSET_Y:
    .word 0x00000008

#Update column height after storing pixel in PLAYING_FIELD 
#(We include the right boundary in playing field so it needs to be offset by another 1 in the x plane)
GAMEBOARD_TO_HEIGHT_OFFSET_X:
    .word 0x00000001

#Height of the Game Board may be convieninent for performing calculations later
GAMEBOARD_HEIGHT:
    .word 0x0000000f

#WIDTH OF THE GAMEBOARD
GAMEBOARD_WIDTH:
    .word 0x00000008

#Colors of GAMEBOARD WALLS
GAMEBOARD_COLOR:
    .word 0x808080
    
#COORDINATES OF THE 'NEXT COLUMN'
NEXT_COLUMN_X:
    .word 0x00000012

NEXT_COLUMN_Y:
    .word 0x00000008

#-----GEM COLORS-----
COLOR_RED:
    .word 0xFF0000

COLOR_BLUE:
    .word 0x0000FF

COLOR_YELLOW:
    .word 0xFFFF00

COLOR_GREEN:
    .word 0x00FF00

COLOR_PURPLE:
    .word 0xFF00FF

COLOR_ORANGE:
    .word 0xFFA500
#----------------
    
##############################################################################
# Mutable Data
##############################################################################

# The number of bytes allocated for the playing field (6 x 13) ints (4 bytes long)
PLAYING_FIELD:
    .space 312

# The number of bytes to display the current column (3 x 1) ints (4 bytes long) 
CURR_COLUMN:
    .space 12

# The number of bytes needed to store the height of each column in playing field (4 x 6 ints)
PLAYING_FIELD_HEIGHTS:
    .space 24
    
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal setup_game
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

# Draw the initial game
setup_game:
    #Save return address
    addi $sp, $sp, -4
    sw $ra 0($sp)
    
    jal draw_gameboard
    jal draw_random_column
    
    lw $ra 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
#This will draw the initial gameboard (DO NOT TAKE ANY PARAMS AS INPUT)
draw_gameboard:
    #THIS WILL DRAW THE CEILING
    lw $t0, ADDR_DSPL #Load Bitmap address into t0
    lw $a0, GAMEBOARD_OFFSET_X #x coord
    lw $a1, GAMEBOARD_OFFSET_Y # y coord
    lw $a2, GAMEBOARD_COLOR #set the color (Medium Gray)
    lw $a3, GAMEBOARD_WIDTH #Size of the line
    
    #Save return address at the bottom of my stack (only need to do this once)
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    addi $sp, $sp, -16
    sw $a0, 0($sp) #Save x coord
    sw $a1, 4($sp) #Save y coord
    sw $a2, 8($sp) #Save color
    sw $a3, 12($sp) #Save size of line
    
    jal draw_line_horizontal
    
    #THIS WILL DRAW THE FLOOR
    lw $a0, GAMEBOARD_OFFSET_X #x coord
    lw $a1, GAMEBOARD_OFFSET_Y # y coord
    lw $a2, GAMEBOARD_COLOR #set the color (Medium Gray)
    lw $a3, GAMEBOARD_WIDTH #Size of the line
    
    #Increment Y coordinate by height of the game board + 1 (We want the height to be the empty space)
    lw $t0, GAMEBOARD_HEIGHT
    addi $t0, $t0, 1
    add $a1, $a1, $t0
    
    #Save x, y coord color and size these are params to be passed on through stack
    addi $sp, $sp, -16 
    sw $a0, 0($sp) 
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    
    jal draw_line_horizontal
    
    #DRAW WALLS
    lw $a0, GAMEBOARD_OFFSET_X #x coord
    lw $a1, GAMEBOARD_OFFSET_Y # y coord
    lw $a2, GAMEBOARD_COLOR #set the color (Medium Gray)
    lw $a3, GAMEBOARD_HEIGHT #Size of the line
    
    #Add size of line by 1 to accomodate height
    addi $a3, $a3, 1
    
    #These are function params to be passed on
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    
    jal draw_line
    
    #Second wall offset x by width
    lw $a0, GAMEBOARD_OFFSET_X #x coord
    lw $a1, GAMEBOARD_OFFSET_Y # y coord
    lw $a2, GAMEBOARD_COLOR #set the color (Medium Gray)
    lw $a3, GAMEBOARD_HEIGHT #Size of the line
    
    #Add size of line by 1 to accomodate height
    addi $a3, $a3, 1
    lw $t0, GAMEBOARD_WIDTH
    subi $t0, $t0, 1
    add $a0, $a0, $t0
    
    #These are function params to be passed on
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    
    jal draw_line
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#Draw random column
draw_random_column:
    #Save return address before performing other actions
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    li $t6, 0
    li $a3, 3
    
    lw $a0, NEXT_COLUMN_X #x coord for displaying next column
    lw $a1, NEXT_COLUMN_Y #y coord for displaying next column
    
draw_random_column_loop:
    bge $t6, $a3, draw_random_column_loop_end
    # Step 1: Get a random number
    #Save param a values to stack as 'generate_random_num' uses a registers
    addi $sp, $sp, -8
    sw $a0, 0($sp) #x coord for displaying next column
    sw $a1, 4($sp) #y coord for displaying next column
    jal generate_random_num
    # Step 2: Get the color from the number
    jal get_color_from_number
    # Step 3: draw the pixel
    lw $a2, 0($sp)  #Get the color from top of stack passed on from 'get_color_from_number'
    lw $a0, 4($sp) #x coord for displaying next column
    lw $a1, 8($sp) #y coord for displaying next column
    addi $sp, $sp, 12
    
    # Push params onto stack
    addi $sp, $sp, -12
    sw $a0, 0($sp) #x coordinate
    sw $a1, 4($sp) #y coordinate
    sw $a2, 8($sp) #color
    jal draw_pixel
    
    # Step 4: save the pixel in our CURR_COLUMN
    jal save_color_curr_column
    
    #update $a1 by $t6
    add $a1, $a1, 1
    addi $t6, $t6, 1
    j draw_random_column_loop
    
draw_random_column_loop_end:
    lw $ra, 0($sp) #load return address
    addi $sp, $sp, 4
    jr $ra
#Take 2 params:
#1: Color stored in $a2
#2: Block index stored in $t6
save_color_curr_column:
    la $t0, CURR_COLUMN
    
    #compute index offset into memory address
    mult $t1, $t6, 4
    
    #update pointer
    add $t0, $t0, $t1
    
    #Save color at address
    sw $a2, 0($t0)
    jr $ra
    
draw_random_column_end:
    lw $ra 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    
#Generate a random number and push it to top of stack
#NO PARAMS
generate_random_num:
    li $v0, 42
    li $a0, 0
    li $a1, 6
    
    #this will set $a0 to some random int from [0 - 5]
    syscall
    
    addi $sp, $sp -4
    sw $a0, 0($sp)
    jr $ra

#ONE PARAMETER: ON TOP OF STACK - NUMBER TO FIND COLOR
get_color_from_number:
    lw $t0, 0($sp) #Load number into $t0
    addi $sp, $sp, 4
    li $t1, 1
    beq $t0, $t1, eq_one #COLOR RED WHEN 1
    li $t1, 2
    beq $t0, $t1, eq_two
    li $t1, 3
    beq $t0, $t1, eq_three
    li $t1, 4
    beq $t0, $t1, eq_four
    li $t1, 5
    beq $t0, $t1, eq_five
    
#Return Orange when 6
else:
    lw $t3, COLOR_ORANGE
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end
    
#Return Red when 1
eq_one:
    lw $t3, COLOR_RED
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Blue when 2
eq_two:
    lw $t3, COLOR_BLUE
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Yellow when 3
eq_three:
    lw $t3, COLOR_YELLOW
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Green when 4
eq_four:
    lw $t3, COLOR_GREEN
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Purple when 5
eq_five:
    lw $t3, COLOR_PURPLE
    
    #push onto stack to be returned
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return back
get_color_from_number_end:
    jr $ra
    
#I want this to take in 3 parameters;
# 1 color 
# 2 - 3: (x, y) coordinate 
#These will all be in the stack when I call it so pop 5 times total (pop 2 in store_in_playing_field (pop last 3 again in draw_pixel)
draw_pixel_board:
    #-----
    # LOAD PARAMETER VALUES PASSED IN
    #----
    lw $t0, 0($sp) #This will be the color
    lw $t1, 4($sp) #This will be the x coordinate
    lw $t2, 8($sp) #This will be the y coordinate
    
    #-----
    # SAVE PARAMETER VALUES ONTO STACK FOR STORE_IN_PLAYING_FIELD (RA FOR OUR FUNCTION RETURN ADDRESS)
    #----
    addiu $sp, $sp, -16 #make 4 * 6 bytes of space on the stack
    sw $t0, 0($sp) #This will be the color
    sw $t1, 4($sp) #This will be the x coordinate
    sw $t2, 8($sp) #This will be the y coordinate
    sw $ra, 12($sp) #Save return address to stack
    
    jal store_in_playing_field #Store the pixel in the PLAYING_FIELD first
    
    #-----
    # LOAD PARAMETER VALUES FROM WHAT WAS PASSED IN
    #----
    lw $t7, ADDR_DSPL #Load Bitmap address into t0
    lw $ra, 0($sp) #RETURN ADDRESS SHOULD BE AT THE TOP
    lw $t0, 4($sp) #This will be the color
    lw $t1, 8($sp) #This will be the x coordinate
    lw $t2, 12($sp) #This will be the y coordinate
    addi $sp, $sp 16 #move stack pointer down 

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
    
    lw $t3, GAMEBOARD_OFFSET_X
    lw $t4, GAMEBOARD_OFFSET_Y
    lw $t0, 0($sp) #This will be the color
    lw $t1, 4($sp) #This will be the x coordinate
    lw $t2, 8($sp) #This will be the y coordinate
    addi $sp, $sp 12
    
    #Calculate memory address to store color pointe rin with offset factored in
    sub $t1, $t1, $t3
    sub $t2, $t2, $t4
    
    mul $t2, $t2, 32 # skip (32 * y) or (4 * 8 (each address is 4 bytes and 8 addresses in a row in the playable space))
    mul $t1, $t1, 4 # x offset (multiply by 4 bytes)
    
    # add the row and column offsets to the base address
    add $t7, $t7, $t1
    add $t7, $t7, $t2
    
    lw $t0, 0($t7) #Load color into PLAYING_FIELD
    jr $ra #RETURN TO CALLER FUNCTION (DRAW_PIXEL_BOARD)

# Takes 3 params
# $a0 -> x
# $a1 -> y
# $a2 -> color
draw_pixel:
    #Load the base address of the screen into register $t0
    lw $t0, ADDR_DSPL
    lw $a0, 0($sp) #x coord
    lw $a1, 4($sp) #y coord
    lw $a2, 8($sp) #color
    addi $sp, $sp, 12 #move stack pointer
    #compute the row offset and store in register $t1: 
    # skip (128 * y) or (4 * 32 (each address is 4 bytes and 32 addresses in a row))
    mul $t1, $a1, 128
    
    #compute col offset store result in $t2
    mul $t2, $a0, 4
    
    # add the row and column offsets to the base address
    add $t0, $t0, $t1
    add $t0, $t0, $t2
    
    # store the color at the computed address
    sw $a2, 0($t0)
    
    #return to the caller
    jr $ra

# This will take 4 parameters
#1 - 2: starting x, y coordinate
#3: color
#4: size of the line
draw_line_horizontal:
    #Load in function params from stack
    lw $a0, 0($sp) #x coord
    lw $a1, 4($sp) #y coord
    lw $a2, 8($sp) #color
    lw $a3, 12($sp) #size of the line
    addi $sp, $sp, 16
    
    li $t7, 0 #set loop counter
    
draw_line_horizontal_loop:
    #check the loop condition
    bge $t7, $a3, draw_line_horizontal_end
    #------
    # PUSHING ALL NEEDED VALUES TO STACK TO USE AFTER DRAW_PIXEL
    #-----
    addi $sp, $sp, -32
    sw $a0, 0($sp) #x coord
    sw $a1, 4($sp) #y coord
    sw $a2, 8($sp) #color
    sw $a0, 12($sp) #x coord
    sw $a1, 16($sp) #y coord
    sw $a2, 20($sp) #color
    sw $a3, 24($sp) #size of the line
    sw $ra, 28($sp) #return address
    
    jal draw_pixel #Draw pixel at x, y position
    
    #------
    # RESTORE ALL NEEDED VALUES FROM STACK TO USE AFTER DRAW_PIXEL
    #-----
    lw $a0, 0($sp) #x coord
    lw $a1, 4($sp) #y coord
    lw $a2, 8($sp) #color
    lw $a3, 12($sp) #size of the line
    lw $ra, 16($sp) #load in return address
    addi $sp, $sp, 20
   
    addi $a0, $a0, 1  # Compute the next pixel's x position
    addi $t7, $t7, 1 #Increment counter by 1
    j draw_line_horizontal_loop
    
draw_line_horizontal_end:
    jr $ra
    
# This will take 4 parameters
#1 - 2: starting x, y coordinate
#3: color
#4: size of the line
draw_line:
    #Load in function params from stack
    lw $a0, 0($sp) #x coord
    lw $a1, 4($sp) #y coord
    lw $a2, 8($sp) #color
    lw $a3, 12($sp) #size of the line
    addi $sp, $sp, 16
    
    li $t7, 0 #set loop counter
    
draw_line_loop:
    #check the loop condition
    bge $t7, $a3, draw_line_end
    #------
    # PUSHING ALL NEEDED VALUES TO STACK TO USE AFTER DRAW_PIXEL
    #-----
    addi $sp, $sp, -32
    sw $a0, 0($sp) #x coord
    sw $a1, 4($sp) #y coord
    sw $a2, 8($sp) #color
    sw $a0, 12($sp) #x coord
    sw $a1, 16($sp) #y coord
    sw $a2, 20($sp) #color
    sw $a3, 24($sp) #size of the line
    sw $ra, 28($sp) #return address
    
    jal draw_pixel #Draw pixel at x, y position
    
    #------
    # RESTORE ALL NEEDED VALUES FROM STACK TO USE AFTER DRAW_PIXEL
    #-----
    lw $a0, 0($sp) #x coord
    lw $a1, 4($sp) #y coord
    lw $a2, 8($sp) #color
    lw $a3, 12($sp) #size of the line
    lw $ra, 16($sp) #load in return address
    addi $sp, $sp, 20
   
    addi $a1, $a1, 1  # Compute the next pixel's y position
    addi $t7, $t7, 1 #Increment counter by 1
    j draw_line_loop
    
draw_line_end:
    jr $ra

