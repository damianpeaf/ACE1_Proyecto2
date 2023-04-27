

; Description: Creates a user-defined function.
; Input: DL = user type (1 = admin, 2 = subadmin, 3 = user)
;        DH = active (1 = active, 0 = inactive)
;        USES usernameBuffer, passwordBuffer
createUser proc
    
    mov bx, free_address
    cmp bx, 0 ; [NULL] address
    jne not_first_user 

    lea bx, data_block
    
    not_first_user:
    mov si, bx ; si = next free address

    ; Set current address
    mov [si], bx

    ; Set the previos user's next address to the current address
    mov di, last_user_address
    cmp di, 0 ; [NULL] address
    je noPrevUser
    
    add di, 2 ; skips user's address
    mov word ptr [di], bx ; Set the next address to the current address

    noPrevUser:
    mov last_user_address, si

    ; Set the next user's address to 0 [NULL]
    add si, 2 ; skips new user's address
    mov word ptr [si], 0

    ; Sets first game address to 0 [NULL]
    add si, 2 ; skips new user's next address
    mov word ptr [si], 0

    ; Sets user's type
    add si, 2 ; skips new user's first game address
    mov [si], dl

    ; Sets user's active status
    add si, 1 ; skips new user's type
    mov [si], dh

    ; Sets user's username
    add si, 1 ; skips new user's active status
    
    lea di, usernameBuffer
    ; di -> max chars
    ; di+1 -> received chars
    ; di+2 -> username

    xor cx, cx
    mov cl, [di+1] ; cl = received chars
    mov [si], cl ; Sets user's username length

    add si, 1 ; skips new user's username length

    add di, 2 ; skips max chars and received chars
    copy_username:
        mov al, [di]
        mov [si], al
        inc di
        inc si
        loop copy_username

    ; Sets user's password
    add si, cx ; skips new user's username
    
    lea di, passwordBuffer
    ; di -> max chars
    ; di+1 -> received chars
    ; di+2 -> password

    xor cx, cx
    mov cl, [di+1] ; cl = received chars
    mov [si], cl ; Sets user's password length

    add si, 1 ; skips new user's password length

    add di, 2 ; skips max chars and received chars
    copy_password:
        mov al, [di]
        mov [si], al
        inc di
        inc si
        loop copy_password

    add si, cx ; skips new user's password


    mov free_address, si

    ; * Debug
    ; mov byte ptr [si], '$' 
    ; lea di, data_block
    ; mPrintAddress di
    ; mWaitForEnter

    call memoryReport

    ret
createUser endp


createAdmin proc

    call reinitUsernameBuffer
    mov si, 0
    mov usernameBuffer[si], 0feh

    inc si
    xor cx, cx
    mov cx, sizeof admin_username
    mov usernameBuffer[si], cl
    inc si

    lea di, admin_username

    copy_admin_username:
        mov al, [di]
        mov usernameBuffer[si], al
        inc si
        inc di
        loop copy_admin_username    

    call reinitPasswordBuffer
    mov si, 0
    mov passwordBuffer[si], 0feh

    inc si
    xor cx, cx
    mov cx, sizeof admin_password
    mov passwordBuffer[si], cl
    inc si

    lea di, admin_password

    copy_admin_password:
        mov al, [di]
        mov passwordBuffer[si], al
        inc si
        inc di
        loop copy_admin_password

    mov dl, 1 ; admin
    mov dh, 1 ; active

    call createUser

    ret
createAdmin endp

 
; Description: Waits for user input and stores the input in the usernameBuffer.
getUsernameInput proc

    push ax
    push bx
    push cx
    push dx

    call reinitUsernameBuffer

    mov si, 0
    mov usernameBuffer[si], 0feh

    lea dx, usernameBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

    ret
getUsernameInput endp

; Description: Waits for user input and stores the input in the passwordBuffer.
getPasswordInput proc

    push ax
    push bx
    push cx
    push dx

    call reinitPasswordBuffer

    mov si, 0
    mov passwordBuffer[si], 0feh

    lea dx, passwordBuffer 
    mov ah, 0ah
    int 21h

    pop dx
    pop cx
    pop bx
    pop ax

    ret
getPasswordInput endp

reinitUsernameBuffer proc
    mReinitBuffer usernameBuffer
    ret
reinitUsernameBuffer endp

reinitPasswordBuffer proc
    mReinitBuffer passwordBuffer
    ret
reinitPasswordBuffer endp


