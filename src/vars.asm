; ----------------- GENERAL -----------------

mGeneralVariables macro 

    errorMessage db "Error: $"
    initialMessage db  "Universidad de San Carlos de Guatemala", 0dh, 0ah,"Facultad de Ingenieria", 0dh, 0ah,"Escuela de Ciencias y Sistemas", 0dh, 0ah,"Arquitectura de Compiladores y ensabladores 1", 0dh, 0ah,"Seccion B", 0dh, 0ah,"Damian Ignacio Pena Afre", 0dh, 0ah,"202110568", 0dh, 0ah,"Presiona ENTER", 0dh, 0ah, "$"
    newLine db 0ah, "$"
    whiteSpace db 20h, "$"
    carryReturn db 0dh, "$"
    sColon db ':', "$"

endm


; ----------------- FILES -----------------
mFilesVariables macro 

    filehandle dw 0
    readCharBuffer db 2 dup(0)
    readStringBuffer db 100 dup('$')
    fileLine dw 1

    firstLevelFile db "niv1.aml",0
    secondLevelFile db "niv2.aml",0
    thirdLevelFile db "niv3.aml",0
    numberReference dw 0
    selectedWall db 0
    portalNumber db 0

    ; Files keyword
    sNivel db '"nivel"'
    sValordot db '"valordot"'
    sAcemanInit db '"acemaninit":{'
    sX db '"x"'
    sY db '"y"'
    sObjectEnd db '},'
    sWalls db '"walls":['
    sPowerdots db '"power-dots":['
    sPortales db '"portales":['
    sNumero db '"numero"'
    sA db '"a":{'
    sB db '"b":{'

endm

mReadLine macro

    push ax

    mov ax, fileLine
    inc ax
    mov fileLine, ax
    

    pop ax

    call readOneLineOfFile
    cmp dx, 1
    je read_file_error

endm


; OUTPUT: AX: x, BX: y
mCheckCoordinate macro
    mCheckNumberPropertie sX
    push ax

    mCheckNumberPropertie sY
    xchg ax, bx
    pop ax
endm

mLineEquals macro variable
    mReadLine
    lea si, readStringBuffer
    lea di, variable
    mov cx, sizeof variable
    call compareStrings
    cmp dx, 1
    je read_file_error
    add si, cx
endm

mCheckNumberPropertie macro variable

    mLineEquals variable

    mov al, [si]
    cmp al, ':'
    jne read_file_error
    inc si

    call checkNumber
    cmp dx, 0
    je read_file_error

endm

; ----------------- GAME -----------------

mGameVariables macro 

; 0-F -> Wall sprites
; 10 -> Aceman
; 11 -> Acedot
; 14  -> Power dot
; 15 > Portal's pair

game_board db 3E8 dup(0) ; 40d x 25d = 1000d = 3E8h
informationMessage db "Informacion", 0
currentLevel dw 0
dotValue dw 0
aceman_x dw 0
aceman_y dw 0
endGame db 0 ; 0 -> Game is running, 255 -> Game is over
gamePoints dw 0
aceman_hp db 3 ; 3 lives
max_score dw 0
random db 0 ; 0 | 1

initialTimestamp dw 0 ; in hundredths of seconds
elapsedTimestamp dw 0 ; in hundredths of seconds

elapsedMinutes dw 0
elapsedSeconds dw 0
elapsedHundredths dw 0

; Direction
is_aceman_open db 0 ; 0 -> Closed, 255 -> Open

aceman_right equ 00 ; Default, its the first sprite of aceman
aceman_left equ 40 ; 40h = 64d that is the offset of the left sprite
aceman_up equ 80 ; 80h = 128d that is the offset of the up sprite
aceman_down equ 0c0h ; 0c0h = 192d that is the offset of the down sprite
aceman_no_direction equ 1

aceman_direction db aceman_right ; right

power_dot_timestamp db 0 ; in seconds
last_power_dot_timestamp db 0 ; in seconds
power_dot_timestamp_set db 0 ; 0 | 1
power_dot_time_left db 0ah ; in seconds

; Ghosts

check_ghost_collission db 0 ; 0 | 1
ghost_points dw 64h ; 100d
eaten_ghosts_in_a_row db 0 
house_return_x dw 0
house_return_y dw 0

red_ghost_x dw 0
red_ghost_y dw 0
red_ghost_direction db aceman_no_direction
is_red_ghost_eatable db 0
has_red_ghost_been_eaten db 0
is_red_ghost_in_house db 0

cyan_ghost_x dw 0
cyan_ghost_y dw 0
cyan_ghost_direction db aceman_no_direction
is_cyan_ghost_eatable db 0
has_cyan_ghost_been_eaten db 0
is_cyan_ghost_in_house db 0

yellow_ghost_x dw 0
yellow_ghost_y dw 0
yellow_ghost_direction db aceman_no_direction
is_yellow_ghost_eatable db 0
has_yellow_ghost_been_eaten db 0
is_yellow_ghost_in_house db 0

pink_ghost_x dw 0
pink_ghost_y dw 0
pink_ghost_direction db aceman_no_direction
is_pink_ghost_eatable db 0
has_pink_ghost_been_eaten db 0
is_pink_ghost_in_house db 0

