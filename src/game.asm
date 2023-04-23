
; Description: Paints the objects located on game_board
graphGameBoard proc 

    lea di, game_board
    mov cx, 0 ; y coordinate

    graph_next_row:
        mov ax, 0 ; x coordinate

    graph_next_col:

        call getGameObject ; get object code
        cmp dx, 0fh ; empty space
        jg not_a_wall ; not a wall (or empty space)

        ; Get wall sprite offset

        push ax ; save x coordinate

        lea di, sprite_walls ; di = wall_sprite offset
        mov ax, dx ; ax = wall type
        mov bx, sprite_size ; bx = sprite size
        mul bx ; ax = wall type * sprite size
        add di, ax ; di = wall_sprite offset + wall type * sprite size

        pop ax ; restore x coordinate

        ; Paint wall sprite
        jmp paint_board_object

        not_a_wall:

        lea di, sprite_ace_dot
        cmp dx, 13h ; ace dot
        je paint_board_object

        lea di, sprite_power_dot
        cmp dx, 14h ; power dot
        je paint_board_object

        lea di, sprite_walls
        cmp dx, 15h ; > 15d -> Portal
        jge paint_board_object


        jmp no_paint_object

        paint_board_object:
        call paintSprite

        no_paint_object:

        inc ax ; next column
        cmp ax, 28h ; 40d columns
        jne graph_next_col ; not 40d columns

        inc cx ; next row
        cmp cx, 19h ; 25d rows
        jne graph_next_row ; not 25d rows

    ; Static elements [score, time, max]

    ; score : row = 0; col = 0
    mov ax, 0
    mov cx, 0
    lea di, sprite_coin
    call paintSprite

    ; time : row = 0; col = 29
    mov ax, 01dh ; 29d
    mov cx, 0
    lea di, sprite_time
    call paintSprite

    ; max : row = 24; col = 3
    mov ax, 10h
    mov cx, 18h
    lea di, sprite_plus
    call paintSprite

    mov ah, 02h 
    mov bh, 0
    mov dh, 18h ; row
    mov dl, 11h ; column
    int 10h

    mov ax, max_score
    call numberToString
    mPrint numberString

graphGameBoard endp


; Description: Sets the object located on game_board
; Entry: AX = x coordinate
;        CX = y coordinate
;        DL = object code
setGameObject proc
    push ax
    push cx
    push di
    push dx

    mov dh, 28h ; 40d columns
    xchg ax, cx ; x <-> y

    mul dh ; y * 40d
    add cx, ax ; y * 40d + x

    lea di, game_board
    add di, cx ; di = game_board offset + y * 40d + x

    mov [di], dl ; game_board[y * 40d + x] = object code

    pop dx
    pop di
    pop cx
    pop ax

    ret
setGameObject endp

; Description: Gets the code of the object located on game_board
; Entry: AX = x coordinate
;        CX = y coordinate
; Exit:  DX = object code
; Codes:    00 = empty space
;           01-0F = walls -> 0-15d
;           13 = ace dots -> 19d
;           14 = power dots -> 20d
;           15 = ghost house -> 21d
;           16 = ghost house door -> 22d
;           17 = Aceman -> 23d
getGameObject proc
    push ax
    push cx
    push di

    mov dx, 28h ; 40d columns
    xchg ax, cx ; x <-> y
    mul dx ; y * 40d
    xchg ax, cx ; x <-> y * 40d
    add cx, ax ; y * 40d + x

    lea di, game_board
    add di, cx ; di = game_board offset + y * 40d + x
    xor dx, dx
    mov dl, [di] ; dx = game_board[y * 40d + x]

    pop di
    pop cx
    pop ax
    ret
getGameObject endp


initGhosts proc

    ; Position

    mov ax, 13; 19d
    mov cx, 0ah ; 10d
    mov red_ghost_x, ax
    mov red_ghost_y, cx
    
    mov ax, 15
    mov cx, 0ah
    mov cyan_ghost_x, ax
    mov cyan_ghost_y, cx

    mov ax, 13; 19d
    mov cx, 0ch ; 12d
    mov yellow_ghost_x, ax
    mov yellow_ghost_y, cx

    mov ax, 15
    mov cx, 0ch
    mov pink_ghost_x, ax
    mov pink_ghost_y, cx

    ; other vars

    mov red_ghost_direction, aceman_no_direction
    mov is_red_ghost_eatable, 0 
    mov is_red_ghost_in_house, 1

    mov cyan_ghost_direction, aceman_no_direction
    mov is_cyan_ghost_eatable, 0
    mov is_cyan_ghost_in_house, 1

    mov yellow_ghost_direction, aceman_no_direction
    mov is_yellow_ghost_eatable, 0
    mov is_yellow_ghost_in_house, 1

    mov pink_ghost_direction, aceman_no_direction
    mov is_pink_ghost_eatable, 0
    mov is_pink_ghost_in_house, 1

    ret 
