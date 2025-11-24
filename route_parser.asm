section .bss
parsed_path: resb 1024
parsed_path_len: resq 1

section .data

section .text
extern path_buff, path_len
global first_pass, parsed_path, parsed_path_len

; converts the requested resource into a valid route
; parsing is done in 2 passes, first step is percent decoding, second step removes double slashes and checks for double periods

first_pass:             xor rcx, rcx
                        xor rdi, rdi
                        xor rsi, rsi
                        mov rbx, path_len

first_pass_loop:        cmp rcx, rbx
                        jge second_pass

                        mov dl, byte [path_buff + rcx]
                        cmp dl, 0x25
                        jne move_to_buff

                        add rcx, 2
                        cmp rcx, rbx
                        jge invalid

                        xor rdx, rdx
                        mov al, byte [path_buff + rcx - 1]
                        cmp al, 0x30
                        jl invalid
                        cmp al, 0x39
                        jg invalid
                        sub al, 0x30
                        mov rsi, 10
                        mul rsi
                        add dl, al

                        mov al, byte [path_buff + rcx]
                        cmp al, 0x30
                        jl invalid
                        cmp al, 0x39
                        jg invalid
                        sub al, 0x30
                        add dl, al

move_to_buff:           mov byte [parsed_path + rcx], dl
                        inc rcx
                        inc rdi
                        jmp first_pass_loop


second_pass:            mov qword [parsed_path_len], rdi
                        ret

invalid:                mov rax, -1
                        ret