; Portals
serchead_portal_x dw 0
serchead_portal_y dw 0
serchead_portal_number dw 0

RandomSeed dw 0
endm


mInitVideoMode macro

    mov ax, 0013h
    int 10h

endm

mEndVideoMode macro

    mov ax, 0003h
    int 10h

endm


mEvalReleaseGhost macro in_house, x_pos, y_pos, direction

    local end_evaluating_ghost

    cmp in_house, 1
    jne end_evaluating_ghost

    ; Ghost is in house

    call GenerateRandom
    cmp random, 5
    jne no_more_evals

    mov in_house, 0

    ; Change position

    ; ghost house x=20d y=09d
    push ax
    push cx
    push di
    ; delete sprite from ghost house
    mov ax, x_pos
    mov cx, y_pos
    lea di, sprite_walls
    call paintSprite

    mov ax, 14h ; 20d
    mov x_pos, ax

    mov ax, 09h ; 9d
    mov y_pos, ax

    mov direction, aceman_right

    pop di
    pop cx
    pop ax

    jmp no_more_evals
    end_evaluating_ghost:

endm


mEvalGhostMovement macro x_pos, y_pos, direction

    local ghost_move_up, ghost_move_left, ghost_move_right, ghost_move_validate, skip_evaluating_ghost_movement, not_move_ghost, portal_transport, move_ghost, eval_new_direction, ghost_move_down

    mov ax, x_pos
    mov cx, y_pos

    mov dh, direction

    cmp dh, aceman_no_direction
    je skip_evaluating_ghost_movement

    ;down
    ghost_move_down:
    cmp dh, aceman_down
    jne ghost_move_up
    inc cx
    jmp ghost_move_validate

    ghost_move_up:
        cmp dh, aceman_up
        jne ghost_move_left
        dec cx
        jmp ghost_move_validate

    ghost_move_left:
        cmp dh, aceman_left
        jne ghost_move_right
        dec ax
        jmp ghost_move_validate

    ghost_move_right:    
        inc ax

    ghost_move_validate:

        call getGameObject
        mov bx, dx

        call isInsideGhostHouse ; * mutates DX
        cmp dl, 1
        je not_move_ghost

        mov dx, bx

        cmp dx, 0 ; Next object is empty space
        je move_ghost

        cmp dx, 0fh 
        jle not_move_ghost ; Next object is wall

        cmp dx, 15h
        jge portal_transport

        jmp move_ghost

        not_move_ghost:

            ; Initial direction
            call GenerateRandom

            mov ax, x_pos
            mov cx, y_pos

            mov dh, aceman_down
            mov direction, dh
            cmp random, 1
            je ghost_move_down

            mov dh, aceman_up
            mov direction, dh
            cmp random, 2
            je ghost_move_up
            
            mov dh, aceman_left
            mov direction, dh
            cmp random, 3   
            je ghost_move_left

            mov dh, aceman_right
            mov direction, dh
            cmp random, 4
            je ghost_move_right

            jmp not_move_ghost

        portal_transport:
            mov serchead_portal_x, ax
            mov serchead_portal_y, cx
            mov serchead_portal_number, dx
            call searchPortalEnd
            jmp move_ghost

        move_ghost:
            mov x_pos, ax
            mov y_pos, cx


    skip_evaluating_ghost_movement:

endm


mDeleteGhost macro x_pos, y_pos

    local restore_sprite

    mov ax, x_pos
    mov cx, y_pos

    call getGameObject
    lea di, sprite_ace_dot
    cmp dx, 13h
    je restore_sprite

    lea di, sprite_power_dot
    cmp dx, 14h
    je restore_sprite

    lea di, sprite_walls ; white space

    restore_sprite:
    call paintSprite

endm


mEvalGhostCollission macro pos_x, pos_y, eatable, has_been_eaten, is_in_house, direction

    local no_ghost_collission, decrease_lives, add_score, bonus_score

    je no_ghost_collission

    ; Same position as aceman
    mov ax, aceman_x
    cmp pos_x, ax
    jne no_ghost_collission

    mov ax, aceman_y
    cmp pos_y, ax
    jne no_ghost_collission

    mov check_ghost_collission, 0
    ; Ghost is not eatable
    cmp eatable, 0
    je decrease_lives

    ; Ghost is eatable
    mov has_been_eaten, 1
    mov eatable, 0
    mov is_in_house, 1

    ; increase score
    
    mov ax, ghost_points
    xor cx, cx
    mov cl, eaten_ghosts_in_a_row
    mov bx, 2h ; double points

    bonus_score:
        cmp cx, 0
        je add_score

        xor dx, dx
        mul bx

        dec cx
        jmp bonus_score

    add_score:
    add gamePoints, ax
    inc eaten_ghosts_in_a_row

    ; move ghost to ghost house
    mDeleteGhost pos_x, pos_y
    mov ax, house_return_x
    mov pos_x, ax
    mov ax, house_return_y
    mov pos_y, ax
    mov direction, aceman_no_direction

    jmp no_ghost_collission
    decrease_lives:
        dec aceman_hp
        cmp aceman_hp, 0
        jne no_ghost_collission

        ; Game over
        mov al, 0ffh        
        mov endGame, al ; toggle endGame


    no_ghost_collission:

endm