initGhosts endp

fillAceDots proc
    mov aceDotsLeft, 0
    mov cx, 1 ; initial y coordinate
    mov current_y, cx

    fill_next_row_dots:
        mov ax, 0 ; x coordinate
        mov current_x, ax

    fill_next_col_dots:

        ; In reachable area
        call searchWallInfo
        
        mov ax, current_x
        mov cx, current_y

        cmp ax, first_horizontal_wall_x
        jle pass_object_dot ; at the left of the first horizontal wall (or equal)
 
        cmp ax, last_horizontal_wall_x
        jge pass_object_dot ; at the right of the last horizontal wall (or equal)

        cmp cx, first_vertical_wall_y
        jle pass_object_dot ; above the first vertical wall (or equal)

        cmp cx, last_vertical_wall_y
        jge pass_object_dot ; below the last vertical wall (or equal)

        ; Inside reachable area
        call getGameObject ; get object code

        cmp dx, 0 
        jne pass_object_dot ; not empty space

        call isInsideGhostHouse
        cmp dl, 1 ; inside ghost house
        je pass_object_dot

        mov dl, 13 ; 19d -> ace dots
        call setGameObject
        inc aceDotsLeft

        pass_object_dot:
            inc ax ; next column
            mov current_x, ax
            cmp ax, 28h ; 40d columns
            jne fill_next_col_dots ; not 40d columns

            inc cx ; next row
            mov current_y, cx
            cmp cx, 18h ; 24d rows
            jne fill_next_row_dots ; not 25d rows

    ret
fillAceDots endp

; Description: searches for the first and last vertical/horizontal wall
; Input: current_x = x coordinate ; current_y = y coordinate
; Output: saves the first and last wall coordinates in the following variables:
;         first_horizontal_wall_x, last_horizontal_wall_x, first_vertical_wall_y, last_vertical_wall_y
; note: consider portals as walls, and a earlier board with only walls, portals and empty spaces
searchWallInfo proc
    
    ; search first horizontal wall
    mov ax, 0
    mov cx, current_y
    first_horizontal:
        call getGameObject
        
        mov first_horizontal_wall_x, ax
        inc ax
        
        cmp ax, 28h ; 40d columns per row
        je end_first_horizontal

        cmp dx, 0 ; empty space, first horizontal wall not found yet
        je first_horizontal

    end_first_horizontal:

    ; search last horizontal wall
    mov ax, 0
    mov cx, current_y

    last_horizontal:
        call getGameObject

        cmp dx, 0 ; empty space
        je next_horizontal

        ; posible last horizontal wall
        mov last_horizontal_wall_x, ax

        next_horizontal:    
            inc ax
            cmp ax, 28h ; 40d columns
            jne last_horizontal ; until 40d columns are checked


    ; search first vertical wall
    mov ax, current_x
    mov cx, 1 ; initial y coordinate

    first_vertical:
        call getGameObject

        mov first_vertical_wall_y, cx
        inc cx

        cmp cx, 18h ; 24d rows
        je end_first_vertical

        cmp dx, 0 ; empty space, first vertical wall not found yet
        je first_vertical

    end_first_vertical:

    ; search last vertical wall
    mov ax, current_x
    mov cx, 1 ; initial y coordinate

    last_vertical:
        call getGameObject

        cmp dx, 0 ; empty space
        je next_vertical

        ; posible last vertical wall
        mov last_vertical_wall_y, cx

        next_vertical:    
            inc cx
            cmp cx, 18h ; 24d rows
            jne last_vertical ; until 24d rows are checked

    ret
searchWallInfo endp

