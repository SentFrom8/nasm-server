section .bss

section .rodata
sock_closed db 10, "[SERVER] Interrupt detected, socket closed", 10
sock_closed_len equ $ - sock_closed

section .text
%include "macros.inc"

global sigint, restorer
extern listener_fd

restorer:   mov rax, 15
            syscall

sigint:     mov rax, 3
            mov rdi, qword [listener_fd]

            cmp rdi, 0
            je exit
            syscall
            print_literal sock_closed, sock_closed_len

exit:       mov rax, 60
            mov rdi, 0
            syscall