; ============================================================================
; PS/2 KEYBOARD DRIVER
; ============================================================================
db "PS2 DRV", 0, 0, 0, 0
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
    
    ; Check Delete (scancode 0x53)
    cmp al, 0x53
    je .check_cad

    cmp al, 0x52
    je .check_cal

    cmp al, 0x49
    je .pgup
    cmp al, 0x51
    je .pgdn
        
    
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
    cmp [kb_shift_pressed], 1
    je .skipF
    cmp [kb_alt_pressed], 1
    je .skipF2
    cmp [kb_ctrl_pressed], 1
    je .skipF3
    cmp al, 0x3b
    je .cdec
    cmp al, 0x3c
    je .cinc
    cmp al, 0x3d
    je .crst
    cmp al, 0x3e
    je .sndRam
    cmp al, 0x3f        ; F5 scancode
    je .toggle_disco
    cmp al, 0x40
    je .toggle_blink
    cmp al, 0x41
    je .binc
    cmp al, 0x42
    je .bdec
    cmp al, 0x43
    je .brst
    cmp al, 0x44
    je .dumpSta
    .skipF:
    cmp al, 0x3f
    je .vgaS
    .skipF2:
    .skipF3:
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

.check_cad:
    ; Check if Ctrl AND Alt are both pressed
    cmp byte [kb_ctrl_pressed], 1
    jne .no_map
    cmp byte [kb_alt_pressed], 1
    jne .no_map
    
    ; It's Ctrl+Alt+Del! Play reverse dingdong
    call dongding
.check_cal:
    ; Check if Ctrl AND Alt are both pressed
    cmp byte [kb_ctrl_pressed], 1
    jne .no_map
    cmp byte [kb_alt_pressed], 1
    jne .no_map
    
    ; It's Ctrl+Alt+Insert! Do a thing!
    call dingdong
    call vga_clear
    ret
.pgup:
    call dingdong
    xor al, al
    ret
.pgdn:
    call dongding
    xor al, al
    ret
.cinc:
   inc [vga_color]
   xor al, al
   call draw_titlebar
   ret
.cdec:
   dec [vga_color]
   xor al, al
   call draw_titlebar
   ret
.crst:
   push ax
   mov al, 0x0a
   call vga_set_color
   pop ax
   xor al, al
   call draw_titlebar
   ret
.binc:
   inc [bbcolor]
   xor al, al
   call draw_titlebar
   ret
.bdec:
   dec [bbcolor]
   xor al, al
   call draw_titlebar
   ret
.brst:
   mov [bbcolor], 0x1f
   xor al, al
   call draw_titlebar
   ret
.dumpSta:
   call regDump
   xor al, al
   ret
.vgaS:
   xor al, al
   call vga_seizure
   ret
.toggle_disco:
    cmp [disco_mode], 1
    je .off_disco
    mov [disco_mode], 1
    push esi
    mov esi, disco_msg
    call vga_print
    pop esi
    xor al, al
    ret
    .off_disco:
       mov [disco_mode], 0
       push esi
       mov esi, disco_msg_2
       call vga_print
       pop esi
       xor al, al
       ret
.toggle_blink:
    call vga_toggle_blink
    xor al, al
    ret
.rTest:
    push eax
    call randNum
    call vga_hex32
    xor al, al
    pop eax
    ret
.sndRam:
    call sendRDmp
    xor al, al
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