; Paints the sprite on video memory
; Entry: AX = x coordinate
;        CX = y coordinate
;        DI = sprite offset
paintSprite proc

    push ax
    push bx
    push cx
    push dx
    push di

    mov bx, 0 
    mov dl, 08 ; 8 rows
    mul dl ; AX = x * 8
    add bx, ax ; bx = x * 8

    xchg ax, cx ; AX = y; CX = x * 8
    mul dl ; AX = y * 8
    mov dx, 140h ; 320d -> pixel width
    mul dx ; AX = y * 8 * 320d
    add bx, ax ; bx = x * 8 + y * 8 * 320d
    end_position:
        mov cx, 8 ; 8 rows
    
    paint_sprite_row:
        push cx
        mov cx, 8 ; 8 columns

    paint_sprite_col:

        mov al, [di] ; get sprite column
        push ds ; save ds

        mov dx, 0A000h ; video memory
        mov ds, dx ; ds = video memory

        mov [BX], AL ; paint sprite

        inc bx ; next column on video memory
        inc di ; next column on sprite
        
        pop ds ; restore ds

        loop paint_sprite_col

        pop cx ; restore row counter
        sub bx, 8 ; go to the next row on video memory
        add bx, 140 ; 320d -> pixel width
        loop paint_sprite_row


    pop di
    pop dx
    pop cx
    pop bx
    pop ax

    ret

paintSprite endp

paintAceman proc

    mov dl, is_aceman_open
    cmp dl, 0ffh ; aceman is open
    je paint_aceman_open

    lea di, sprite_aceman_close
    xor dx, dx
    mov dl, aceman_direction
    add di, dx ; di = sprite_aceman_close + aceman_direction [OFFSET]

    jmp paint_object

    paint_aceman_open:
    lea di, sprite_aceman_open
    xor dx, dx
    mov dl, aceman_direction
    add di, dx ; di = sprite_aceman_open + aceman_direction [OFFSET]

    paint_object:
        mov ax, aceman_x
        mov cx, aceman_y
        call paintSprite

        ; paint ghost
        call paintGhosts

        call defaultDelay

        mov dl, is_aceman_open
        not dl
        mov is_aceman_open, dl ; toggle is_aceman_open

        lea di, sprite_walls ; Empty space
        
        mov ax, aceman_x
        mov cx, aceman_y
        call paintSprite ; Paint empty space

        ; Delete ghost
        mDeleteGhost red_ghost_x, red_ghost_y
        mDeleteGhost cyan_ghost_x, cyan_ghost_y
        mDeleteGhost yellow_ghost_x, yellow_ghost_y
        mDeleteGhost pink_ghost_x, pink_ghost_y

    ; reset lives
    mov dl, 3
    mov ax, 25h ; 37d
    mov cx, 18h ; 24d
    lea di, sprite_walls

    reset_next_life:
        call paintSprite
        inc ax
        dec dl
        jnz reset_next_life

    ; paint lives
    mov dl, aceman_hp
    mov ax, 25h ; 37d
    mov cx, 18h ; 24d
    lea di, sprite_hearth

    paint_next_life:
        call paintSprite
        inc ax
        dec dl
        jnz paint_next_life

    ret         
paintAceman endp

paintGhosts proc

    lea di, sprite_red_ghost
    cmp is_red_ghost_eatable, 1
    jne paint_red_ghost

    lea di, sprite_eatable_ghost

    paint_red_ghost:
        mov ax, red_ghost_x
        mov cx, red_ghost_y
        call paintSprite

    lea di, sprite_cyan_ghost
    cmp is_cyan_ghost_eatable, 1
    jne paint_cyan_ghost

    lea di, sprite_eatable_ghost

    paint_cyan_ghost:
        mov ax, cyan_ghost_x
        mov cx, cyan_ghost_y
        call paintSprite

    lea di, sprite_yellow_ghost
    cmp is_yellow_ghost_eatable, 1
    jne paint_yellow_ghost

    lea di, sprite_eatable_ghost

    paint_yellow_ghost:
        mov ax, yellow_ghost_x
        mov cx, yellow_ghost_y
        call paintSprite

    lea di, sprite_pink_ghost
    cmp is_pink_ghost_eatable, 1
    jne paint_pink_ghost

    lea di, sprite_eatable_ghost

    paint_pink_ghost:
        mov ax, pink_ghost_x
        mov cx, pink_ghost_y
        call paintSprite

    ; Check timestamp

    cmp power_dot_timestamp_set, 1
    jne no_check_timestamp

    push ax
    push bx
    push cx
    push dx

    ; Set cursor for remaining time
    mov ah, 02h 
    mov bh, 0
    mov dh, 18h ; row
    mov dl, 1h ; column
    int 10h

    xor ax, ax
    mov al, power_dot_time_left
    call numberToString
    lea si, numberString
    add si, 4 ; Skip 0000
    mPrintAddress si

    mov ah, 2ch
    int 21h

    ; a second passed
    mov dl, dh ; Copy seconds
    cmp dh, last_power_dot_timestamp
    je end_power_dot

    mov last_power_dot_timestamp, dl
    dec power_dot_time_left

    jnz end_power_dot

    mov is_red_ghost_eatable, 0
    mov is_cyan_ghost_eatable, 0
    mov is_yellow_ghost_eatable, 0
    mov is_pink_ghost_eatable, 0
    mov power_dot_timestamp_set, 0

    ; remove icon
    mov ax, 0
    mov cx, 18h
    lea di, sprite_walls ; Empty space
    call paintSprite ; Paint empty space

    inc ax
    call paintSprite ; Paint empty space

    inc ax
    call paintSprite ; Paint empty space

    end_power_dot:

    pop dx
    pop cx
    pop bx
    pop ax

    no_check_timestamp:

    ret
