section .bss

section .data
path_buff db "loremipsum%21%23%2f%2E/////////tt//2/%2Fh%2F%2F.%2e"
; path_buff db "/../../etc/passwd"
; path_buff: times 20000 db "a" 
path_len dq $ - path_buff

section .text
global _start, path_buff, path_len, exit
extern parse_route, final_path, final_path_len

_start:             jmp parse_route

print_result:       mov rax, 1
                    mov rdi, 1
                    lea rsi, [final_path]
                    mov rdx, final_path_len
                    syscall

exit:               mov rax, 60
                    mov rdi, 0
                    syscall