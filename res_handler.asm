FILE_BUFFER_SIZE equ 1024 * 16

section .bss
file_content: resb FILE_BUFFER_SIZE
file_content_len: resq 1

digits_str_buff: resb 10
digits_buffer_len: resq 1

fstat_buff: resb 144

file_fd: resq 1

mime_type: resq 1

iovec_buff: resb 16*3

section .rodata

ext_html:     db ".html", 0
ext_html_len: equ $ - ext_html
mime_html:    db "text/html"
mime_html_len: equ $ - mime_html

ext_css:      db ".css", 0
ext_css_len:  equ $ - ext_css
mime_css:     db "text/css"
mime_css_len: equ $ - mime_css

ext_js:       db ".js", 0
ext_js_len:   equ $ - ext_js
mime_js:      db "application/javascript"
mime_js_len:  equ $ - mime_js

ext_jpeg:     db ".jpeg", 0
ext_jpeg_len: equ $ - ext_jpeg
mime_jpeg:    db "image/jpeg"
mime_jpeg_len: equ $ - mime_jpeg

ext_jpg:      db ".jpg", 0
ext_jpg_len:  equ $ - ext_jpg
mime_jpg:     db "image/jpeg"
mime_jpg_len: equ $ - mime_jpg

ext_png:      db ".png", 0
ext_png_len:  equ $ - ext_png
mime_png:     db "image/png"
mime_png_len: equ $ - mime_png

ext_webp:     db ".webp", 0
ext_webp_len: equ $ - ext_webp
mime_webp:    db "image/webp"
mime_webp_len: equ $ - mime_webp

ext_ico:     db ".ico", 0
ext_ico_len: equ $ - ext_ico
mime_ico:    db "image/x-icon"
mime_ico_len: equ $ - mime_ico

ext_txt:      db ".txt", 0
ext_txt_len:  equ $ - ext_txt
mime_txt:     db "text/plain"
mime_txt_len: equ $ - mime_txt

ext_gif:      db ".gif", 0
ext_gif_len:  equ $ - ext_gif
mime_gif:     db "image/gif"
mime_gif_len: equ $ - mime_gif

ext_json:     db ".json", 0
ext_json_len: equ $ - ext_json
mime_json:    db "application/json"
mime_json_len: equ $ - mime_json

mime_table dq ext_html, mime_html 
           dd ext_html_len, mime_html_len

           dq ext_css, mime_css 
           dd ext_css_len, mime_css_len

           dq ext_js, mime_js 
           dd ext_js_len, mime_js_len

           dq ext_jpeg, mime_jpeg 
           dd ext_jpeg_len, mime_jpeg_len

           dq ext_jpg, mime_jpg 
           dd ext_jpg_len, mime_jpg_len

           dq ext_png, mime_png 
           dd ext_png_len, mime_png_len

           dq ext_webp, mime_webp 
           dd ext_webp_len, mime_webp_len

           dq ext_ico, mime_ico
           dd ext_ico_len, mime_ico_len

           dq ext_gif, mime_gif 
           dd ext_gif_len, mime_gif_len

           dq ext_json, mime_json 
           dd ext_json_len, mime_json_len

           dq ext_txt, mime_txt 
           dd ext_txt_len, mime_txt_len

mime_table_len equ ($ - mime_table) / 24

section .data

headers db "HTTP/1.1 200 OK", 13, 10
        db "Connection: close", 13, 10
        db "Content-Type: "

headers_len equ $ - headers

content_len_header db 13, 10, "Content-Length: "
content_len_header_len equ $ - content_len_header

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
extern connection_status, path_buff, print, epoll_wait, client_loop, client_cls, file_extension, file_extension_len

; needs a cork
; sendfile needs to loop

last_digit:     div r15
                add rdx, 0x30
                mov byte [digits_str_buff + rcx], dl
                xor rdx, rdx
                dec rcx
                cmp rax, 0
                jne last_digit
                ret

handle_res:     cmp qword [file_extension_len], 0
                jle client_cls
                xor r15, r15
                xor rdx, rdx

mime_lookup:    cmp r15, mime_table_len
                jge client_cls
                mov rax, r15
                imul rax, 24            
                mov rdi, qword [mime_table + rax]
                mov rsi, qword [file_extension]
                mov rcx, qword [file_extension_len]
                repe cmpsb
                je save_mime_type
                inc r15
                jmp mime_lookup

