

; Description: Generate the top10.txt file
; Input: AddressArray with the ordered addresses
; Output: File top10.txt with the top 10 addresses
generateReport proc
    
    ; Create file
    mov cx, 0 ; Read-only
    mov dx, offset top10File
    mov ah, 3ch
    int 21h
    jc create_file_error

    mov filehandle, ax

    jmp end_report_generation
    create_file_error:
        mPrint errorMessage

    end_report_generation:
    ret
generateReport endp

writeNewLine proc
    mov bx, filehandle
    mov cx, sizeof pageHeader
    lea dx, pageHeader
    mov ah, 40h
    int 21h
    ret
writeNewLine endp