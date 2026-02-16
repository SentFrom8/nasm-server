struc Epoll_event
.flags: resd 1
.info: resq 1
endstruc

struc Timespec
.seconds: resq 1
.nanoseconds: resq 1
endstruc

struc Client
.fd: resq 1
.read_buff: resq 1
.req_len: resq 1
.req_file_fd: resq 1
.res_file_sent: resq 1
.res_total: resq 1
.time: resb Timespec_size
.heap_index: resd 1
.flags: resd 1                                          ; 1: Request parsed, 4: Sending file, 8: Skip mime lookup, 16: Socket closed
endstruc

struc Itimerspec
.interval: resb Timespec_size
.value: resb Timespec_size
endstruc

struc Iovec
.iov_base: resq 1                                       ; pointer to the beginning of the string
.iov_len: resq 1                                        ; size of the string
endstruc

struc Headers
.method: resb Iovec_size
.path: resb Iovec_size
.http_v: resb Iovec_size
endstruc

struc Extension_link
.extension: resb Iovec_size
.content_type: resb Iovec_size
endstruc

struc Stat
    .st_dev:        resq 1
    .st_ino:        resq 1
    .st_nlink:      resq 1
    .st_mode:       resd 1
    .st_uid:        resd 1
    .st_gid:        resd 1
    .__pad0:        resd 1
    .st_rdev:       resq 1
    .st_size:       resq 1
    .st_blksize:    resq 1
    .st_blocks:     resq 1

    .st_atim:       resb Timespec_size
    .st_mtim:       resb Timespec_size
    .st_ctim:       resb Timespec_size
endstruc
