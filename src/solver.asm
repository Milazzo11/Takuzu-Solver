# File:         solver.asm
#
# Author:       Max Milazzo
# Email:        mam9563@rit.edu
# Section:      CS250.02
#
# Description:  Backtracking algorithm for "three-in-a-row" puzzle solver.
#               After puzzle data is properly loaded in the main
#               (three_in_row.asm) module, the solver written in this
#               module will be employed to find a puzzle solution.
#

# base puzzle cell values
EMPTY = 0
PERM_WHITE = 1
PERM_BLACK = 2

# additional cell values used by backtracker
TEST_WHITE = 3
TEST_BLACK = 4
        
        .data
        .align  2

is_valid_row_count_switch:
        .word   count_empty_cell_in_row, count_white_cell_in_row
        .word   count_black_cell_in_row, count_white_cell_in_row
        .word   count_black_cell_in_row

        .globl  config
        .globl  run_solver
        
        .text
        .align  2

#
# Name:         run_solver
#
# Description:  run backtrack solver on puzzle.
#
# Arguments:    a0 contains input square size
#
# Returns:      v0 contains exit status code (0=success, 1=impossible)
#

run_solver:
        addi    $sp, $sp, -36
        sw      $ra, 32($sp)
        sw      $s7, 28($sp)
        sw      $s6, 24($sp)
        sw      $s5, 20($sp)
        sw      $s4, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        la      $s0, config         # initialize cursor to first cell address
        li      $s1, EMPTY          # s1 = empty val
        li      $s2, TEST_WHITE     # s2 = non-perm white val
        li      $s3, TEST_BLACK     # s3 = non-perm black val

        move    $s4, $a0            # s4 = input square size
        mul     $s5, $s4, $s4       # s5 = total number of cells
        li      $s6, 0              # s6 = cur_index_counter = 0
        li      $s7, 1              # s7 = increment = 1

backtrack_loop:
        beq     $s5, $s6, end_backtrack_loop
                                    # end loop once program cursor points
                                    # past valid grid

        li      $t0, -1
        beq     $s6, $t0, impossible_puzzle
                                    # tests for impossible puzzle condition
                                    # (backtracking off of grid)

        lb      $t1, 0($s0)         # loads value at current cell

        beq     $t1, $s1, change_cell_to_white
                                    # changes cell to white if empty

        beq     $t1, $s2, change_cell_to_black
                                    # changes cell to black if non-perm white

        beq     $t1, $s3, revert_cell_to_empty
                                    # reverts cell to empty and backtracks if
                                    # non-perm black, otherwise skip cell

        j       backtrack_loop_increment
                                    # skips to address increment

change_cell_to_white:
        sb      $s2, 0($s0)         # writes non-perm white to cell
        j       valid_cell_call_check
                                    # skips to valid cell check function call

change_cell_to_black:
        sb      $s3, 0($s0)         # writes non-perm black to cell

valid_cell_call_check:
        li      $s7, 1              # s7 = increment = 1
        move    $a0, $s4            # a0 = input square size
        move    $a1, $s6            # a1 = current cell location

        jal     is_valid_config     # runs validity check

        beq     $v0, $zero, backtrack_loop_increment
                                    # jump to increment if valid

        j       backtrack_loop      # continue

revert_cell_to_empty:
        sb      $s1, 0($s0)         # reverts current cell to empty
        li      $s7, -1             # s7 = increment = -1

backtrack_loop_increment:
        add     $s0, $s0, $s7       # increments cell address
        add     $s6, $s6, $s7       # increments cur_index_counter

        j       backtrack_loop      # jump to start of loop

end_backtrack_loop: 
        move    $a0, $s5            # a0 = total number of cells
        jal     finalize_config     # finalizes puzzle to remove temp vals

        li      $v0, 0              # returns success code (0)
        j       end_run_solver      # jumps to end of function

impossible_puzzle:
        li      $v0, 1              # returns failure code (1)

end_run_solver:
        lw      $ra, 32($sp)
        lw      $s7, 28($sp)
        lw      $s6, 24($sp)
        lw      $s5, 20($sp)
        lw      $s4, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 36

        jr      $ra                 # return from function

#
# Name:         is_valid_config
#
# Description:  determines if a newly generated config is valid.
#
# Arguments:    a0 contains input square size
#               a1 contains location of new cell in current config
#
# Returns:      v0 contains validity information (0=valid, 1=invalid)
#

is_valid_config:
        addi    $sp, $sp, -20
        sw      $ra, 16($sp)
        sw      $s3, 12($sp)
        sw      $s2, 8($sp)
        sw      $s1, 4($sp)
        sw      $s0, 0($sp)

        la      $s0, config         # gets config address in s0 (temporarily)

        rem     $t0, $a1, $a0       # t0 = cell_loc % square_size
                                    # (t0 holds first cell in modified col)

        sub     $t1, $a1, $t0       # t1 = cell_loc - (cell_loc % square_size)
                                    # (t0 holds first cell in modified row)

        add     $t0, $t0, $s0       # add starting cell address to col offset
        add     $t1, $t1, $s0       # add starting cell address to row offset

        li      $t2, 0              # t2 = current num of cells "in a row" = 0
        li      $t3, 0              # t3 = num of white cells found = 0
        li      $t4, 0              # t4 = num of black cells found = 0
        li      $t5, 0              # t5 = generic_counter = 0

        la      $t6, is_valid_row_count_switch
                                    # t6 = row count switch statement address

        li      $t7, 0              # t7 = prev_cell_type = 0
                                    # (0=empty, 1=white, 2=black)

        li      $v0, 1              # invalid by default unless both loops
                                    # determine validity

        li      $s0, 1              # address increment mode
                                    # (increments 1 horizontally and    
                                    # square_size vertically)

