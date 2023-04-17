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

.code

include files.asm
include game.asm

.startup
    
    initial_messsage:
        mPrint initialMessage
        mWaitForEnter

        ; TODO: menus

    start_game:

        mov gamePoints, 0
        mov aceman_hp, 3
        call getInitialTime

        load_first_level:

        ; first level
        lea dx, firstLevelFile
        call readLevelFile
        mWaitForEnter

        mInitVideoMode

        call fillAceDots
        call graphGameBoard
        call initGhosts

        mWaitForEnter


    game_sequence:

        call printGameInformation
		call paintAceman
        ; call paintGhosts

		call userInput

        call moveAceman
        call moveGhosts
        ; TODO: move ghosts, separate delay

        mov dl, endGame
        cmp dl, 0
        je game_sequence

    mEndVideoMode
   

end_program:
    mov al, 0c
    mov ah, 4ch                         
    int 21h


end