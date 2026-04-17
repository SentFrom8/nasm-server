section .bss
%include "structs.inc"
%include "defines.inc"

path_len: resq 1

global file_extension
file_extension_offset: resq 1

section .data

error_receive db "[ERROR] Receive failed", 10
error_receive_len equ $ - error_receive

error_req_len db "[ERROR] Request too long", 10
error_req_len_len equ $ - error_req_len

error_invalid_req db "[ERROR] Invalid request", 10
error_invalid_req_len equ $ - error_invalid_req

req_end db 13, 10, 13, 10

get_req_identifier db "GET /"
get_req_identifier_len equ $ - get_req_identifier

index db "/index.html", 0
index_len equ $ - index
index_extension_offset equ 6

section .text
%include "macros.inc"

global handle_req, invalid_request
extern client_cls, handle_res, client_req_buffer, conn_close, reset_timer, \
       event_loop, parse_req, parse_route


handle_req:             mov rax, 0
                        mov rdi, qword [r13]
                        mov r15, qword [r13 + Client.req_len]
                        mov rsi, [r13 + Client.read_buff]
                        add rsi, r15
                        mov rdx, MAX_REQUEST_LEN
                        sub rdx, r15
                        cmp rdx, 0
                        je req_len_error
                        syscall                                                     ; sys_read

                        cmp rax, 0
                        jg update_client
                        jl read_error
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

read_error:             cmp rax, -11
                        jne receive_error
                        jmp event_loop

update_client:          add r15, rax
                        mov qword [r13 + Client.req_len], r15
                        call reset_timer

req_finished_check:     mov rax, qword [r13 + Client.read_buff]
                        mov eax, dword [rax + r15 - 4]
                        cmp eax, dword [req_end]
                        jne event_loop

                        print_addr qword [r13 + Client.read_buff], qword [r13 + Client.req_len]

                        call parse_req
                        cmp rax, 0
                        jl invalid_request
                        call parse_route

                        jmp handle_res


receive_error:          print_literal error_receive, error_receive_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

req_len_error:          print_literal error_req_len, error_req_len_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

invalid_request:        print_literal error_invalid_req, error_invalid_req_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop
