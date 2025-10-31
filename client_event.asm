section .bss

section .data

error_client_epoll db "[CLIENT] EPOLLERR", 10
error_client_epoll_len equ $ - error_client_epoll

client_epollhup db "[CLIENT] EPOLLHUP", 10
client_epollhup_len equ $ - client_epollhup

section .text
%include "macros.inc"
global client_event
extern listener_fd, event_loop, conn_close, handle_req

client_event:                   test r14d, 0x8                                              ; Check for errors
                                jz client_hup
                                lea rsi, [error_client_epoll]
                                mov rdx, error_client_epoll_len
                                jmp print_and_close

client_hup:                     test r14d, 0x10                                             ; Check for hangup
                                jnz print_hup
                                test r14d, 0x2000                                           ; Check for half-close
                                jnz print_hup

client_read_write:              test r14d, 0x1
                                jnz handle_req

                                test r14d, 0x4
                                ;jnz handle_res

print_hup:                      lea rsi, [client_epollhup]
                                mov rdx, client_epollhup_len

print_and_close:                print
                                mov rdi, r13
                                call conn_close
                                jmp event_loop