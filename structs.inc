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
.res_sent: resq 1
.res_total: resq 1
.time: resb Timespec_size
.heap_index: resd 1
.flags: resd 1
endstruc

struc Itimerspec
.interval: resb Timespec_size
.value: resb Timespec_size
endstruc

