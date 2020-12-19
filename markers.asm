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

info:	.asciiz "Wspolrzedne punktu P:\n"

x_info:	.asciiz "X: "

y_info:	.asciiz "Y: "

fname:	.asciiz "mymarkers.bmp"
	.text
	

main:
	jal	read_bmp

	li	$a0, 0	#x
	li	$a1, 0	#y
	j x_loop
	
	
	#li 	$a2, 0x00FF0000	#color - 00RRGGBB
	#jal	put_pixel
x_loop:
	beq $a0, 320, y_loop		#end of line, go to next above
	
	jal get_pixel		
	beqz $v0, black_detected
	addi $a0, $a0, 1		#increment x
	j x_loop
y_loop:
	beq $a1, 240, exit		#top of the picture, end
	addi $a1, $a1, 1		#increment y
	la $a0, ($zero)			#reset x
	j x_loop			#proceed to checking the row

black_detected:
	la $t8, ($a0)			#save x coordinate for P
	la $t9, ($a1)			#save y coordinate for P
	la $t7, ($zero)			#width_counter=0
	j check_width
	
check_width:
	addi $a0, $a0, 1		#increment x
	bgt $a0, 320, calculate_width
	jal get_pixel
	beqz $v0, check_width		#if the next pixel is black continue
	
	j calculate_width
	
calculate_width:
	sub $t7, $a0, $t8		
	sub $t7, $t7, 1			#if not then calculate width
	
	la $t6, ($zero)			#height=0
	la $a0, ($t8)			#restore x before proceeding to checking height
	j check_height

check_height:
	addi $a1, $a1, 1		#increment y
	bgt $a1, 240, calculate_height
	jal get_pixel
	beqz $v0, check_height		#if the pixel above is black continue
	
	j calculate_height
	
calculate_height:
	sub $t6, $a1, $t9		
	sub $t6, $t6, 1			#if not then calculate height
	
	beq $t6, $t7, pre_thick_right	#if H=W then proceed to cleaning and the to checking thickness of arms
	j pre_loop_x_clean		#if not go back to loop_x
	
pre_loop_x_clean:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	addi $a0, $a0, 1		#increment x
	j x_loop			#go back to loop_x after cleaning
	
pre_thick_right:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	la $t5, ($zero)			#thick_right=0
	add $a0, $a0, $t7 		#move to the end of bottom bar
	j check_thick_right
	
check_thick_right:
	
	
	addi $a1, $a1, 1		#increment y
	jal get_pixel
	beqz $v0, check_thick_right	#if pixel above is black continue
	sub $t5, $a1, $t9		#if not then calculate thickness of right arm
	j pre_thick_top	
	
pre_thick_top:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	la $t4, ($zero)			#thick_top=0
	add $a1, $a1, $t6 		#move to the beginnig of top bar
	j check_thick_top
	
check_thick_top:
	addi $a0, $a0, 1		#increment x
	jal get_pixel
	beqz $v0, check_thick_top	#if the next pixel is black continue
	
	sub $t4, $a0, $t8		#if not then calculate thickness of top arm
	
	beq $t4, $t5, pre_check_inside	#if thickness of right and top arm are equal proceed to checking inside
	j pre_loop_x_clean		#if not then go back to the loop_x

pre_check_inside:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	add $t4, $t4, $a0		#x coordinate of top right vertex
	add $t5, $t5, $a1		#y coordinate of top of right arm vertex
	add $t6, $t6, $a0		#x coordinate of bottom right vertex
	add $t7, $t7, $a1		#y coordinate of top left vertex
	j check_inside_x

check_inside_x:
	beq $a0, $t7, check_inside_y	#if end of the row go to the line above
	jal get_pixel	
	bnez $v0, pre_loop_x_clean	#if white detected then go back to loop_x
	addi $a0, $a0, 1		#increment x
	j check_inside_x
	
check_inside_y:
	bgt $a1, $t5, pre_check_inside_x_2	#top of the right arm, proceed to checking the upper arm
	addi $a1, $a1, 1		#increment y
	la $a0, ($t8)			#reset x
	j check_inside_x		#proceed to checking the next row
	
