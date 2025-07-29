section .bss
sockaddr: resb 16
usr_sockaddr: resb 16
upeer_addrlen: resd 1

listener_epoll_event: resb 16
client_epoll_event: resb 16
epoll_return: resb 16*256

listener_fd: resq 1
epoll_fd: resq 1
client_fd: resq 1

section .data
server_listening db "[SERVER] Listening on 0.0.0.0:8080", 10
server_listening_len equ $ - server_listening

error_socket db "[ERROR] Unable to create a socket", 10
error_socket_len equ $ - error_socket

error_bind db "[ERROR] Unable to bind socket to 0.0.0.0:8080", 10
error_bind_len equ $ - error_bind

error_accept db "[ERROR] Accept failed", 10
error_accept_len equ $ - error_accept

error_epoll_ctl db "[ERROR] Unable to add socket to the epoll watch list", 10
error_epoll_ctl_len equ $ - error_epoll_ctl

error_epoll_wait db "[ERROR] Epoll wait failed", 10
error_epoll_wait_len equ $ - error_epoll_wait

error_client_epoll db "[CLIENT] EPOLLERR", 10
error_client_epoll_len equ $ - error_client_epoll

client_epollhup db "[CLIENT] EPOLLHUP", 10
client_epollhup_len equ $ - client_epollhup

section .text
global _start, print, client_loop, client_cls, epoll_wait
extern handle_req

print:          mov rax, 1
                mov rdi, 1
                syscall
                ret

; The server uses an epoll to handle file descriptors
; epoll emits an event when an fd is ready for an operation

_start:         mov rax, 41
                mov rdi, 2                              ; IPv4 family (AF_INET)
                mov rsi, 1                              ; SOCK_STREAM type
                or rsi, 0x800                           ; SOCK_NONBLOCK flag
                xor rdx, rdx                            ; System picks the protocol (TCP for SOCK_STREAM type)
                syscall                                 ; sys_socket -> creates the socket
                mov qword [listener_fd], rax            ; save socket fd
                cmp rax, 0                              ; if error, print the error and jump to end
                jge bind
                lea rsi, [error_socket]
                mov rdx, error_socket_len
                call print
                jmp end

bind:           xor rbx, rbx                            ; Zero out rbx because the address is 0.0.0.0
                mov rbx, 0x901F                         ; The bind syscall expects big endian, so the order of bytes in the number 8080 is reversed
                shl rbx, 16                             ; Move the port by 16 bits, because the first 16 bits are reserved for the family
                add rbx, 2                              ; Sets the family to AF_INET
                mov qword [sockaddr], rbx       
                mov qword [sockaddr + 8], 0             ; pads the second qword of the sock_addr struct with zeroes

                mov rdi, qword [listener_fd]
                mov rax, 49
                lea rsi, [sockaddr]
                mov rdx, 16
                syscall                                 ; sys_bind -> binds the socket to the address
                cmp rax, 0
                jge listen
                lea rsi, [error_bind]
                mov rdx, error_bind_len
                call print
                jmp main_socket

listen:         mov rax, 50
                mov rdi, qword [listener_fd]
                mov rsi, 128
                syscall                                 ; sys_listen -> marks the socket as passive, ready to accept connections
                lea rsi, [server_listening]
                mov rdx, server_listening_len
                call print

epoll:          mov rax, 291
                xor rdi, rdi
                syscall                                 ; sys_epoll_create1 -> creates an epoll
                mov qword [epoll_fd], rax               ; Save epoll fd

epoll_ctl:      mov rdi, rax                            ; epoll fd
                mov rax, 233                            
                mov rsi, 1                              ; operation: EPOLL_CTL_ADD
                mov rdx, qword [listener_fd]            ; socket fd
                mov rbx, 0x001                          ; EPOLLIN for incoming connections
                or rbx, 0x008                           ; EPOLLERR if the fd errors
                or rbx, 0x010                           ; EPOLLHUP if the client disconnects right away
                mov qword [listener_epoll_event], rbx           ; Event flag numbers can be found in /usr/include/x86_64-linux-gnu/sys/epoll.h
                mov rbx, qword [listener_fd]
                mov qword [listener_epoll_event + 8], rbx       ; FD in data for later use
                lea r10, [listener_epoll_event]                 
                syscall                                 ; sys_epoll_ctl -> adds the listener socket to the watch list
                cmp rax, 0
                jge epoll_wait
                lea rsi, [error_epoll_ctl]
                mov rdx, error_epoll_ctl_len
                call print
                jmp epoll_cls

