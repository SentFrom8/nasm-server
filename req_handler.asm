section .bss
%include "structs.inc"
path_len: resq 1

global file_extension
file_extension_offset: resq 1

section .data

MAX_PATH_LENGTH = 1024

error_receive db "[ERROR] Receive failed", 10
error_receive_len equ $ - error_receive

error_req_len db "[ERROR] Request too long", 10
error_req_len_len equ $ - error_req_len

error_invalid_req db "[ERROR] Invalid request"
error_invalid_req_len equ $ - error_invalid_req

global path_buff, path_len
path_buff db "./", 30 dup(0)

req_end db 13, 10, 13, 10

get_req_identifier db "GET /"
get_req_identifier_len equ $ - get_req_identifier

index db "/index.html", 0
index_len equ $ - index
index_extension_offset equ 6

section .text
%include "macros.inc"

global handle_req
extern client_cls, handle_res, client_req_buffer, conn_close, reset_timer, event_loop, client_req_limit, parse_route

; IMPORTANT! There is a buffer overflow here if index.html is appended when there is no room for it in the buffer
; write better path size logic
; use an offset for the extension
; actually, consider using fstat, checking if it's a folder and appending /index.html if it is

handle_req:             mov rax, 0
                        mov rdi, qword [r13]
                        mov r15, qword [r13 + Client.req_len]
                        mov rsi, [r13 + Client.read_buff]
                        add rsi, r15
                        mov rdx, client_req_limit
                        sub rdx, r15
                        cmp rdx, 0
                        je req_len_error
                        syscall                                                     ; sys_read -> reads the incoming message from the client and writes it into req
                        cmp rax, 0
                        jg req_finished_check
                        jl read_error
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

read_error:             cmp rax, -11
                        jne receive_error
                        jmp event_loop

req_finished_check:     call reset_timer
                        add r15, rax
                        mov qword [r13 + Client.req_len], r15
                        mov rax, qword [r13 + Client.read_buff]
                        mov eax, dword [rax + r15 - 4]
                        cmp eax, dword [req_end]
                        je reset_conn_timer
                        jmp event_loop

validate_req:           cld
                        mov rdi, qword [r13 + Client.read_buff]
                        lea rsi, [get_req_identifier]
                        mov rcx, get_req_identifier_len
                        repe cmpsb
                        jne invalid_req_error
                        mov rax, get_req_identifier_len
                        xor rdx, rdx
                        mov rbx, qword [r13 + Client.read_buff]
                        mov r15b, 0

extract_path:           mov dl, r15b
                        mov r15b, byte [rbx + rax]
                        lea r10, [path_buff + 2 + rax - get_req_identifier_len]     ; moves the bytes after the get request indicator to the path buffer, sanitizing them in the process
                        cmp rax, MAX_PATH_LENGTH
                        jge invalid_req_error
                        cmp r15b, 13
                        je invalid_req_error
                        cmp r15b, 10
                        je invalid_req_error
;                        cmp r15b, 0x2E                                              ; Checks if a period is present, indicating a file extension
;                        je handle_period
                
;                        cmp r15b, 0x41
;                        jl check_space
;                        cmp r15b, 0x5A
;                        jg check_space
;                        or r15b, 0x20                                               ; Checks for upper case characters, converts them to lower case

check_space:            cmp r15b, 0x20
                        je parse_route

write_to_buff:          mov byte [r10], r15b
                        inc rax
                        jmp extract_path

;handle_period:          cmp dl, r15b                                                ; when encountering a period, compares the current character with the previous one
;                        je invalid_req_error
;                        mov dh, 1
;                        sub rax, 2
;                        mov qword [file_extension_offset], rax
;                        add rax, 2
;                        jmp write_to_buff

mk_rel_path:            sub rax, (get_req_identifier_len - 2)
                        cmp dh, 1
                        je finalize_path
                        xor rcx, rcx

append_home:            cld
                        lea rsi, [index]
                        lea rdi, [path_buff + rax]
                        mov rcx, index_len
                        rep movsb
                        add rax, index_extension_offset
                        mov qword [file_extension_offset], rax
                        lea rax, [rax - index_extension_offset + index_len]         ; this just does arithmetic

finalize_path:          mov qword [path_len], rax
                        mov dword [r13 + Client.flags], 1

print_path:             print path_buff, rax

                        jmp handle_res

receive_error:          print error_receive, error_receive_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

req_len_error:          print error_req_len, error_req_len_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop

invalid_req_error:      print error_invalid_req, error_invalid_req_len
                        mov rdi, r13
                        call conn_close
                        jmp event_loop