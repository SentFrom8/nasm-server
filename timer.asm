section .bss
%include "structs.inc"

section .data
itimerspec: times Itimerspec_size db 0 

section .text
%include "macros.inc"
global update_timer, timer_event, reset_timer
extern heap, heap_size, timer_fd, conn_close, connection_timer_seconds, event_loop, mh_bubble

; If r9 is used, update conn_handler to use push/pop

; sets the timer timeout to the first element in the heap
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

; resets the timer of the element *r13 and bubbles it. The syscall clobbers rdi so might as well be r13
reset_timer:                get_time r13 + Client.time
                            add qword [r13 + Client.time + Timespec.seconds], connection_timer_seconds
                            mov edi, dword [r13 + Client.heap_index]
                            call mh_bubble
                            call update_timer
                            ret

timer_event:                mov rdi, qword [heap]
                            call conn_close
                            jmp event_loop