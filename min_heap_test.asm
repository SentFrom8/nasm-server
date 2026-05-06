section .bss

%include "structs.inc"
client_data_struct: resb Client_size * 4098

section .data
heap_values: dq 1, 3, 4, 8, 9, 10, 11, 12, 13, 14
heap_values_size equ $ - heap_values
%assign values_len heap_values_size/8

section .text
global _start
extern mh_force_push, mh_bubble, mh_remove

_start:             xor rcx, rcx
                    xor rax, rax
                    mov r12, Client_size

heap_push_loop:     mov rax, rcx
                    mul r12
                    mov rbx, qword [heap_values + rcx*8]
                    mov qword [client_data_struct + rax + Client.time], rbx
                    lea rdi, [client_data_struct + rax]
                    call mh_force_push
                    inc rcx
                    cmp rcx, values_len
                    jl heap_push_loop

remove_first:       mov rdi, 0
                    call mh_remove

remove_last:        mov rdi, values_len - 1
                    call mh_remove

remove_middle:      mov rdi, 2
                    call mh_remove

remove_invalid:     mov rdi, 100
                    call mh_remove

remove_invalid2:    mov rdi, -1
                    call mh_remove

bubble_down_test:   lea rax, [client_data_struct + Client_size]
                    mov qword [rax + Client.time], 21
                    mov edi, dword [rax + Client.heap_index]
                    call mh_bubble

bubble_up_test:     lea rax, [client_data_struct + %eval(Client_size*9)]
                    mov qword [rax + Client.time], 1
                    mov edi, dword [rax + Client.heap_index]
                    call mh_bubble

exit:               mov rax, 60
                    mov rdi, 0
                    syscall
