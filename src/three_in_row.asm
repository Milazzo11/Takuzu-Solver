# File:         three_in_row.asm
#
# Author:       Max Milazzo
# Email:        mam9563@rit.edu
# Section:      CS250.02
#
# Description:  A "three-in-a-row" puzzle solver (main module).
#               This module of the program reads puzzle data from STDIN,
#               calls the backtracking solver writtem in solver.asm, and
#               displays the proper output to STDOUT.
#

# syscall codes
PRINT_STRING = 4
READ_INT = 5

# maximum game board size
MAX_SIZE = 10

        .data
        .align  0

config:
        .space  MAX_SIZE * MAX_SIZE
        # defines space for a game board config

        .globl  config

# display text
banner_text:
        .ascii  "\n******************\n"
        .ascii  "**  3-In-A-Row  **\n"
        .asciiz "******************\n\n"

invalid_size_text:
        .asciiz "Invalid board size, 3-In-A-Row terminating\n"

illegal_input_text:
        .asciiz "Illegal input value, 3-In-A-Row terminating\n"

initial_puzzle_title_text:
        .asciiz "Initial Puzzle\n\n"

final_puzzle_title_text:
        .asciiz "\nFinal Puzzle\n\n"

impossible_puzzle_text:
        .asciiz "\nImpossible Puzzle\n\n"

white_square_text:
        .asciiz " "

black_square_text:
        .asciiz "#"

unknown_square_text:
        .asciiz "."

horizontal_puzzle_border_text:
        .asciiz "-"

left_corner_puzzle_border_text:
        .asciiz "+"

right_corner_puzzle_border_text:
        .asciiz "+\n"

left_puzzle_border_text:
        .asciiz "|"

right_puzzle_border_text:
        .asciiz "|\n"

end_empty_line_text:
        .asciiz "\n"

        .globl  run_solver
        .globl  main

        .text
        .align  2

#
# Name:         main
#
# Description:  program entry point.
#
# Arguments:    none
#
# Returns:      none
#

main:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)

        la      $a0, banner_text
        li      $v0, PRINT_STRING
        syscall                     # displays main program title banner

        li      $v0, READ_INT
        syscall                     # reads integer from stdin

        move    $s0, $v0            # s0 = read_val

        li      $t0, 2              # t0 = smallest positive even number
                                    # (min board size)
        li      $t1, MAX_SIZE       # t1 = max board size

        slt     $t2, $s0, $t0       # t2 = 1 if read_val < 2
        bne     $t2, $zero, invalid_size
                                    # invalid size if read_val < 2

        slt     $t2, $t1, $s0       # t2 = 1 if 10 < read_val
        bne     $t2, $zero, invalid_size
                                    # invalid size if read_val > 10

        rem     $t3, $s0, $t0       # t3 = read_val % 2
        bne     $t3, $zero, invalid_size
                                    # invalid size if read_val not even

        move    $a0, $s0            # a0 = input square size (read_val)
        jal     make_puzzle         # builds initial puzzle from input

        bne     $v0, $zero, end_main
                                    # exits program if make_puzzle returns
                                    # an error status

        la      $a0, initial_puzzle_title_text
        li      $v0, PRINT_STRING
        syscall                     # displays "initial puzzle" title text

        move    $a0, $s0            # a0 = input square size (read_val)
        jal     display_puzzle      # display initial puzzle

        move    $a0, $s0            # a0 = input square size (read val)
        jal     run_solver          # run backtracking solver on game board

        bne     $v0, $zero, no_puzzle_solution
                                    # displays "no solution" text if solver
                                    # returns "no solution" (1) code

        la      $a0, final_puzzle_title_text
        li      $v0, PRINT_STRING
        syscall                     # displays "final puzzle" title text

        move    $a0, $s0            # a0 = input square size (read val)
        jal     display_puzzle      # solved puzzle output

        la      $a0, end_empty_line_text
        li      $v0, PRINT_STRING
        syscall                     # displays empty line after puzzle

        j       end_main            # skips invalid size display

invalid_size:
        la      $a0, invalid_size_text
        li      $v0, PRINT_STRING
        syscall                     # prints invalid size text

        j       end_main            # exits function

no_puzzle_solution:
        la      $a0, impossible_puzzle_text
        li      $v0, PRINT_STRING
        syscall                     # display impossible puzzle error message

end_main:
        lw      $ra, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 8

        jr      $ra                 # return from function

#
# Name:         make_puzzle
#
# Description:  creates initial puzzle from stdin.
#
# Arguments:    a0 contains input square size
#
# Returns:      v0 contains exit status code (0=success, 1=error)
#

make_puzzle:
        addi    $sp, $sp, -4
        sw      $ra, 0($sp)

        mul     $t0, $a0, $a0       # t0 = number of board cells
        li      $t1, 0              # t1 (used as counter) set to 0

        la      $t2, config         # loads initial config address in t2

