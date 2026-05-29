%include "timer_defines.inc"

section .bss
%include "structs.inc"

timer_read_buff resq 1

section .rodata

error_timer_read db "[SERVER] Critical! Unable to read the timer event, can't safely proceed", 10
error_timer_read_len equ $ - error_timer_read

warn_timer_overshoot db "[WARN] Timer expired more than once, consider extending it", 10
warn_timer_overshoot_len equ $ - warn_timer_overshoot

expired_test db "Timer expired", 10
expired_test_len equ $ - expired_test

section .data
itimerspec: times Itimerspec_size db 0

section .text
%include "macros.inc"
global update_timer, timer_event, reset_timer
extern heap, heap_size, timer_fd, conn_close, connection_timer_seconds, event_loop, mh_bubble, end

; If r9 is used, update conn_handler to use push/pop

; sets the timer timeout to the first element in the heap
update_timer:               cmp dword [heap_size], 0
                            jne get_client_time

                            pxor xmm0, xmm0                                             ; pxor is just xor for simd registers
                            movdqu [itimerspec + Itimerspec.value], xmm0                ; reset the timer if the heap is empty
                            jmp set_time_call

get_client_time:            mov rax, qword [heap]
                            xor rdx, rdx
                            mov rax, qword [rax + Client.time]
                            mov rdi, 1000000000
                            div rdi
                            mov qword [itimerspec + Itimerspec.value + Timespec.seconds], rax
                            mov qword [itimerspec + Itimerspec.value + Timespec.nanoseconds], rdx

set_time_call:              mov rax, 286
                            mov rdi, qword [timer_fd]
                            mov rsi, TFD_TIMER_ABSTIME                                  ; sets the timer to an absolute time instead of relative
                            lea rdx, [itimerspec]
                            mov r10, 0
                            syscall                                                     ; sys_timerfd_settime -> sets the timer to the absolute time of the first element in the heap
                            ret

; resets the timer of the element *r13 and bubbles it. The syscall clobbers rdi so might as well be r13
reset_timer:                get_time itimerspec
                            mov rax, qword [itimerspec + Timespec.seconds]
                            add rax, SECONDS_PER_CLIENT_EXTEND
                            imul rax, 1000000000
                            add rax, qword [itimerspec + Timespec.nanoseconds]
                            mov qword [r13 + Client.time], rax
                            mov edi, dword [r13 + Client.heap_index]
                            call mh_bubble
                            call update_timer
                            ret

timer_event:                print_literal expired_test, expired_test_len
                            mov rax, 0
                            mov rdi, qword [timer_fd]
                            lea rsi, [timer_read_buff]
                            mov rdx, 8
                            syscall                                                         ; reads 8 bytes from the timer, the timer returns the number of times it expired

                            cmp rax, 0
                            jg timer_read
                            
                            cmp rax, -11
                            je event_loop

                            print_literal error_timer_read, error_timer_read_len
                            jmp end

timer_read:                 cmp qword [timer_read_buff], 1
                            je connection_expired

                            print_literal warn_timer_overshoot, warn_timer_overshoot_len

connection_expired:         cmp dword [heap_size], 0
                            je event_loop

                            get_time itimerspec
                            mov rax, qword [itimerspec + Timespec.seconds]
                            imul rax, 1000000000
                            add rax, qword [itimerspec +  Timespec.nanoseconds]

                            mov rdi, qword [heap]
                            cmp rax, qword [rdi + Client.time]                                  ; Checks if the timer of the first client is actually expired. This prevents the case where the timer expires while the client is being closed

                            jl event_loop

                            call conn_close
                            jmp event_loop










