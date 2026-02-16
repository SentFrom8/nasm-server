%include "defines.inc"
%include "macros.inc"

section .bss
%include "structs.inc"

digits_str_buff: resb 10
digits_buffer_len: resq 1

file_size_str_buff: resb MAX_NUM_LEN

mime_type: resq 1

headers_iovec: resb Iovec_size*5

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

line_break db 13, 10, 13, 10
line_break_len equ $ - line_break

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
extern final_path, final_path_len, print, epoll_wait, event_loop, invalid_request, file_extension_offset, stat_buff, i_to_s, handle_file, conn_close

handle_res:             test dword [r13 + Client.flags], READY_FOR_RES
                        jz event_loop

                        test dword [r13 + Client.flags], SENDING_FILE
                        jnz prep_args

                        lea rdi, [final_path]
                        call handle_file
                        mov qword [r13 + Client.req_file_fd], rax

                        test dword [r13 + Client.flags], REQUESTING_INDEX
                        jnz file_size_str

                        xor r15, r15
                        xor rdx, rdx

mime_lookup:            cmp r15, mime_table_len
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

save_mime_type:         lea r15, [mime_table + rax]
                        mov qword [mime_type], r15

file_size_str:          mov edi, dword [stat_buff + Stat.st_size]
                        lea rsi, [file_size_str_buff]
                        mov qword [file_size_iovec + Iovec.iov_base], rsi                                                               ; any previous value must be cleared
                        lea rsi, [file_size_iovec]
                        call i_to_s

mk_iovec:               lea r15, [headers]
                        mov qword [headers_iovec + Iovec.iov_base], r15

                        mov r15, headers_len
                        mov qword [headers_iovec + Iovec.iov_len], r15

                        test dword [r13 + Client.flags], REQUESTING_INDEX
                        jz use_found_mime_type

                        lea r15, index_content_type
                        mov qword [headers_iovec + Iovec_size + Iovec.iov_base], r15

                        mov r15, index_content_type_len
                        mov qword [headers_iovec + Iovec_size + Iovec.iov_len], r15
                        jmp content_len

use_found_mime_type:    mov r15, qword [mime_type]
                        mov rax, qword [r15 + Extension_link.content_type + Iovec.iov_base]
                        mov qword [headers_iovec + Iovec_size + Iovec.iov_base], rax

                        mov rax, qword [r15 + Extension_link.content_type + Iovec.iov_len]
                        mov qword [headers_iovec + Iovec_size + Iovec.iov_len], rax

content_len:            lea r15, [content_len_header]
                        mov qword [headers_iovec + Iovec_size*2 + Iovec.iov_base], r15

                        mov r15, content_len_header_len
                        mov qword [headers_iovec + Iovec_size*2 + Iovec.iov_len], r15

                        lea r15, [file_size_iovec]
                        mov rax, qword [r15 + Iovec.iov_base]
                        mov qword [headers_iovec + Iovec_size*3 + Iovec.iov_base], rax

                        mov rax, qword [r15 + Iovec.iov_len]
                        mov qword [headers_iovec + Iovec_size*3 + Iovec.iov_len], rax

                        lea r15, [line_break]
                        mov qword [headers_iovec + Iovec_size*4 + Iovec.iov_base], r15

                        mov r15, line_break_len
                        mov qword [headers_iovec + Iovec_size*4 + Iovec.iov_len], r15

cork:                   mov rax, 54
                        mov rdi, qword [r13 + Client.fd]
                        mov rsi, 6
                        mov rdx, 3
                        lea r10, [optval_cork]
                        mov r8, 4
                        syscall                                                                         ; sys_setsockopt -> sets the TCP_CORK option to 1 where level is IPPROTO_TCP(6) and optname is TCP_CORK(3)

; limit_buff:                    mov rax, 54
;                                mov rdi, r13
;                                mov rsi, 1
;                                mov rdx, 7
;                                lea r10, [optval_sendbuff]
;                                mov r8, 4
;                                syscall                                 ; Testing only! Sets the SO_SNDBUF option to 16kb where level is SOL_SOCKET(1) and optname is SO_SNDBUF(7)

writev:                 mov rax, 20
                        lea rsi, [headers_iovec]
                        mov rdx, 5
                        syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
                        cmp rax, 0
                        jge sendfile
writev_error:           print_literal error_write, error_write_len
                        mov rdi, r13
                        call conn_close
                        jmp file_cls

sendfile:               or dword [r13 + Client.flags], SENDING_FILE

prep_args:              mov rdi, qword [r13 + Client.fd]
                        mov r10, qword [stat_buff + Stat.st_size]
                        mov rsi, qword [r13 + Client.req_file_fd]
                        lea rdx, [r13 + Client.res_file_sent]

sendfile_loop:          mov rax, 40
                        syscall                                 ; sys_sendfile -> sends r10 bytes from one file to another, starting at rdx
                        cmp rax, 0
                        jl sendfile_error
                        je uncork
                        add qword [r13 + Client.res_file_sent], rax
                        jmp sendfile_loop


sendfile_error:         cmp rax, -11
                        je event_loop

                        mov rdi, r13
                        call conn_close
                        jmp file_cls

uncork:                 mov rax, 54
                        mov rsi, 6
                        mov rdx, 3
                        lea r10, [optval_uncork]
                        mov r8, 4
                        syscall

file_cls:               mov rax, 3
                        mov rdi, qword [r13 + Client.req_file_fd]
                        syscall

                        xor qword [r13 + Client.flags], SENDING_FILE

                        jmp event_loop

