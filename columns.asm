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
    .word 0x00000010

#WIDTH OF THE GAMEBOARD
GAMEBOARD_WIDTH:
    .word 0x00000007

#Colors of GAMEBOARD WALLS
GAMEBOARD_COLOR:
    .word 0x808080
    
#COORDINATES OF THE 'NEXT COLUMN'
NEXT_COLUMN_X:
    .word 0x00000014

NEXT_COLUMN_Y:
    .word 0x0000000c

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
    
#GRAVITY SPEED UP COUNTER CONTROL HOW OFTEN GRAVITY WILL SPEED UP
GRAVITY_SPEED_UP_COUNTER:
    .word  0xE10   #60 so 60 seconds (it runs in the gravity counter)
#----------------
    
##############################################################################
# Mutable Data
##############################################################################

# The number of bytes allocated for the playing field (8 x 16) ints (4 bytes long)
PLAYING_FIELD:
    .space 512

# The number of bytes to display the current column colors(3 x 1) ints (4 bytes long) 
CURR_COLUMN_COLORS:
    .space 12
    
# The number of bytes to display the current column colors(3 x 1) ints (4 bytes long) 
NEXT_COLUMN_COLORS:
    .space 12

# The number of bytes to display the current column colors(3 x 1) ints (4 bytes long) 
NEXT_COLUMN_COLORS_2:
    .space 12
    
# The number of bytes to display the current column colors(3 x 1) ints (4 bytes long) 
NEXT_COLUMN_COLORS_3:
    .space 12

# The number of bytes to display the current column colors(3 x 1) ints (4 bytes long) 
NEXT_COLUMN_COLORS_4:
    .space 12

#Store the (x, y) coordinates of the current column IMPORTANT: (THIS ONLY STORES THE TOP COORDINATE, ADD 1 TO Y TO GET THE 2nd AND BOTTOM GEM COORDINATE)
CURR_COLUMN_COORD:
    .space 8

# The number of bytes needed to store the height of each column in playing field (8 ints)
PLAYING_FIELD_HEIGHTS:
    .space 32

#GRAVITY COUNTER FOR FALLING COLUMN #One integer so 4 bytes
FALLING_COUNTER_VALUE:
    .space 4
    
##############################################################################
# Code
##############################################################################
	.text
	.globl main

    # Run the game.
main:
    # Initialize the game
    jal setup_game
    
    #Setup gravity counter
    li $t9 60
    sw $t9, FALLING_COUNTER_VALUE
    
    lw $t8 GRAVITY_SPEED_UP_COUNTER
    
game_loop:
    #Save gravity counter to stack
    addi $sp, $sp, -8
    sw $t9, 0($sp) #Save gravity counter to stack
    sw $t8, 4($sp) #Save gravity speed up counter to stack
    # 1a. Check if key has been pressed
    # 1b. Check which key has been pressed
    jal keyboard_input_check
    
    #Load gravity pointer from stack
    lw $t9 0($sp)
    lw $t8 4($sp)
    addi $sp, $sp, 8
    
    # PERFORM GRAVITY SPEED UP CHECK
    bgt $t8, $zero skip_gravity_speed_up
    la $t0, FALLING_COUNTER_VALUE
    lw $t1, 0($t0)
    # Make gravity value 75% of the original
    sra  $t2, $t1, 2      # t2 = x / 4  (arithmetic shift right by 2)
    sub  $t1, $t1, $t2    # t1 = x - (x / 4) = 0.75 * x (integer)
    #Save back into falling value
    sw $t1, 0($t0)
    lw $t8 GRAVITY_SPEED_UP_COUNTER

skip_gravity_speed_up:
    # Perform the gravity
    bgt $t9, $zero skip_gravity
    #Move column down 1
    la $t0, CURR_COLUMN_COORD
    lw $t1, 4($t0)
    addi $t1, $t1, 1
    sw $t1, 4($t0)
    lw $t9 FALLING_COUNTER_VALUE
    
skip_gravity:
    #Save back onto stack
    addi $sp, $sp, -8
    sw $t9, 0($sp) #Save gravity counter
    sw $t8, 4($sp) #Save gravity speed up counter
    # 2a. Check for collisions
	# 2b. Update locations (capsules)
    jal check_collision_and_place
	# 3. Draw the screen
    jal draw_screen
	# 4. Sleep
    jal sleep_60fps
    # 5. Go back to Step 1
    
    lw $t9, 0($sp) #load in gravity counter
    lw $t8, 4($sp) #save gravity speed up counter
    addi $sp, $sp, 8
    
    addi $t9, $t9, -1
    addi $t8, $t8, -1
    
    j game_loop
    
sleep_60fps:
    li $v0, 32          # syscall 32 = sleep
    li $a0, 16         # sleep for 100ms (roughly 60fps)
    syscall
    jr $ra

draw_screen:
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_screen
    jal draw_gameboard #DRAW BOARD BOUNDARY
    jal draw_playing_field #DRAW PLACED GEMS
    jal draw_curr_column #DRAW CURRENT COLUMN
    jal draw_next_columns #DRAW ALL NEXT COLUMNS
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
clear_screen:
    lw   $t0, ADDR_DSPL      # load base display address
    li   $t1, 0              # black color (clear color)
    li   $t2, 1024           # 32x32 = 1024 pixels to clear
clear_loop:
    sw   $t1, 0($t0)         # write black pixel at current address
    addi $t0, $t0, 4         # move to next pixel (4 bytes per pixel)
    addi $t2, $t2, -1        # decrement counter
    bnez $t2, clear_loop     # loop until all pixels cleared
    jr   $ra
    
# Draw the initial game
setup_game:
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal draw_gameboard #DRAW GAMEBOARD
    
    #RUN LOOP 5 TIMES TO LOAD IN ALL COMPONENTS
    li $t0, 5
    li $t1, 0