epoll_wait:     mov rax, 232
                mov rdi, qword [epoll_fd]
                lea rsi, [epoll_return]                 ; Buffer for events
                mov rdx, 256                            ; Max simultaneous connections, not total
                mov r10, 60000                          ; Timeout, set to -1 for permanent
                syscall
                mov r12, rax                            ; sys_epoll_wait -> Blocks the thread until there is an EPOLLIN connection or the timeout expires
                xor rbx, rbx
                cmp r12, 0
                jge client_loop
                lea rsi, [error_epoll_wait]
                mov rdx, error_epoll_wait_len
                call print
                jmp epoll_cls

client_loop:    cmp rbx, r12                            ; Check if the counter passed the last connection
                jge epoll_wait

client_error:   mov r15, rbx
                shl r15, 4
                mov r13, qword [epoll_return + r15 + 8]
                mov r14, qword [epoll_return + r15]
                test r14, 0x008                         ; Check for errors
                jz client_hup
                lea rsi, [error_client_epoll]
                mov rdx, error_client_epoll_len
                call print
                jmp client_cls

client_hup:     test r14, 0x010                         ; Check for hangup
                jnz print_hup
                test r14, 0x2000                        ; Check for half-close
                jnz print_hup
                jz accept

print_hup:      lea rsi, [client_epollhup]
                mov rdx, client_epollhup_len
                call print

client_cls:     inc rbx
                cmp r13, qword [listener_fd]
                je client_loop
                mov rdi, r13
                mov rax, 3
                syscall                                 ; If not, close the socket
                jmp client_loop
                
accept:         cmp r13, qword [listener_fd]
                jne handle_req                          ; If not a connecting socket, jump to receive
                mov rax, 43
                mov rdi, qword [listener_fd]
                lea rsi, [usr_sockaddr]
                mov dword [upeer_addrlen], 16
                lea rdx, [upeer_addrlen]
                syscall
                mov qword [client_fd], rax
                inc rbx
                cmp rax, 0
                jge epoll_wlist
                lea rsi, [error_accept]
                mov rdx, error_accept_len
                call print
                jmp client_loop

epoll_wlist:    mov rdx, rax
                mov rax, 233
                mov rdi, qword [epoll_fd]
                mov rsi, 1
                mov r13, 0x001
                or r13, 0x008
                or r13, 0x010
                or r13, 0x2000                          ; EPOLLRDHUP if the client half-closes
                mov qword [client_epoll_event], r13
                mov qword [client_epoll_event + 8], rdx
                lea r10, [client_epoll_event]
                syscall
                cmp rax, 0
                jge client_loop

safety_cls:     mov rdi, qword [client_fd]              ; Closes the socket if adding to the epoll watch list fails
                mov rax, 3
                syscall

                lea rsi, [error_epoll_ctl]
                mov rdx, error_epoll_ctl_len
                call print
                jmp client_loop 



; reply:          test r14, 0x004
;                 jz child_sock_cls

;                 mov rdi, r13
;                 mov rax, 20
;                 lea rsi, [iovec_buff]
;                 mov rdx, 3
;                 syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
;                 cmp rax, 0
;                 jge child_sock_cls
;                 inc rbx
;                 jge client_loop
;                 lea rsi, [error_write]
;                 mov rdx, error_write_len
;                 call print

child_sock_cls: mov rdi, r13
                mov rax, 3
                syscall
                inc rbx
                jmp client_loop

epoll_cls:      mov rdi, qword [epoll_fd]
                mov rax, 3
                syscall

main_socket:    mov rdi, qword [listener_fd]
                mov rax, 3
                syscall

end:            ; exits the program
                mov rax, 60
                mov rdi, 0
                syscall