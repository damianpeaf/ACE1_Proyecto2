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

        lea dx, firstLevelFile
        call readLevelFile
        mWaitForEnter

        mInitVideoMode

        call graphGameBoard

        mWaitForEnter


    game_sequence:		
		call paintAceman

		; push AX
		; push CX
		; call entrada
		; pop CX
		; pop AX

        mov dl, endGame
        cmp dl, 0
        je game_sequence

    mEndVideoMode
   

end_program:
    mov al, 0
    mov ah, 4ch                         
    int 21h


end