setup_game_next_column_loop:
    bge $t1, $t0 setup_game_rest
    #Save onto stack
    addi $sp, $sp, -8
    sw $t1, 0($sp)
    sw $t0, 4($sp)
    
    jal draw_random_column #DRAW RANDOM COLUMN TO NEXT_COLUMN_4
    jal change_curr_column_from_next
    #Restore from stack
    lw $t1, 0($sp)
    lw $t0, 4($sp)
    addi $sp, $sp, 8
    
    addi $t1, $t1, 1
    j setup_game_next_column_loop
setup_game_rest:
    jal setup_column_position
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

setup_column_position:
    la $t9, CURR_COLUMN_COORD   # load address of current column coordinates
    lw $t0, GAMEBOARD_OFFSET_X  # get board's x offset
    lw $t1, GAMEBOARD_OFFSET_Y  # get board's y offset
    addi $a0, $t0, 4            # start at column 4 (middle of 8-wide board)
    addi $a1, $t1, -2            # start at row 1 (just below ceiling)
    sw $a0, 0($t9)              # save x coordinate
    sw $a1, 4($t9)              # save y coordinate
    jr $ra

#-------
# START OF DRAW GAMEBOARD FUNCTIONS
# ------
#This will draw the initial gameboard (DO NOT TAKE ANY PARAMS AS INPUT)
draw_gameboard:
    lw $a0, GAMEBOARD_OFFSET_X
    lw $a1, GAMEBOARD_OFFSET_Y
    lw $a2, GAMEBOARD_COLOR
    lw $a3, GAMEBOARD_WIDTH
    addi $sp, $sp, -4
    sw $ra, 0($sp)              # save return address
    addi $a3, $a3, 1            # add 1 to width for border
    
    # Draw ceiling (top horizontal line)
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    jal draw_line_horizontal
    
    # Draw floor (bottom horizontal line)
    lw $a0, GAMEBOARD_OFFSET_X
    lw $a1, GAMEBOARD_OFFSET_Y
    lw $a2, GAMEBOARD_COLOR
    lw $a3, GAMEBOARD_WIDTH
    lw $t0, GAMEBOARD_HEIGHT
    addi $t0, $t0, 1            # offset y by height + 1
    add $a1, $a1, $t0
    addi $a3, $a3, 1
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    jal draw_line_horizontal
    
    # Draw left wall (vertical line)
    lw $a0, GAMEBOARD_OFFSET_X
    lw $a1, GAMEBOARD_OFFSET_Y
    lw $a2, GAMEBOARD_COLOR
    lw $a3, GAMEBOARD_HEIGHT
    addi $a3, $a3, 1
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    jal draw_line
    
    # Draw right wall (vertical line)
    lw $a0, GAMEBOARD_OFFSET_X
    lw $a1, GAMEBOARD_OFFSET_Y
    lw $a2, GAMEBOARD_COLOR
    lw $a3, GAMEBOARD_HEIGHT
    addi $a3, $a3, 1
    lw $t0, GAMEBOARD_WIDTH
    add $a0, $a0, $t0           # offset x by width for right wall
    addi $sp, $sp, -16
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    sw $a3, 12($sp)
    jal draw_line
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#DRAW NEXT COLUMN WITH RANDOM COLORS
draw_random_column:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    li $t6, 0                   # loop counter = 0
    li $a3, 3                   # loop 3 times (3 gems)
    lw $a0, NEXT_COLUMN_X       # x position for next column display
    lw $a1, NEXT_COLUMN_Y       # y position for next column display
draw_random_column_loop:
    bge $t6, $a3, draw_random_column_loop_end   # if counter >= 3, exit
    
    # Step 1: Generate random number (0-5)
    jal generate_random_num
    
    # Step 2: Convert number to color
    jal get_color_from_number
    
    lw $a2, 0($sp)              # pop color from stack
    addi $sp, $sp, 4
    
    # Step 3: Save color in NEXT_COLUMN array
    jal save_color_next_column
    
    addi $t6, $t6, 1            # increment counter
    j draw_random_column_loop
draw_random_column_loop_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#DRAW NEXT COLUMN TO CURRENT COLUMN
change_curr_column_from_next:
    la $t9, CURR_COLUMN_COLORS  # address of current column colors
    la $t8, NEXT_COLUMN_COLORS  # address of next column colors
    la $t7, NEXT_COLUMN_COLORS_2 # address of next column colors 2
    la $t6, NEXT_COLUMN_COLORS_3 # address of next column colors 3
    la $t5, NEXT_COLUMN_COLORS_4 # address of next column colors 4
    
    #LOAD IN ALL OTHER COLUMN COLORS
    
    # Copy next column colors to current column
    # Load from 1 -> curr column then 2-> 1 then 3 -> 2 then 4 -> 3
    lw $a0, 0($t8)              # load first color from next
    lw $a1, 4($t8)              # load second color from next
    lw $a2, 8($t8)              # load third color from next
    sw $a0, 0($t9)              # store first color to current
    sw $a1, 4($t9)              # store second color to current
    sw $a2, 8($t9)              # store third color to current
    
    lw $a0, 0($t7)              # load first color from next 2
    lw $a1, 4($t7)              # load second color from next 2
    lw $a2, 8($t7)              # load third color from next 2
    sw $a0, 0($t8)              # store first color to next 
    sw $a1, 4($t8)              # store second color to next 
    sw $a2, 8($t8)              # store third color to next 
    
    lw $a0, 0($t6)              # load first color from next 3
    lw $a1, 4($t6)              # load second color from next 3
    lw $a2, 8($t6)              # load third color from next 3
    sw $a0, 0($t7)              # store first color to next 2
    sw $a1, 4($t7)              # store second color to next 2
    sw $a2, 8($t7)              # store third color to next 2
    
    lw $a0, 0($t5)              # load first color from next 4
    lw $a1, 4($t5)              # load second color from next 4
    lw $a2, 8($t5)              # load third color from next 4
    sw $a0, 0($t6)              # store first color to next 3
    sw $a1, 4($t6)              # store second color to next 3
    sw $a2, 8($t6)              # store third color to next 3
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Generate new random next column
    jal draw_random_column
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#Take 2 params:
#1: Color stored in $a2
#2: Block index stored in $t6
save_color_next_column:
    la $t9, NEXT_COLUMN_COLORS_4  # base address of next column array
    mul $t1, $t6, 4             # calculate offset (index * 4 bytes)
    add $t9, $t9, $t1           # add offset to base address
    sw $a2, 0($t9)              # store color at calculated address
    jr $ra
    