loginMenu proc
    
    login_loop:

    mPrint newLine
    mPrint newLine
    mPrint sLoginMenu

    mov ah, 10h
    int 16h

    cmp al, 31h ; 1
    je main_login

    cmp al, 32h ; 2
    je end_program

    cmp ah, 42h ; F8
    je create_user
    
    mPrint invalidOption
    mWaitForEnter
    jmp login_loop

    main_login:
    mPrint newLine

    mPrint newLine
    mPrint sUsername
    call getUsernameInput

    mPrint newLine
    mPrint sPassword
    call getPasswordInput

    call authUser

    cmp logged_user_address, 0 ; [NULL] address
    je invalid_login

    cmp logged_user_type, 1 ; admin
    je goToAdminMenu

    cmp logged_user_type, 2 ; subadmin
    je goToSubAdminMenu

    cmp logged_user_type, 3 ; user
    je goToUserMenu

    goToAdminMenu:
    call adminMenu
    jmp end_login

    goToSubAdminMenu:
    call subAdminMenu
    jmp end_login

    goToUserMenu:
    call userMenu
    jmp end_login

    create_user:
    mPrint newLine

    mPrint sUsername
    call getUsernameInput

    mPrint newLine

    mPrint sPassword
    call getPasswordInput

    mov dl, 3 ; user
    mov dh, 0 ; inactive
    call createUser
    jmp login_loop

    invalid_login:
    mPrint newLine
    mPrint sInvalidLogin
    mWaitForEnter
    jmp login_loop

    end_login:

    ret
loginMenu endp


; Description: veryfies if the username and password are correct.
; Input: usernameBuffer, passwordBuffer
; Output: logged_user_address
authUser proc

    lea si, data_block ; first user address

    registered_user_loop:
        mov bx, [si] ; bx = user address

        cmp bx, 0 ; [NULL] address
        je end_auth

        mov si, bx ; si = user address
        ; search for the username
        ; si + 2 -> skip user's address
        ; si + 2 + 2 -> skip user's next address
        ; si + 2 + 2 + 2 -> skip user's first game address

        ; search for the user type
        add si, 6
        mov al, [si] ; al = user type
        mov logged_user_type, al ; save user type

        inc si ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 0 ; al = 0 if inactive, 1 if active
        je is_not_the_user

        inc si ; si = username length address
        xor cx, cx
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        lea di, usernameBuffer
        add di, 2 ; di = username bytes
        push si ; save username address
        push bx ;?
        push cx ; save username length

        call compareStrings

        pop cx ; restore username length
        pop bx ;?
        pop si ; restore username address
        cmp dx, 0 ; dx = 0 if equal, 1 if not equal
        jne is_not_the_user

        ; search for the password
        add si, cx ; si = password length
        xor cx, cx
        mov cl, [si] ; cl = password length
        add si, 1 ; si = password bytes
        lea di, passwordBuffer
        add di, 2 ; di = password bytes
        push si ; save password address
        push bx ;?

        call compareStrings
        
        pop bx ;?
        pop si ; restore password address
        cmp dx, 0 ; dx = 0 if equal, 1 if not equal
        je end_auth ; if password is correct, end auth

        is_not_the_user:
            mov si, bx ; si = first user address
            add si, 2 ; si = next user address
            jmp registered_user_loop

    end_auth:
        mov logged_user_address, bx

    ret
authUser endp

adminMenu proc
    
    print_admin_options:
        mPrint newLine
        mPrint newLine
        mPrint sInitGame
        mPrint sDeactivateUser
        mPrint sActivateUser
        mPrint sTop10GlobalTimes
        mPrint sTop10GlobalScores
        mPrint sExitMenu
        
        mov ah, 10h
        int 16h

        cmp al, 31h ; 1
        je admin_init_game

        cmp al, 32h ; 2
        je admin_deactivate_user

        cmp al, 33h ; 3
        je admin_activate_user

        cmp al, 34h ; 4
        je admin_top10_global_times

        cmp al, 35h ; 5
        je admin_top10_global_scores

        cmp al, 36h ; 6
        je end_admin_menu
        
        mPrint invalidOption
        mWaitForEnter
        jmp print_admin_options

        admin_init_game:
            call startGame
            jmp print_admin_options

        admin_deactivate_user:
            call deactivateUser
            jmp print_admin_options
            
        admin_activate_user:
            call activateUser
            jmp print_admin_options

        admin_top10_global_times:
            call loadGlobalGames
            mov metric, 0
            call algorithmParams
            jmp print_admin_options

        admin_top10_global_scores:
            call loadGlobalGames
            mov metric, 1
            call algorithmParams
            jmp print_admin_options

    end_admin_menu:
    ret ; -> Exit menu
