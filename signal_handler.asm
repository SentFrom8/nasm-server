section .rodata
ran db "Signal ran"
ran_len equ $ - ran

section .text
%include "macros.inc"

global handler, restorer

handler:    print_literal ran, ran_len

            mov rax, 60
            mov rdi, 123
            syscall

restorer:   mov rax, 15
            syscall