paintGhosts endp


defaultDelay proc

    push bp
    push si

    mov BP, 03000
    default_delay_loop_b:		
        mov SI, 00010
    default_delay_loop_a:		
        dec SI
		cmp SI, 00
		jne default_delay_loop_a
		dec BP
		cmp BP, 00
		jne default_delay_loop_b

        pop si
        pop bp
		ret
defaultDelay endp

; Detects the user input in game
userInput proc
    mov ah, 1
    int 16h ; get user input

    jz return_input

    cmp al, 1b ; ESC
    je input_pause_game

    cmp ah, 48h ; UP
    je input_up

    cmp ah, 50h ; DOWN
    je input_down

    cmp ah, 4bh ; LEFT
    je input_left

    cmp ah, 4dh ; RIGHT
    je input_right

    mov ah, 0
    int 16h ; clear buffer
    ret

    input_up: 
        mov ah, aceman_up
        jmp change_direction

    input_down:
        mov ah, aceman_down
        jmp change_direction

    input_left:
        mov ah, aceman_left
        jmp change_direction

    input_right:
        mov ah, aceman_right
        jmp change_direction

    input_pause_game:
        mov al, 1        
        mov pauseGame, al ; toggle endGame

        mov ah, 0
        int 16h ; clear buffer
        ret 

    change_direction:
        mov aceman_direction, ah

        mov ah, 0
        int 16h ; clear buffer
    return_input:
        ret


userInput endp


; Determines if the aceman can move to the next position
moveAceman proc

    mov ax, aceman_x
    mov cx, aceman_y

    mov dh, aceman_direction

    ;down
    cmp dh, aceman_down
    jne aceman_move_up
    inc cx
    jmp aceman_move_validate

    aceman_move_up:
        cmp dh, aceman_up
        jne aceman_move_left
        dec cx
        jmp aceman_move_validate

    aceman_move_left:
        cmp dh, aceman_left
        jne aceman_move_right
        dec ax
        jmp aceman_move_validate

    aceman_move_right:      
        cmp dh, aceman_right
        jne aceman_move_validate
        inc ax

    aceman_move_validate:
    
        call getGameObject

        mov bx, dx

        call isInsideGhostHouse ; * mutates DX
        cmp dl, 1
        je not_move_aceman

        mov dx, bx

        cmp dx, 0 ; Next object is empty space
        je move_aceman

        cmp dx, 0fh 
        jle not_move_aceman ; Next object is wall

        cmp dx, 13h ; Next object is ace dot
        je ace_dot_eaten

        cmp dx, 14h ; Next object is power dot
        je power_dot_eaten

        cmp dx, 15h
        jge portal_transport
       
        not_move_aceman:
            ret

        power_dot_eaten:
            mov dx, 0
            call setGameObject

            call setGhostsEatable

            push ax
            push cx

            mov ax, dotValue
            mov dx, 5h ; multiply by 5
            mul dx
            add gamePoints, ax

            pop cx
            pop ax

            dec powerDotsLeft

            jmp move_aceman


        ace_dot_eaten:
            mov dx, 0
            call setGameObject

            mov dx, dotValue
            add gamePoints, dx

            dec aceDotsLeft

            jmp move_aceman

        portal_transport:
            mov serchead_portal_x, ax
            mov serchead_portal_y, cx
            mov serchead_portal_number, dx
            call searchPortalEnd
            jmp move_aceman

        move_aceman:
            mov aceman_x, ax
            mov aceman_y, cx

            cmp aceDotsLeft, 0
            jne not_end_game

            cmp powerDotsLeft, 0
            jne not_end_game

            mov al, 1
            mov endGame, al

            not_end_game:

            ret