pre_check_inside_x_2:
	la $a0, ($t8)			#restore x
	la $a1, ($t5)			#set y to the height of thickness of right arm
	addi $a1, $a1, 1 		#set y to one above
	j check_inside_x_2
	
	
check_inside_x_2:
	beq $a0, $t4, check_inside_y_2	#if end of the row go to the line above
	jal get_pixel	
	bnez $v0, pre_loop_x_clean	#if white detected then go back to loop_x
	addi $a0, $a0, 1		#increment x
	j check_inside_x_2
	
check_inside_y_2:
	beq $a1, $t5, pre_check_outside	#top of the right arm, proceed to checking the outside
	addi $a1, $a1, 1		#increment y
	la $a0, ($t8)			#reset x
	j check_inside_x_2		#proceed to checking the next row
	
pre_check_outside:
	la $a0, ($t8)			#restore x
	la $a1, ($t9)			#restore y
	
	j pre_check_bottom
	
pre_check_bottom:
	addi $s4, $t4, 1		#set vertices to the outside
	addi $s5, $t5, 1
	addi $s6, $t6, 1
	addi $s7, $t7, 1	
	
					#if tag touches one of the borders of image then don't check that border
					
	beq $a1, 0, pre_check_right	#no bottom
	sub $a0, $a0, 1			#move below P
	
			
	j check_bottom
	
check_bottom:
	bgt $a0, $s7, pre_check_right	#check row below the bottom + 1
	jal get_pixel
	beqz $v0, pre_loop_x_clean	#if black pixel found then not a tag, go back to loop_x
	addi $a0, $a0, 1
	j check_bottom

pre_check_right:
	beq $t7, 320, pre_check_inner_top	#no right
	
	la $a0, ($s7)			#set x to width + 1
	la $a1, ($t9)			#restore y		
	j check_right

check_right:	
	bgt $a1, $s5, pre_check_inner_top	#end of checking, proceed to next border
	jal get_pixel
	beqz $v0, pre_loop_x_clean	#if black pixel found then not a tag, go back to loop_x
	addi $a1, $a1, 1
	j check_right
	
pre_check_inner_top:
	la $a0, ($t7)			#set x to width 
	la $a1, ($s5)			#set y to  right_thick +1
	j check_inner_top
	
check_inner_top:
	beq $a0, $t4, check_inner_right	#end of checking, proceed to next border
	jal get_pixel
	beqz $v0, pre_loop_x_clean	#if black pixel found then not a tag, go back to loop_x
	sub $a0, $a0, 1			
	j check_inner_top

check_inner_right:
	beq $a1, $t6, pre_check_top
	jal get_pixel
	beqz $v0, pre_loop_x_clean	#if black pixel found then not a tag, go back to loop_x
	addi $a1, $a1, 1
	j check_inner_right
	
pre_check_top:
	beq $t6, 240, pre_check_left #no top
	la $a0, ($t8)
	la $a1, ($s6)

check_top:
	bgt $a0, $s4, pre_check_left
	jal get_pixel
	beqz $v0, pre_loop_x_clean	#if black pixel found then not a tag, go back to loop_x
	addi $a0, $a0, 1
	j check_top

pre_check_left:
	beq $t8, 0, tag_found 	#no left
	la $a0, ($t8)
	sub $a0, $a0, 1		
	la $a1, ($t9)
	sub $a1, $a1, 1			#move to (x-1, y-1)
	j check_left
	
check_left:
	bgt $a1, $s6, tag_found
	jal get_pixel
	beqz $v0, pre_loop_x_clean
	addi $a1, $a1, 1
	j check_left
	
tag_found:
	la $a0, info
	li $v0, 4
	syscall 
	
	la $a0, x_info
	syscall
	
	la $a0, ($t8)
	syscall 
	
	la $a0, y_info
	syscall
	
	la $a0, ($t9)
	syscall
	
	j pre_loop_x_clean
	

exit:
	jal 	save_bmp
	li 	$v0,10		#Terminate the program
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
	srl $a0, $a0, 1
	
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

