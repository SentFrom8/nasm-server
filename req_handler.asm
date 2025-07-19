section .data
error_receive db "[ERROR] Receive failed", 10
error_receive_len equ $ - error_receive

section .text
global handle_req
extern req, req_len, reply, print 

handle_req:     test r14, 0x001
                jz reply
                mov rax, 0
                mov rdi, r13
                lea rsi, [req]
                mov rdx, 1000
                syscall
                mov qword [req_len], rax
                mov rdx, rax
                cmp rdx, 0
                jge parse_req
                lea rsi, [error_receive]
                mov rdx, error_receive_len
                call print
                jmp reply

parse_req:      lea rsi, [req]
                call print