%include "defines.inc"
%include "socket_defines.inc"
%include "header_strings.inc"
%include "macros.inc"

%strcat headers_beginning_str valid_req_str, newline_str
%strcat headers_beginning_str headers_beginning_str, content_type_str
%strlen headers_beginning_len headers_beginning_str

section .bss
%include "structs.inc"

digits_str_buff: resb 10
digits_buffer_len: resq 1

file_size_str_buff: resb MAX_NUM_LEN

mime_type: resq 1

headers_iov: resb Iovec_size*5

file_offset_buff: resq 1

section .rodata
; contains a mime_table array of Extension_link elements
%include "mime_table.inc"

mime_table_len equ ($ - mime_table) / Extension_link_size

index_content_type db "text/html"
index_content_type_len equ $ - index_content_type

index_content_type_iov:
    istruc Iovec
        at .iov_base, dq index_content_type
        at .iov_len, dq index_content_type_len
    iend

headers_beginning db headers_beginning_str

headers_beginning_iov:
    istruc Iovec
        at .iov_base, dq headers_beginning
        at .iov_len, dq headers_beginning_len
    iend

newline db newline_str

newline_iov:
    istruc Iovec
        at .iov_base, dq newline
        at .iov_len, dq newline_len
    iend

content_length db content_length_str

content_length_iov:
    istruc Iovec
        at .iov_base, dq content_length
        at .iov_len, dq content_length_len
    iend

error_invalid_file db "[ERROR] Resource not found", 10
error_invalid_file_len equ $ - error_invalid_file

error_read_failed db "[ERROR] Unable to read the requested file"
error_read_failed_len equ $ - error_read_failed

error_write db "[ERROR] Write failed", 10
error_write_len equ $ - error_write

timer_extended db "Timer extended", 10
timer_extended_len equ $ - timer_extended

section .data

file_size_iov:
        istruc Iovec
                at .iov_base, dq file_size_str_buff
                at .iov_len, dq 0
        iend


optval_cork dd 1
optval_uncork dd 0

section .text

global handle_res
extern final_path, final_path_len, print, epoll_wait, event_loop, invalid_request, file_extension_offset, stat_buff, \
i_to_s, handle_file, conn_close, reset_timer, res_headers_buff, merge_iov

handle_res:             test dword [r13 + Client.flags], READY_FOR_RES
                        jz event_loop

                        test dword [r13 + Client.flags], SENDING_HEADERS
                        jnz send_headers

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
                        sub rcx, qword [file_extension_offset]
                        cmovl rcx, qword [mime_table + rax + Extension_link.extension + Iovec.iov_len]                                  ; Works under the assumption that the cpu supports conditional move
                        repe cmpsb

                        je save_mime_type
                        inc r15
                        jmp mime_lookup

save_mime_type:         lea r15, [mime_table + rax]
                        mov qword [mime_type], r15

file_size_str:          mov edi, dword [stat_buff + Stat.st_size]
                        lea rsi, [file_size_str_buff]
                        mov qword [file_size_iov + Iovec.iov_base], rsi                                                               ; any previous value must be cleared
                        lea rsi, [file_size_iov]
                        call i_to_s

build_headers:          lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [headers_beginning_iov]
                        call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]

                        test dword [r13 + Client.flags], REQUESTING_INDEX
                        jz use_found_mime_type

                        lea rsi, [index_content_type_iov]
                        jmp continue_headers

use_found_mime_type:    mov rsi, qword [mime_type]
                        lea rsi, [rsi + Extension_link.content_type]

continue_headers:       call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [newline_iov]
                        call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [content_length_iov]
                        call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [file_size_iov]
                        call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [newline_iov]
                        call merge_iov

                        lea rdi, [r13 + Client.res_headers_iov]
                        lea rsi, [newline_iov]
                        call merge_iov

                        or dword [r13 + Client.flags], SENDING_HEADERS

; cork:                   mov rax, 54
;                         mov rdi, qword [r13 + Client.fd]
;                         mov rsi, IPPROTO_TCP
;                         mov rdx, TCP_CORK
;                         lea r10, [optval_cork]
;                         mov r8, 4
;                         syscall                                                                         ; sys_setsockopt -> sets the TCP_CORK option to 1 where level is IPPROTO_TCP(6) and optname is TCP_CORK(3)

send_headers:           mov rax, 1
                        mov rdi, qword [r13 + Client.fd]
                        mov rsi, qword [r13 + Client.res_headers_iov + Iovec.iov_base]
                        add rsi, qword [r13 + Client.res_headers_sent]
                        mov rdx, qword [r13 + Client.res_headers_iov + Iovec.iov_len]
                        syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
                        cmp rax, 0
                        jge sendfile

                        cmp rax, -11
                        jne write_error

                        jmp event_loop

write_error:            print_literal error_write, error_write_len
                        mov rdi, r13
                        call conn_close
                        jmp file_cls

sendfile:               or dword [r13 + Client.flags], %eval(SENDING_FILE | DATA_SENT)
                        add rax, qword [r13 + Client.res_headers_sent]
                        mov qword [r13 + Client.res_headers_sent], rax
                        cmp rax, qword [r13 + Client.res_headers_iov + Iovec.iov_len]
                        jge prep_args

                        call reset_timer
                        jmp event_loop


prep_args:              xor qword [r13 + Client.flags], SENDING_HEADERS
                        mov rdi, qword [r13 + Client.fd]
                        mov r10, qword [stat_buff + Stat.st_size]
                        mov rsi, qword [r13 + Client.req_file_fd]
                        lea rdx, [r13 + Client.res_file_sent]

sendfile_loop:          mov rax, 40
                        syscall                                 ; sys_sendfile -> sends r10 bytes from one file to another, starting at rdx
                        cmp rax, 0
                        jl sendfile_error
                        je file_cls
                        
                        or dword [r13 + Client.flags], DATA_SENT
                        jmp sendfile_loop

sendfile_error:         cmp rax, -11
                        jne file_cls
                        
                        test dword [r13 + Client.flags], DATA_SENT
                        jz event_loop

                        call reset_timer
                        xor dword [r13 + Client.flags], DATA_SENT
                        jmp event_loop

; uncork:                 mov rax, 54
;                         mov rsi, IPPROTO_TCP
;                         mov rdx, TCP_CORK
;                         lea r10, [optval_uncork]
;                         mov r8, 4
;                         syscall

file_cls:               mov rax, 3
                        mov rdi, qword [r13 + Client.req_file_fd]
                        syscall

                        mov rdi, r13
                        call conn_close

                        jmp event_loop

