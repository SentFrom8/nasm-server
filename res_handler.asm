%include "defines.inc"
%include "macros.inc"

section .bss
%include "structs.inc"

digits_str_buff: resb 10
digits_buffer_len: resq 1

fstat_buff: resb 144

file_fd: resq 1
file_size_str_buff: resb MAX_NUM_LEN

mime_type: resq 1

headers_iovec: resb 16*3

file_offset_buff: resq 1

section .rodata
; contains a mime_table array of Extension_link elements
%include "mime_table.inc"

mime_table_len equ ($ - mime_table) / Extension_link_size

section .data

file_size_iovec:
        istruc Iovec
                at .iov_base, dq file_size_str_buff
                at .iov_len, dq 0
        iend

headers db "HTTP/1.1 200 OK", 13, 10
        db "Connection: close", 13, 10
        db "Content-Type: "

headers_len equ $ - headers

content_len_header db 13, 10, "Content-Length: "
content_len_header_len equ $ - content_len_header

index_content_type db "text/html"
index_content_type_len equ $ - index_content_type

optval_cork dd 1
optval_uncork dd 0

optval_sendbuff dd 1024 * 16

error_invalid_file db "[ERROR] Resource not found", 10
error_invalid_file_len equ $ - error_invalid_file

error_read_failed db "[ERROR] Unable to read the requested file"
error_read_failed_len equ $ - error_read_failed

error_write db "[ERROR] Write failed", 10
error_write_len equ $ - error_write

section .text
global handle_res
extern connection_status, final_path, final_path_len, print, epoll_wait, event_loop, invalid_request, file_extension_offset, stat_buff, i_to_s, handle_file

last_digit:     div r15
                add rdx, 0x30
                mov byte [digits_str_buff + rcx], dl
                xor rdx, rdx
                dec rcx
                cmp rax, 0
                jne last_digit
                ret

handle_res:     test dword [r13 + Client.flags], 1
                jnz event_loop

                test dword [r13 + Client.flags], 8
                jnz file_open

                xor r15, r15
                xor rdx, rdx

mime_lookup:    cmp r15, mime_table_len
                jge invalid_request
                mov rax, r15
                imul rax, Extension_link_size
                mov rdi, qword [mime_table + rax + Extension_link.extension + Iovec.iov_base]
                lea rsi, [final_path]
                add rsi, qword [file_extension_offset]
                mov rcx, qword [final_path_len]
                sub rcx, file_extension_offset
                cmovl rcx, qword [mime_table + rax + Extension_link.extension + Iovec.iov_len]                                  ; Works under the assumption that the cpu supports conditional move
                repe cmpsb

                je save_mime_type
                inc r15
                jmp mime_lookup

save_mime_type: lea r15, [mime_table + rax]
                mov qword [mime_type], r15

file_open:      call handle_file

file_size_str:  mov edi, dword [stat_buff + Stat.st_size]
                lea rsi, [file_size_iovec]
                call i_to_s

mk_iovec:       lea r15, [headers]
                mov qword [headers_iovec + 0*8], r15

                mov r15, headers_len
                mov qword [headers_iovec + 1*8], r15

                mov r15, qword [mime_type]
                mov rax, qword [r15 + 8]
                mov qword [headers_iovec + 2*8], rax

                mov r15d, dword [r15 + 20]
                mov qword [headers_iovec + 3*8], r15

                lea r15, [content_len_header]
                mov qword [headers_iovec + 4*8], r15

                mov r15, content_len_header_len
                mov qword [headers_iovec + 5*8], r15

                lea r15, [digits_str_buff + rcx + 1]
                mov qword [headers_iovec + 6*8], r15

                mov r15, 9
                sub r15, rcx
                mov qword [headers_iovec + 7*8], r15

cork:           mov rax, 54
                mov rdi, r13
                mov rsi, 6
                mov rdx, 3
                lea r10, [optval_cork]
                mov r8, 4
                syscall                                 ; sys_setsockopt -> sets the TCP_CORK option to 1 where level is IPPROTO_TCP(6) and optname is TCP_CORK(3)

