; Input: ECX = number of frames to wait
sleep:
    push eax
    push edx
    
    test ecx, ecx       ; Safety check
    jz .done

.frame_loop:
    mov dx, 0x3DA       ; VGA Input Status Register 1
.wait_low:
    in al, dx
    test al, 8          ; Check bit 3 (Vertical Retrace)
    jnz .wait_low       ; If it's already happening, wait for it to stop
.wait_high:
    in al, dx
    test al, 8
    jz .wait_high       ; Wait for it to start again
    
    dec ecx             ; Decrement frame counter
    jnz .frame_loop     ; Loop if not zero

.done:
    pop edx
    pop eax
    ret

; Macro: play_note frequency, duration_frames
macro play_note freq, dur
{
    push eax
    push ecx
    mov al, 0xB6
    out 0x43, al
    mov ax, 1193180 / freq
    out 0x42, al
    mov al, ah
    out 0x42, al
    in al, 0x61
    or al, 3
    out 0x61, al
    mov ecx, dur
    call sleep
    in al, 0x61
    and al, 0xFC
    out 0x61, al
    pop ecx
    pop eax
}
regDump:
        pushad
        call vga_hex32
        mov al, 'G'
        call vga_putchar
        mov eax, ebx
        call vga_hex32
        mov al, 'H'
        call vga_putchar
        mov eax, ecx
        call vga_hex32
        mov al, 'I'
        call vga_putchar
        mov eax, edx
        call vga_hex32
        mov al, 'J'
        call vga_putchar
        mov eax, esp
        call vga_hex32
        mov al, 'K'
        call vga_putchar
        mov eax, esi
        call vga_hex32
        mov al, 'L'
        call vga_putchar
        mov eax, edi
        call vga_hex32
        mov al, 'M'
        call vga_putchar
        mov eax, $
        call vga_hex32
        popad
        ret
; Returns: AX = random number 0-65535
randNum:
    push ebx
    push edx
    push ecx

    movzx eax, word [rSeed]
    mov ebx, 25173
    mul ebx                     ; eax = seed * 25173   (32-bit result)

    add eax, 13849

    and eax, 0xFFFF

    mov [rSeed], ax

    pop ecx
    pop edx
    pop ebx
    ret
reset_registers:
   mov eax, 0
   mov ebx, 0
   mov ecx, 0
   mov edx, 0
   mov esi, 0
   mov edi, 0
   ret
sendRDmp:
   pushad
   mov si, rDSmsg
   call vga_print
   mov ecx, 0
   .loop:
      mov al, byte [ecx]
      call serial_send
      inc ecx
      cmp ecx, 0x100000 ; max real mode addressable memory. it's all we really use anyway so ehhh
      jne .loop
   mov si, rDSdone
   call vga_print
   popad
   ret
common_exception_handler:
    pushad              ; Save all general purpose registers

    mov eax, [esp + 32]

    cmp eax, 31
    ja .unknown

    mov esi, dword [exception_messages + eax * 4]
    jmp .print

.unknown:
    mov esi, msg_exc_unknown

.print:
    mov [vga_color], 0x4f
    call vga_clear
    call vga_print
    call sendRDmp
    
    cli
    hlt
    jmp $


align 4
exception_messages:
    dd msg_exc_0,  msg_exc_1,  msg_exc_2,  msg_exc_3
    dd msg_exc_4,  msg_exc_5,  msg_exc_6,  msg_exc_7
    dd msg_exc_8,  msg_exc_9,  msg_exc_10, msg_exc_11
    dd msg_exc_12, msg_exc_13, msg_exc_14, msg_exc_15
    dd msg_exc_16, msg_exc_17, msg_exc_18, msg_exc_19
    dd msg_exc_20, msg_exc_21, msg_exc_22, msg_exc_23
    dd msg_exc_24, msg_exc_25, msg_exc_26, msg_exc_27
    dd msg_exc_28, msg_exc_29, msg_exc_30, msg_exc_31

dataRM: ; it's called dataRM not 'data' because FASM
   disco_mode db 0
   bbcolor db 0x1f
   rSeed dw 13849
   kb_ctrl_pressed db 0
   kb_alt_pressed db 0
   disco_msg db "Disco mode engaged!", 0
   disco_msg_2 db "Disco mode disengaged!", 0
   rDSmsg db "Sending RAM over serial (this will take a while)...", 0
   rDSdone db "Done!", 13, 10, 0
   ; Scancode to ASCII table (US layout, lowercase only for now)
   ; Index = scancode, value = ASCII (0 = no mapping)
   kb_scancode_table:
      db 0, 27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', 8, 9
      db 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', 13, 0, 'a', 's'
      db 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', "'", '`', 0, '\', 'z', 'x', 'c', 'v'
      db 'b', 'n', 'm', ',', '.', '/', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0
      db 0, 0, 0, 0, 0, 0, 0, '7', '8', '9', '-', '4', '5', '6', '+', '1'
      db '2', '3', '0', '.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
   ; Shifted characters (what you get when holding shift)
   kb_scancode_table_shift:
      db 0, 27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', 8, 9
      db 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', 13, 0, 'A', 'S'
      db 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~', 0, '|', 'Z', 'X', 'C', 'V'
      db 'B', 'N', 'M', '<', '>', '?', 0, '*', 0, ' ', 0, 0, 0, 0, 0, 0
      db 0, 0, 0, 0, 0, 0, 0, '7', '8', '9', '-', '4', '5', '6', '+', '1'
      db '2', '3', '0', '.', 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
   kb_shift_pressed db 0
   kb_caps_lock db 0
   vga_cursor_x db 0
   vga_cursor_y db 0
   msg_exc_0  db "0", 0
   msg_exc_1  db "1", 0
   msg_exc_2  db "2", 0
   msg_exc_3  db "3", 0
   msg_exc_4  db "4", 0
   msg_exc_5  db "5", 0
   msg_exc_6  db "6", 0
   msg_exc_7  db "7", 0
   msg_exc_8  db "8", 0
   msg_exc_9  db "9", 0
   msg_exc_10 db "10", 0
   msg_exc_11 db "11", 0
   msg_exc_12 db "12", 0
   msg_exc_13 db "13", 0
   msg_exc_14 db "14", 0
   msg_exc_15 db "15", 0
   msg_exc_16 db "16", 0
   msg_exc_17 db "17", 0
   msg_exc_18 db "18", 0
   msg_exc_19 db "19", 0
   msg_exc_20 db "20", 0
   msg_exc_21 db "21", 0
   msg_exc_22 db "22", 0
   msg_exc_23 db "23", 0
   msg_exc_24 db "24", 0
   msg_exc_25 db "25", 0
   msg_exc_26 db "26", 0
   msg_exc_27 db "27", 0
   msg_exc_28 db "28", 0
   msg_exc_29 db "29", 0
   msg_exc_30 db "30", 0
   msg_exc_31 db "31", 0
   msg_exc_unknown db "?", 0
   msg_exc_nl db 13, 10
   vga_color db 0x0F    ; White on black default