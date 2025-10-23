#include <stdio.h>
#include <sys/epoll.h>
#include <stddef.h>
#include <time.h>

int main() {
    printf("Size of epoll_event: %zu\n", sizeof(struct epoll_event));
    printf("Offset of events: %zu\n", offsetof(struct epoll_event, events));
    printf("Offset of data: %zu\n", offsetof(struct epoll_event, data));
    printf("Size of the timespec struct: %zu\n", sizeof(struct timespec));
    return 0;
}