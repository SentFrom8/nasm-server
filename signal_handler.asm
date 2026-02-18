section .bss

section .rodata
sock_closed db 10, "[SERVER] Interrupt detected, socket closed", 10
sock_closed_len equ $ - sock_closed

section .text
%include "macros.inc"

global restorer
extern listener_fd

restorer:   mov rax, 15
            syscall