moveAceman endp


; Description: looks for x and y coordinates of the end portal
; Input: DX = Portal ID
; Output: AX = x coordinate of the end portal
;         CX = y coordinate of the end portal
searchPortalEnd proc

    mov cx, 1 ; initial y coordinate

    fill_next_row:
        mov ax, 0 ; x coordinate

    fill_next_col:

        call getGameObject ; get object code

        cmp dx, serchead_portal_number
        jne pass_object ; not the portal id

        posible_portal:
            ; Compare initial x coordinate with the current x coordinate
            cmp ax, serchead_portal_x
            jne portal_found

            ; Compare initial y coordinate with the current y coordinate
            cmp cx, serchead_portal_y
            jne portal_found

        pass_object:
            inc ax ; next column
            cmp ax, 28h ; 40d columns
            jne fill_next_col ; not 40d columns

            inc cx ; next row
            cmp cx, 18h ; 24d rows
            jne fill_next_row ; not 25d rows

        portal_found:

    ret
searchPortalEnd endp


; Description: Evals if coords are inside ghost house
; Input: AX = x coordinate
;        CX = y coordinate
; Output: DL = 1 if inside ghost house

isInsideGhostHouse proc

    mov dl, 0 ; not inside ghost house

    ; House coords: x = 13h - 15h & y = 0ah - 0ch
    cmp ax, 13h
    jl not_inside_ghost_house

    cmp ax, 15h
    jg not_inside_ghost_house

    cmp cx, 0ah
    jl not_inside_ghost_house

    cmp cx, 0ch
    jg not_inside_ghost_house

    mov dl, 1 ; inside ghost house

    not_inside_ghost_house:
        ret
isInsideGhostHouse endp


printGameInformation proc
    call printPoints
    call printElapsedTime
    ret

printGameInformation endp

; Description get the initial time of the game
getInitialTime proc

    call getTimeInHundreths
    mov initialTimestamp, ax ; save initial timestamp
    ret 
getInitialTime endp


printPoints proc

    push ax
    push bx
    push cx
    push dx

    mov ah, 02h
    mov bh, 0
    mov dh, 0 ; row
    mov dl, 1 ; column
    int 10h

    mov ax, gamePoints
    call numberToString
    mPrint numberString

    pop dx
    pop cx
    pop bx
    pop ax

    ret
printPoints endp

printElapsedTime proc
    ; ?PUSHs?

    call getTimeInHundreths
    sub ax, initialTimestamp 
    mov elapsedTimestamp, ax ; AX = elapsed time in hundredths

    ; Get minutes
    mov bx, 1770h ; 60d * 100d = 6000d = 1770h
    mov cx, 0
    mov dx, 0
    div bx

    mov elapsedMinutes, ax ; save minutes
    mul bx

    sub elapsedTimestamp, ax
    mov ax, elapsedTimestamp

    ; Get seconds
    mov bx, 64h ; 60d
    mov cx, 0
    mov dx, 0
    div bx

    mov elapsedSeconds, ax ; save seconds
    mul bx

    sub elapsedTimestamp, ax
    mov ax, elapsedTimestamp

    ; Get hundredths
    mov elapsedHundredths, ax ; save hundredths

    ; Set cursor position
    ; col 31d = d -> top right corner ; row 0
    mov ah, 02h 
    mov bh, 0
    mov dh, 0 ; row
    mov dl, 1fh ; column
    int 10h

    ; Print minutes
    mov ax, elapsedMinutes
    call numberToString
    lea di, numberString ; numberString = xxxxxx$
    add di, 4 ; di = xx$
    mPrintAddress di

    ; Print colon
    mPrint sColon

    ; Print seconds
    mov ax, elapsedSeconds
    call numberToString
    lea di, numberString ; numberString = xxxxxx$
    add di, 4 ; di = xx$
    mPrintAddress di

    ; Print colon
    mPrint sColon

    ; Print hundredths
    mov ax, elapsedHundredths
    call numberToString
    lea di, numberString ; numberString = xxxxxx$
    add di, 4 ; di = xx$
    mPrintAddress di

    ret
printElapsedTime endp


