section .bss
usr_sockaddr: resb 16
upeer_addrlen: resd 1

section .data

error_listener db "[SERVER] CRITICAL ERROR! Listener returned EPOLLERR or EPOLLHUP"
error_listener_length equ $ - error_listener

error_accept db "[ERROR] Accept failed", 10
error_accept_len equ $ - error_accept

section .text
extern event_loop, print, listener_fd

listener_event:     test r14d, 0x001                          
                    jz listener_epollhup                    ; if not a connecting socket, or a timer, handle the request

; when there is an accept event, accepts all incoming connections
accept_loop:        mov rax, 288
                    mov rdi, qword [listener_fd]
                    lea rsi, [usr_sockaddr]
                    mov dword [upeer_addrlen], 16
                    lea rdx, [upeer_addrlen]
                    mov r10, 3                              ; sets the sock_nonblock and sock_cloexec flags
                    syscall                                 ; sys_accept4 -> same as accept but allows flags to be set
                    cmp rax, 0
                    jl accept_error

epoll_wlist:        mov r15, rax
                    mul 48
                    lea rax, [client_data_struct + rax]
                    mov qword [rax], r15
                    mov [rax + 48], 0
                    mov r15, rax
                    mov rdx, rax
                    mov rax, 233
                    mov rdi, qword [epoll_fd]
                    mov rsi, 1
                    mov r13d, 0x001
                    or r13d, 0x008
                    or r13d, 0x010
                    or r13d, 0x2000                         ; epollrdhup if the client half-closes
                    mov dword [epoll_event], r13d
                    mov qword [epoll_event + 4], r15
                    lea r10, [epoll_event]
                    syscall
                    cmp rax, 0                              ; !IMPORTANT: close_connection should be a function that's called here that closes the connection and updates the heap, the current safety_cls doesn't work because it uses client_fd which no longer exists
                    jl safety_cls

timer_set:          mov rdi, rdx
                    mov rax, 286
                    mov rsi, 0
                    lea rdx, [itimerspec]
                    mov r10, 0
                    syscall                                 ; sys_timerfd_settime -> 
                    jmp event_loop

accept_error:       cmp rax, -11                            ; EAGAIN/EWOULDBLOCK errno. List of error numbers can be found in /usr/include/asm-generic/errno(-base).h
                    jne acc_err_print

                    inc rbx
                    jmp event_loop

accept_err_print:   lea rsi, [error_accept]
                    mov rdx, error_accept_len
                    call print
                    jmp accept_loop


listener_epollhup:  lea rsi, [error_listener]
                    mov rdx, error_listener_length
                    call print
                    inc rbx
                    jmp event_loop
                    
