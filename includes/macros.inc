%macro get_time 1 
                        mov rax, 228 
                        lea rsi, [%1] 
                        mov rdi, 0 
                        syscall                                     ; sys_clock_gettime -> gets the current clock time from the epoch and writes it into the address at %1 
%endmacro

%macro print_literal 2
                        mov rax, 1
                        mov rdi, 1
                        lea rsi, [%1]
                        mov rdx, %2
                        syscall
%endmacro

%macro print_addr 2
                        mov rax, 1
                        mov rdi, 1
                        mov rsi, %1
                        mov rdx, %2
                        syscall
%endmacro

%macro print_iovec 1
                        lea r10, [%1]
                        mov rax, 1
                        mov rdi, 1
                        mov rsi, qword [r10 + Iovec.iov_base]
                        mov rdx, qword [r10 + Iovec.iov_len]
                        syscall
%endmacro

%macro hex_char_to_num 2
                        cmp al, 0x30
                        jl %2
                        cmp al, 0x39
                        jg %%check_A_to_F
                        
                        sub al, 0x30
                        jmp %1

%%check_A_to_F:         cmp al, 0x41
                        jl %2
                        cmp al, 0x46
                        jg %%check_a_to_f

                        sub al, 0x37
                        jmp %1

%%check_a_to_f:         cmp al, 0x61
                        jl %2
                        cmp al, 0x66
                        jg %2

                        sub al, 0x57
                        jmp %1
%endmacro

; This part allows for conversion of a 64 bit register to a 32 bit one when passed as an argument to a macro
; This is the only way I found that works
%define reg32_rax eax
%define reg32_rbx ebx
%define reg32_rcx ecx
%define reg32_rdx edx

%define reg32_rsi esi
%define reg32_rdi edi
%define reg32_rbp ebp
%define reg32_rsp esp

%define reg32_r8  r8d
%define reg32_r9  r9d
%define reg32_r10 r10d
%define reg32_r11 r11d
%define reg32_r12 r12d
%define reg32_r13 r13d
%define reg32_r14 r14d
%define reg32_r15 r15d

%define reg32(reg) reg32_ %+ reg
