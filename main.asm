%include "defines.inc"
%include "epoll_defines.inc"
%include "socket_defines.inc"
%include "timer_defines.inc"
%include "open_defines.inc"

; unshare flags
%define	CLONE_FILES 1024
%define	CLONE_FS 512
%define	CLONE_NEWNS 131072
%define	CLONE_NEWPID 536870912
%define	CLONE_NEWUSER 268435456

section .bss
%include "structs.inc"

sockaddr: resb 16

uid_map_buff: resb 25
gid_map_buff: resb 25

uid_buff: resb MAX_NUM_LEN
gid_buff: resb MAX_NUM_LEN

epoll_event: resb Epoll_event_size
epoll_return: resb Epoll_event_size*248

client_req_limit equ 4096
clients: resb Client_size * 4096
client_req_buffer: resb 8192 * client_req_limit

listener_fd: resq 1
epoll_fd: resq 1
timer_fd resq 1

section .rodata

setgroups db "/proc/self/setgroups", 0
uid_map db "/proc/self/uid_map", 0
gid_map db "/proc/self/gid_map", 0

section .data

setgroups_value db "deny"
setgroups_value_len equ $ - setgroups_value

uid_map_buff_len dq 0
gid_map_buff_len dq 0

uid_iovec:
        istruc Iovec
                at .iov_base, dq uid_buff
                at .iov_len, dq 0
        iend

gid_iovec:
        istruc Iovec
                at .iov_base, dq gid_buff
                at .iov_len, dq 0
        iend


inside_id_str db "0 "
inside_id_str_len equ $ - inside_id_str

id_map_len_str db " 1", 10
id_map_len_str_len equ $ - id_map_len_str

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

global _start, event_loop, epoll_wait, epoll_event, listener_fd, epoll_fd, timer_fd, \
        clients, client_req_buffer, client_req_limit, connection_timer_seconds, end
extern handle_req, listener_event, timer_event, client_event, i_to_s, jail

%include "macros.inc"



; The server uses an epoll to handle file descriptors
; epoll emits an event when an fd is ready for an operation

; Todos: 
; should handle partial requests
; Should check nested function and jumps inside functions. Each function must return in all cases
; Should return 404 for files not found
; the connection header should be handled
; the expired timer must be read
; writev is not suitable for headers, a single string must be constructed

_start:             xor r13, r13

                    lea rdi, [uid_map_buff]
                    lea rsi, [inside_id_str]
                    mov rcx, inside_id_str_len
                    add r13, rcx
                    rep movsb

                    mov r12, rdi

                    mov rax, 102
                    syscall                                                     ; sys_getuid -> gets the user id

                    mov rdi, rax
                    lea rsi, [uid_iovec]
                    call i_to_s

                    mov rdi, r12
                    mov rsi, qword [uid_iovec + Iovec.iov_base]
                    mov rcx, qword [uid_iovec + Iovec.iov_len]
                    add r13, rcx
                    rep movsb

                    lea rsi, [id_map_len_str]
                    mov rcx, id_map_len_str_len
                    add r13, rcx
                    rep movsb

                    mov qword [uid_map_buff_len], r13

mk_gid_buff:        xor r13, r13

                    lea rdi, [gid_map_buff]
                    lea rsi, [inside_id_str]
                    mov rcx, inside_id_str_len
                    add r13, rcx
                    rep movsb

                    mov r12, rdi

                    mov rax, 104
                    syscall                                                     ; sys_getuid -> gets the user id

                    mov rdi, rax
                    lea rsi, [gid_iovec]
                    call i_to_s

                    mov rdi, r12
                    mov rsi, qword [gid_iovec + Iovec.iov_base]
                    mov rcx, qword [gid_iovec + Iovec.iov_len]
                    add r13, rcx
                    rep movsb

                    lea rsi, [id_map_len_str]
                    mov rcx, id_map_len_str_len
                    add r13, rcx
                    rep movsb

                    mov qword [gid_map_buff_len], r13

