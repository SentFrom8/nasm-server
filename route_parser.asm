section .bss
%include "structs.inc"

parsed_path: resb 1024

final_path: resb 1024
final_path_len resq 1

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
global parse_route, final_path, final_path_len
extern parsed_headers, conn_close

; converts the requested resource into a valid route
; parsing is done in 2 passes, first step is percent decoding, second step removes double slashes and checks for double periods

%include "macros.inc"

parse_route:            xor rcx, rcx
                        xor r10, r10
                        xor rsi, rsi
                        mov rbx, qword [parsed_headers + Headers.path + Iovec.iov_len]
                        mov r15, qword [parsed_headers + Headers.path + Iovec.iov_base]

first_pass_loop:        cmp rcx, rbx
                        jge second_pass

                        mov dl, byte [r15 + rcx]
                        cmp dl, 0x25
                        jne move_to_parsed_buff

decode_percent:         add rcx, 2
                        cmp rcx, rbx
                        jge invalid_route

                        xor rdx, rdx
                        mov al, byte [r15 + rcx - 1]

hex_decode_first:       hex_char_to_num get_first_digit, invalid_route

get_first_digit:        shl al, 4
                        add dl, al

                        mov al, byte [r15 + rcx]
hex_decode_second:      hex_char_to_num add_last_digit, invalid_route

add_last_digit:         add dl, al

move_to_parsed_buff:    mov byte [parsed_path + r10], dl
                        inc rcx
                        inc r10
                        jmp first_pass_loop

second_pass:            xor rbx, rbx
                        xor rax, rax
                        xor rdx, rdx

second_pass_loop:       cmp rbx, r10
                        jge parse_finished
                        mov ah, al
                        mov al, byte [parsed_path + rbx]
                        lea rdi, [valid_route_chars]
                        mov rcx, valid_chars_len
                        repne scasb

                        jne invalid_route

period_check:           cmp al, 46
                        je handle_period

slash_check:            cmp al, 47
                        je handle_slash

                        jmp move_to_final_buff

handle_period:          cmp al, ah
;                        je finalize_path
                        je invalid_route

                        mov qword [file_extension_offset], rdx

                        jmp move_to_final_buff


handle_slash:           cmp al, ah
                        jne move_to_final_buff

                        inc rbx
                        jmp second_pass_loop

move_to_final_buff:     mov byte [final_path + rdx], al
                        inc rbx
                        inc rdx
                        jmp second_pass_loop

                        ; mov dh, 1
                        ; sub rax, 2
                        ; mov qword [file_extension_offset], rax
                        ; add rax, 2
                        ; jmp write_to_buff

parse_finished:         mov qword [final_path_len], rdx
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
                        
