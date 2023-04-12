; Práctica 4 - Arquitectura de Compiladores y ensambladores 1
; Made By: Damián Ignacio Pena Afre
; ID: 202110568
; Section: B
; Description: Excel with ASM

; --------------------- INCLUDES ---------------------

include utils.asm
include inputs.asm
include strings.asm

.model small
.stack
.radix 16

.data

; --------------------- VARIABLES ---------------------

initialMessage db  "Universidad de San Carlos de Guatemala", 0dh, 0ah,"Facultad de Ingenieria", 0dh, 0ah,"Escuela de Ciencias y Sistemas", 0dh, 0ah,"Arquitectura de Compiladores y ensabladores 1", 0dh, 0ah,"Seccion B", 0dh, 0ah,"Damian Ignacio Pena Afre", 0dh, 0ah,"202110568", 0dh, 0ah,"Presiona ENTER", 0dh, 0ah, "$"
newLine db 0ah, "$"
whiteSpace db 20h, "$"

; - STRINGS -
mStringVariables

; - INPUTS -
mInputVariables

.code

.startup
    
    initial_messsage: 
        mPrint initialMessage
        mPrint newLine

        mWaitForEnter
        mPrint newLine

    datasheet_sequence:
        mPrintDatasheet
        mPrint promptIndicator
        mEvalPromt

        jmp datasheet_sequence

    mOperations ; Operations labels

end_program:
    mov al, 0
    mov ah, 4ch                         
    int 21h

end