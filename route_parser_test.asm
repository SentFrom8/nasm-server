section .bss

section .data
path_buff db "loremipsum%21%23%2F%2E%2E"
path_len equ $ - path_buff

section .text
global _start, path_buff, path_len
extern parse_route, parsed_path, parsed_path_len

_start:             call parse_route

print_result:       mov rax, 1
                    mov rdi, 1
                    lea rsi, [parsed_path]
                    mov rdx, parsed_path_len
                    syscall

exit:               mov rax, 60
                    mov rdi, 0
                    syscall