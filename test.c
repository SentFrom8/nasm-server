#include <stdio.h>
#include <sys/epoll.h>
#include <stddef.h>

int main() {
    printf("Size of epoll_event: %zu\n", sizeof(struct epoll_event));
    printf("Offset of events: %zu\n", offsetof(struct epoll_event, events));
    printf("Offset of data: %zu\n", offsetof(struct epoll_event, data));
    return 0;
}