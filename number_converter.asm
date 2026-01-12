%include "defines.inc"

section .bss

section .data

section .text
global i_to_s

; writes the number at rdi to the buffer [rsi] with the length stored ar [rdx]
; Returns a pointer to the beginning of the string in rax
i_to_s:         mov rax, rdi
                mov rdi, 10
                mov r10, rdx
                xor rdx, rdx
                mov rbx, MAX_NUM_LEN

; there is no need to check the length, the largest unsigned 64 bit integer is 20 digits long
i_to_s_loop:    div rdi
                add rdx, 0x30
                mov byte [rsi + rbx - 1], dl
                dec rbx
                xor rdx, rdx
                cmp rax, 0
                jne i_to_s_loop

                mov rax, MAX_NUM_LEN
                sub rax, rbx
                mov qword [r10], rax
                lea rax, [rsi + rbx]
                ret

; converts the string at [rdi] whose length is at rsi to an integer and stores its value in rax
; s_to_i:         to be implemented