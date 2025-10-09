section .bss
heap: resq 4096

section .data
heap_size dd 0

section .text
global mh_push, mh_bubble, mh_remove

; Swaps places of elements at indices rdi, rax with the elements themselves loaded into rsi, rdx respectively. Also changes the heap_index value for each element
swap_places:            mov rsi, qword [heap + rdi*8]
                        mov rdx, qword [heap + rax*8]

                        mov r10d, dword [rsi + 48]
                        mov r8d, dword [rdx + 48]

                        mov dword [rsi + 48], r8d
                        mov dword [rdx + 48], r10d

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
                        mov rax, qword [rax + 40]
                        cmp rax, qword [rdi + 40]
                        jg invalid_entry

push:                   mov eax, dword [heap_size]
                        mov qword [heap + rax*8], rdi

                        mov dword [rdi + 48], eax
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
                        mov dword [rsi + 48], edi
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

cmp_parent_init:        mov rax, rdi
                        dec rax
                        shr rax, 1
                        mov rsi, qword [heap + rdi*8]
                        mov r10, qword [rsi + 40]
                        mov rdx, qword [heap + rax*8]
                        mov r8, qword [rdx + 40]
                        cmp r10, r8
                        jl mh_bubble_up_loop

; When bubbling down, places should only be swapped with the smaller child. This preserves the min heap property
mh_bubble_down:         mov rax, rdi
                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl has_right_child_init
                        ret

has_right_child_init:   inc rax
                        cmp eax, dword [heap_size]
                        jl cmp_children_init
                        dec rax
                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + 40]
                        jmp cmp_child_init

cmp_children_init:      mov rsi, rax
                        dec rsi

                        mov rsi, qword [heap + rsi*8]
                        mov rsi, qword [rsi + 40]

                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + 40]
                        cmp rsi, r10
                        jg cmp_child_init
                        dec rax
                        mov r10, rsi

cmp_child_init:         mov rsi, qword [heap + rdi*8]
                        mov rsi, qword [rsi + 40]
                        cmp rsi, r10
                        jg mh_bubble_down_loop
                        ret

mh_bubble_up_loop:      call swap_places

                        mov rdi, rax

                        cmp rdi, 0
                        jg cmp_parent
                        ret

cmp_parent:             mov rax, rdi
                        dec rax
                        shr rax, 1
                        mov rsi, qword [heap + rdi*8]
                        mov r10, qword [rsi + 40]
                        mov rdx, qword [heap + rax*8]
                        mov r8, qword [rdx + 40]
                        cmp r10, r8
                        jl mh_bubble_up_loop

mh_bubble_down_loop:    call swap_places

                        mov rdi, rax

                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl has_right_child
                        ret

has_right_child:        inc rax
                        cmp eax, dword [heap_size]
                        jl cmp_children
                        dec rax
                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + 40]
                        jmp cmp_child

cmp_children:           mov rsi, rax
                        dec rsi

                        mov rsi, qword [heap + rsi*8]
                        mov rsi, qword [rsi + 40]

                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + 40]
                        cmp rsi, r10
                        jg cmp_child
                        dec rax
                        mov r10, rsi

cmp_child:              mov rsi, qword [heap + rdi*8]
                        mov rsi, qword [rsi + 40]
                        cmp rsi, r10
                        jg mh_bubble_down_loop
                        ret
