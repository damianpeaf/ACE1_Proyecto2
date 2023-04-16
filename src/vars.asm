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

red_ghost_x dw 0
red_ghost_y dw 0
red_ghost_direction db aceman_no_direction
is_red_ghost_eatable db 0

cyan_ghost_x dw 0
cyan_ghost_y dw 0
cyan_ghost_direction db aceman_no_direction
is_cyan_ghost_eatable db 0

yellow_ghost_x dw 0
yellow_ghost_y dw 0
yellow_ghost_direction db aceman_no_direction
is_yellow_ghost_eatable db 0

pink_ghost_x dw 0
pink_ghost_y dw 0
pink_ghost_direction db aceman_no_direction
is_pink_ghost_eatable db 0

; Portals
serchead_portal_x dw 0
serchead_portal_y dw 0
serchead_portal_number dw 0

endm


mInitVideoMode macro

    mov ax, 0013h
    int 10h

endm

mEndVideoMode macro

    mov ax, 0003h
    int 10h

endm

