
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
    call paintSprite

    not_a_wall:

    inc ax ; next column
    cmp ax, 28h ; 40d columns
    jne graph_next_col ; not 40d columns

    inc cx ; next row
    cmp cx, 19h ; 25d rows
    jne graph_next_row ; not 25d rows

graphGameBoard endp



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
getGameObject endp


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