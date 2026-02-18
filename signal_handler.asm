section .text
%include "macros.inc"

global restorer

restorer:   mov rax, 15
            syscall