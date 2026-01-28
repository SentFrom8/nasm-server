section .bss
%include "structs.inc"
%include "defines.inc"

final_path: resb PATH_MAX + 1                                   ; File paths are null terminated so it has to account for the terminator
final_path_len: resq 1

file_extension_offset: resq 1

invalid_route_iovec resb Iovec_size*2

section .data

; creates a string of all valid characters in the path, including the semicolon(59) and the single quote(39)
valid_route_chars:
%assign i 0
%rep 10
db  48 + i
%assign i i+1
%endrep

%assign i 0
%rep 26
db 65 + i
%assign i i+1
%endrep

%assign i 0
%rep 26
db 97 + i
%assign i i+1
%endrep

db '-', '.', '_', '~', '!', '$', '&', 39, '(', ')', '*', '+', ',', 59, '=', ':', '@', '%', '?', '/', '#'            

valid_chars_len equ $ - valid_route_chars

error_invalid_route db "[WARN] Invalid or malicious route: "
error_invalid_route_len equ $ - error_invalid_route

section .text
global parse_route, final_path, final_path_len, file_extension_offset
extern parsed_headers, conn_close

; percent decodes, validates each character and stores the index of the last period

%include "macros.inc"

parse_route:            xor rsi, rsi
                        xor r10, r10
                        xor rsi, rsi
                        mov r8, qword [parsed_headers + Headers.path + Iovec.iov_base]
                        mov r9, qword [parsed_headers + Headers.path + Iovec.iov_len]

first_pass_loop:        cmp rsi, r9
                        jge parse_finished

                        mov al, byte [r8 + rsi]
                        cmp al, 0x25
                        jne validate_char

decode_percent:         add rsi, 2
                        cmp rsi, r9
                        jge invalid_route

                        xor rdx, rdx
                        mov dl, byte [r8 + rsi - 1]

hex_decode_first:       hex_char_to_num get_first_digit, invalid_route

get_first_digit:        shl dl, 4
                        add al, dl

                        mov dl, byte [r8 + rsi]
hex_decode_second:      hex_char_to_num add_last_digit, invalid_route

add_last_digit:         add al, dl

validate_char:          lea rdi, [valid_route_chars]
                        mov rcx, valid_chars_len
                        repne scasb
                        jne invalid_route

                        cmp al, 46
                        jne move_to_final_buff

                        mov qword [file_extension_offset], r10

move_to_final_buff:     mov byte [final_path + r10], al
                        inc rsi
                        inc r10
                        jmp first_pass_loop

; second_pass:            xor rbx, rbx
;                         xor rax, rax
;                         xor rdx, rdx

; second_pass_loop:       cmp rbx, r10
;                         jge parse_finished
;                         mov ah, al
;                         mov al, byte [parsed_path + rbx]
;                         lea rdi, [valid_route_chars]
;                         mov rcx, valid_chars_len
;                         repne scasb

;                         jne invalid_route

; period_check:           cmp al, 46
;                         je handle_period

; slash_check:            cmp al, 47
;                         je handle_slash

;                         jmp move_to_final_buff

; handle_period:          cmp al, ah
; ;                        je finalize_path
;                         je invalid_route

;                         mov qword [file_extension_offset], rdx

;                         jmp move_to_final_buff


; handle_slash:           cmp al, ah
;                         jne move_to_final_buff

;                         inc rbx
;                         jmp second_pass_loop

; move_to_final_buff:     mov byte [final_path + rdx], al
;                         inc rbx
;                         inc rdx
;                         jmp second_pass_loop

;                         ; mov dh, 1
;                         ; sub rax, 2
;                         ; mov qword [file_extension_offset], rax
;                         ; add rax, 2
;                         ; jmp write_to_buff

parse_finished:         mov byte [final_path_len + r10], 0
                        mov qword [final_path_len], r10
                        ret

invalid_route:          lea rax, [error_invalid_route]
                        mov qword [invalid_route_iovec + Iovec.iov_base], rax
                        mov rax, error_invalid_route_len
                        mov qword [invalid_route_iovec + Iovec.iov_len], rax
                        mov rax, qword [parsed_headers + Headers.path + Iovec.iov_base]
                        mov qword [invalid_route_iovec + Iovec_size + Iovec.iov_base], rax
                        mov rax, qword [parsed_headers + Headers.path + Iovec.iov_len]
                        mov qword [invalid_route_iovec + Iovec_size + Iovec.iov_len], rax
                        mov rax, 20
                        mov rdi, 1
                        lea rsi, [invalid_route_iovec]
                        mov rdx, 16
                        syscall
                        mov rdi, r13
                        call conn_close
                        ret
                        
