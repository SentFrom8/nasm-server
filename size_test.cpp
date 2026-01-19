#include <iostream>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <linux/limits.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <sys/timerfd.h>

int main(){
	std::cout << "Size of size_t: " << sizeof(std::size_t) << '\n';
	std::cout << "Size of unshare flags: " << sizeof(CLONE_FILES) << '\n';
	std::cout << "Value of unshare flags: "  << '\n';
	std::cout << '\t' << "CLONE_FILES: " << CLONE_FILES << '\n';
	std::cout << '\t' << "CLONE_FS: " << CLONE_FS << '\n';
	std::cout << '\t' << "CLONE_NEWNS: " << CLONE_NEWNS << '\n';
	std::cout << '\t' << "CLONE_NEWPID: " << CLONE_NEWPID << '\n';
	std::cout << '\t' << "CLONE_NEWUSER: " << CLONE_NEWUSER << '\n';
	std::cout << "Value of O_WRONLY: " << O_WRONLY << '\n';
	std::cout << "Value of O_RDWR: " << O_RDWR << '\n';
	std::cout << "Value of MS_PRIVATE: " << MS_PRIVATE << '\n';
	std::cout << "Value of MS_REC: " << MS_REC << '\n';
	std::cout << "Value of MS_BIND: " << MS_BIND << '\n';
	std::cout << "Value of MS_RDONLY: " << MS_RDONLY << '\n';
	std::cout << "Value of MNT_DETACH: " << MNT_DETACH << '\n';
	std::cout << "Value of PATH_MAX: " << PATH_MAX << '\n';
	std::cout << "Value of SOCK_STREAM: " << SOCK_STREAM << '\n';
	std::cout << "Value of SOCK_NONBLOCK: " << SOCK_NONBLOCK << '\n';
	std::cout << "Value of SOCK_NONBLOCK: " << SOCK_NONBLOCK << '\n';
	std::cout << "Value of EPOLLIN: " << EPOLLIN << '\n';
	std::cout << "Value of EPOLLOUT: " << EPOLLOUT << '\n';
	std::cout << "Value of EPOLLERR: " << EPOLLERR << '\n';
	std::cout << "Value of EPOLLHUP: " << EPOLLHUP << '\n';
	std::cout << "Value of EPOLLRDHUP: " << EPOLLRDHUP << '\n';
	std::cout << "Value of CLOCK_MONOTONIC: " << CLOCK_MONOTONIC << '\n';
	std::cout << "Value of TFD_NONBLOCK: " << TFD_NONBLOCK << '\n';
	std::cout << "Value of TFD_TIMER_ABSTIME: " << TFD_TIMER_ABSTIME << '\n';
	std::cout << "Value of EPOLL_CTL_ADD: " << EPOLL_CTL_ADD << '\n';
	std::cout << "Value of EPOLL_CTL_MOD: " << EPOLL_CTL_MOD << '\n';
	std::cout << "Value of EPOLL_CTL_DEL: " << EPOLL_CTL_DEL << '\n';

	return 0;
}
