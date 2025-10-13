section .bss
heap: resq 4096

section .data
heap_size dd 0

CLIENT_NANOSECOND_OFFSET equ 40
CLIENT_HEAP_INDEX_OFFSET equ 48

section .text
global mh_push, mh_bubble, mh_remove
; extern CLIENT_NANOSECOND_OFFSET, CLIENT_HEAP_INDEX_OFFSET

; Compares the element at index rdi to its parent
%macro cmp_parent 0
                        mov rax, rdi
                        dec rax
                        shr rax, 1
                        mov rsi, qword [heap + rdi*8]
                        mov r10, qword [rsi + CLIENT_NANOSECOND_OFFSET]
                        mov rdx, qword [heap + rax*8]
                        mov r8, qword [rdx + CLIENT_NANOSECOND_OFFSET]
                        cmp r10, r8
%endmacro

; compares the element at index rdi to its smaller child
%macro cmp_smaller_child 0
                        mov rax, rdi
                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl %%has_right_child
                        ret

%%has_right_child:      inc rax
                        cmp eax, dword [heap_size]
                        jl %%cmp_children
                        dec rax
                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + CLIENT_NANOSECOND_OFFSET]
                        jmp %%cmp_child

%%cmp_children:         mov rsi, rax
                        dec rsi

                        mov rsi, qword [heap + rsi*8]
                        mov rsi, qword [rsi + CLIENT_NANOSECOND_OFFSET]

                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + CLIENT_NANOSECOND_OFFSET]
                        cmp rsi, r10
                        jg %%cmp_child
                        dec rax
                        mov r10, rsi

%%cmp_child:            mov rsi, qword [heap + rdi*8]
                        mov rsi, qword [rsi + CLIENT_NANOSECOND_OFFSET]
                        cmp rsi, r10
%endmacro

; Swaps places of elements at indices rdi, rax. Also changes the heap_index value for each element
swap_places:            mov rsi, qword [heap + rdi*8]
                        mov rdx, qword [heap + rax*8]

                        mov r10d, dword [rsi + CLIENT_HEAP_INDEX_OFFSET]
                        mov r8d, dword [rdx + CLIENT_HEAP_INDEX_OFFSET]

                        mov dword [rsi + CLIENT_HEAP_INDEX_OFFSET], r8d
                        mov dword [rdx + CLIENT_HEAP_INDEX_OFFSET], r10d

                        mov qword [heap + rdi*8], rdx
                        mov qword [heap + rax*8], rsi
                        ret

; Pushes the value in RDI to the heap
mh_push:                cmp dword [heap_size], 0
                        je push
                        
                        mov eax, dword [heap_size]
                        dec eax
                        shr eax, 1 
                        mov rax, qword [heap + eax*8]
                        mov rax, qword [rax + CLIENT_NANOSECOND_OFFSET]
                        cmp rax, qword [rdi + CLIENT_NANOSECOND_OFFSET]
                        jg invalid_entry

push:                   mov eax, dword [heap_size]
                        mov qword [heap + rax*8], rdi

                        mov dword [rdi + CLIENT_HEAP_INDEX_OFFSET], eax
                        inc dword [heap_size]
                        ret

invalid_entry:          mov rax, -1
                        ret


; Removes the element at index rdi. Does this by swapping the places of the element with the last element in the heap, reducing heap size, then bubbling it up.
mh_remove:              mov eax, dword [heap_size]
                        dec eax
                        cmp rdi, rax
                        je last_element
                        jg invalid_entry

                        cmp rdi, 0
                        jl invalid_entry

                        mov rsi, qword [heap + rax*8]
                        mov dword [rsi + CLIENT_HEAP_INDEX_OFFSET], edi
                        mov qword [heap + rdi*8], rsi
                        mov dword [heap_size], eax
                        call mh_bubble
                        ret

last_element:           dec dword [heap_size]
                        ret


mh_bubble:              cmp rdi, 0
                        jg cmp_parent_init
                        je mh_bubble_down
                        jmp invalid_entry

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