#Generate a random number and push it to top of stack
#NO PARAMS
generate_random_num:
    li $v0, 42              # syscall 42 = random int range
    li $a0, 0               # random number generator ID
    li $a1, 6               # upper bound (generates 0-5)
    syscall                 # result stored in $a0
    
    addi $sp, $sp, -4       # push result to stack
    sw $a0, 0($sp)
    jr $ra

#ONE PARAMETER: ON TOP OF STACK - NUMBER TO FIND COLOR
get_color_from_number:
    lw $t0, 0($sp)          # pop number from stack
    addi $sp, $sp, 4
    
    # Check which number and branch to corresponding color
    li $t1, 1
    beq $t0, $t1, eq_one    # if 1, return red
    li $t1, 2
    beq $t0, $t1, eq_two    # if 2, return blue
    li $t1, 3
    beq $t0, $t1, eq_three  # if 3, return yellow
    li $t1, 4
    beq $t0, $t1, eq_four   # if 4, return green
    li $t1, 5
    beq $t0, $t1, eq_five   # if 5, return purple
    
#Return Orange when 0
else:
    lw $t3, COLOR_ORANGE
    addi $sp, $sp, -4       # push color to stack
    sw $t3, 0($sp)
    j get_color_from_number_end
    
#Return Red when 1
eq_one:
    lw $t3, COLOR_RED
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Blue when 2
eq_two:
    lw $t3, COLOR_BLUE
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Yellow when 3
eq_three:
    lw $t3, COLOR_YELLOW
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Green when 4
eq_four:
    lw $t3, COLOR_GREEN
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return Purple when 5
eq_five:
    lw $t3, COLOR_PURPLE
    addi $sp, $sp, -4
    sw $t3, 0($sp)
    j get_color_from_number_end

#Return back
get_color_from_number_end:
    jr $ra

# Takes 3 params
# $a0 -> x
# $a1 -> y
# $a2 -> color
draw_pixel:
    lw $t0, ADDR_DSPL
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    lw $a2, 8($sp)
    addi $sp, $sp, 12
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


# Takes 3 params
# $a0 -> x
# $a1 -> y
# $a2 -> color

#NO PARAMS LOAD COLUMN COORDINATE FROM MEMORY
draw_curr_column:
    la $t9, CURR_COLUMN_COORD
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    la $t8, CURR_COLUMN_COLORS
    li $t7, 0
    li $a3, 3
    #LOAD IN Y OFFSET TO CHECK WHEN TO DRAW PIXEL
    la $t6 GAMEBOARD_OFFSET_Y
    lw $t5, 0($t6)
    
    addi $sp, $sp, -4
    sw $ra, 0($sp)
draw_curr_column_loop:
    bge $t7, $a3, draw_curr_end
    lw $a2, 0($t8)
    
    #CHECK IF COLUMN IS ABOVE CEILING IF SO CONTINUE AND DO NOT DRAW
    ble $a1, $t5 skip_draw_pixel
    addi $sp, $sp, -12
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel

skip_draw_pixel:
    addi $t8, $t8, 4
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j draw_curr_column_loop
draw_curr_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra
    
draw_next_columns:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal draw_next_column
    jal draw_next_column_2
    jal draw_next_column_3
    jal draw_next_column_4
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    
    jr $ra
    

#NO PARAMS LOAD NEXT COLUMN FROM MEMORY
draw_next_column:
    lw $a0, NEXT_COLUMN_X
    lw $a1, NEXT_COLUMN_Y
    la $t8, NEXT_COLUMN_COLORS
    li $t7, 0
    li $a3, 3
    addi $sp, $sp, -4
    sw $ra, 0($sp)
draw_next_column_loop:
    bge $t7, $a3, draw_next_end
    lw $a2, 0($t8)
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel
    addi $t8, $t8, 4
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j draw_next_column_loop
draw_next_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_next_column_4:
    lw $a0, NEXT_COLUMN_X
    lw $a1, NEXT_COLUMN_Y
    la $t8, NEXT_COLUMN_COLORS_4
    addi $a0, $a0, 6
    li $t7, 0
    li $a3, 3
    addi $sp, $sp, -4
    sw $ra, 0($sp)
draw_next_column_4_loop:
    bge $t7, $a3, draw_next_4_end
    lw $a2, 0($t8)
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel
    addi $t8, $t8, 4
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j draw_next_column_4_loop
draw_next_4_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_next_column_2:
    lw $a0, NEXT_COLUMN_X
    lw $a1, NEXT_COLUMN_Y
    la $t8, NEXT_COLUMN_COLORS_2
    addi $a0, $a0, 2
    li $t7, 0
    li $a3, 3
    addi $sp, $sp, -4
    sw $ra, 0($sp)
draw_next_column_2_loop:
    bge $t7, $a3, draw_next_2_end
    lw $a2, 0($t8)
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel
    addi $t8, $t8, 4
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j draw_next_column_2_loop
draw_next_2_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

draw_next_column_3:
    lw $a0, NEXT_COLUMN_X
    lw $a1, NEXT_COLUMN_Y
    addi $a0, $a0, 4
    la $t8, NEXT_COLUMN_COLORS_3
    li $t7, 0
    li $a3, 3
    addi $sp, $sp, -4
    sw $ra, 0($sp)
