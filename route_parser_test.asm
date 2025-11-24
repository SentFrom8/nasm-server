section .bss

section .data
path_buff db "loremipsum%33%35%47%46%46"
path_len equ $ - path_buff

section .text
global _start, path_buff, path_len
extern first_pass, parsed_path, parsed_path_len

_start:             call first_pass

print_result:       mov rax, 1
                    mov rdi, 1
                    lea rsi, [parsed_path]
                    mov rdx, parsed_path_len
                    syscall

exit:               mov rax, 60
                    mov rdi, 0
                    syscall