save_mime_type: lea r15, [mime_table + rax]
                mov qword [mime_type], r15

file_open:      mov rax, 2
                lea rdi, [path_buff]
                mov rsi, 0
                mov rdx, 577
                syscall                                 ; sys_open -> opens the requested file in read only mode
                cmp rax, 0
                jge file_fstat
                lea rsi, [error_invalid_file]
                mov rdx, error_invalid_file_len
                call print
                jmp client_cls

file_fstat:     mov qword [file_fd], rax
                mov rdi, rax
                mov rax, 5
                lea rsi, [fstat_buff]
                syscall                                 ; sys_fstat -> gives us the size of the file for the content-length header

file_size_str:  mov rax, qword [rsi + 48]
                mov r15, 10
                mov rcx, 9
                mov byte [digits_str_buff + rcx], 10
                dec rcx
                mov byte [digits_str_buff + rcx], 13
                dec rcx
                mov byte [digits_str_buff + rcx], 10
                dec rcx
                mov byte [digits_str_buff + rcx], 13
                dec rcx
                xor rdx, rdx
                call last_digit                         ; Converts the length returned from the read syscall to a string and writes it to a buffer

mk_iovec:       lea r15, [headers]
                mov qword [iovec_buff + 0*8], r15

                mov r15, headers_len
                mov qword [iovec_buff + 1*8], r15

                mov r15, qword [mime_type]
                mov rax, qword [r15 + 8]
                mov qword [iovec_buff + 2*8], rax

                mov r15d, dword [r15 + 20]
                mov qword [iovec_buff + 3*8], r15

                lea r15, [content_len_header]
                mov qword [iovec_buff + 4*8], r15

                mov r15, content_len_header_len
                mov qword [iovec_buff + 5*8], r15

                lea r15, [digits_str_buff + rcx + 1]
                mov qword [iovec_buff + 6*8], r15

                mov r15, 9
                sub r15, rcx
                mov qword [iovec_buff + 7*8], r15

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
                lea rsi, [iovec_buff]
                mov rdx, 4
                syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
                cmp rax, 0
                jge prep_args
                lea rsi, [error_write]
                mov rdx, error_write_len
                call print
                jmp client_cls

prep_args:      xor r15, r15
                mov r10, qword [fstat_buff + 48]
                mov rsi, qword [file_fd]

sendfile_loop:  cmp r10, 0
                je uncork

                mov rax, 40
                mov rdx, r15
                syscall                                 ; sys_sendfile -> sends r10 bytes from one file to another, starting at rdx
                cmp rax, 0
                jle client_cls
                add r15, rax
                sub r10, rax
                jmp sendfile_loop

uncork:         mov rax, 54
                mov rsi, 6
                mov rdx, 3
                lea r10, [optval_uncork]
                mov r8, 4
                syscall

                jmp client_cls

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
;                 mov qword [iovec_buff + 0*8], r15

;                 mov r15, headers_len
;                 mov qword [iovec_buff + 1*8], r15

;                 mov r15, qword [mime_type]
;                 mov rax, qword [r15 + 8]
;                 mov qword [iovec_buff + 2*8], rax

;                 mov r15d, dword [r15 + 20]
;                 mov qword [iovec_buff + 3*8], r15

;                 lea r15, [content_len_header]
;                 mov qword [iovec_buff + 4*8], r15

;                 mov r15, content_len_header_len
;                 mov qword [iovec_buff + 5*8], r15

;                 lea r15, [digits_str_buff + rcx + 1]
;                 mov qword [iovec_buff + 6*8], r15

;                 mov r15, 9
;                 sub r15, rcx
;                 mov qword [iovec_buff + 7*8], r15

;                 lea r15, [file_content]
;                 mov qword [iovec_buff + 8*8], r15

;                 mov r15, qword [file_content_len]
;                 mov qword [iovec_buff + 9*8], r15


; reply:          mov rdi, r13
;                 mov rax, 20
;                 lea rsi, [iovec_buff]
;                 mov rdx, 5
;                 syscall                                 ; sys_writev -> writes an array of buffers (I/O vector)
;                 cmp rax, 0
;                 jge client_cls
;                 lea rsi, [error_write]
;                 mov rdx, error_write_len
;                 call print
;                 jmp client_cls


