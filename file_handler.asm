%include "defines.inc"
%include "open_defines.inc"

%define S_IFMT 0o170000

%define S_IFSOCK 0o140000
%define S_IFLNK 0o120000
%define S_IFREG 0o100000
%define S_IFBLK 0o060000
%define S_IFDIR 0o040000
%define S_IFCHR 0o020000
%define S_IFIFO 0o010000

section .bss
%include "structs.inc"
stat_buff: resb Stat_size

section .data
index db "index.html", 0

section .text

global handle_file, stat_buff
extern invalid_request, stat_buff

; Receives the null terminated path at *rdi
handle_file:        mov rax, 2
                    mov rsi, O_RDONLY
                    mov rdx, 0
                    syscall                                                 ; sys_open -> opens the file

                    cmp rax, 0
                    jl not_found

                    mov r9, rax

fstat:              mov rdi, rax
                    mov rax, 5
                    lea rsi, [stat_buff]
                    syscall                                                 ; sys_fstat -> gets the data about the file, which allows us to determine the type and cache it

is_dir:             mov r8d, dword [stat_buff + Stat.st_mode]
                    and r8d, S_IFMT
                    cmp r8d, S_IFDIR
                    jne is_symlink

                    mov rax, 257
                    lea rsi, [index]
                    mov rdx, O_RDONLY
                    mov r10, 0
                    syscall                                                 ; sys_openat -> if the file is a directory, tries to open index.html inside it

                    mov r9, rax

                    mov rax, 3
                    syscall                                                 ; sys_close -> closes the open directory fd

                    cmp r9, 0
                    jl not_found

                    mov rax, REQUESTING_INDEX
                    or dword [r13 + Client.flags], eax

                    mov rax, 5
                    mov rdi, r9
                    lea rsi, [stat_buff]
                    syscall                                                 ; sys_fstat -> calls fstat for the newly opened index.html file

                    mov r8d, dword [stat_buff + Stat.st_mode]
                    and r8d, S_IFMT

is_symlink:         cmp r8d, S_IFLNK
                    je return_file

is_regular:         cmp r8d, S_IFREG
                    je return_file

                    jmp invalid_request

return_file:        mov rax, r9
                    ret

not_found:          jmp invalid_request                                     ; 404 should be handled here

