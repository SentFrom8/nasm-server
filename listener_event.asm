section .bss
%include "structs.inc"

usr_sockaddr: resb 16
upeer_addrlen: resd 1

section .data

error_listener db "[SERVER] CRITICAL ERROR! Listener returned EPOLLERR or EPOLLHUP", 10
error_listener_length equ $ - error_listener

error_accept db "[ERROR] Accept failed", 10
error_accept_len equ $ - error_accept

error_using_client db "[ERROR] Failed to add a client to the epoll or heap", 10
error_using_client_len equ $ - error_using_client

section .text
global listener_event
extern clients, epoll_fd, event_loop, print, listener_fd, epoll_event, mh_push, update_timer, client_req_buffer, connection_timer_seconds

%include "macros.inc"

listener_event:     test r14d, 0x001                          
                    jz listener_epollhup                    ; if not a connecting socket, or a timer, handle the request

; when there is an accept event, accepts all incoming connections
accept_loop:        mov rax, 288
                    mov rdi, qword [listener_fd]
                    lea rsi, [usr_sockaddr]
                    mov dword [upeer_addrlen], 16
                    lea rdx, [upeer_addrlen]
                    mov r10, 0x800                          ; SOCK_NONBLOCK
                    or r10, 0x80000                         ; SOCK_CLOEXEC closes the socket when any exec family functions are called. Not strictly necessary
                    syscall                                 ; sys_accept4 -> same as accept but allows flags to be set
                    cmp rax, 0
                    jl accept_error

epoll_wlist:        mov r15, rax
                    mov rcx, Client_size
                    mul rcx
                    lea rbx, [clients + rax]
                    mov rdi, rbx
                    xor rax, rax
                    rep stosb                               ; zeroes out the client struct

                    mov qword [rbx], r15
                    mov rdx, r15
                    mov rdi, qword [epoll_fd]
                    mov rax, 233
                    mov rsi, 1
                    mov r13d, 0x1
                    or r13d, 0x4                            ; EPOLLOUT for the server response
                    or r13d, 0x8
                    or r13d, 0x10
                    or r13d, 0x2000                         ; EPOLLRDHUP if the client half-closes
                    mov dword [epoll_event + Epoll_event.flags], r13d
                    mov qword [epoll_event + Epoll_event.info], rbx
                    lea r10, [epoll_event]
                    syscall
                    cmp rax, 0
                    jge get_clock_time
                    mov rdi, qword [rbx]
                    mov rax, 3
                    syscall                                 ; sys_exit -> If the connection can't be added to the epoll, close it
                    lea rsi, [error_using_client]
                    mov rdx, error_using_client_len
                    print
                    jmp accept_loop

get_clock_time:     get_time rbx + Client.time
                    add qword [rbx + Client.time + Timespec.seconds], connection_timer_seconds

                    mov rdi, rbx
                    call mh_push
                    cmp rax, 0
                    je timer_start
                    jg event_loop
                    mov rdi, qword [rbx]
                    mov rax, 3
                    syscall
                    lea rsi, [error_using_client]
                    mov rdx, error_using_client_len
                    print
                    jmp accept_loop

timer_start:        call update_timer

req_pointer:        mov rax, qword [rbx]
                    shl rax, 13                             ; multiplies the fd by 4096 to get the pointer to the request buffer
                    lea rax, [client_req_buffer + rax]
                    mov qword [rbx + Client.read_buff], rax
                    jmp accept_loop

accept_error:       cmp rax, -11                            ; EAGAIN/EWOULDBLOCK errno. List of error numbers can be found in /usr/include/asm-generic/errno(-base).h
                    jne acc_err_print

                    jmp event_loop

acc_err_print:      lea rsi, [error_accept]
                    mov rdx, error_accept_len
                    print
                    jmp accept_loop


listener_epollhup:  lea rsi, [error_listener]
                    mov rdx, error_listener_length
                    print
                    jmp event_loop

