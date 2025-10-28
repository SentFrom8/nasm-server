%macro get_time 1 
                        mov rax, 228 
                        mov rdi, 0 
                        mov rsi, %1 
                        syscall                                     ; sys_clock_gettime -> gets the current clock time from the epoch and writes it into the address at %1 
%endmacro

%macro print 0      
                        mov rax, 1
                        mov rdi, 1
                        syscall
%endmacro
                    