; limit_buff:     mov rax, 54
;                 mov rdi, r13
;                 mov rsi, 1
;                 mov rdx, 7
;                 lea r10, [optval_sendbuff]
;                 mov r8, 4
;                 syscall                                 ; Testing only! Sets the SO_SNDBUF option to 16kb where level is SOL_SOCKET(1) and optname is SO_SNDBUF(7)

writev:         mov rax, 20
                lea rsi, [headers_iovec]
                mov rdx, 4
                syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
                cmp rax, 0
                jge prep_args
                print_literal error_write, error_write_len
                jmp file_cls

prep_args:      xor r15, r15
                mov r10, qword [fstat_buff + 48]
                mov rsi, qword [file_fd]
                mov qword [file_offset_buff], 0

sendfile_loop:  cmp r10, 0
                je uncork

                mov rax, 40
                lea rdx, file_offset_buff
                syscall                                 ; sys_sendfile -> sends r10 bytes from one file to another, starting at rdx
                cmp rax, 0
                jle file_cls
                add r15, rax
                sub r10, rax
                mov qword [file_offset_buff], r15
                jmp sendfile_loop

uncork:         mov rax, 54
                mov rsi, 6
                mov rdx, 3
                lea r10, [optval_uncork]
                mov r8, 4
                syscall

file_cls:       mov rax, 3
                mov rdi, qword [file_fd]
                syscall

                jmp invalid_request

; file_read:      mov qword [file_fd], rax
;                 mov rdi, rax
;                 mov rax, 0
;                 lea rsi, [file_content]
;                 mov rdx, FILE_BUFFER_SIZE
;                 syscall                                 ; sys_read -> reads the contents of the opened file
;                 cmp rax, 0
;                 jg print_file
;                 lea rsi, [error_read_failed]
;                 mov rdx, [error_read_failed_len]
;                 call print
;                 jmp client_cls

; print_file:     mov qword [file_content_len], rax
;                 lea rsi, [file_content]
;                 mov rdx, rax
;                 call print

;                 mov r15, 10
;                 mov rcx, 9
;                 mov byte [digits_str_buff + rcx], 10
;                 dec rcx
;                 mov byte [digits_str_buff + rcx], 13
;                 dec rcx
;                 mov byte [digits_str_buff + rcx], 10
;                 dec rcx
;                 mov byte [digits_str_buff + rcx], 13
;                 dec rcx
;                 xor rdx, rdx
;                 call last_digit                         ; Converts the length returned from the read syscall to a string and writes it to a buffer

; mk_iovec:       lea r15, [headers]
;                 mov qword [headers_iovec + 0*8], r15

;                 mov r15, headers_len
;                 mov qword [headers_iovec + 1*8], r15

;                 mov r15, qword [mime_type]
;                 mov rax, qword [r15 + 8]
;                 mov qword [headers_iovec + 2*8], rax

;                 mov r15d, dword [r15 + 20]
;                 mov qword [headers_iovec + 3*8], r15

;                 lea r15, [content_len_header]
;                 mov qword [headers_iovec + 4*8], r15

;                 mov r15, content_len_header_len
;                 mov qword [headers_iovec + 5*8], r15

;                 lea r15, [digits_str_buff + rcx + 1]
;                 mov qword [headers_iovec + 6*8], r15

;                 mov r15, 9
;                 sub r15, rcx
;                 mov qword [headers_iovec + 7*8], r15

;                 lea r15, [file_content]
;                 mov qword [headers_iovec + 8*8], r15

;                 mov r15, qword [file_content_len]
;                 mov qword [headers_iovec + 9*8], r15


; reply:          mov rdi, r13
;                 mov rax, 20
;                 lea rsi, [headers_iovec]
;                 mov rdx, 5
;                 syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
;                 cmp rax, 0
;                 jge client_cls
;                 lea rsi, [error_write]
;                 mov rdx, error_write_len
;                 call print
;                 jmp client_cls


