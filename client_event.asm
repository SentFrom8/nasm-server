%include "epoll_defines.inc"
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

client_event:                   test r14d, EPOLLERR                                         ; Check for errors
                                jz client_hup
                                print_literal error_client_epoll, error_client_epoll_len
                                jmp client_error

client_hup:                     test r14d, EPOLLHUP                                         ; Check for hangup
                                jnz print_hup
                                test r14d, EPOLLRDHUP                                       ; Check for half-close
                                jnz print_hup

client_read_write:              test r14d, EPOLLIN
                                jnz handle_req

                                test r14d, EPOLLOUT
                                jmp event_loop
                                ;jnz handle_res

print_hup:                      print_literal client_epollhup, client_epollhup_len

client_error:                   mov rdi, r13
                                call conn_close
                                jmp event_loop