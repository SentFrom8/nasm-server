%include "defines.inc"

section .bss
%include "structs.inc"

section .data

section .text
global conn_close
extern heap, mh_remove, update_timer

; closes the connection at *RDI
conn_close:                 test dword [rdi + Client.flags], SOCKET_CLOSED
                            jz update_heap
                            ret

update_heap:                mov rbx, rdi
                            mov edi, dword [rdi + Client.heap_index]
                            call mh_remove

                            cmp dword [rbx + Client.heap_index], 0
                            jne sys_close
                            call update_timer

sys_close:                  mov rax, 3
                            mov rdi, qword [rbx + Client.fd]                                    ; sys_close -> closes the client socket, this frees up the FD
                            syscall
                            or dword [rbx + Client.flags], SOCKET_CLOSED
                            ret
                            