draw_next_column_3_loop:
    bge $t7, $a3, draw_next_3_end
    lw $a2, 0($t8)
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    addi $sp, $sp, -4
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel
    addi $t8, $t8, 4
    addi $a1, $a1, 1
    addi $t7, $t7, 1
    j draw_next_column_3_loop
draw_next_3_end:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

#-------
# END OF DRAW GAMEBOARD FUNCTIONS
#-------

#-------
# START OF DRAW IN GAME FUNCTION
#-------

# Draw all placed gems from PLAYING_FIELD
draw_playing_field:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    la $t7, PLAYING_FIELD       # base address of playing field
    lw $t8, GAMEBOARD_OFFSET_X
    lw $t9, GAMEBOARD_OFFSET_Y
    lw $t2, GAMEBOARD_WIDTH     # board width (8)
    lw $t3, GAMEBOARD_HEIGHT 
    
    li $t1, 0
dpf_y:
    bge $t1, $t3, dpf_done      # if y >= height, done
    li $t0, 0                   # x counter = 0
dpf_x:
    bge $t0, $t2, dpf_next_y
    
    # Calculate memory address: PLAYING_FIELD[y][x]
    sll $t4, $t1, 5             # y * 32 (y * 8 * 4)
    sll $t5, $t0, 2             # x * 4
    add $t6, $t7, $t4
    add $t6, $t6, $t5
    
    lw $a2, 0($t6)              # load color at this position
    beqz $a2, dpf_skip          # if color is 0 (empty), skip drawing
    
    # Calculate screen position
    add $a0, $t0, $t8           # x = board_x + offset_x
    addi $a0, $a0, 1            # +1 for left wall
    add $a1, $t1, $t9           # y = board_y + offset_y
    addi $a1, $a1, 1            # +1 for ceiling
    
    # Save all registers before function call
    addi $sp, $sp, -32
    sw $t0, 0($sp)
    sw $t1, 4($sp)
    sw $t2, 8($sp)
    sw $t3, 12($sp)
    sw $t7, 16($sp)
    sw $t8, 20($sp)
    sw $t9, 24($sp)
    sw $ra, 28($sp)
    
    # Push draw_pixel parameters
    addi $sp, $sp, -12
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal draw_pixel
    
    # Restore all registers
    lw $t0, 0($sp)
    lw $t1, 4($sp)
    lw $t2, 8($sp)
    lw $t3, 12($sp)
    lw $t7, 16($sp)
    lw $t8, 20($sp)
    lw $t9, 24($sp)
    lw $ra, 28($sp)
    addi $sp, $sp, 32
dpf_skip:
    addi $t0, $t0, 1            # x++
    j dpf_x
dpf_next_y:
    addi $t1, $t1, 1            # y++
    j dpf_y
dpf_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# 3 PARAMETERS: (THESE WILL BE PASSED IN THROUGH THE STACK)
# 1 x coordinate
# 2 y coordinate 
# 3 color 
store_in_playing_field:
    la $t7, PLAYING_FIELD       # load base address of playing field
    lw $t0, 0($sp)              # pop x coordinate
    lw $t1, 4($sp)              # pop y coordinate
    lw $t2, 8($sp)              # pop color
    addi $sp, $sp, 12           # adjust stack pointer
    
    lw $t3, GAMEBOARD_OFFSET_X
    lw $t4, GAMEBOARD_OFFSET_Y
    
    # Convert screen coordinates to board coordinates
    sub $t0, $t0, $t3           # x = x - offset_x
    sub $t1, $t1, $t4           # y = y - offset_y
    addi $t0, $t0, -1           # -1 for left wall
    addi $t1, $t1, -1           # -1 for ceiling
    
    # Calculate memory offset: (y * 8 + x) * 4
    sll $t1, $t1, 5             # y * 32 (y * 8 * 4)
    sll $t0, $t0, 2             # x * 4
    
    # Calculate final address and store
    add $t7, $t7, $t1
    add $t7, $t7, $t0
    sw $t2, 0($t7)              # store color at calculated address
    jr $ra

#------
# COLLISION AND PLACEMENT LOGIC
#------

# Check if column should be placed and handle placement
check_collision_and_place:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Get current column position
    la $t9, CURR_COLUMN_COORD
    lw $a0, 0($t9)              # x coordinate
    lw $a1, 4($t9)              # y coordinate (top gem)
    addi $a1, $a1, 2            # move to bottom gem (y + 2)
    addi $a1, $a1, 1            # check one position below bottom gem
    
    # Check if collision would occur below
    addi $sp, $sp, -8
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    jal check_collision
    
    lw $v1, 0($sp)              # get collision result
    addi $sp, $sp, 4
    
    beq $v1, 1, place_gems      # if collision detected, place gems
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

place_gems:
    la $t9, CURR_COLUMN_COORD   # get column position
    la $t8, CURR_COLUMN_COLORS  # get column colors
    lw $a0, 0($t9)              # x coordinate
    lw $a1, 4($t9)              # y coordinate (top gem)
    
    # Place gem 1 (top)
    lw $a2, 0($t8)              # get first color
    addi $sp, $sp, -12
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal store_in_playing_field
    
    # Place gem 2 (middle)
    lw $a0, 0($t9)
    lw $a1, 4($t9)
    addi $a1, $a1, 1            # y + 1
    lw $a2, 4($t8)              # get second color
    addi $sp, $sp, -12
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal store_in_playing_field
    
    # Place gem 3 (bottom)
    lw $a0, 0($t9)
    lw $a1, 4($t9)
    addi $a1, $a1, 2            # y + 2
    lw $a2, 8($t8)              # get third color
    addi $sp, $sp, -12
    sw $a0, 0($sp)
    sw $a1, 4($sp)
    sw $a2, 8($sp)
    jal store_in_playing_field
    
    # Check for matches and clear them
    jal check_matches
    
    # Generate new column and reset position
    jal change_curr_column_from_next
    jal setup_column_position
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