adminMenu endp

subAdminMenu proc
    print_subadmin_options:
        mPrint newLine
        mPrint newLine
        mPrint sInitGame
        mPrint sTop10PersonalTimes
        mPrint sTop10PersonalScores
        mPrint sTop10GlobalTimes
        mPrint sTop10GlobalScores
        mPrint sExitMenu

        mov ah, 10h
        int 16h

        cmp al, 31h ; 1
        je subadmin_init_game

        cmp al, 32h ; 2
        je subadmin_top10_personal_times

        cmp al, 33h ; 3
        je subadmin_top10_personal_scores
        
        cmp al, 34h ; 4
        je subadmin_top10_global_times

        cmp al, 35h ; 5
        je subadmin_top10_global_scores

        cmp al, 36h ; 6
        je end_subadmin_menu

        mPrint invalidOption
        mWaitForEnter
        jmp print_subadmin_options

        subadmin_init_game:
            call startGame
            jmp print_subadmin_options

        subadmin_top10_personal_times:
            call loadPersonalGames
            mov metric, 0
            call algorithmParams
            jmp print_subadmin_options

        subadmin_top10_personal_scores:
            call loadPersonalGames
            mov metric, 1
            call algorithmParams
            jmp print_subadmin_options

        subadmin_top10_global_times:
            call loadGlobalGames
            mov metric, 0
            call algorithmParams
            jmp print_subadmin_options

        subadmin_top10_global_scores:
            call loadGlobalGames
            mov metric, 1
            call algorithmParams
            jmp print_subadmin_options

    end_subadmin_menu:
    ret ; -> Exit menu
subAdminMenu endp

userMenu proc
    
    print_user_options:
        mPrint newLine
        mPrint newLine
        mPrint sInitGame
        mPrint sTop10PersonalTimes
        mPrint sTop10PersonalScores
        mPrint sExitMenu

        mov ah, 10h
        int 16h

        cmp al, 31h ; 1
        je user_init_game

        cmp al, 32h ; 2
        je user_top10_personal_times

        cmp al, 33h ; 3
        je user_top10_personal_scores

        cmp al, 34h ; 4
        je end_user_menu

        mPrint invalidOption
        mWaitForEnter
        jmp print_user_options

        user_init_game:
            call startGame
            jmp print_user_options

        user_top10_personal_times:
            call loadPersonalGames
            mov metric, 0
            call algorithmParams
            jmp print_user_options

        user_top10_personal_scores:
            call loadPersonalGames
            mov metric, 1
            call algorithmParams
            jmp print_user_options

    end_user_menu:
    ret ; -> Exit menu
userMenu endp


deactivateUser proc
    mov cl, 1 ; first non-admin user

    select_user_loop_inactive:
        call getUserByIndex
        cmp bx, 0 ; [NULL] address
        je deactivate_null_user
        
        
        mov si, bx ; si = user address
        add si, 7 ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 0 ; al = 0 if active
        je skip_inactive_user

        mPrint newLine
        mPrint sSelectedUser

        push cx ; save user index
        add si, 1 ; si = username length address
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        call copyStringInBuffer
        lea di, stringCopyBuffer
        mPrintAddress di

        mPrint newLine

        mPrint sInactiveUser ; a
        mPrint sNextUser ; d
        mPrint sBack ; r

        pop cx ; restore user index

        mov ah, 10h
        int 16h

        cmp al, 61h ; a
        je innactivate_selected_user

        cmp al, 64h ; d
        je skip_inactive_user

        cmp al, 72h ; r
        je end_user_inactivation

        mPrint invalidOption
        mWaitForEnter
        jmp select_user_loop_inactive

        deactivate_null_user:
            mPrint sNotFoundUser
            mWaitForEnter
            jmp end_user_inactivation
        
        skip_inactive_user:
            inc cl ; cl = cl + 1
            jmp select_user_loop_inactive

        innactivate_selected_user: 
            mov si, bx ; si = user address
            add si, 7 ; si = user active status
            mov al, 0 ; al = 0
            mov [si], al ; user active status = 0
            
            mPrint sUserDeactivated
            mWaitForEnter
            jmp skip_inactive_user
            

    end_user_inactivation:
    ret
deactivateUser endp


