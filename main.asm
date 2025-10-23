section .bss
%include "structs.inc"

sockaddr: resb 16

epoll_event: resb Epoll_event_size
epoll_return: resb Epoll_event_size*248

client_data_struct: resb Client_size * 4096
client_req_buffer: resb 8192 * 4096

; flags: 1 - timer, 2 - listener, 4 - ready_to_write

section .data

connection_timer: istruc Itimerspec
at Itimerspec.interval dq 0, 0
at Itimerspec.value dq 15, 0
iend

server_listening db "[SERVER] Listening on 0.0.0.0:8080", 10
server_listening_len equ $ - server_listening

error_socket db "[ERROR] Unable to create a socket", 10
error_socket_len equ $ - error_socket

error_bind db "[ERROR] Unable to bind socket to 0.0.0.0:8080", 10
error_bind_len equ $ - error_bind

error_epoll_ctl db "[ERROR] Unable to add socket to the epoll watch list", 10
error_epoll_ctl_len equ $ - error_epoll_ctl

error_epoll_wait db "[ERROR] Epoll wait failed", 10
error_epoll_wait_len equ $ - error_epoll_wait

error_client_epoll db "[CLIENT] EPOLLERR", 10
error_client_epoll_len equ $ - error_client_epoll

client_epollhup db "[CLIENT] EPOLLHUP", 10
client_epollhup_len equ $ - client_epollhup

section .text
global _start, print, event_loop, client_cls, epoll_wait, listener_fd, client_data_struct, client_req_buffer, Client, Timespec
extern handle_req

print:              mov rax, 1
                    mov rdi, 1
                    syscall
                    ret

; The server uses an epoll to handle file descriptors
; epoll emits an event when an fd is ready for an operation

_start:             mov rax, 41
                    mov rdi, 2                                                  ; IPv4 family (AF_INET)
                    mov rsi, 1                                                  ; SOCK_STREAM type
                    or rsi, 0x800                                               ; SOCK_NONBLOCK flag
                    xor rdx, rdx                                                ; System picks the protocol (TCP for SOCK_STREAM type)
                    syscall                                                     ; sys_socket -> creates the socket
                    cmp rax, 0                                                  ; if error, print the error and jump to end
                    jge bind
                    lea rsi, [error_socket]
                    mov rdx, error_socket_len
                    call print
                    jmp end

bind:               mov r13, rax
                    mul 48
                    lea rax, [client_data_struct + rax]
                    mov qword [rax], r13
                    mov qword [rax + 48], 2
                    mov r14, rax

                    xor rbx, rbx                                                ; Zero out rbx because the address is 0.0.0.0
                    mov rbx, 0x901F                                             ; The bind syscall expects big endian, so the order of bytes in the number 8080 is reversed
                    shl rbx, 16                                                 ; Move the port by 16 bits, because the first 16 bits are reserved for the family
                    add rbx, 2                                                  ; Sets the family to AF_INET
                    mov qword [sockaddr], rbx       
                    mov qword [sockaddr + 8], 0                                 ; pads the second qword of the sock_addr struct with zeroes

                    mov rdi, qword [listener_fd]
                    mov rax, 49
                    lea rsi, [sockaddr]
                    mov rdx, 16
                    syscall                                                     ; sys_bind -> binds the socket to the address
                    cmp rax, 0
                    jge listen
                    lea rsi, [error_bind]
                    mov rdx, error_bind_len
                    call print
                    jmp main_socket

listen:             mov rax, 50
                    mov rdi, qword [listener_fd]
                    mov rsi, 128
                    syscall                                                     ; sys_listen -> marks the socket as passive, ready to accept connections
                    lea rsi, [server_listening]
                    mov rdx, server_listening_len
                    call print

epoll:              mov rax, 291
                    xor rdi, rdi
                    syscall                                                     ; sys_epoll_create1 -> creates an epoll
                    mov qword [epoll_fd], rax                                   ; Save epoll fd

epoll_ctl:          mov rdi, rax                                                ; epoll fd
                    mov rax, 233                            
                    mov rsi, 1                                                  ; operation: EPOLL_CTL_ADD
                    mov rdx, qword [listener_fd]                                ; socket fd
                    mov ebx, 0x001                                              ; EPOLLIN for incoming connections
                    or ebx, 0x008                                               ; EPOLLERR if the fd errors
                    or ebx, 0x010                                               ; EPOLLHUP if there is an issue with the fd or the network stack
                    mov dword [epoll_event], ebx                                ; Event flag numbers can be found in /usr/include/x86_64-linux-gnu/sys/epoll.h
                    mov qword [epoll_event + Epoll_event.info], r14             ; FD in data for later use
                    lea r10, [epoll_event]                 
                    syscall                                                     ; sys_epoll_ctl -> adds the listener socket to the watch list
                    cmp rax, 0
                    jge epoll_wait
                    lea rsi, [error_epoll_ctl]
                    mov rdx, error_epoll_ctl_len
                    call print
                    jmp epoll_cls

get_time:           mov rax, 228
                    mov rdi, 0

; timer_create:       mov rax, 283
;                     mov rdi, 1                              ; clock_monotonic
;                     mov rsi, 3                              ; sets the sock_nonblock and sock_cloexec flags
;                     syscall                                 ; sys_timerfd_create -> creates a timer that uses a min heap to keep track of connections that need closing

timer_epoll:        mov qword [timer_fd], rax
                    mov rdx, rax
                    mov rax, 233
                    mov rdi, qword [epoll_fd]
                    mov rsi, 1
                    mov dword [epoll_event], 0x1
                    mov qword [epoll_event + 4], rax
                    lea r10, epoll_event
                    syscall

