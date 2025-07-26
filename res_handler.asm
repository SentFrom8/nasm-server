section .bss
file_content: resb 10000
file_content_len: resq 1

digits_str_buffer: resb 10
digits_buffer_len: resq 1

file_fd: resq 1

section .data
headers db "HTTP/1.1 200 OK", 13, 10
        db "Content-Type: text/html", 13, 10
        db "Content-Length: "

headers_len equ $ - headers

error_invalid_file db "[ERROR] Resource not found", 10
error_invalid_file_len equ $ - error_invalid_file

error_read_failed db "[ERROR] Unable to read the requested file"
error_read_failed_len equ $ - error_read_failed

error_write db "[ERROR] Write failed", 10
error_write_len equ $ - error_write

section .text
global handle_res
extern connection_status, path_buff, print, epoll_wait, client_loop, client_cls

last_digit:     div r12
                add rdx, 0x30
                mov byte [digits_str_buffer + rbx], dl
                xor rdx, rdx
                dec rbx
                cmp rax, 0
                jne last_digit
                ret

handle_res:     mov rax, 2
                lea rdi, [path_buff]
                mov rsi, 0
                mov rdx, 577
                syscall                                 ; sys_open -> opens the requested file in read only mode
                cmp rax, 0
                jge file_read
                lea rsi, [error_invalid_file]
                mov rdx, error_invalid_file_len
                call print
                jmp client_cls

file_read:      mov qword [file_fd], rax
                mov rdi, rax
                mov rax, 0
                lea rsi, [file_content]
                mov rdx, 10000
                syscall                                 ; sys_read -> reads the contents of the opened file
                cmp rax, 0
                jg print_file
                lea rsi, [error_read_failed]
                mov rdx, [error_read_failed_len]
                call print
                jmp client_cls

print_file:     mov qword [file_content_len], rax
                lea rsi, [file_content]
                mov rdx, rax
                call print

reply:          mov rdx, rax
                mov rdi, r13
                mov rax, 1
                lea rsi, [file_content]
                syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
                cmp rax, 0
                jge client_cls
                inc rbx
                jge client_loop
                lea rsi, [error_write]
                mov rdx, error_write_len
                call print
                jmp client_cls

; reply:          mov rdi, r13
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


;                 mov r12, 10
;                 mov rbx, 9
;                 mov byte [digits_str_buffer + rbx], 10
;                 dec rbx
;                 mov byte [digits_str_buffer + rbx], 13
;                 dec rbx
;                 mov byte [digits_str_buffer + rbx], 10
;                 dec rbx
;                 mov byte [digits_str_buffer + rbx], 13
;                 dec rbx
;                 xor rdx, rdx
;                 call last_digit                         ; Converts the length returned from the read syscall to a string and writes it to a buffer

; mk_iovec:       lea r12, [headers]
;                 mov qword [iovec_buff], r12

;                 mov r12, headers_len
;                 mov qword [iovec_buff + 8], r12

;                 lea r12, [digits_str_buffer + rbx + 1]
;                 mov qword [iovec_buff + 16], r12

;                 mov r12, 9
;                 sub r12, rbx
;                 mov qword [iovec_buff + 24], r12

;                 lea r12, [file_content]
;                 mov qword [iovec_buff + 32], r12

;                 mov r12, qword [file_content_len]
;                 mov qword [iovec_buff + 40], r12