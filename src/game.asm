
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
        jmp paint_object

        not_a_wall:

        lea di, sprite_ace_dot
        cmp dx, 13h ; ace dot
        je paint_object

        lea di, sprite_power_dot
        cmp dx, 14h ; power dot
        je paint_object

        lea di, sprite_portal
        cmp dx, 15h ; > 15d -> Portal
        jge paint_object


        jmp no_paint_object

        paint_object:
        call paintSprite

        no_paint_object:

        inc ax ; next column
        cmp ax, 28h ; 40d columns
        jne graph_next_col ; not 40d columns

        inc cx ; next row
        cmp cx, 19h ; 25d rows
        jne graph_next_row ; not 25d rows

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


initGhoasts proc

    mov ax, 13; 19d
    mov cx, 0ah ; 10d
    mov red_ghoast_x, ax
    mov red_ghoast_y, cx
    
    mov ax, 15
    mov cx, 0ah
    mov cyan_ghoast_x, ax
    mov cyan_ghoast_y, cx

    mov ax, 13; 19d
    mov cx, 0ch ; 12d
    mov yellow_ghoast_x, ax
    mov yellow_ghoast_y, cx

    mov ax, 15
    mov cx, 0ch
    mov pink_ghoast_x, ax
    mov pink_ghoast_y, cx


    ret 
initGhoasts endp

fillAceDots proc

    mov cx, 1 ; initial y coordinate

    fill_next_row:
        mov ax, 0 ; x coordinate

    fill_next_col:

        call getGameObject ; get object code
        
        cmp dx, 0 ; empty space
        jne pass_object

        call isInsideGhostHouse
        cmp dl, 1 ; inside ghost house
        je pass_object

        mov dl, 13 ; 19d -> ace dots
        call setGameObject

        pass_object:
            inc ax ; next column
            cmp ax, 28h ; 40d columns
            jne fill_next_col ; not 40d columns

            inc cx ; next row
            cmp cx, 18h ; 24d rows
            jne fill_next_row ; not 25d rows

    ret
fillAceDots endp


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

printStringScreen proc
    push ax
    push si

    mov ax, 0eh
    mov bh, 0
    mov bl, 01h

    print_next_char:
        mov al, [si]
        cmp al, 0
        je end_print_screen

        inc si
        mov ah, 0eh
        int 10h
        jmp print_next_char

    end_print_screen:
        pop si
        pop ax
        ret

printStringScreen endp



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

        call defaultDelay

        mov dl, is_aceman_open
        not dl
        mov is_aceman_open, dl ; toggle is_aceman_open

        lea di, sprite_walls ; Empty space
        call paintSprite ; Paint empty space

    ret         
paintAceman endp

paintGhoasts proc

    lea di, sprite_red_ghoast
    mov ax, red_ghoast_x
    mov cx, red_ghoast_y
    call paintSprite

    lea di, sprite_pink_ghoast
    mov ax, pink_ghoast_x
    mov cx, pink_ghoast_y
    call paintSprite

    lea di, sprite_cyan_ghoast
    mov ax, cyan_ghoast_x
    mov cx, cyan_ghoast_y
    call paintSprite

    lea di, sprite_yellow_ghoast
    mov ax, yellow_ghoast_x
    mov cx, yellow_ghoast_y
    call paintSprite

    ret
paintGhoasts endp


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
    je input_end_game

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

    input_end_game:
        mov al, 0ffh        
        mov endGame, al ; toggle endGame

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


        cmp dx, 15h
        jge portal_transport

        ; TODO: aceman collision with other objects



        not_move_aceman:
            ret

        ace_dot_eaten:
            mov dx, 0
            call setGameObject
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