setGhostsEatable proc

    mov eaten_ghosts_in_a_row, 0

    mov is_red_ghost_eatable, 1
    mov is_cyan_ghost_eatable, 1
    mov is_pink_ghost_eatable, 1
    mov is_yellow_ghost_eatable, 1

    push ax
    push bx
    push cx
    push dx

    mov ah, 2ch
    int 21h
    mov power_dot_timestamp, dh
    mov last_power_dot_timestamp, dh
    mov power_dot_timestamp_set, 1
    mov power_dot_time_left, 0ch ; 12d seconds

    mov ax, 0
    mov cx, 18h
    lea di, sprite_eatable_ghost
    call paintSprite

    pop dx
    pop cx
    pop bx
    pop ax

    ret 
setGhostsEatable endp



; Description: Converts a sign number of 16 bits to an ascii representation string
; Input : AX - number to convert
; Output: DX - 0 if no error, 1 if error
;         numberString - the string representation of the number
numberToString proc

    ; REGISTER PROTECTION
    push ax
    push bx
    push cx
    push si
    
    mov cx, 0
    ; Comparte if its a negative number
    mov [negativeNumber], 0
    cmp ax, 0
    jge convert_positive

    convert_negative:
        mov [negativeNumber], 1 ; Set the negative number flag to 1
        inc cx

        ; Convert to positive
        neg ax
        jmp convert_positive
    
    convert_positive:
        mov bx, 0ah

        extract_digit:
            mov dx, 0 ; Clear the dx register [Remainder]
            div bx ; Divide the AX number by 10 and store the remainder in dx
            add dl, '0' ; Convert the remainder to ascii
            push dx ; Push the remainder to the stack
            inc cx ; Increment the digit counter
            cmp ax, 0 ; Check if the number is 0
            jne extract_digit ; If not, extract the next digit

    ; No representable number
    cmp cx, 6
    jg representation_error

    ; ------------------- Fill the string -------------------
    mov si, 0

    ; ! Fill with 0 every digit that is not used <- Change this to fill with spaces
    mov dx, 6
    sub dx, cx
    cmp dx, 0
    jz set_negative

    fill_with_0:
        mov numberString[si], '0'
        inc si
        dec dx
        jnz fill_with_0

    set_negative:

    ; If the number is negative, add the '-' sign
    cmp [negativeNumber], 1
    jne set_digit
    mov numberString[si], '-'
    inc si
    dec cx

    ; Copy the digits to the string
    set_digit:
        pop dx
        mov numberString[si], dl
        inc si
        loop set_digit

    mov dx, 0 ; NO ERROR
    jmp end_number_string

    representation_error:
        mPrint numberRepresentationError

        ; empty the stack
        empty_stack:
            pop dx
            loop empty_stack

        mov dx, 1 ; ERROR

    end_number_string:
        ; REGISTER RESTORATION
        pop si
        pop cx
        pop bx
        pop ax

        ret
numberToString endp

; Description: puts in ax, the current time as a sum of minutes, seconds and hundredths, in hundredths
getTimeInHundreths proc

    mov ah, 2ch
    int 21h

    xor ax, ax
    add al, dl ; + hundredths

    push ax

    mov ah, 2ch
    int 21h
    xor ax, ax
    mov al, dh
    mov dx, 64h ; 100d
    mul dx
    mov dx, ax

    pop ax

    add ax, dx ; + seconds

    push ax
        
    mov ah, 2ch
    int 21h
    xor ax, ax
    mov al, cl
    mov dx, 1770h ; 60d * 100d
    mul dx
    mov dx, ax

    pop ax
    add ax, dx ; + minutes


    ret
getTimeInHundreths endp

; Description: Gives a random number between 0 and 9
; Input: None
; Output: random - random number
GenerateRandom proc
    
    push ax
    push bx
    push cx
    push dx
    
    mov ah, 2ch
    int 21h

    mov ax, dx
    mov dx, 0
    mov bx, 9
    div bx
    inc dx

    mov bh, 0
    mov bl, dl
    call DoRangedRandom
    mov random,al

    mov ah, 0

    pop dx
    pop cx
    pop bx
    pop ax
    
    ret
GenerateRandom endp