# Check if position (a0, a1) has collision
# Parameters: a0 = x, a1 = y (on stack)
# Returns: v1 = 1 if collision, 0 if clear (on stack)
check_collision:
    lw $a0, 0($sp)
    lw $a1, 4($sp)
    addi $sp, $sp, 8
    lw $t0, GAMEBOARD_OFFSET_Y
    lw $t1, GAMEBOARD_HEIGHT
    add $t1, $t1, $t0
    bge $a1, $t1, collision_yes
    lw $t0, GAMEBOARD_OFFSET_X
    lw $t2, GAMEBOARD_WIDTH
    add $t2, $t2, $t0
    
    ble $a0, $t0, collision_yes
    bge $a0, $t2, collision_yes
    la $t7, PLAYING_FIELD
    lw $t3, GAMEBOARD_OFFSET_X
    lw $t4, GAMEBOARD_OFFSET_Y
    sub $t0, $a0, $t3
    sub $t1, $a1, $t4
    addi $t0, $t0, -1
    addi $t1, $t1, -1
    bltz $t0, collision_no
    bltz $t1, collision_no
    lw $t5, GAMEBOARD_WIDTH
    bge $t0, $t5, collision_no
    lw $t5, GAMEBOARD_HEIGHT
    bge $t1, $t5, collision_no
    sll $t1, $t1, 5
    sll $t0, $t0, 2
    add $t7, $t7, $t1
    add $t7, $t7, $t0
    lw $t2, 0($t7)
    bnez $t2, collision_yes
collision_no:
    li $t5, 0
    addi $sp, $sp, -4
    sw $t5, 0($sp)
    jr $ra
collision_yes:
    li $t5, 1
    addi $sp, $sp, -4
    sw $t5, 0($sp)
    jr $ra

#------
# MATCHING LOGIC
#------

# Check and clear all matches (3+ in a row)
check_matches:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
check_again:
    # Clear horizontal/vertical matches and apply gravity
    jal clear_horizontal
    jal clear_vertical
    jal apply_gravity
    
    #double check again in case of registration bugs
    jal clear_horizontal
    jal apply_gravity
    
    # Note: In full implementation, would loop if matches found
    # to handle chain reactions
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra



#------------------------------------------------------------------------------------------
# Find and clear horizontal matches
# Returns: 1 if any matches found, 0 otherwise
clear_horizontal:
    la $t7, PLAYING_FIELD       # base address of playing field
    lw $t8, GAMEBOARD_WIDTH     # width = 8
    lw $t9, GAMEBOARD_HEIGHT    # height = 16
    li $t1, 0                   # y counter = 0
h_y_loop:
    bge $t1, $t9, h_done        # for each row
    li $t0, 0                   # x counter = 0
h_x_loop:
    bge $t0, $t8, h_next_y      # for each column
    
    # Get color at current position (x, y)
    mul $t3, $t1, 32            # y offset = y * 8 * 4
    mul $t4, $t0, 4             # x offset = x * 4
    add $t5, $t7, $t3           # add y offset to base
    add $t5, $t5, $t4           # add x offset
    lw $t6, 0($t5)              # load color
    
    beqz $t6, h_skip            # if empty (color = 0), skip
    
    # Count consecutive gems of same color
    li $s1, 1                   # match count = 1 (current gem)
    addi $s3, $t0, 1            # check starting from next position
h_count:
    bge $s3, $t8, h_check       # if reached end of row, check count
    
    # Get color at (current_x, y)
    mul $t3, $t1, 32
    mul $t4, $s3, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $s4, 0($t5)              # load color at next position
    
    bne $s4, $t6, h_check       # if different color, stop counting
    
    addi $s1, $s1, 1            # increment match count
    addi $s3, $s3, 1            # move to next position
    j h_count
h_check:
    blt $s1, 3, h_skip          # if less than 3 in a row, skip
    
    # Clear matched gems (set to 0)
    move $s5, $t0               # start from first gem in match
h_clear:
    bge $s5, $s3, h_skip        # clear until end of match
    
    mul $t3, $t1, 32
    mul $t4, $s5, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear gem (set color to 0)
    
    addi $s5, $s5, 1
    j h_clear
h_skip:
    addi $t0, $t0, 1            # move to next column
    j h_x_loop
h_next_y:
    addi $t1, $t1, 1            # move to next row
    j h_y_loop
h_done:
    jr $ra

#---------------------------------------------------------------------------------------------------------
# Find and clear vertical matches
# Returns: 1 if any matches found, 0 otherwise
clear_vertical:
    la $t7, PLAYING_FIELD       # base address of playing field
    lw $t8, GAMEBOARD_WIDTH     # width = 8
    lw $t9, GAMEBOARD_HEIGHT    # height = 16
    li $t0, 0                   # x counter = 0
v_x_loop:
    bge $t0, $t8, v_done        # for each column
    li $t1, 0                   # y counter = 0
v_y_loop:
    bge $t1, $t9, v_next_x      # for each row
    
    # Get color at current position (x, y)
    mul $t3, $t1, 32            # y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $t6, 0($t5)              # load color
    
    beqz $t6, v_skip            # if empty, skip
    
    # Count consecutive gems of same color going down
    li $s1, 1                   # match count = 1
    addi $s3, $t1, 1            # check starting from next row
v_count:
    bge $s3, $t9, v_check       # if reached bottom, check count
    
    # Get color at (x, current_y)
    mul $t3, $s3, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $s4, 0($t5)              # load color below
    
    bne $s4, $t6, v_check       # if different color, stop
    
    addi $s1, $s1, 1            # increment match count
    addi $s3, $s3, 1            # move down one row
    j v_count
v_check:
    blt $s1, 3, v_skip          # need at least 3 in a column
    
    # Clear matched gems
    move $s5, $t1               # start from first gem