activateUser proc

    mov cl, 1 ; first non-admin user

    select_user_loop:
        call getUserByIndex
        cmp bx, 0 ; [NULL] address
        je activate_null_user
        
        
        mov si, bx ; si = user address
        add si, 7 ; si = user active status
        mov al, [si] ; al = user active status
        cmp al, 1 ; al = 1 if active
        je skip_active_user

        mPrint newLine
        mPrint sSelectedUser

        push cx ; save user index
        add si, 1 ; si = username length address
        mov cl, [si] ; cl = username length
        add si, 1 ; si = username bytes
        call copyStringInBuffer
        lea di, stringCopyBuffer
        mPrintAddress di

        mPrint newLine

        mPrint sAcceptUser ; a
        mPrint sAcceptUser2 ; s
        mPrint sNextUser ; d
        mPrint sBack ; r

        pop cx ; restore user index

        mov ah, 10h
        int 16h

        cmp al, 61h ; a
        je accept_selected_user

        cmp al, 73h ; s
        je accept_selected_user_as_admin

        cmp al, 64h ; d
        je skip_active_user


        cmp al, 72h ; r
        je end_user_activation

        mPrint invalidOption
        mWaitForEnter
        jmp select_user_loop

        activate_null_user:
            mPrint sNotFoundUser
            mWaitForEnter
            jmp end_user_activation
        
        skip_active_user:
            inc cl ; cl = cl + 1
            jmp select_user_loop

        accept_selected_user: 
            mov si, bx ; si = user address
            add si, 7 ; si = user active status
            mov al, 1 ; al = 1
            mov [si], al ; activate user
            
            mPrint sUserActivated
            mWaitForEnter
            jmp skip_active_user
            
        accept_selected_user_as_admin: 
            mov si, bx ; si = user address
            add si, 6 ; si = user type address
            mov al, 2 ; al = 2 ; subadmin
            mov [si], al ; activate user
            add si, 1 ; si = user active status
            mov al, 1 ; al = 1
            mov [si], al ; activate user
            
            mPrint sUserActivated
            mWaitForEnter
            jmp skip_active_user

    end_user_activation:
    ret
activateUser endp

; Description: Get the user address by index
; Input: CL = user index
; Output: BX = user address | 0 if not found
getUserByIndex proc

    push cx ; save user index    
    lea si, data_block ; first user address

    registered_user_loop:
        mov bx, [si] ; bx = user address

        cmp bx, 0 ; [NULL] address
        je return_user

        cmp cl, 0 ; cl = 0 if is the user
        je return_user

        dec cl ; cl = cl - 1

        mov si, bx ; si = first user address
        add si, 2 ; si = next user address
        jmp registered_user_loop


    return_user:
    pop cx ; restore user index
    ret
getUserByIndex endp


; Description: Copies a string into a $ buffer
; Input: CL=chars to copy, SI=source address
; Output: stringCopyBuffer
copyStringInBuffer proc

    mov ch, 0
    ; reset stringCopyBuffer
    push cx

    lea di, stringCopyBuffer
    mov cl, 20
    mov al, '$'

    reset_copy_buffer:
        mov [di], al
        inc di
        loop reset_copy_buffer

    pop cx
    ; copy string
    
    lea di, stringCopyBuffer

    copy_string:
        mov al, [si]
        mov [di], al
        inc si
        inc di
        loop copy_string

    ret
copyStringInBuffer endp


; Description: Saves the game data on the respective user
saveGame proc
    
    mov bx, free_address

    mov si, bx ; si = next free address

    ; Set current address
    mov [si], bx

    ; set it in the user
    mov bx, logged_user_address ; bx = logged user address
    ; bx + 2 -> next user address
    ; bx + 4 -> first game address
    add bx, 4 ; bx = first game address

    mov ax, [bx] ; ax = first game address

    get_next_game_address:
        cmp ax, 0 ; ax = 0 if is the last game
        je set_game_address

        mov bx, ax ; bx = game address
        add bx, 2 ; bx = next game address
        mov ax, [bx] ; ax = next game address
        jmp get_next_game_address

    set_game_address:
        mov [bx], si ; set game address

    ; set next game address
    add si, 2 ; si = next game address
    mov word ptr [si], 0 ; set next game address to 0

    ; - set game data -

    ; set score
    add si, 2 ; si = game score address
    mov ax, gamePoints
    mov [si], ax

    ; set difference in hundredths
    add si, 2 ; si = game difference in hundredths address
    mov ax, differenceTimestamp
    mov [si], ax

    ; set currrent level
    add si, 2 ; si = game current level address
    mov al, levelCounter
    mov [si], al

    ; set user address
    inc si 
    mov bx, logged_user_address ; bx = logged user address
    mov [si], bx

    add si, 2 ; si = next free address
    mov free_address, si

    call memoryReport

    ret
