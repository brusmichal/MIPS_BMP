#-------------------------------------------------------------------------------
#author: Zbigniew Szymanski
#data : 2018.05.07
#description : example program for reading, modifying and writing a BMP file 
#-------------------------------------------------------------------------------

#only 24-bits 600x50 pixels BMP files are supported
.eqv BMP_FILE_SIZE 230454
.eqv BYTES_PER_ROW 960

	.data
#space for the 320x240px 24-bits bmp image
.align 4
res:	.space 2
image:	.space BMP_FILE_SIZE

fname:	.asciiz "markers.bmp"
	.text
main:
	jal	read_bmp

	li	$a0, -1		#x
	li	$a1, -1		#y

	
	
	#li 	$a2, 0x00FF0000	#color - 00RRGGBB
	#jal	put_pixel
x_loop:
	beq $a0, 319, y_loop		#end of line, go to next above
	
	jal get_pixel		
	beqz $v0, black_detected
	addi $a0, $a0, 1		#increment x
	j x_loop
y_loop:
	beq $a1, 239, end		#top of the picture, end
	addi $a1, $a1, 1		#increment y
	j x_loop			#proceed to checking the row

black_detected:
	la $t8, ($a0)			#save x coordinate for P
	la $t9, ($a1)			#save y coordinate for P
	la $t7, ($zero)			#width_counter=0
	j check_width
	
check_width:
	addi $a0, $a0, 1		#increment x
	jal get_pixel
	beqz $v0, check_width		#if the next pixel is black continue
	sub $t7, $a0, $t8		#if not then calculate width
	la $t6, ($zero)			#height=0
	la $a0, ($t8)			#restore x before proceeding to checking height
	j check_height

check_height:

	addi $a1, $a1, 1		#increment y
	jal get_pixel
	beqz $v0, check_height		#if the pixel above is black continue
	sub $t6, $a1, $t9		#if not then calculate height
	beq $t6, $t7, pre_thick_right	#if H=W then proceed to cleaning and the to checking thickness of arms
	j pre_loop_x_clean		#if not go back to loop_x
	
pre_loop_x_clean:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	addi $a0, $a0, 1		#increment x
	j loop_x			#go back to loop_x after cleaning
	
pre_thick_right:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	la $t5, ($zero)			#thick_right=0
	j check_thick_right
	
check_thick_right:
	
	add $a0, $a0, $t7 		#move to the end of bottom bar
	addi $a1, $a1, 1		#increment y
	jal get_pixel
	beqz $v0, check_thick_right	#if pixel above is black continue
	sub $5, $a1, $t9		#if not then calculate thickness of right arm
	j pre_thick_top	
	
pre_thick_top:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	la $t4, ($zero)			#thick_top=0
	j check_thick_top
	
check_thick_top:
	add $a1, $a1, $t6 		#move to the beginnig of top bar
	addi $a0, $a0, 1		#increment x
	jal get_pixel
	beqz $v0, check_thick_top	#if the next pixel is black continue
	sub $t4, $a0, $t8		#if not then calculate thickness of top arm
	beq $t4, $t5, pre_check_inside	#if thickness of right and top arm are equal proceed to checking inside
	j pre_loop_x_clean		#if not then go back to the loop_x

pre_check_inside:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	add $6, $6, $a0			#x coordinate of bottom right vertex
	add $7, $7, $a1			#y coordinate of top left vertex
	j check_inside_x

check_inside_x:
	beq $a0, $7, check_inside_y	#if end of the row go to the line above
	jal get_pixel	
	bnez $v0, pre_loop_x_clean	#if white detected then go back to loop_x
	addi $a0, $a0, 1		#increment x
	j check_inside_x
	
check_inside_y:
	beq $a1, $6, pre_check_outside	#top of the picture, proceed to checking the outside
	addi $a1, $a1, 1		#increment y
	j check_inside_x		#proceed to checking the next row
	
pre_check_outside:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	j check_conditions
	
check_conditions:
	beq $a0, 0, no_left_border		#if tag touches one of the borders of image then don't check that border
	beq $a1, 0, no_bottom_border
	beq $6, 240, no_top_border
	beq $7, 320, no_right_border
	
	sub $a0, $a0, 1			#move below P
	j check_bottom
	
check_bottom:
	beq $a0, $7, check_right
	jal get_pixel
	bnez pre_loop_x_check
	addi $a0, $a0, 1
	j check_bottom
	
	
	jal 	save_bmp

exit:	li 	$v0,10		#Terminate the program
	syscall

# ============================================================================
read_bmp:
#description: 
#	reads the contents of a bmp file into memory
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 0		#flags: 0-read file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#read file
	li $v0, 14
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================
save_bmp:
#description: 
#	saves bmp file stored in memory to a file
#arguments:
#	none
#return value: none
	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)
	sub $sp, $sp, 4		#push $s1
	sw $s1, 4($sp)
#open file
	li $v0, 13
        la $a0, fname		#file name 
        li $a1, 1		#flags: 1-write file
        li $a2, 0		#mode: ignored
        syscall
	move $s1, $v0      # save the file descriptor
	
#check for errors - if the file was opened
#...

#save file
	li $v0, 15
	move $a0, $s1
	la $a1, image
	li $a2, BMP_FILE_SIZE
	syscall

#close file
	li $v0, 16
	move $a0, $s1
        syscall
	
	lw $s1, 4($sp)		#restore (pop) $s1
	add $sp, $sp, 4
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra


# ============================================================================
put_pixel:
#description: 
#	sets the color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#	$a2 - 0RGB - pixel color
#return value: none

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#set new color
	sb $a2,($t2)		#store B
	srl $a2,$a2,8
	sb $a2,1($t2)		#store G
	srl $a2,$a2,8
	sb $a2,2($t2)		#store R

	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra
# ============================================================================
get_pixel:
#description: 
#	returns color of specified pixel
#arguments:
#	$a0 - x coordinate
#	$a1 - y coordinate - (0,0) - bottom left corner
#return value:
#	$v0 - 0RGB - pixel color

	sub $sp, $sp, 4		#push $ra to the stack
	sw $ra,4($sp)

	la $t1, image + 10	#adress of file offset to pixel array
	lw $t2, ($t1)		#file offset to pixel array in $t2
	la $t1, image		#adress of bitmap
	add $t2, $t1, $t2	#adress of pixel array in $t2
	
	#pixel address calculation
	mul $t1, $a1, BYTES_PER_ROW #t1= y*BYTES_PER_ROW
	move $t3, $a0		
	sll $a0, $a0, 1
	add $t3, $t3, $a0	#$t3= 3*x
	add $t1, $t1, $t3	#$t1 = 3x + y*BYTES_PER_ROW
	add $t2, $t2, $t1	#pixel address 
	
	#get color
	lbu $v0,($t2)		#load B
	lbu $t1,1($t2)		#load G
	sll $t1,$t1,8
	or $v0, $v0, $t1
	lbu $t1,2($t2)		#load R
        sll $t1,$t1,16
	or $v0, $v0, $t1
					
	lw $ra, 4($sp)		#restore (pop) $ra
	add $sp, $sp, 4
	jr $ra

# ============================================================================

