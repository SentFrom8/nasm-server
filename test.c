#include <stdio.h>
#include <sys/epoll.h>
#include <stddef.h>
#include <time.h>
#include <sys/timerfd.h>
#include <sys/types.h>
#include <sys/socket.h>

int main() {
    printf("Size of epoll_event: %zu\n", sizeof(struct epoll_event));
    printf("Offset of events: %zu\n", offsetof(struct epoll_event, events));
    printf("Offset of data: %zu\n", offsetof(struct epoll_event, data));
    printf("Size of the timespec struct: %zu\n", sizeof(struct timespec));
    printf("Value of CLOCK_REALTIME: %d\n", CLOCK_MONOTONIC);
    printf("Value of TFD_NONBLOCK: %d\n", TFD_NONBLOCK);
    printf("Value of TFD_CLOEXEC: %d\n", TFD_CLOEXEC);
    printf("Value of SOCK_NONBLOCK: %d\n", SOCK_NONBLOCK);
    printf("Value of SOCK_CLOEXEC: %d\n", SOCK_CLOEXEC);
    printf("Value of TFD_TIMER_ABSTIME: %d\n", TFD_TIMER_ABSTIME);
    return 0;
}