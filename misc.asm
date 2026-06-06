db "GNR STF", 0, 0, 0, 0
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

bootSound:
    play_note 262, 17
    play_note 330, 17
    play_note 392, 17
    play_note 523, 25
    ret

dingdong:
    play_note 440, 3
    play_note 220, 3
    play_note 880, 3
    ret

dongding:
    play_note 880, 3
    play_note 220, 3
    play_note 440, 3
    ret
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
    push cx
    push dx
    mov ax, [rSeed]
    mov cx, 31821    ; 31821 * 65536 + 1 works well for 16-bit
    mul cx
    add ax, dx
    inc ax
    mov [rSeed], ax
    pop dx
    pop cx
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
   msg_exc_0  db "PANIC: Divide by Zero", 0
   msg_exc_1  db "PANIC: Debug Exception", 0
   msg_exc_2  db "PANIC: Non-Maskable Interrupt", 0
   msg_exc_3  db "PANIC: Breakpoint", 0
   msg_exc_4  db "PANIC: Overflow", 0
   msg_exc_5  db "PANIC: Bound Range Exceeded", 0
   msg_exc_6  db "PANIC: Invalid Opcode (Tried executing garbage)", 0
   msg_exc_7  db "PANIC: Device Not Available", 0
   msg_exc_8  db "PANIC: Double Fault (Something went horribly wrong)", 0
   msg_exc_9  db "PANIC: Coprocessor Segment Overrun", 0
   msg_exc_10 db "PANIC: Invalid TSS", 0
   msg_exc_11 db "PANIC: Segment Not Present", 0
   msg_exc_12 db "PANIC: Stack-Segment Fault", 0
   msg_exc_13 db "PANIC: General Protection Fault (You touched bad memory)", 0
   msg_exc_14 db "PANIC: Page Fault", 0
   msg_exc_15 db "PANIC: Reserved (15)", 0
   msg_exc_16 db "PANIC: x87 Floating-Point Exception", 0
   msg_exc_17 db "PANIC: Alignment Check", 0
   msg_exc_18 db "PANIC: Machine Check", 0
   msg_exc_19 db "PANIC: SIMD Floating-Point Exception", 0
   msg_exc_20 db "PANIC: Virtualization Exception", 0
   msg_exc_21 db "PANIC: Control Protection Exception", 0
   msg_exc_22 db "PANIC: Reserved (22)", 0
   msg_exc_23 db "PANIC: Reserved (23)", 0
   msg_exc_24 db "PANIC: Reserved (24)", 0
   msg_exc_25 db "PANIC: Reserved (25)", 0
   msg_exc_26 db "PANIC: Reserved (26)", 0
   msg_exc_27 db "PANIC: Reserved (27)", 0
   msg_exc_28 db "PANIC: Hypervisor Injection Exception", 0
   msg_exc_29 db "PANIC: VMM Communication Exception", 0
   msg_exc_30 db "PANIC: Security Exception", 0
   msg_exc_31 db "PANIC: Reserved (31)", 0
   msg_exc_unknown db "PANIC: Unknown Interrupt Received", 0
   vga_color db 0x0F    ; White on black default
bort_msg_1: db "Are you talking to me?", 13, 10
bort_msg_2: db "No, my OS is also named Bort", 13, 10
bort_msg_3: db "Sorry, we're out of Bort license plates", 13, 10
bort_msg_4: db "I repeat, we are sold out of Bort", 13, 10, 0, 0, 0, 0
db "END KRN", 0, 0, 0, 0