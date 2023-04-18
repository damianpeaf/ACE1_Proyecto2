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
Randoms1:
    db 0Ah,9Fh,0F0h,1Bh,69h,3Dh,0E8h,52h,0C6h,41h,0B7h,74h,23h,0ACh,8Eh,0D5h
Randoms2:
    db 9Ch,0EEh,0B5h,0CAh,0AFh,0F0h,0DBh,69h,3Dh,58h,22h,06h,41h,17h,74h,83h
    
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
		
        call userInput

        mov check_ghost_collission, 1

        call moveGhosts
        call ghostsCollission
        call moveAceman
        call ghostsCollission
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