v_clear:
    bge $s5, $s3, v_skip        # clear until end of match
    
    mul $t3, $s5, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear gem
    
    addi $s5, $s5, 1
    j v_clear
v_skip:
    addi $t1, $t1, 1            # move to next row
    j v_y_loop
v_next_x:
    addi $t0, $t0, 1            # move to next column
    j v_x_loop
v_done:
    jr $ra

# Apply gravity - make gems fall down into empty spaces
apply_gravity:
    la $t7, PLAYING_FIELD       # base address
    lw $t8, GAMEBOARD_WIDTH     # width = 8
    lw $t9, GAMEBOARD_HEIGHT    # height = 16
    li $t0, 0                   # x counter = 0
g_x_loop:
    bge $t0, $t8, g_done        # for each column
    addi $t1, $t9, -1           # y counter = height - 1 (start from bottom)
g_y_loop:
    bltz $t1, g_next_x          # if y < 0, done with this column
    
    # Check if current position is empty
    mul $t3, $t1, 32            # y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $t6, 0($t5)              # load color at current position
    
    bnez $t6, g_skip            # if not empty, skip to next position
    
    # Found empty space - look for gem above to fall down
    addi $s1, $t1, -1           # start searching one row above
g_find:
    bltz $s1, g_skip            # if no more rows above, skip
    
    # Check if gem exists above
    mul $t3, $s1, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $s2, 0($t5)              # load color above
    
    beqz $s2, g_find_next       # if empty, keep searching upward
    
    # Found gem above - move it down to empty space
    # Store gem in empty position
    mul $t3, $t1, 32            # empty position y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $s2, 0($t5)              # move gem down
    
    # Clear old position
    mul $t3, $s1, 32            # old position y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear old position
    
    j g_skip                    # done with this empty space
g_find_next:
    addi $s1, $s1, -1           # check next row up
    j g_find
g_skip:
    addi $t1, $t1, -1           # move up one row
    j g_y_loop
g_next_x:
    addi $t0, $t0, 1            # move to next column
    j g_x_loop
g_done:
    jr $ra

#------
# END OF DRAW IN GAME FUNCTIONS
#------

#------
# KEYBOARD FUNCTIONS
#------
keyboard_input_check:
    lw $t0, ADDR_KBRD           # load keyboard address
    lw $t8, 0($t0)              # check if key is pressed (1 = yes, 0 = no)
    beq $t8, 1, keyboard_input  # if key pressed, process it
    jr $ra                       # otherwise return

keyboard_input:
    lw $t0, ADDR_KBRD           # load keyboard address
    lw $t2, 4($t0)              # load ASCII value of key pressed
    beq $t2, 0x71, respond_to_Q # if 'q', quit game
    beq $t2, 0x61, respond_to_A # if 'a', move left
    beq $t2, 0x64, respond_to_D # if 'd', move right
    beq $t2, 0x73, respond_to_S # if 's', move down
    beq $t2, 0x77, respond_to_W # if 'w', rotate colors
    jr $ra                       # if other key, ignore

respond_to_A:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY TO THE LEFT
    addi $a0, $a0, -1

response_to_A_check_loop:
    bge $t7, $a3, move_gems_left
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #New x coord
    sw $a1, 4($sp) #y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #New x coord
    sw $a1, 12($sp) #y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_A
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_A_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_left:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    addi $a0, $a0, -1 #Move x coordinate left
    sw $a0, 0($t9) #Update coordinate of x in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_A:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    
    
respond_to_D:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY TO THE RIGHT
    addi $a0, $a0, 1

response_to_D_check_loop:
    bge $t7, $a3, move_gems_right
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #New x coord
    sw $a1, 4($sp) #y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #New x coord
    sw $a1, 12($sp) #y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord    
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_D
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_D_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_right:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    addi $a0, $a0, 1 #Move x coordinate right
    sw $a0, 0($t9) #Update coordinate of x in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_D:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    
    
respond_to_S:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY DOWNWARD
    addi $a1, $a1, 1

response_to_S_check_loop:
    bge $t7, $a3, move_gems_down
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #x coord
    sw $a1, 4($sp) #New y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #x coord
    sw $a1, 12($sp) #New y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_S
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_S_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_down:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a1, 4($t9) #y coord
    addi $a1, $a1, 1 #Move y coordinate down
    sw $a1, 4($t9) #Update coordinate of y in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_S:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    

respond_to_W:
    #STEP 0: LOAD IN COLUMN COLORS
    la $t8, CURR_COLUMN_COLORS
    lw $t0, 0($t8) #First color
    lw $t1, 4($t8) #Second color
    lw $t2, 8($t8) #Third color

W_swap_colors:
    #SWAP COLORS (rotate upward)
    sw $t2, 0($t8) #Bottom -> Top
    sw $t0, 4($t8) #Top -> Middle
    sw $t1, 8($t8) #Middle -> Bottom

return_response_W:
    jr $ra  


#TERMINATE PROGRAM
respond_to_Q:
    li $v0, 10
    syscall
#------
# END OF KEYBOARD FUNCTIONS
#------

#-------
# Boundary Checker Logic Function (INCLUDING COLLISIONS)
#-------

#PARAMETERS:
# $a0: x coordinate 
# $a1: y coordinate
# WILL RETURN 1 IF VALID (NO COLLISION) OTHERWISE 0
check_in_bounds:
    #Step 0: Load in input parameters
    lw $a0, 0($sp) # x coordinate
    lw $a1, 4($sp) # y coordinate
    addi $sp, $sp, 8
    
    #Step 1: Load in all 'Game boundary' values
    lw $t0, GAMEBOARD_OFFSET_X
    lw $t1, GAMEBOARD_OFFSET_Y
    lw $t2, GAMEBOARD_WIDTH
    lw $t3, GAMEBOARD_HEIGHT
    
    #Step 2: Compute boundaries
    #Compute farther x boundary
    add $t2, $t2, $t0 
    
    #compute bottom y boundary
    add $t3, $t3, $t1
    addi $t3, $t3, 1
    
    #Step 3: branch statements to check if points are in boundaries (DO NOT NEED TO CHECK FOR Y AS WE WILL SET THE STARTING POINT)
    bge $a0, $t2, out_of_bounds_return #Check if x coordinate is out of bounds
    bge $a1, $t3, out_of_bounds_return #Check if y coordinate is out of bounds
    ble $a0, $t0, out_of_bounds_return #Check if x coordinate is out of bounds (too small)

