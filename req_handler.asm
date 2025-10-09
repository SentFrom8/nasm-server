section .bss
fextension: resb 30
path_len: resq 1

global file_extension, file_extension_len
file_extension: resq 1
file_extension_len: resq 1

section .data
error_receive db "[ERROR] Receive failed", 10
error_receive_len equ $ - error_receive

global path_buff
path_buff db "./", 30 dup(0)

get_req_identifier db "GET /"
get_req_identifier_len equ $ - get_req_identifier

index db "/index.html", 0
index_len equ $ - index
index_extension_offset equ 6

section .text
global handle_req
extern print, client_cls, handle_res, client_req_buffer

; Fds of valid get requests should be stored and a response should only be sent if the fd is in the list
; EPOLLOUT should be saved for a period of time in case an EPOLLIN arrives later

handle_req:     test qword [r13 + 40], 1
                jnz client_cls
                test r14d, 0x001
                jz handle_res
                mov rax, 0
                mov rdi, qword [r13]
                mov r15, rdi
                shl r15, 13
                lea rsi, [client_req_buffer + r15]
                mov qword [r13 + 16], rsi
                mov rdx, 32768
                syscall                                         ; sys_read -> reads the incoming message from the client and writes it into req
                cmp rax, 0
                jg validate_req
                lea rsi, [error_receive]
                mov rdx, error_receive_len
                call print
                jmp client_cls

validate_req:   cld
                shr r13

                lea rdi, [req]
                lea rsi, [get_req_identifier]
                mov rcx, get_req_identifier_len
                repe cmpsb
                jne client_cls
                mov rax, get_req_identifier_len
                xor rdx, rdx
                xor r8, r8

extract_path:   cmp rax, qword [req_len]
                jge client_cls
                mov r15b, byte [req + rax]
                lea r8, [path_buff + 2 + rax - get_req_identifier_len]
                cmp rax, 30
                jge client_cls
                cmp r15b, 13
                je client_cls
                cmp r15b, 10
                je client_cls
                cmp r15b, 0x2E                                  ; Checks if a period is present, indicating a file extension
                je handle_period
                xor dl, dl
                
                cmp r15b, 0x41
                jl check_space
                cmp r15b, 0x5A
                jg check_space
                or r15b, 0x20                                   ; Checks for upper case characters, converts them to lower case

check_space:    cmp r15b, 0x20
                je mk_rel_path

write_to_buff:  mov byte [r8], r15b
                inc rax
                jmp extract_path

handle_period:  cmp dl, 1                                       ; dl is set to 0 for every non-period character. If it is 1 it means there is 2 periods in a row
                je client_cls
                mov dh, 1
                mov dl, 1
                mov qword [file_extension], r8
                jmp write_to_buff

mk_rel_path:    sub rax, (get_req_identifier_len - 2)
                cmp dh, 1
                je finalize_path
                xor rcx, rcx

append_home:    cld
                lea rsi, [index]
                lea rdi, [path_buff + rax]
                mov rcx, index_len
                rep movsb
                lea r8, [path_buff + rax + index_extension_offset]
                mov qword [file_extension], r8
                add rax, index_len

finalize_path:  lea rcx, [path_buff + rax]
                mov byte [rcx], 0
                sub rcx, qword [file_extension]
                mov qword [file_extension_len], rcx

print_path:     mov qword [path_len], rax
                lea rsi, [path_buff]
                mov rdx, rax
                call print

                jmp handle_res                

