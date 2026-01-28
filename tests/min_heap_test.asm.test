section .bss
client_data_struct: resb 48 * 4098

section .data
heap_values: dq 1, 3, 4, 8, 7, 9, 10, 11, 12, 13, 14

section .text
global _start
extern mh_push, mh_bubble, mh_remove

_start:             xor rcx, rcx
                    xor rax, rax
                    mov r12, 48

heap_push_loop:     mov rax, rcx
                    mul r12
                    mov rbx, qword [heap_values + rcx*8]
                    mov qword [client_data_struct + rax + 40], rbx
                    lea rdi, [client_data_struct + rax]
                    call mh_push
                    inc rcx
                    cmp rcx, 10
                    jle heap_push_loop

push_small:         mov rax, rcx
                    mul r12
                    mov qword [client_data_struct + rax + 40], 2
                    lea rdi, [client_data_struct + rax]
                    call mh_push

remove_first:       mov rdi, 0
                    call mh_remove

remove_last:        mov rdi, 9
                    call mh_remove

remove_middle:      mov rdi, 5
                    call mh_remove

remove_invalid:     mov rdi, 100
                    call mh_remove

remove_invalid2:    mov rdi, -1
                    call mh_remove

bubble_down_test:   lea rax, [client_data_struct + 96]
                    mov qword [rax + 40], 21
                    mov rdi, 2
                    call mh_bubble

bubble_up_test:     lea rax, [client_data_struct + 432]
                    mov qword [rax + 40], 1
                    mov rdi, 4
                    call mh_bubble

exit:               mov rax, 60
                    mov rdi, 0
                    syscall