; Description: Moves ghost
; Input: None
; Output: Nonve
moveGhosts proc
    
    mEvalReleaseGhost is_red_ghost_in_house, red_ghost_x, red_ghost_y, red_ghost_direction
    mEvalReleaseGhost is_cyan_ghost_in_house, cyan_ghost_x, cyan_ghost_y, cyan_ghost_direction
    mEvalReleaseGhost is_pink_ghost_in_house, pink_ghost_x, pink_ghost_y, pink_ghost_direction
    mEvalReleaseGhost is_yellow_ghost_in_house, yellow_ghost_x, yellow_ghost_y, yellow_ghost_direction
    no_more_evals:

    ; Movement

    mEvalGhostMovement red_ghost_x, red_ghost_y, red_ghost_direction

    mEvalGhostMovement cyan_ghost_x, cyan_ghost_y, cyan_ghost_direction

    mEvalGhostMovement pink_ghost_x, pink_ghost_y, pink_ghost_direction
    
    mEvalGhostMovement yellow_ghost_x, yellow_ghost_y, yellow_ghost_direction

    ; collision

    ret
moveGhosts endp

; Description: Evaluates the ghosts collision with pacman
; Input: none
; Output: none
ghostsCollission proc

    cmp check_ghost_collission, 0
    je no_more_evals_ghosts
    ; red
    mov house_return_x, 13h
    mov house_return_y, 0ah
    mEvalGhostCollission red_ghost_x, red_ghost_y, is_red_ghost_eatable, is_red_ghost_in_house, red_ghost_direction

    ; cyan
    mov house_return_x, 15h
    mov house_return_y, 0ah
    mEvalGhostCollission cyan_ghost_x, cyan_ghost_y, is_cyan_ghost_eatable, is_cyan_ghost_in_house, cyan_ghost_direction

    ; yellow
    mov house_return_x, 13h
    mov house_return_y, 0ch
    mEvalGhostCollission yellow_ghost_x, yellow_ghost_y, is_yellow_ghost_eatable, is_yellow_ghost_in_house, yellow_ghost_direction

    ; pink
    mov house_return_x, 15h
    mov house_return_y, 0ch
    mEvalGhostCollission pink_ghost_x, pink_ghost_y, is_pink_ghost_eatable, is_pink_ghost_in_house, pink_ghost_direction
    
    no_more_evals_ghosts:
    ret
ghostsCollission endp

DoRandomByte1:
	mov al,cl			;Get 1st seed
DoRandomByte1b:
	ror al,1			;Rotate Right
	ror al,1
	xor al,cl			;Xor 1st Seed
	ror al,1
	ror al,1			;Rotate Right
	xor al,ch			;Xor 2nd Seed
	ror al,1			;Rotate Right
 	xor al,9dh	;Xor Constant
	xor al,cl			;Xor 1st seed
	ret

DoRandomByte2:
	mov bx,OFFSET Randoms1	
	mov ah,0
	mov al,ch		
    xor al, 0bh
    and al, 0fh

	mov si,ax
	mov dh,[bx+si]		;Get Byte from LUT 1
	
	call DoRandomByte1	
	and al,0fh		;Convert random number from 1st 
	
	mov bx,OFFSET Randoms2	;geneerator to Lookup
	mov si,ax
	mov al,[bx+si]		;Get Byte from LUT2
	
	xor al,dh				;Xor 1st lookup
	ret
	
	
DoRandom:			;RND outputs to A (no input)
	push bx
	push cx
	push dx
		mov cx,word PTR [RandomSeed]    ;Get and update
		inc cx							  	  ;Random Seed
		mov word PTR [RandomSeed],cx
		call DoRandomWord
		mov al,dl
		xor al,dh
	pop dx
	pop cx
	pop bx
	ret
	
DoRandomWord:		;Return Random pair in HL from Seed BC
	call DoRandomByte1		;Get 1st byte
	mov dh,al
	push dx
	push cx
	push bx
		call DoRandomByte2	;Get 2nd byte
	pop bx
	pop cx
	pop dx
	mov dl,al
	inc cx
	ret	
	
	
DoRangedRandom: 		;Return a value between B and C
	call DoRandom
	cmp AL,BH
	jc DoRangedRandom
	cmp AL,BL
	jnc DoRangedRandom
	ret


; Description: Clears the screen
; Input: None
; Output: None
clearScreen proc
    
    push ds ; save ds

    mov dx, 0A000h ; video memory
    mov ds, dx ; ds = video memory
    mov bx, 0 ; start at 0
    mov al, 0

    clear_screen_loop:
        mov [BX], al ; clear screen
        inc bx ; next column on video memory
        cmp bx, 0fa00h ; end of screen
        jne clear_screen_loop
    
    pop ds ; restore ds

    ret
