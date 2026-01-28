section .bss

section .data
route db "./", 0

section .text
global _start
extern handle_file, invalid_request

_start:             lea rdi, [route]
                    call handle_file

invalid_request:
end:                mov rax, 60
                    mov rdi, 0
                    syscall