is_row_valid_loop:
        beq     $a0, $t5, end_is_row_valid_loop
                                    # while (counter != square_size)

        lb      $t8, 0($t1)         # gets cell value

        li      $t9, 4
        mul     $t9, $t9, $t8       # t9 = offset to correct switch address

        add     $t9, $t9, $t6       # adds switch address to offset
        lw      $t9, 0($t9)         # loads correct jump point from switch

        jr      $t9                 # jumps to correct code in switch statement

count_empty_cell_in_row:
        li      $t2, 0              # no cells in a row
        li      $t9, 0              # marks empty cell as visited
        j       is_row_valid_loop_increment
                                    # jumps to loop increment

count_white_cell_in_row:
        addi    $t3, $t3, 1         # adds to white cell count
        li      $t9, 1              # marks white cell as visited
        j       color_count_cells_in_row
                                    # skips black cell counting code

count_black_cell_in_row:
        addi    $t4, $t4, 1         # adds to black cell count
        li      $t9, 2              # marks black cell as visited

color_count_cells_in_row:
        beq     $t7, $t9, same_cell_in_row
                                    # branch if cur_cell == prev_cell

        li      $t2, 1              # cells in row reset if no equality

        j       is_row_valid_loop_increment
                                    # skips "cur_cell == prev_cell" handling

same_cell_in_row:
        addi    $t2, $t2, 1         # adds to "cells in a row" count

is_row_valid_loop_increment:
        move    $t7, $t9            # prev_cell_val = cur_cell_val

        li      $t9, 3
        beq     $t2, $t9, end_is_valid_config
                                    # return function if 3 in a row

        add     $t1, $t1, $s0       # increments row address
        addi    $t5, $t5, 1         # generic_counter++

        j       is_row_valid_loop
                                    # jumps to start of loop
        
end_is_row_valid_loop:
        li      $s2, 2
        div     $s2, $a0, $s2       # s2 = square_size / 2
        addi    $s2, $s2, 1         # s2 = square_size / 2 + 1

        slt     $s3, $t3, $s2       # s3 = 1 if legal # of white cells
        beq     $s3, $zero, end_is_valid_config
                                    # return invalid if too many white cells

        slt     $s3, $t4, $s2       #s3 = 1 if legal # of black cells
        beq     $s3, $zero, end_is_valid_config
                                    # return invalid if too many black cells
        
        li      $s1, 1
        beq     $s0, $s1, check_vertical_row
                                    # if horizontal row was just cheked,
                                    # then check vertical row

        li      $v0, 0              # if this point is reached, return valid
        j       end_is_valid_config
                                    # exits function

check_vertical_row:
        li      $t2, 0              # t2 = current num of cells "in a row" = 0
        li      $t3, 0              # t3 = num of white cells found = 0
        li      $t4, 0              # t4 = num of black cells found = 0
        li      $t5, 0              # t5 = generic_counter = 0
        li      $t7, 0              # t7 = prev_cell_type = 0
                                    # (0=empty, 1=white, 2=black)

        move    $s0, $a0            # s0 = square_size (for vert row check)
        move    $t1, $t0            # set "address" register to starting col
        j       is_row_valid_loop
                                    # loops again checking vertical row

end_is_valid_config:
        lw      $ra, 16($sp)
        lw      $s3, 12($sp)
        lw      $s2, 8($sp)
        lw      $s1, 4($sp)
        lw      $s0, 0($sp)
        addi    $sp, $sp, 20

        jr      $ra                 # return from function

#
# Name:         finalize_config
#
# Description:  finalizes config to only contain permanent values.
#
# Arguments:    a0 contains total number of cells
#
# Returns:      none
#

finalize_config:
        addi    $sp, $sp, -4
        sw      $ra, 0($sp)

        la      $t0, config         # t0 = address of config
        li      $t1, 0              # t1 = current_cell = 0

        li      $t2, TEST_WHITE     # t2 = temp white cell num
        li      $t3, TEST_BLACK     # t3 = temp black cell num
        li      $t4, PERM_WHITE     # t4 = perm white cell num
        li      $t5, PERM_BLACK     # t5 = perm black cell num

check_temp_cell_loop:
        beq     $t1, $a0, end_check_temp_cell_loop
                                    # while (current_cell != num_cells)

        lb      $t6, 0($t0)         # load current cell value
        beq     $t6, $t2, replace_temp_white
                                    # temp white cell found
        
        beq     $t6, $t3, replace_temp_black
                                    # temp black cell found

        j       check_temp_cell_loop_increment
                                    # jumps to loop increment if no temp vals

replace_temp_white:
        sb      $t4, 0($t0)         # changes cell to perm white val
        j       check_temp_cell_loop_increment
                                    # jumps to loop increment
replace_temp_black:
        sb      $t5, 0($t0)         # changes cell to perm black val

check_temp_cell_loop_increment:
        addi    $t0, $t0, 1         # increments cell address
        addi    $t1, $t1, 1         # increments current_cell counter

        j       check_temp_cell_loop
                                    # jump to start of loop

end_check_temp_cell_loop:

end_finalize_config:
        lw      $ra, 0($sp)
        addi    $sp, $sp, 4

        jr      $ra                 # return from function