epoll_wait:         mov rax, 232
                    mov rdi, qword [epoll_fd]
                    lea rsi, [epoll_return]                                     ; Buffer for events
                    mov rdx, 248                                                ; Max simultaneous connections, not total
                    mov r10, 60000                                              ; Timeout, set to -1 for permanent
                    syscall
                    mov r12, rax                                                ; sys_epoll_wait -> Blocks the thread until there is an EPOLLIN connection or the timeout expires
                    xor rbx, rbx
                    cmp r12, 0
                    jge event_loop
                    lea rsi, [error_epoll_wait]
                    mov rdx, error_epoll_wait_len
                    call print
                    jmp epoll_cls

event_loop:         cmp rbx, r12                                                ; Check if the counter passed the last connection
                    jge epoll_wait

client_error:       mov rax, 12
                    mul rbx
                    mov r13, qword [epoll_return + rax + 4]
                    mov r14d, dword [epoll_return + rax]

                    cmp r13, qword [listener_fd]
                    je listener_event

                    cmp r13, qword [timer_fd]
                    je timer_event

                    jmp client_event

                    test r14d, 0x008                                            ; Check for errors
                    jz client_hup
                    lea rsi, [error_client_epoll]
                    mov rdx, error_client_epoll_len
                    call print
                    jmp client_cls

client_hup:         test r14d, 0x010                                            ; Check for hangup
                    jnz print_hup
                    test r14d, 0x2000                                           ; Check for half-close
                    jnz print_hup
                    jz accept

print_hup:          lea rsi, [client_epollhup]
                    mov rdx, client_epollhup_len
                    call print

client_cls:         inc rbx
                    cmp r13, qword [listener_fd]
                    je event_loop
                    mov rdi, qword [r13]
                    mov rax, 3
                    syscall                                                     ; If not, close the socket

                    mov rdi, qword [r13 + 8]
                    mov rax, 3
                    syscall                                                     ; Also close the timer

                    jmp event_loop

accept:             cmp r13, qword [epoll_fd]
                    je accept_loop                                              ; if not a connecting socket, or a timer, handle the request

                    cmp r13, qword [timer_fd]
                    je timer_expired

                    jmp handle_req

                    mov rdi, qword [listener_fd]
                    lea rsi, [usr_sockaddr]
                    mov dword [upeer_addrlen], 16
                    lea rdx, [upeer_addrlen]
                    mov r10, 3                                                  ; sets the sock_nonblock and sock_cloexec flags

; when there is an accept event, accepts all incoming connections
accept_loop:        mov rax, 288
                    mov rdi, qword [listener_fd]
                    lea rsi, [usr_sockaddr]
                    mov dword [upeer_addrlen], 16
                    lea rdx, [upeer_addrlen]
                    mov r10, 3                                                  ; sets the sock_nonblock and sock_cloexec flags
                    syscall                                                     ; sys_accept4 -> same as accept but allows flags to be set
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
                    or r13d, 0x2000                                             ; epollrdhup if the client half-closes
                    mov dword [epoll_event], r13d
                    mov qword [epoll_event + 4], r15
                    lea r10, [epoll_event]
                    syscall
                    cmp rax, 0                                                  ; !IMPORTANT: close_connection should be a function that's called here that closes the connection and updates the heap, the current safety_cls doesn't work because it uses client_fd which no longer exists
                    jl safety_cls

timer_create:       mov rax, 283
                    mov rdi, 1                                                  ; clock_monotonic
                    mov rsi, 3                                                  ; sets the sock_nonblock and sock_cloexec flags
                    syscall                                                     ; sys_timerfd_create -> creates a timer with an fd for each client. this will be used to close inactive sockets

timer_epoll:        mov r15, rax
                    mul 48
                    lea rax, [client_data_struct + rax]
                    mov qword [rax], r15
                    mov qword [rax + 40], 1
                    mov rdx, r15
                    mov rax, 233
                    mov rdi, qword [epoll_fd]
                    mov rsi, 1
                    mov dword [epoll_event], 0x1
                    mov qword [epoll_event + 4], rax
                    lea r10, epoll_event
                    syscall

timer_set:          mov rdi, rdx
                    mov rax, 286
                    mov rsi, 0
                    lea rdx, connection_timer
                    mov r10, 0
                    syscall
                    jmp event_loop

accept_error:       cmp rax, -11                                                ; EAGAIN/EWOULDBLOCK errno. List of error numbers can be found in /usr/include/asm-generic/errno(-base).h

safety_cls:         mov rdi, qword [client_fd]                                  ; closes the socket if adding to the epoll watch list fails
                    mov rax, 3
                    syscall

                    lea rsi, [error_epoll_ctl]
                    mov rdx, error_epoll_ctl_len
                    call print
                    jmp event_loop 



; reply:          test r14, 0x004
;                 jz child_sock_cls
;                 mov rdi, r13
;                 mov rax, 20
;                 lea rsi, [iovec_buff]
;                 mov rdx, 3
;                 syscall                                 ; sys_writev -> writes an array of buffers (i/o vector)
;                 cmp rax, 0
;                 jge child_sock_cls
;                 inc rbx
;                 jge event_loop
;                 lea rsi, [error_write]
;                 mov rdx, error_write_len
;                 call print

child_sock_cls:     mov rdi, r13
                    mov rax, 3
                    syscall
                    inc rbx
                    jmp event_loop

epoll_cls:          mov rdi, qword [epoll_fd]
                    mov rax, 3
                    syscall

main_socket:        mov rdi, qword [listener_fd]
                    mov rax, 3
                    syscall

end:                ; exits the program
                    mov rax, 60
                    mov rdi, 0
                    syscall