clearScreen endp

; Description: Shows the pre-game information
; Input: None
; Output: None
showPregameInfo proc
    
    call clearScreen
    
    ; Ace dots
    mov ax, 1
    mov cx, 2
    lea di, sprite_ace_dot
    call paintSprite

    mov ah, 02h 
    mov bh, 0
    mov dh, 2 ; row
    mov dl, 3h ; column
    int 10h

    mov ax, dotValue
    call numberToString
    mPrint numberString
    
    ; Power dots

    mov ax, 1
    mov cx, 3
    lea di, sprite_power_dot
    call paintSprite

    mov ah, 02h
    mov bh, 0
    mov dh, 3 ; row
    mov dl, 3h ; column
    int 10h

    mov ax, dotValue
    xor dx, dx
    mov bx, 5 ; multiplier
    mul bx
    call numberToString
    mPrint numberString

    ; Ghosts
    
    mov ax, 1
    mov cx, 4
    lea di, sprite_red_ghost
    call paintSprite

    mov ah, 02h
    mov bh, 0
    mov dh, 4 ; row
    mov dl, 3h ; column
    int 10h

    mov ax, ghost_points
    call numberToString
    mPrint numberString

    ; Game points

    mov ax, 1
    mov cx, 5
    lea di, sprite_coin
    call paintSprite

    mov ah, 02h
    mov bh, 0
    mov dh, 5 ; row
    mov dl, 3h ; column
    int 10h

    mov ax, gamePoints
    call numberToString
    mPrint numberString

    ; Current level

    mov ah, 02h
    mov bh, 0
    mov dh, 6 ; row
    mov dl, 1h ; column
    int 10h

    mPrint sCurrentLevel

    mov ax, currentLevel
    call numberToString
    lea di, numberString
    add di, 5 ; skip "00000x"
    mPrintAddress di

    ; Lives

    mov ax, 1
    mov cx, 7
    lea di, sprite_hearth
    call paintSprite

    mov ah, 02h
    mov bh, 0
    mov dh, 7 ; row
    mov dl, 3h ; column
    int 10h

    xor ax, ax
    mov al, aceman_hp
    call numberToString
    lea di, numberString
    add di, 5 ; skip "00000x"
    mPrintAddress di

    ; Username

    mov ah, 02h
    mov bh, 0
    mov dh, 8 ; row
    mov dl, 1h ; column
    int 10h

    mPrint sCurrentPlayer

    lea di, usernameBuffer
    add di, 2 ; skip max size and current size
    mPrintAddress di

    ; Developer

    mov ah, 02h
    mov bh, 0
    mov dh, 9 ; row
    mov dl, 1h ; column
    int 10h

    mPrint sDeveloper

    ret
showPregameInfo endp

pauseTitle proc
    mov ah, 02h 
    mov bh, 0
    mov dh, 0 ; row
    mov dl, 11h ; column
    int 10h
    mPrint pauseMessage

    mov ah, 02h
    mov bh, 0
    mov dh, 0ch ; row
    mov dl, 5 ; column
    int 10h

    mPrint resumeInfo

    
    mov ah, 02h
    mov bh, 0
    mov dh, 0dh ; row
    mov dl, 8h ; column
    int 10h

    mPrint quitInfo

    ret
 pauseTitle endp


 ; Description: Resets game board
 ; Input: None
 ; Output: None
resetGameBoard proc

    mov cx, 1 ; initial y coordinate

    fill_next_row_reset:
        mov ax, 0 ; x coordinate
    fill_next_col_reset:
        mov dl, 0 ; 19d -> ace dots
        call setGameObject

        ; pass_object:
        inc ax ; next column
        cmp ax, 28h ; 40d columns
        jne fill_next_col_reset ; not 40d columns

        inc cx ; next row
        cmp cx, 18h ; 24d rows
        jne fill_next_row_reset ; not 25d rows

    ret
 resetGameBoard endp

acemanRandomInitialDirection proc

    compute_direction_random:

    call GenerateRandom

    mov aceman_direction, aceman_right
    cmp random, 2
    je end_initial_direction

    mov aceman_direction, aceman_left
    cmp random, 3
    je end_initial_direction

    mov aceman_direction, aceman_up
    cmp random, 4
    je end_initial_direction

    mov aceman_direction, aceman_down
    cmp random, 5
    je end_initial_direction

    jmp compute_direction_random

    end_initial_direction:

    ret
acemanRandomInitialDirection endp 