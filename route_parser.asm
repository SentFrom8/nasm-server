section .bss
%include "structs.inc"

parsed_path: resb 1024
parsed_path_len: resq 1

invalid_route_iovec resb Iovec_size*2

section .data

valid_route_chars
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

db '-','.','_','~','!','$','&',39,'(',')','*','+',',',59,'=',':','@','%'                   ; creates a string of all valid characters in the path, including the semicolon(59) and the single quote(39)

valid_chars_len equ $ - valid_route_chars

error_invalid_route db "[ERROR] Invalid or malicious route: "
error_invalid_route_len equ $ - error_invalid_route

section .text
extern path_buff, path_len, exit
global parse_route, parsed_path, parsed_path_len

; converts the requested resource into a valid route
; parsing is done in 2 passes, first step is percent decoding, second step removes double slashes and checks for double periods

%include "macros.inc"

parse_route:            xor rcx, rcx
                        xor rdi, rdi
                        xor rsi, rsi
                        mov rbx, path_len

first_pass_loop:        cmp rcx, rbx
                        jge second_pass

                        mov dl, byte [path_buff + rcx]
                        cmp dl, 0x25
                        jne move_to_buff

decode_percent:         add rcx, 2
                        cmp rcx, rbx
                        jge invalid_request

                        xor rdx, rdx
                        mov al, byte [path_buff + rcx - 1]

check_1_to_9_first:     check_1_to_9 get_first_digit, invalid_request

get_first_digit:        shl al, 4
                        add dl, al

                        mov al, byte [path_buff + rcx]
check_1_to_9_second:    check_1_to_9 add_last_digit, invalid_request

add_last_digit:         add dl, al

move_to_buff:           mov byte [parsed_path + rcx], dl
                        inc rcx
                        inc rdi
                        jmp first_pass_loop

second_pass:            mov qword [parsed_path_len], rdi
                        mov rbx, qword [parsed_path_len]

second_pass_loop:       cmp rbx, 0
                        ; je finalize_path
                        je exit
                        mov al, byte [parsed_path + rbx]
                        lea rdi, [valid_route_chars]
                        mov rcx, valid_chars_len
                        repne scasb

                        jne invalid_request

period_check:           cmp al, 46
                        je handle_period

                        dec rbx
                        jmp second_pass_loop

handle_period:          dec rbx
                        cmp rbx, 0
                        ; je finalize_path
                        je exit

                        mov al, byte [parsed_path + rbx]
                        lea rdi, [valid_route_chars]
                        mov rcx, valid_chars_len
                        repne scasb

                        jne invalid_request

                        cmp al, 46
                        je invalid_request

                        dec rbx
                        jmp second_pass_loop

                        ; mov dh, 1
                        ; sub rax, 2
                        ; mov qword [file_extension_offset], rax
                        ; add rax, 2
                        ; jmp write_to_buff

invalid_request:        lea rax, [error_invalid_route]
                        mov qword [invalid_route_iovec + Iovec.iov_base], rax
                        mov rax, error_invalid_route_len
                        mov qword [invalid_route_iovec + Iovec.iov_len], rax
                        lea rax, [parsed_path]
                        mov qword [invalid_route_iovec + Iovec_size + Iovec.iov_base], rax
                        mov rax, parsed_path_len
                        mov qword [invalid_route_iovec + Iovec_size + Iovec.iov_len], rax
                        mov rax, 20
                        mov rdi, 1
                        lea rsi, [invalid_route_iovec]
                        mov rdx, 16
                        syscall
                        mov rdi, r13
                        ; call conn_close
                        jmp exit
                        
