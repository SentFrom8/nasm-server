section .bss
%include "structs.inc"
heap: resq 4096

section .data
heap_size dd 0

section .text
global mh_push, mh_bubble, mh_remove, heap, heap_size

; Compares the element at index rdi to its parent, 
%macro cmp_parent 0
                        mov rax, rdi
                        dec rax
                        shr rax, 1
                        mov r10, qword [heap + rax*8]
                        cmp rsi, qword [r10 + Client.time + Timespec.seconds]
                        jne %%skip

                        cmp rdx, qword [r10 + Client.time + Timespec.nanoseconds]
%%skip:                 
%endmacro

; compares the element at index rdi to its smaller child
%macro cmp_smaller_child 0
                        mov rax, rdi
                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl %%has_right_child
                        ret

%%has_right_child:      lea r10, [heap + rax*8]
                        mov r8, qword [r10]
                        inc rax
                        cmp eax, dword [heap_size]
                        jl %%cmp_children
                        jmp %%cmp_vertical

%%cmp_children:         mov rax, [r8 + Client.time + Timespec.seconds]
                        mov r9, qword [r10 + 8]
                        cmp rax, [r9 + Client.time + Timespec.seconds]
                        jl %%cmp_vertical
                        je %%cmp_children_ns

%%second_child_smaller: mov r8, qword [r10 + 8]
                        jmp %%cmp_vertical

%%cmp_children_ns:      mov rax, [r8 + Client.time + Timespec.nanoseconds]
                        cmp rax, [r9 + Client.time + Timespec.nanoseconds]
                        jle %%cmp_vertical
                        jmp %%second_child_smaller

%%cmp_vertical:         mov eax, dword [r8 + Client.heap_index]
                        cmp rsi, [r8 + Client.time + Timespec.seconds]
                        jne %%skip

                        cmp rdx, [r8 + Client.time + Timespec.nanoseconds]

%%skip:
%endmacro

; Swaps places of elements at indices rdi, rax. Also changes the heap_index value for each element
swap_places:            mov r10, qword [heap + rdi*8]
                        mov r8, qword [heap + rax*8]

                        mov dword [r10 + Client.heap_index], eax
                        mov dword [r8 + Client.heap_index], edi

                        mov qword [heap + rdi*8], r8
                        mov qword [heap + rax*8], r10
                        ret

; Pushes the client in [RDI] to the heap
mh_push:                cmp dword [heap_size], 0
                        je push
                        
                        mov eax, dword [heap_size]
                        dec eax
                        shr eax, 1 
                        mov rax, qword [heap + eax*8]
                        mov r10, qword [rax + Client.time + Timespec.seconds]
                        cmp r10, qword [rdi + Client.time + Timespec.seconds]
                        jg invalid_entry
                        jl push

                        mov r10, qword [rax + Client.time + Timespec.nanoseconds]
                        cmp r10, qword [rdi + Client.time + Timespec.nanoseconds]
                        jg invalid_entry

push:                   mov eax, dword [heap_size]
                        mov qword [heap + rax*8], rdi

                        mov dword [rdi + Client.heap_index], eax
                        inc dword [heap_size]
                        ret

invalid_entry:          mov rax, -1
                        ret


; Removes the element at index rdi. Does this by swapping the places of the element with the last element in the heap, reducing heap size, then bubbling it up.
mh_remove:              cmp rdi, 0
                        jl invalid_entry        

                        mov eax, dword [heap_size]
                        dec eax
                        cmp rdi, rax
                        je last_element
                        jg invalid_entry

                        mov r10, qword [heap + rax*8]
                        mov dword [r10 + Client.heap_index], edi
                        mov qword [heap + rdi*8], r10
                        dec dword [heap_size]
                        call mh_bubble
                        ret

last_element:           dec dword [heap_size]
                        ret


mh_bubble:              cmp rdi, 0
                        jl invalid_entry

                        mov rsi, qword [heap + rdi*8]
                        mov rdx, qword [rsi + Client.time + Timespec.nanoseconds]
                        mov rsi, qword [rsi + Client.time + Timespec.seconds]

                        jg cmp_parent_init
                        jmp mh_bubble_down
                        


cmp_parent_init:        cmp_parent
                        jl mh_bubble_up_loop

; When bubbling down, places should only be swapped with the smaller child. This preserves the min heap property
mh_bubble_down:         cmp_smaller_child
                        jg mh_bubble_down_loop
                        ret

mh_bubble_up_loop:      call swap_places

                        mov rdi, rax

                        cmp rdi, 0
                        jg cmp_parent_loop
                        ret

cmp_parent_loop:        cmp_parent
                        jl mh_bubble_up_loop

mh_bubble_down_loop:    call swap_places

                        mov rdi, rax

                        cmp_smaller_child
                        jg mh_bubble_down_loop
                        ret
