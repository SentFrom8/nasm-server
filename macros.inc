%macro get_time 1 
                        mov rax, 228 
                        lea rsi, [%1] 
                        mov rdi, 0 
                        syscall                                     ; sys_clock_gettime -> gets the current clock time from the epoch and writes it into the address at %1 
%endmacro

%macro print 2
                        mov rax, 1
                        mov rdi, 1
                        lea rsi, [%1]
                        mov rdx, %2
                        syscall
%endmacro

%macro hex_char_to_num  2
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