in_of_bounds_return:
    #push 1 to stack so caller can pop and return
    li $t5, 1
    addi $sp, $sp, -4
    sw $t5, 0($sp)

return_from_bounds:
    jr $ra
    
out_of_bounds_return:
    #push 0 to stack so caller can pop and return
    li $t5, 0
    addi $sp, $sp, -4
    sw $t5, 0($sp)
    j return_from_boundslw $s4, 0($t5)              # load color at next position
    
    bne $s4, $t6, h_check       # if different color, stop counting
    
    addi $s1, $s1, 1            # increment match count
    addi $s3, $s3, 1            # move to next position
    j h_count
h_check:
    blt $s1, 3, h_skip          # if less than 3 in a row, skip
    
    # Clear matched gems (set to 0)
    move $s5, $t0               # start from first gem in match
h_clear:
    bge $s5, $s3, h_skip        # clear until end of match
    
    mul $t3, $t1, 32
    mul $t4, $s5, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear gem (set color to 0)
    
    addi $s5, $s5, 1
    j h_clear
h_skip:
    addi $t0, $t0, 1            # move to next column
    j h_x_loop
h_next_y:
    addi $t1, $t1, 1            # move to next row
    j h_y_loop
h_done:
    jr $ra

#---------------------------------------------------------------------------------------------------------
# Find and clear vertical matches
# Returns: 1 if any matches found, 0 otherwise
clear_vertical:
    la $t7, PLAYING_FIELD       # base address of playing field
    lw $t8, GAMEBOARD_WIDTH     # width = 8
    lw $t9, GAMEBOARD_HEIGHT    # height = 16
    li $t0, 0                   # x counter = 0
v_x_loop:
    bge $t0, $t8, v_done        # for each column
    li $t1, 0                   # y counter = 0
v_y_loop:
    bge $t1, $t9, v_next_x      # for each row
    
    # Get color at current position (x, y)
    mul $t3, $t1, 32            # y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $t6, 0($t5)              # load color
    
    beqz $t6, v_skip            # if empty, skip
    
    # Count consecutive gems of same color going down
    li $s1, 1                   # match count = 1
    addi $s3, $t1, 1            # check starting from next row
v_count:
    bge $s3, $t9, v_check       # if reached bottom, check count
    
    # Get color at (x, current_y)
    mul $t3, $s3, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $s4, 0($t5)              # load color below
    
    bne $s4, $t6, v_check       # if different color, stop
    
    addi $s1, $s1, 1            # increment match count
    addi $s3, $s3, 1            # move down one row
    j v_count
v_check:
    blt $s1, 3, v_skip          # need at least 3 in a column
    
    # Clear matched gems
    move $s5, $t1               # start from first gem
v_clear:
    bge $s5, $s3, v_skip        # clear until end of match
    
    mul $t3, $s5, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear gem
    
    addi $s5, $s5, 1
    j v_clear
v_skip:
    addi $t1, $t1, 1            # move to next row
    j v_y_loop
v_next_x:
    addi $t0, $t0, 1            # move to next column
    j v_x_loop
v_done:
    jr $ra

# Apply gravity - make gems fall down into empty spaces
apply_gravity:
    la $t7, PLAYING_FIELD       # base address
    lw $t8, GAMEBOARD_WIDTH     # width = 8
    lw $t9, GAMEBOARD_HEIGHT    # height = 16
    li $t0, 0                   # x counter = 0
g_x_loop:
    bge $t0, $t8, g_done        # for each column
    addi $t1, $t9, -1           # y counter = height - 1 (start from bottom)
g_y_loop:
    bltz $t1, g_next_x          # if y < 0, done with this column
    
    # Check if current position is empty
    mul $t3, $t1, 32            # y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $t6, 0($t5)              # load color at current position
    
    bnez $t6, g_skip            # if not empty, skip to next position
    
    # Found empty space - look for gem above to fall down
    addi $s1, $t1, -1           # start searching one row above
g_find:
    bltz $s1, g_skip            # if no more rows above, skip
    
    # Check if gem exists above
    mul $t3, $s1, 32
    mul $t4, $t0, 4
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    lw $s2, 0($t5)              # load color above
    
    beqz $s2, g_find_next       # if empty, keep searching upward
    
    # Found gem above - move it down to empty space
    # Store gem in empty position
    mul $t3, $t1, 32            # empty position y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $s2, 0($t5)              # move gem down
    
    # Clear old position
    mul $t3, $s1, 32            # old position y offset
    mul $t4, $t0, 4             # x offset
    add $t5, $t7, $t3
    add $t5, $t5, $t4
    sw $zero, 0($t5)            # clear old position
    
    j g_skip                    # done with this empty space
g_find_next:
    addi $s1, $s1, -1           # check next row up
    j g_find
g_skip:
    addi $t1, $t1, -1           # move up one row
    j g_y_loop
g_next_x:
    addi $t0, $t0, 1            # move to next column
    j g_x_loop
g_done:
    jr $ra

#------
# END OF DRAW IN GAME FUNCTIONS
#------

#------
# KEYBOARD FUNCTIONS
#------
keyboard_input_check:
    lw $t0, ADDR_KBRD           # load keyboard address
    lw $t8, 0($t0)              # check if key is pressed (1 = yes, 0 = no)
    beq $t8, 1, keyboard_input  # if key pressed, process it
    jr $ra                       # otherwise return

