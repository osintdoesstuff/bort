; ============================================================================
; PS/2 KEYBOARD DRIVER
; ============================================================================
KB_DATA   equ 0x60
KB_STATUS equ 0x64
; Check if key available (non-blocking)
; Returns: CF set = no key, CF clear = scancode in AL
kb_poll:
    in al, KB_STATUS
    test al, 1
    jz .no_key
    in al, KB_DATA
    clc
    ret
.no_key:
    stc
    ret

; Wait for keypress (blocking)
; Returns: scancode in AL
kb_wait_scancode:
    in al, KB_STATUS
    test al, 1
    jz kb_wait_scancode
    in al, KB_DATA
    ret

; Wait for keypress and convert to ASCII (blocking)
; Returns: ASCII in AL (0 if no mapping or key release)
kb_getchar:
    call kb_wait_scancode
    
    ; Check for key release (bit 7 set)
    test al, 0x80
    jnz .key_release
    
    ; Check for extended prefix (eat it and get next byte)
    cmp al, 0xE0
    je kb_getchar           ; Just skip 0xE0 and read next scancode

    ; Check Ctrl
    cmp al, 0x1D
    je .ctrl_press
    
    ; Check Alt
    cmp al, 0x38
    je .alt_press
        
    
    ; Check arrow keys FIRST (before table lookup!)
    cmp al, 0x48            ; Up
    je .arrow_up
    cmp al, 0x50            ; Down
    je .arrow_down
    cmp al, 0x4B            ; Left
    je .arrow_left
    cmp al, 0x4D            ; Right
    je .arrow_right
    
    ; Check modifier keys
    cmp al, 0x2A
    je .shift_press
    cmp al, 0x36
    je .shift_press
    cmp al, 0x3A
    je .caps_press
    ; Normal key - convert to ASCII
    cmp al, 96
    jae .no_map
    
    movzx ebx, al
    
    mov cl, [kb_shift_pressed]
    xor cl, [kb_caps_lock]
    test cl, cl
    jz .use_normal
    
    mov al, [kb_scancode_table_shift + ebx]
    ret
    
.use_normal:
    mov al, [kb_scancode_table + ebx]
    ret

.arrow_up:
    mov al, 0x01
    ret
.arrow_down:
    mov al, 0x02
    ret
.arrow_left:
    mov al, 0x03
    ret
.arrow_right:
    mov al, 0x04
    ret
    
.ctrl_press:
    mov byte [kb_ctrl_pressed], 1
    xor al, al
    ret
    
.alt_press:
    mov byte [kb_alt_pressed], 1
    xor al, al
    ret
    
.shift_press:
    mov byte [kb_shift_pressed], 1
    xor al, al
    ret
    
.caps_press:
    xor byte [kb_caps_lock], 1
    xor al, al
    ret
    
.key_release:
    and al, 0x7F
    
    ; Check for Ctrl release
    cmp al, 0x1D
    je .ctrl_release
    
    ; Check for Alt release
    cmp al, 0x38
    je .alt_release
    
    ; Check for Shift release
    cmp al, 0x2A
    je .shift_release
    cmp al, 0x36
    je .shift_release
    jmp .no_map
    
.ctrl_release:
    mov byte [kb_ctrl_pressed], 0
    jmp .no_map
    
.alt_release:
    mov byte [kb_alt_pressed], 0
    jmp .no_map
    
.shift_release:
    mov byte [kb_shift_pressed], 0
    
.no_map:
    xor al, al
    ret
; Non-blocking getchar
; Returns: CF set = no key, CF clear = ASCII in AL
kb_getchar_poll:
    call kb_poll
    jc .no_key
    test al, 0x80
    jnz .release
    cmp al, 96
    jae .no_map
    movzx eax, al
    mov al, [kb_scancode_table + eax]
    test al, al
    jz .no_map
    clc
    ret
.release:
.no_map:
.no_key:
    stc
    ret