unshare:            mov rax, 272
                    mov rdi, CLONE_NEWNS 
                    or rdi, CLONE_NEWUSER
                    syscall                                                     ; sys_unshare -> unshares the mount and the user namespace, so that the server is isolated and can act as root

deny_setgroups:     mov rax, 2
                    lea rdi, [setgroups]
                    mov rsi, O_WRONLY
                    mov rdx, 0
                    syscall                                                     ; sys_open

                    mov rdi, rax
                    mov rax, 1
                    lea rsi, [setgroups_value]
                    mov rdx, setgroups_value_len
                    syscall                                                     ; sys_write -> this prevents users from being able to call setgroups, security feature

                    mov rax, 3
                    syscall                                                     ; sys_close

map_uid:            mov rax, 2
                    lea rdi, [uid_map]
                    mov rsi, O_RDWR
                    mov rdx, 0
                    syscall                                                     ; sys_open

                    mov rdi, rax
                    mov rax, 1
                    lea rsi, [uid_map_buff]
                    mov rdx, qword [uid_map_buff_len]
                    syscall                                                     ; sys_write

                    mov rax, 3
                    syscall                                                     ; sys_close


map_gid:            mov rax, 2
                    lea rdi, [gid_map]
                    mov rsi, 2                                                  ; 1: O_WRONLY 2: O_RDWR
                    mov rdx, 0
                    syscall                                                     ; sys_open

                    mov rdi, rax
                    mov rax, 1
                    lea rsi, [gid_map_buff]
                    mov rdx, qword [gid_map_buff_len]
                    syscall                                                     ; sys_write

                    mov rax, 3
                    syscall

                    call jail

socket:             mov rax, 41
                    mov rdi, 2                                                  ; IPv4 family (AF_INET)
                    mov rsi, SOCK_STREAM
                    or rsi, SOCK_NONBLOCK
                    xor rdx, rdx                                                ; System picks the protocol (TCP for SOCK_STREAM type)
                    syscall                                                     ; sys_socket -> creates the socket
                    cmp rax, 0                                                  ; if error, print_literal the error and jump to end
                    jge bind
                    print_literal error_socket, error_socket_len
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
                    print_literal error_bind, error_bind_len
                    jmp end

listen:             mov rax, 50
                    mov rdi, qword [listener_fd]
                    mov rsi, 128
                    syscall                                                     ; sys_listen -> marks the socket as passive, ready to accept connections
                    print_literal server_listening, server_listening_len

epoll:              mov rax, 291
                    xor rdi, rdi
                    syscall                                                     ; sys_epoll_create1 -> creates an epoll
                    mov qword [epoll_fd], rax                                   ; Save epoll fd

listener_epoll:     mov rdi, rax                                                ; epoll fd
                    mov rax, 233                            
                    mov rsi, EPOLL_CTL_ADD
                    mov rdx, qword [listener_fd]                                ; socket fd
                    mov ebx, EPOLLIN                                            ; for incoming connections
                    or ebx, EPOLLERR                                            ; if the fd errors
                    or ebx, EPOLLHUP                                            ; if there is an issue with the fd or the network stack
                    mov dword [epoll_event], ebx                                ; Event flag numbers can be found in /usr/include/x86_64-linux-gnu/sys/epoll.h
                    mov qword [epoll_event + Epoll_event.info], rdx             ; FD in data for later use
                    lea r10, [epoll_event]                 
                    syscall                                                     ; sys_epoll_ctl -> adds the listener socket to the watch list
                    cmp rax, 0
                    jge timer_create
                    print_literal error_listener_epoll, error_listener_epoll_len
                    jmp end

timer_create:       mov rax, 283
                    mov rdi, CLOCK_MONOTONIC                                    ; clock_monotonic
                    xor rdi, rdi
                    mov rsi, TFD_NONBLOCK
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
                    print_literal error_epoll_wait, error_epoll_wait_len
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