section .bss
%include "structs.inc"

section .data

section .text
global conn_close
extern heap, mh_remove, update_timer

; closes the connection at *RDI
conn_close:                 mov r9, rdi
                            mov edi, dword [rdi + Client.heap_index]
                            mov rdx, rdi
                            call mh_remove

                            cmp rdx, 0
                            jne sys_close
                            call update_timer

sys_close:                  mov rax, 3
                            mov rdi, qword [r9]                                    ; sys_close -> closes the client socket, this frees up the FD
                            syscall
                            ret
                            