saveGame endp


; Description: Gets the highest score of all games
getHighestScore proc
    
    mov dx, 0 ; dx = highest score
    mov cl, 0

    search_highest_score_user:
        call getUserByIndex
        
        cmp bx, 0 ; [NULL] address
        je end_search_highest_score

        inc cl ; next user

        add bx, 4 ; bx = first game prop address
        mov si, [bx] ; si = first game address

        search_highest_score_game:
            cmp si, 0 ; bx = 0 if is the last game
            je search_highest_score_user

            add si, 4 ; si = game score address
            mov ax, [si] ; ax = game score

            cmp ax, dx ; ax = highest score
            jle not_highest_score

            mov dx, ax ; dx = highest score

            not_highest_score:
            sub si, 2 ; si = next game address
            mov bx, [si] ; bx = next game address
            mov si, bx ; si = next game address
            jmp search_highest_score_game

    end_search_highest_score:

    ret
getHighestScore endp


resetAddressesArray proc
    
    mov addressSize, 0
    mov cx, 28h
    mov al, 0
    lea bx, addressArray

    reset_addresses_array:
        mov [bx], al
        inc bx
        loop reset_addresses_array

    ret
resetAddressesArray endp

loadPersonalGames proc

    call resetAddressesArray

    mov bx, logged_user_address ; bx = logged user address
    add bx, 4 ; bx = first game address

    lea si, addressArray
    mov ax, [bx] ; ax = first game address

    load_personal_game:
        cmp ax, 0 ; ax = 0 if is the last game
        je end_load_personal_game
        inc addressSize ; increase address size 

        mov word ptr [si], ax ; set game address
        add si, 2 ; si = next game address

        mov bx, ax ; bx = game address
        add bx, 2 ; bx = next game address
        mov ax, [bx] ; ax = next game address
        jmp load_personal_game

    end_load_personal_game:

    ret
loadPersonalGames endp


loadGlobalGames proc
    
    call resetAddressesArray
    mov cl, 0 ; cl = user index
    lea di, addressArray

    global_game_user_loop:
        push di
        call getUserByIndex
        pop di

        cmp bx, 0 ; [NULL] address
        je end_load_global_games

        inc cl ; next user

        add bx, 4 ; bx = first game prop address
        mov si, [bx] ; si = first game address

        next_global_game:
            cmp si, 0 ; bx = 0 if is the last game
            je global_game_user_loop

            inc addressSize ; increase address size
            mov word ptr [di], si ; set game address

            add di, 2 ; di = next game address
            mov bx, si ; bx = game address
            add bx, 2 ; bx = next game address
            mov si, [bx] ; si = next game address

            jmp next_global_game

    end_load_global_games:
    ret
loadGlobalGames endp

; Description: gets the time value from a game address
; Input: BX = game address
; Output: DX = time value
getTimeFromGame proc
    
    push bx

    add bx,6 ; bx = game difference in hundredths address
    mov dx, [bx] ; dx = game difference in hundredths

    pop bx

    ret
getTimeFromGame endp


; Description: gets the score value from a game address
; Input: BX = game address
; Output: DX = score value
getScoreFromGame proc
    
    push bx

    add bx,4 ; bx = game score address
    mov dx, [bx] ; dx = game score

    pop bx

    ret
getScoreFromGame endp

; Description: Algorithm params
algorithmParams proc
    
    algorithm_selection:
        mPrint newLine
        mPrint sBubbleSort
        mPrint sCocktailSort
        mPrint sPrimeSort

        mov ah, 10h
        int 16h

        cmp al, '1'
        je bubble_sort_param

        ; TODO:
        ; cmp al, '2'
        ; je cocktail_sort_param

        ; cmp al, '3'
        ; je prime_sort_param

        mPrint invalidOption
        mWaitForEnter
        jmp algorithm_selection

        bubble_sort_param:
            mov selected_algorithm, 0
            jmp orientation_selection

        cocktail_sort_param:
            mov selected_algorithm, 1
            jmp orientation_selection

        prime_sort_param:
            mov selected_algorithm, 2
            jmp orientation_selection

        orientation_selection:
            mPrint newLine
            mPrint sAsc
            mPrint sDesc

            mov ah, 10h
            int 16h

            cmp al, '1'
            je ascending_param

            cmp al, '2'
            je descending_param

            mPrint invalidOption
            mWaitForEnter
            jmp orientation_selection

            ascending_param:
                mov orientation, 0
                jmp velocity_selection

            descending_param:
                mov orientation, 1

            velocity_selection:
                mPrint newLine
                mPrint sVelocity

                mov ah, 10h
                int 16h

                cmp al, '0'
                jl invalid_velocity

                cmp al, '9'
                jg invalid_velocity

                sub al, '0'
                mov velocity, al
                jmp end_algoritm_params

                invalid_velocity:
                    mPrint invalidOption
                    mWaitForEnter
                    jmp velocity_selection

    end_algoritm_params:

    ; cmp selected_algorithm, 0
    ; je do_bubble_sort

    ; cmp selected_algorithm, 1
    ; je do_cocktail_sort

    ; cmp selected_algorithm, 2
    ; je do_prime_sort

    ; do_bubble_sort:
    call bubbleSort

    call generateReport
    ret

