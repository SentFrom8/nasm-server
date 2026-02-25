%include "defines.inc"

section .bss
%include "structs.inc"

section .data

section .text
global i_to_s, merge_iov

; writes the number at rdi to the iovec [rsi]
; treats every integer as unsigned
; since it writes the string from the back of the buffer, iov_base will change to the beginning of the string

i_to_s:         mov rax, rdi
                mov rdi, 10
                mov r10, qword [rsi + Iovec.iov_base]
                xor rdx, rdx
                mov r8, MAX_NUM_LEN

; there is no need to check the length, the largest unsigned 64 bit integer is 20 digits long
i_to_s_loop:    div rdi
                add rdx, 0x30
                mov byte [r10 + r8 - 1], dl
                dec r8
                xor rdx, rdx
                cmp rax, 0
                jne i_to_s_loop


write_to_iov:   add r10, r8
                mov qword [rsi + Iovec.iov_base], r10

                mov rax, MAX_NUM_LEN
                sub rax, r8
                mov qword [rsi + Iovec.iov_len], rax
                ret


; Appends the contents of Iovec* at rsi to the Iovec* at rdi, updating iov_len. The Iovec at rsi remains unchanged
; Does not check buffer size, assumes valid input
merge_iov:      mov r10, rdi
                mov r8, rsi
                mov rdi, qword [r10 + Iovec.iov_base]
                add rdi, qword [r10 + Iovec.iov_len]
                mov rsi, qword [r8 + Iovec.iov_base]
                mov rcx, qword [r8 + Iovec.iov_len]
                add qword [r10 + Iovec.iov_len], rcx
                rep movsb
                ret

; converts the string at [rdi] whose length is at rsi to an integer and stores its value in rax
; s_to_i:         to be implemented