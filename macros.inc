%macro get_time 1 
                        mov rax, 228 
                        lea rsi, [%1] 
                        mov rdi, 0 
                        syscall                                     ; sys_clock_gettime -> gets the current clock time from the epoch and writes it into the address at %1 
%endmacro

%macro print 0      
                        mov rax, 1
                        mov rdi, 1
                        syscall
%endmacro

%macro check_1_to_9 1
                        cmp al, 0x30
                        jl invalid
                        cmp al, 0x39
                        jg %%check_A_to_F
                        sub al, 0x30
                        jmp %1

%%check_A_to_F:         cmp al, 0x41
                        jl invalid
                        cmp al, 0x46
                        jg invalid
                        sub al, 0x37
%endmacro