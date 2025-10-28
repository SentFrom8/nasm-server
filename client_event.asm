section .bss

section .data

error_client_epoll db "[CLIENT] EPOLLERR", 10
error_client_epoll_len equ $ - error_client_epoll

client_epollhup db "[CLIENT] EPOLLHUP", 10
client_epollhup_len equ $ - client_epollhup

section .text
%include "macros.inc"
global client_event
extern listener_fd, event_loop

client_event:                   inc rbx
                                jmp event_loop
                                test r14d, 0x008                                            ; Check for errors
                                jz client_hup
                                lea rsi, [error_client_epoll]
                                mov rdx, error_client_epoll_len
                                print
                                jmp client_cls

client_hup:                     test r14d, 0x010                                            ; Check for hangup
                                jnz print_hup
                                test r14d, 0x2000                                           ; Check for half-close
                                jnz print_hup

print_hup:                      lea rsi, [client_epollhup]
                                mov rdx, client_epollhup_len
                                print

client_cls:                     inc rbx
                                cmp r13, qword [listener_fd]
                                je event_loop
                                mov rdi, qword [r13]
                                mov rax, 3
                                syscall                                                     ; If not, close the socket

                                mov rdi, qword [r13 + 8]
                                mov rax, 3
                                syscall                                                     ; Also close the timer

                                jmp event_loop

child_sock_cls:                 mov rdi, r13
                                mov rax, 3
                                syscall
                                inc rbx
                                jmp event_loop
