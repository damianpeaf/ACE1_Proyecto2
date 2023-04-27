; Proyecto 2 - Arquitectura de Compiladores y ensambladores 1
; Made By: Damián Ignacio Pena Afre
; ID: 202110568
; Section: B
; Description: Pacman game

; --------------------- INCLUDES ---------------------

include utils.asm
include inputs.asm
include strings.asm
include sprites.asm
include vars.asm
include memory.asm

.model small
.stack
.radix 16

.data

; --------------------- VARIABLES ---------------------

; - GENERAL -
mGeneralVariables

; - STRINGS -
mStringVariables

; - INPUTS -
mInputVariables

; - SPRITES -
mSpritesInfo
mSprites

; - GAME -
mGameVariables

; - Files -
mFilesVariables

; - MEMORY -
mMemoryBlocks ; *IMPORTANT* This must be the last variable declared


free_address dw 0 ; next free address
data_block dw 0

.code

include files.asm
include game.asm
include crud.asm
include reports.asm
.startup
    

    ; initial_messsage
        call createAdmin
        mPrint initialMessage
        mWaitForEnter

    initial_menu:
        mov logged_user_address, 0
        call loginMenu
        jmp initial_menu

    startGame proc

        mInitVideoMode
        mov differenceTimestamp, 0
        mov levelCounter, 1
        mov aceman_hp, 3
        mov gamePoints, 0
        mov pauseGame, 0
        mov gameLost, 0

        call getHighestScore
        mov max_score, dx

        call getInitialTime

        load_level:
        mov endGame, 0

        call resetGameBoard

        ; load level
        lea dx, firstLevelFile
        cmp levelCounter, 1
        je read_level_file

        lea dx, secondLevelFile
        cmp levelCounter, 2
        je read_level_file

        lea dx, thirdLevelFile

        read_level_file:
        call readLevelFile

        call acemanRandomInitialDirection

        ; Show pregamescreen
        call showPregameInfo
        mWaitForEnter

        call fillAceDots

        call clearScreen
        call graphGameBoard
        call initGhosts
    game_sequence:
        call printGameInformation
		call paintAceman
		
        call userInput

        mov check_ghost_collission, 1

        call moveGhosts
        call ghostsCollission
        call moveAceman
        call ghostsCollission

        mov dl, gameLost
        cmp dl, 1
        je exit_game

        mov dl, pauseGame
        cmp dl, 1
        je pause_menu

        mov dl, endGame
        cmp dl, 0
        je game_sequence

        inc levelCounter
        cmp levelCounter, 4
        jne load_level

        exit_game:
        mEndVideoMode

        ; Register score
        call saveGame
        ret ; -> return to caller

        pause_menu:
            call showPregameInfo
            call pauseTitle
            mPauseOptions

    startGame endp

end_program:
    call memoryReport
    mov al, 0c
    mov ah, 4ch                         
    int 21h


end