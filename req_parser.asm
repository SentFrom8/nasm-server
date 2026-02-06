%include "defines.inc"

section .bss
%include "structs.inc"
parsed_headers: resb Headers_size

section .data

section .text
global parsed_headers, parse_req
extern invalid_request

parse_req:              mov rax, qword [r13 + Client.read_buff]
                        xor rdi, rdi
                        xor rcx, rcx

parse_req_loop:         mov r15b, byte [rax + rcx]
                        
                        cmp r15b, 13                                                            ; checks for a LF char
                        je handle_new_line

                        cmp r15b, 10
                        je handle_new_line                                                      ; checks for CR

                        cmp r15b, 32                                                            ; check for space
                        je handle_space

                        inc rcx
                        jmp parse_req_loop

handle_space:           mov qword [parsed_headers + rdi + Iovec.iov_base], rax
                        mov qword [parsed_headers + rdi + Iovec.iov_len], rcx
                        add rax, rcx
                        add rdi, Iovec_size

                        inc rax
                        xor rcx, rcx
                        jmp parse_req_loop

handle_new_line:        mov qword [parsed_headers + rdi + Iovec.iov_base], rax
                        mov qword [parsed_headers + rdi + Iovec.iov_len], rcx
                        add rax, rcx
                        add rdi, Iovec_size

                        cmp rdi, Headers_size
                        jne invalid_request

final_checks:           mov rax, qword [parsed_headers + Headers.method + Iovec.iov_len]
                        cmp rax, MAX_METHOD_LEN
                        jg invalid_request
                        
                        cmp rax, 0
                        je invalid_request

                        mov rax, qword [parsed_headers + Headers.path + Iovec.iov_len]
                        cmp rax, MAX_PATH_LEN
                        jg invalid_request

                        cmp rax, 0
                        je invalid_request

                        mov rax, qword [parsed_headers + Headers.http_v + Iovec.iov_len]
                        cmp rax, MAX_HTTPV_LEN
                        jg invalid_request

                        cmp rax, 0
                        je invalid_request

                        mov qword [r13 + Client.flags], 1

                        ret