

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

    ; Write to file
    mWriteIndDoc sSeparator
    call writeNewLine

    mWriteIndDoc initialMessage
    call writeNewLine

    mWriteIndDoc sSeparator
    call writeNewLine

    mWriteIndDoc sDeveloper
    call writeNewLine

    mWriteIndDoc sSeparator
    call writeNewLine

    call writeReportHeader

    ; Close file
    mov bx, filehandle
    mov ah, 3eh
    int 21h
    jmp end_report_generation

    create_file_error:
        mPrint errorMessage

    end_report_generation:
    ret
generateReport endp

writeNewLine proc
    mWriteIndDoc newLine
    ret
writeNewLine endp


; Description: Write the report header
writeReportHeader proc
    
    mWriteIndDoc sType

    ; cmp selected_algorithm, 0
    ; je writeBubbleSort

    mWriteIndDoc sBubbleSort

    mWriteIndDoc sOrientation


    cmp orientation, 0
    je writeAscending

    mWriteIndDoc sDesc
    jmp end_write_orientation

    writeAscending:
        mWriteIndDoc sAsc

    end_write_orientation:
    call writeTimes

    mWriteIndDoc sSeparator

    mWriteIndDoc sHeader

    ret
writeReportHeader endp


; Description: Write the date and time of the report
writeTimes proc
    
    mWriteIndDoc sDate

    mov ah, 2ah
    int 21h
    ; DL = day, DH = month, CX = year

    ; Write day
    mov ax, 0
    mov al, dl
    call write2DigitNumber

    mWriteIndDoc dateDelimiter

    ; Write month
    mov ah, 2ah
    int 21h
    mov ax, 0
    mov al, dh
    call write2DigitNumber

    mWriteIndDoc dateDelimiter

    ; Write year
    mov ah, 2ah
    int 21h
    mov ax, cx
    call write2DigitNumber


    ; ----- HOUR -----
    call writeNewLine
    mWriteIndDoc sTime

    mov ah, 2ch
    int 21h
    ; CH = hour, CL = minute, DH = second

    ; Write hour
    mov ax, 0
    mov al, ch
    call write2DigitNumber

    mWriteIndDoc hourDelimiter

    ; Write minute
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, cl
    call write2DigitNumber

    mWriteIndDoc hourDelimiter

    ; Write second
    mov ah, 2ch
    int 21h
    mov ax, 0
    mov al, dh
    call write2DigitNumber
    
    ret
writeTimes endp

; Description: Write the top 10 addresses
; Input: 
; Output: 
write2DigitNumber proc
    call numberToString
    lea dx, numberString
    add dx, 4 ; Last 2 digits of the day
    mov bx, filehandle
    mov cx, 2
    mov ah, 40h
    int 21h
    ret
write2DigitNumber endp