keyboard_input:
    lw $t0, ADDR_KBRD           # load keyboard address
    lw $t2, 4($t0)              # load ASCII value of key pressed
    beq $t2, 0x71, respond_to_Q # if 'q', quit game
    beq $t2, 0x61, respond_to_A # if 'a', move left
    beq $t2, 0x64, respond_to_D # if 'd', move right
    beq $t2, 0x73, respond_to_S # if 's', move down
    beq $t2, 0x77, respond_to_W # if 'w', rotate colors
    jr $ra                       # if other key, ignore

respond_to_A:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY TO THE LEFT
    addi $a0, $a0, -1

response_to_A_check_loop:
    bge $t7, $a3, move_gems_left
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #New x coord
    sw $a1, 4($sp) #y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #New x coord
    sw $a1, 12($sp) #y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_A
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_A_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_left:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    addi $a0, $a0, -1 #Move x coordinate left
    sw $a0, 0($t9) #Update coordinate of x in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_A:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    
    
respond_to_D:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY TO THE RIGHT
    addi $a0, $a0, 1

response_to_D_check_loop:
    bge $t7, $a3, move_gems_right
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #New x coord
    sw $a1, 4($sp) #y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #New x coord
    sw $a1, 12($sp) #y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord    
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_D
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_D_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_right:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    addi $a0, $a0, 1 #Move x coordinate right
    sw $a0, 0($t9) #Update coordinate of x in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_D:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    
    
respond_to_S:
    #STEP 0: LOAD IN COLUMN COORDINATIONS (THESE WILL BE THE CORDS OF THE TOP GEM)
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a0, 0($t9) #x coord
    lw $a1, 4($t9) #y coord
    
    #Save return address
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    #Initialize count and loop condition registers (loop 3 times)
    li $t7, 0
    li $a3, 3
    
    #STEP 1: CHECK VALID BOUNDARY DOWNWARD
    addi $a1, $a1, 1

response_to_S_check_loop:
    bge $t7, $a3, move_gems_down
    
    #load onto stack to be used
    addi $sp, $sp, -16
    sw $a0, 0($sp) #x coord
    sw $a1, 4($sp) #New y coord    
    #SAVE VALUES SO WE CAN REVERT OUR REGISTERS
    sw $a0, 8($sp) #x coord
    sw $a1, 12($sp) #New y coord
    
    jal check_collision
    
    lw $v1, 0($sp) #RETURN VALUE FROM 'check_collision'
    lw $a0, 4($sp) #New x coord
    lw $a1, 8($sp) #y coord    
    addi $sp, $sp, 12
    #IF INVALID MOVE RETURN AND DO NOTHING
    bne $v1, 0, return_response_S
    
    addi $t7, $t7, 1 #Increment counter
    addi $a1, $a1, 1 #Update GEM Coordinate
    j response_to_S_check_loop

#IF ALL MOVES VALID MOVE GEMS
move_gems_down:
    la $t9, CURR_COLUMN_COORD #Get base address of column
    lw $a1, 4($t9) #y coord
    addi $a1, $a1, 1 #Move y coordinate down
    sw $a1, 4($t9) #Update coordinate of y in COLUMN_COORD
    
#IF NOT VALID DO NOTHING
return_response_S:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra    

respond_to_W:
    #STEP 0: LOAD IN COLUMN COLORS
    la $t8, CURR_COLUMN_COLORS
    lw $t0, 0($t8) #First color
    lw $t1, 4($t8) #Second color
    lw $t2, 8($t8) #Third color

W_swap_colors:
    #SWAP COLORS (rotate upward)
    sw $t2, 0($t8) #Bottom -> Top
    sw $t0, 4($t8) #Top -> Middle
    sw $t1, 8($t8) #Middle -> Bottom

return_response_W:
    jr $ra  


#TERMINATE PROGRAM
respond_to_Q:
    li $v0, 10
    syscall
#------
# END OF KEYBOARD FUNCTIONS
#------

#-------
# Boundary Checker Logic Function (INCLUDING COLLISIONS)
#-------

#PARAMETERS:
# $a0: x coordinate 
# $a1: y coordinate
# WILL RETURN 1 IF VALID (NO COLLISION) OTHERWISE 0
check_in_bounds:
    #Step 0: Load in input parameters
    lw $a0, 0($sp) # x coordinate
    lw $a1, 4($sp) # y coordinate
    addi $sp, $sp, 8
    
    #Step 1: Load in all 'Game boundary' values
    lw $t0, GAMEBOARD_OFFSET_X
    lw $t1, GAMEBOARD_OFFSET_Y
    lw $t2, GAMEBOARD_WIDTH
    lw $t3, GAMEBOARD_HEIGHT
    
    #Step 2: Compute boundaries
    #Compute farther x boundary
    add $t2, $t2, $t0 
    
    #compute bottom y boundary
    add $t3, $t3, $t1
    addi $t3, $t3, 1
    
    #Step 3: branch statements to check if points are in boundaries (DO NOT NEED TO CHECK FOR Y AS WE WILL SET THE STARTING POINT)
    bge $a0, $t2, out_of_bounds_return #Check if x coordinate is out of bounds
    bge $a1, $t3, out_of_bounds_return #Check if y coordinate is out of bounds
    ble $a0, $t0, out_of_bounds_return #Check if x coordinate is out of bounds (too small)

in_of_bounds_return:
    #push 1 to stack so caller can pop and return
    li $t5, 1
    addi $sp, $sp, -4
    sw $t5, 0($sp)

return_from_bounds:
    jr $ra
    
out_of_bounds_return:
    #push 0 to stack so caller can pop and return
    li $t5, 0
    addi $sp, $sp, -4
    sw $t5, 0($sp)
    j return_from_bounds