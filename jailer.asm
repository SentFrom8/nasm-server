; mount flags
%define MS_BIND 4096
%define MS_PRIVATE 262144
%define MS_REC 16384

; umount flags
%define MNT_DETACH 2

section .bss
cwd_buff: resb 100
cwd_buff_len equ $ - cwd_buff

old_path_buff: resb 120
old_path_buff_len equ $ - old_path_buff

test_buff: resb 100
test_buff_len equ $ - test_buff

section .data
root_mp db "/", 0
old_root db "/old", 0

section .text
global jail


jail:               
propagation_off:            mov rax, 165
                            mov rdi, 0
                            lea rsi, root_mp
                            mov rdx, 0
                            mov r10, MS_PRIVATE                                 ; disables propagation
                            or r10, MS_REC                                      ; does so recursively for all child mount points
                            mov r8, 0
                            syscall                                             ; sys_mount -> disables propagation recursively for the root mount point, ensuring complete isolation of mounts

mount_self:                 mov rax, 79
                            lea rdi, cwd_buff
                            mov rsi, cwd_buff_len
                            syscall                                             ; sys_getcwd -> fetches the current working directory, to be bind mounted to itself

                            mov rax, 165
                            lea rdi, cwd_buff
                            lea rsi, cwd_buff
                            mov r10, MS_BIND
                            or r10, MS_REC                                      ; MS_REC is here just in case there is a mount point lower down the tree it also gets bound
                            mov rdx, 0
                            mov r8, 0
                            syscall

mk_old_root_path:           lea rax, old_path_buff
                            lea rdi, cwd_buff
                            xor rcx, rcx

copy_cwd_loop:              mov bl, byte [rdi + rcx]
                            cmp bl, 0
                            je append_old

                            mov byte [rax + rcx], bl
                            inc rcx
                            jmp copy_cwd_loop

append_old:                 lea rax, [rax + rcx]
                            xor rcx, rcx
                            lea rdi, old_root

copy_old_loop:              mov bl, byte [rdi + rcx]

                            mov byte [rax + rcx], bl
                            inc rcx

                            cmp bl, 0
                            jne copy_old_loop

mk_old_dir:                 mov rax, 83
                            lea rdi, old_path_buff
                            mov rsi, 0o777
                            syscall


pivot_root:                 mov rax, 155
                            lea rdi, cwd_buff
                            lea rsi, old_path_buff
                            syscall                                             ; sys_pivot_root -> pivots the root to the current directory, mounts the old root to ./old

                            mov rax, 80
                            lea rdi, root_mp
                            syscall                                             ; sys_chdir -> updates the working directory

                            mov rax, 166
                            lea rdi, old_root
                            mov rsi, MNT_DETACH
                            syscall                                             ; sys_umount2 -> unmounts the old root, making it inaccessible

                            mov rax, 84
                            lea rdi, old_root
                            syscall                                             ; sys_rmdir -> removes the old directory as it serves no purpose

                            ret