algorithmParams endp

; Description: Do the bubble sort algorithm from the games addresses
; Input: addressArray
;        metric: 0 -> time; 1 -> score
;        orientation: 0 -> ascending; 1 -> descending
;        velocity: [0-9] ?
; Output: 
bubbleSort proc
    
    ; si prev address
    ; di next address

    cmp addressSize, 1
    jle end_bubble_sort

    mov cx, 1 ; i = 1
    mov i, cx

    bubble_sort_outer_loop:
        mov cx, 0 ; j = 0
        mov j, cx

        bubble_sort_inner_loop:

            ; a[j]
            mov cx, j
            call getValueFromIndex
            mov ax, dx ; AX = a[j]

            ; a[j+1]
            mov cx, j
            inc cx
            call getValueFromIndex

            ; a[j] > a[j+1] or a[j] < a[j+1]
            cmp orientation, 0 ; ascending
            je ascending_condition

            ; - descending -
            cmp ax, dx ; a[j] < a[j+1]
            jl exchange_address
            jmp next_inner_iteration

            ascending_condition:
                cmp ax, dx ; a[j] > a[j+1]
                jg exchange_address
                jmp next_inner_iteration
            
            exchange_address:
                mov ax, j
                mov ch, al ; ch = j
                inc ax
                mov cl, al ; cl = j + 1
                call exchangeAddressFromindex
                jmp next_inner_iteration

            next_inner_iteration:
                mov cx, j
                inc cx
                mov j, cx ; j++

                mov ax, addressSize
                dec ax

                cmp cx, ax
                jl bubble_sort_inner_loop

            next_outer_iteration:
                mov cx, i
                inc cx
                mov i, cx ; i++

                mov ax, addressSize
                ; dec ax

                cmp cx, ax
                jl bubble_sort_outer_loop
                ; jg end_bubble_sort

    end_bubble_sort:
    ret
bubbleSort endp



; Description: exchanges the values of two addresses
; Input: ch = 1st index; cl = 2nd index
exchangeAddressFromindex proc
    
    mov bl, 2
    
    xor ax, ax
    xor dx, dx
    mov al, ch
    mul bl ; al = 2 * ch
    mov ch, al ; ch = 2 * ch

    xor ax, ax
    xor dx, dx
    mov al, cl
    mul bl ; al = 2 * cl
    mov cl, al ; cl = 2 * cl

    lea si, addressArray ; * si first address
    lea di, addressArray ; * di second address

    xor bx, bx
    mov bl, ch
    add si, bx ; si = 1st address
    mov dx, [si] ; dx = 1st address

    xor bx, bx
    mov bl, cl
    add di, bx ; di = 2nd address
    mov ax, [di] ; ax = 2nd address

    mov [si], ax ; 1st address = 2nd address
    mov [di], dx ; 2nd address = 1st address

    ret
exchangeAddressFromindex endp 


; Description: Gets the value corresponding to a game address from index
; Input: CX = index
; Output: DX = value
getValueFromIndex proc

    push cx
    push si
    push bx
    
    lea si, addressArray

    getAddressFromIndex_loop:
        cmp cx, 0
        je end_getAddressFromIndex

        add si, 2
        dec cx
        jmp getAddressFromIndex_loop

    end_getAddressFromIndex:

    mov bx, [si]

    cmp metric, 0
    je get_time_from_game

    call getScoreFromGame
    jmp return_getAddressFromIndex

    get_time_from_game:
        call getTimeFromGame

    return_getAddressFromIndex:
    pop bx
    pop si
    pop cx
    ret
getValueFromIndex endp