fill_cells_loop:
        beq     $t0, $t1, end_fill_cells_loop
                                    # while (num_cells != counter)

        li      $v0, READ_INT
        syscall                     # reads integer from stdin

        beq     $v0, $zero, valid_cell_input
                                    # valid input if 0

        li      $t3, 1
        beq     $v0, $t3, valid_cell_input
                                    # valid input if 1

        li      $t3, 2
        beq     $v0, $t3, valid_cell_input
                                    # valid input if 2
                                    # otherwise illegal input

        la      $a0, illegal_input_text
        li      $v0, PRINT_STRING
        syscall                     # prints illegal input text

        li      $v0, 1              # make_puzzle returns 1 on error
        j       end_make_puzzle     # exit function

valid_cell_input:
        sb      $v0, 0($t2)         # store read value on the board

        addi    $t1, $t1, 1         # counter++
        addi    $t2, $t2, 1         # increment cell address by 1

        j       fill_cells_loop     # jump to start of loop

end_fill_cells_loop:

        li      $v0, 0              # make_puzzle returns 0 on success

end_make_puzzle:
        lw      $ra, 0($sp)
        addi    $sp, $sp, 4

        jr      $ra                 # return from function

#
# Name:         display_puzzle
#
# Description:  displays a formatted puzzle to stdout from config data.
#
# Arguments:    a0 contains input square size.
#
# Returns:      none
#

display_puzzle:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        move    $s0, $a0            # s0 = input square size

        jal     display_horizontal_border
                                    # displays top horizontal border

        move    $s1, $s0            # s1 = outer loop counter
        la      $s3, config         # loads initial config address in s3

display_content_row_loop:
        beq     $s1, $zero, end_display_content_row_loop
                                    # while (outer_counter != 0)

        la      $a0, left_puzzle_border_text
        li      $v0, PRINT_STRING
        syscall                     # displays left vertical border segment

        move    $s2, $s0            # reset inner loop counter (in t1)

display_content_cell_loop:
        beq     $s2, $zero, end_display_content_cell_loop
                                    # while (inner_counter != 0)

        lb      $t0, 0($s3)         # t0 = current cell value

        bne     $t0, $zero, cur_cell_not_zero_check
                                    # branches if val not 0

        la      $a0, unknown_square_text
                                    # set print to unknown square text

        j       display_cell        # go to display code

cur_cell_not_zero_check:
        li      $t1, 1
        bne     $t0, $t1, cur_cell_two
                                    # branches if val not 1

        la      $a0, white_square_text
                                    # set print to white square

        j       display_cell        # go to display code

cur_cell_two:
        la      $a0, black_square_text
                                    # set print to black square
display_cell:
        li      $v0, PRINT_STRING
        syscall                     # displays cell contents
        
        addi    $s2, $s2, -1        # inner_counter-- 
        addi    $s3, $s3, 1         # increments current cell address

        j       display_content_cell_loop
                                    # jump to start of inner loop
end_display_content_cell_loop:

        la      $a0, right_puzzle_border_text
        li      $v0, PRINT_STRING
        syscall                     # displays right vertical border segment
        
        addi    $s1, $s1, -1        # outer_counter--
        j       display_content_row_loop
                                    # jump to start of outer

end_display_content_row_loop:

        move    $a0, $s0            # a0 = input square size
        jal     display_horizontal_border
                                    # displays bottom horizontal border
end_display_puzzle:
        lw      $ra, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 20

        jr      $ra                 # return from function

#
# Name:         display_horizontal_border
#
# Description:  displays puzzle horizontal border.
#
# Arguments:    a0 contains input square size
#
# Returns:      none
#

display_horizontal_border:
        addi    $sp, $sp, -8
        sw      $ra, 4($sp)
        sw      $s0, 0($sp)
        
        move    $s0, $a0            # s0 = input square size (used as counter)

        la      $a0, left_corner_puzzle_border_text
        li      $v0, PRINT_STRING
        syscall                     # displays left corder

horizontal_segment_display_loop:
        beq     $s0, $zero, end_horizontal_segment_display_loop
                                    # while (counter != 0)

        la      $a0, horizontal_puzzle_border_text
        li      $v0, PRINT_STRING
        syscall                     # displays horizontal border segment

        addi    $s0, $s0, -1        # counter--
        j       horizontal_segment_display_loop
                                    # jump to start of loop 

end_horizontal_segment_display_loop:
        
        la      $a0, right_corner_puzzle_border_text
        li      $v0, PRINT_STRING
        syscall                     # displays right corner

end_display_horizontal_border:
        lw      $ra, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 8

        jr      $ra                 # return from function