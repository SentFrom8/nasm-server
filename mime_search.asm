%use ifunc

section .bss
%include "structs.inc"

section .rodata
%include "mime_table.inc"

mime_table_len equ ($ - mime_table)/Extension_link_size

section .text
global search_mime
extern final_path, final_path_len, file_extension_offset

; l = rax, r = rdx, r10 = m, r8 = target_extension_size, rcx = current_extension_size
; mime_table is sorted, implemented using binary search
search_mime:            
                        mov r8, qword [final_path_len]
                        sub r8, qword [file_extension_offset]
                        mov rax, 0
                        mov rdx, mime_table_len

search_loop:            cmp rax, rdx
                        jge invalid

                        mov r10, rax
                        add r10, rdx
                        shr r10, 1

                        mov r9, r10
                        shl r9, %eval(ilog2(Extension_link_size))
                        
                        mov rcx, qword [mime_table + r9 + Extension_link.extension + Iovec.iov_len]
                        cmp r8, rcx
                        cmovl rcx, r8

cmp_str:                mov rdi, qword [mime_table + r9 + Extension_link.extension + Iovec.iov_base]
                        lea rsi, [final_path]
                        add rsi, qword [file_extension_offset]
                        repe cmpsb
                        jl before
                        jg after

                        mov rcx, qword [mime_table + r9 + Extension_link.extension + Iovec.iov_len]
                        cmp r8, rcx
                        jl before
                        jg after

                        lea rax, [mime_table + r9]
                        ret


; branches here if the target string is after the current one
after:                  mov rax, r10
                        inc rax
                        jmp search_loop

before:                 mov rdx, r10
                        jmp search_loop


invalid:                mov rax, -1
                        ret
