section .bss
%include "structs.inc"

section .data
itimerspec: times Itimerspec_size db 0 

section .text
global update_timer, timer_event
extern heap, heap_size, timer_fd, conn_close, event_loop

; If r9 is used, update conn_handler to use push/pop

update_timer:               cmp dword [heap_size], 0
                            jne get_client_time

                            pxor xmm0, xmm0                                             ; pxor is just xor for simd registers
                            movdqu [itimerspec + Itimerspec.value], xmm0                ; reset the timer if the heap is empty
                            jmp set_time_call

get_client_time:            mov rax, qword [heap]
                            movdqu xmm0, [rax + Client.time]
                            movdqu [itimerspec + Itimerspec.value], xmm0

set_time_call:              mov rax, 286
                            mov rdi, qword [timer_fd]
                            mov rsi, 1                                                  ; TFD_TIMER_ABSTIME flag, sets the timer to an absolute time instead of relative
                            lea rdx, [itimerspec]
                            mov r10, 0
                            syscall                                                     ; sys_timerfd_settime -> sets the timer to the absolute time of the first element in the heap
                            ret

timer_event:                mov rdi, qword [heap]
                            call conn_close
                            inc rbx
                            jmp event_loop