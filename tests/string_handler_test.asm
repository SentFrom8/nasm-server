%include "macros.inc"

section .bss
%include "structs.inc"

final_buff resb 1024
final_buff_len equ $ - final_buff

section .data

final_buff_iovec:
    istruc Iovec
        at .iov_base, dq final_buff
        at .iov_len, dq 0
    iend


section .rodata

s1 db "test test"
s1_len equ $ - s1

space db " "
space_len equ $ - space

s2 db "drugi test"
s2_len equ $ - s2

newline_double db 13, 10, 13, 10
newline_double_len equ $ - newline_double

s3 db "hello"
s3_len equ $ - s3

s1_iovec:
    istruc Iovec
        at .iov_base, dq s1
        at .iov_len, dq s1_len
    iend

s2_iovec:
    istruc Iovec
        at .iov_base, dq s2
        at .iov_len, dq s2_len
    iend

s3_iovec:
    istruc Iovec
        at .iov_base, dq s3
        at .iov_len, dq s3_len
    iend

space_iovec:
    istruc Iovec
        at .iov_base, dq space
        at .iov_len, dq space_len
    iend

newline_double_iovec:
    istruc Iovec
        at .iov_base, dq newline_double
        at .iov_len, dq newline_double_len
    iend


section .text
global _start
extern merge_iov

_start:         lea rdi, [final_buff_iovec]
                lea rsi, [s1_iovec]
                call merge_iov

                lea rdi, [final_buff_iovec]
                lea rsi, [space_iovec]
                call merge_iov

                lea rdi, [final_buff_iovec]
                lea rsi, [s2_iovec]
                call merge_iov

                lea rdi, [final_buff_iovec]
                lea rsi, [newline_double_iovec]
                call merge_iov

                lea rdi, [final_buff_iovec]
                lea rsi, [s3_iovec]
                call merge_iov

                print_iovec final_buff_iovec

                mov rax, 60
                mov rdi, 0
                syscall