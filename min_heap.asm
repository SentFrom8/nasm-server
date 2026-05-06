section .bss
%include "structs.inc"
heap: resq 4096

section .data
heap_size dd 0

section .text
%include "macros.inc"
global mh_force_push, mh_bubble, mh_remove, heap, heap_size
extern Client

; Takes an index as the first argument, returns the index of the parent if one exists, -1 otherwise
%macro get_parent_index 1
                        mov rax, %1
                        dec rax                                 ; if zero is passed, returns a negative number anyway
                        sar rax, 1                              ; arithmetic shift to preserve the sign
%endmacro

%macro get_left_child_index 1
                        mov rax, %1
                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl %%skip

                        mov rax, -1
%%skip:
%endmacro

; Takes an index as the first argument, returns the index of the smaller child if one exists, -1 otherwise
%macro get_smaller_child_index 1
                        mov rax, %1
                        shl rax, 1
                        inc rax
                        cmp eax, dword [heap_size]
                        jl %%has_right_child

                        mov rax, -1
                        jmp %%skip

%%has_right_child:      inc rax
                        cmp eax, dword [heap_size]
                        jl %%cmp_children
                        
                        dec rax
                        jmp %%skip

%%cmp_children:         mov rdx, qword [heap + rax*8 - 8]
                        mov rdx, qword [rdx + Client.time]

                        mov r10, qword [heap + rax*8]
                        mov r10, qword [r10 + Client.time]
                        cmp r10, rdx
                        jl %%skip

                        dec rax
%%skip:
%endmacro

; Swaps places of elements at indices %1, %2. Also changes the heap_index values. Arguments must be registers
%macro swap_places 2    
                        cmp %1, %2
                        je %%skip_swap
                        mov rdx, qword [heap + %1*8]
                        mov r10, qword [heap + %2*8]

                        mov dword [rdx + Client.heap_index], reg32(%2)
                        mov dword [r10 + Client.heap_index], reg32(%1)

                        mov qword [heap + %1*8], r10
                        mov qword [heap + %2*8], rdx
%%skip_swap:
%endmacro

; Pushes the pointer in RDI to the heap. Does not check for validity or heap order
mh_force_push:          mov eax, dword [heap_size]
                        mov qword [heap + rax*8], rdi

                        mov dword [rdi + Client.heap_index], eax
                        inc dword [heap_size]
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
                        mov dword [rsi + Client.heap_index], edi
                        mov qword [heap + rdi*8], rsi
                        mov dword [heap_size], eax
                        call mh_bubble
                        ret

last_element:           dec dword [heap_size]
                        ret

; Bubbles the client at index rdi up or down, ensuring the min heap property is preserved
mh_bubble:              mov rsi, qword [heap + rdi*8]
                        mov rsi, qword [rsi + Client.time]                      ; 0101 -> 1010 -> 1011 -> 1101 -> 0010 -> 0011
                        mov r9d, dword [heap_size]

mh_bubble_up_loop:      get_parent_index rdi
                        cmp rax, 0
                        jl mh_bubble_down_loop

                        mov rdx, qword [heap + rax*8]
                        cmp rsi, qword [rdx + Client.time]

                        jge mh_bubble_down_loop

                        swap_places rdi, rax
                        mov rdi, rax
                        jmp mh_bubble_up_loop
                        

; When bubbling down, places should only be swapped with the smaller child. This preserves the min heap property
mh_bubble_down_loop:    get_smaller_child_index rdi
                        cmp rax, 0
                        jl bubble_end

                        mov rdx, qword [heap + rax*8]
                        cmp rsi, qword [rdx + Client.time]
                        jle bubble_end

                        swap_places rdi, rax
                        mov rdi, rax
                        jmp mh_bubble_down_loop

bubble_end:             ret


invalid_entry:          mov rax, -1
                        ret



