section .bss
%include "structs.inc"


sockaddr: resb 16

epoll_event: resb Epoll_event_size
epoll_return: resb Epoll_event_size*248

client_req_limit equ 4096
clients: resb Client_size * 4096                                                ; flags: 1 - timer, 2 - listener, 4 - ready_to_write
client_req_buffer: resb 8192 * client_req_limit
connection_timer_seconds equ 15

listener_fd: resq 1
epoll_fd: resq 1
timer_fd resq 1

section .data

server_listening db "[SERVER] Listening on 0.0.0.0:8080", 10
server_listening_len equ $ - server_listening

error_socket db "[ERROR] Unable to create a socket", 10
error_socket_len equ $ - error_socket

error_bind db "[ERROR] Unable to bind socket to 0.0.0.0:8080", 10
error_bind_len equ $ - error_bind

error_listener_epoll db "[ERROR] Unable to add socket the listening to the epoll watch list", 10
error_listener_epoll_len equ $ - error_listener_epoll

error_epoll_wait db "[ERROR] Epoll wait failed", 10
error_epoll_wait_len equ $ - error_epoll_wait

section .text

global _start, event_loop, epoll_wait, epoll_event, listener_fd, epoll_fd, timer_fd, clients, client_req_buffer, client_req_limit, connection_timer_seconds
extern handle_req, listener_event, timer_event, client_event

%include "macros.inc"

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
                    print
                    jmp end

bind:               mov qword [listener_fd], rax

                    xor rbx, rbx                                                ; Zero out rbx because the address is 0.0.0.0
                    mov rbx, 0x901F                                             ; The bind syscall expects big endian, so the order of bytes in the number 8080 is reversed
                    shl rbx, 16                                                 ; Move the port by 16 bits, because the first 16 bits are reserved for the family
                    add rbx, 2                                                  ; Sets the family to AF_INET
                    mov qword [sockaddr], rbx       
                    mov qword [sockaddr + 8], 0                                 ; pads the second qword of the sock_addr struct with zeroes

                    mov rdi, rax
                    mov rax, 49
                    lea rsi, [sockaddr]
                    mov rdx, 16
                    syscall                                                     ; sys_bind -> binds the socket to the address
                    cmp rax, 0
                    jge listen
                    lea rsi, [error_bind]
                    mov rdx, error_bind_len
                    print
                    jmp end

listen:             mov rax, 50
                    mov rdi, qword [listener_fd]
                    mov rsi, 128
                    syscall                                                     ; sys_listen -> marks the socket as passive, ready to accept connections
                    lea rsi, [server_listening]
                    mov rdx, server_listening_len
                    print

epoll:              mov rax, 291
                    xor rdi, rdi
                    syscall                                                     ; sys_epoll_create1 -> creates an epoll
                    mov qword [epoll_fd], rax                                   ; Save epoll fd

listener_epoll:     mov rdi, rax                                                ; epoll fd
                    mov rax, 233                            
                    mov rsi, 1                                                  ; operation: listener_epoll_ADD
                    mov rdx, qword [listener_fd]                                ; socket fd
                    mov ebx, 0x1                                                ; EPOLLIN for incoming connections
                    or ebx, 0x8                                                 ; EPOLLERR if the fd errors
                    or ebx, 0x10                                                ; EPOLLHUP if there is an issue with the fd or the network stack
                    mov dword [epoll_event], ebx                                ; Event flag numbers can be found in /usr/include/x86_64-linux-gnu/sys/epoll.h
                    mov qword [epoll_event + Epoll_event.info], rdx             ; FD in data for later use
                    lea r10, [epoll_event]                 
                    syscall                                                     ; sys_epoll_ctl -> adds the listener socket to the watch list
                    cmp rax, 0
                    jge timer_create
                    lea rsi, [error_listener_epoll]
                    mov rdx, error_listener_epoll_len
                    print
                    jmp end

timer_create:       mov rax, 283
                    mov rdi, 1                                                  ; clock_monotonic
                    xor rdi, rdi
                    mov rsi, 0x800                                              ; sets the sock_nonblock and sock_cloexec flags
                    or rsi, 0x80000
                    syscall                                                     ; sys_timerfd_create -> creates a timer with a file descriptor

timer_epoll:        mov qword [timer_fd], rax
                    mov dword [epoll_event], 0x1
                    mov qword [epoll_event + 4], rax
                    mov rdx, rax
                    mov rax, 233
                    mov rdi, qword [epoll_fd]
                    mov rsi, 1
                    lea r10, epoll_event
                    syscall

epoll_wait:         mov rax, 232
                    mov rdi, qword [epoll_fd]
                    lea rsi, [epoll_return]                                     ; buffer for events
                    mov rdx, 248                                                ; max simultaneous connections, not total
                    mov r10, 60000                                              ; timeout, set to -1 for permanent
                    syscall
                    mov r12, rax                                                ; sys_epoll_wait -> Blocks the thread until there is an EPOLLIN connection or the timeout expires
                    cmp r12, 0
                    jge event_loop
                    lea rsi, [error_epoll_wait]
                    mov rdx, error_epoll_wait_len
                    print
                    jmp end

event_loop:         cmp r12, 0                                                  ; Handles requests back to front. This introduces a bias towards later events per batch, but it's equally unfair
                    je epoll_wait

event_handler:      dec r12
                    mov rax, Epoll_event_size
                    mul r12
                    mov r13, qword [epoll_return + rax + 4]
                    mov r14d, dword [epoll_return + rax]

                    cmp r13, qword [listener_fd]
                    je listener_event

                    cmp r13, qword [timer_fd]
                    je timer_event

                    jmp client_event

end:                mov rax, 60
                    mov rdi, 0
                    syscall