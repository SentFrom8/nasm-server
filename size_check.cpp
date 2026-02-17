#include <iostream>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>
#include <linux/limits.h>
#include <sys/socket.h>
#include <sys/epoll.h>
#include <sys/timerfd.h>
#include <sys/stat.h>
#include <signal.h>

void enclose_text(std::string text){
	std::cout << '\n' << std::string(30, '=') << '\n' << text << '\n' << std::string(30, '=') << '\n';

}

int main(){
	std::cout << "Size of size_t: " << sizeof(std::size_t) << '\n';
	std::cout << "Size of off_t: " << sizeof(off_t) << '\n';
	std::cout << "Size of unshare flags: " << sizeof(CLONE_FILES) << '\n';

	enclose_text("sys_unshare");
	std::cout << "Value of CLONE_FILES: " << CLONE_FILES << '\n';
	std::cout << "Value of CLONE_FS: " << CLONE_FS << '\n';
	std::cout << "Value of CLONE_NEWNS: " << CLONE_NEWNS << '\n';
	std::cout << "Value of CLONE_NEWPID: " << CLONE_NEWPID << '\n';
	std::cout << "Value of CLONE_NEWUSER: " << CLONE_NEWUSER << '\n';

	enclose_text("sys_open");
	std::cout << "Value of O_RDONLY: " << O_RDONLY << '\n';
	std::cout << "Value of O_WRONLY: " << O_WRONLY << '\n';
	std::cout << "Value of O_RDWR: " << O_RDWR << '\n';

	enclose_text("sys_mount");
	std::cout << "Value of MS_PRIVATE: " << MS_PRIVATE << '\n';
	std::cout << "Value of MS_REC: " << MS_REC << '\n';
	std::cout << "Value of MS_BIND: " << MS_BIND << '\n';
	std::cout << "Value of MS_RDONLY: " << MS_RDONLY << '\n';

	enclose_text("sys_umount");
	std::cout << "Value of MNT_DETACH: " << MNT_DETACH << '\n';
	std::cout << "Value of PATH_MAX: " << PATH_MAX << '\n';

	enclose_text("sys_socket");
	std::cout << "Value of SOCK_STREAM: " << SOCK_STREAM << '\n';
	std::cout << "Value of SOCK_NONBLOCK: " << SOCK_NONBLOCK << '\n';
	std::cout << "Value of SOCK_NONBLOCK: " << SOCK_NONBLOCK << '\n';

	enclose_text("sys_epoll");
	std::cout << "Value of EPOLLIN: " << EPOLLIN << '\n';
	std::cout << "Value of EPOLLOUT: " << EPOLLOUT << '\n';
	std::cout << "Value of EPOLLERR: " << EPOLLERR << '\n';
	std::cout << "Value of EPOLLHUP: " << EPOLLHUP << '\n';
	std::cout << "Value of EPOLLRDHUP: " << EPOLLRDHUP << '\n';

	enclose_text("sys_timerfd");
	std::cout << "Value of CLOCK_MONOTONIC: " << CLOCK_MONOTONIC << '\n';
	std::cout << "Value of TFD_NONBLOCK: " << TFD_NONBLOCK << '\n';
	std::cout << "Value of TFD_TIMER_ABSTIME: " << TFD_TIMER_ABSTIME << '\n';

	enclose_text("sys_epollctl");
	std::cout << "Value of EPOLL_CTL_ADD: " << EPOLL_CTL_ADD << '\n';
	std::cout << "Value of EPOLL_CTL_MOD: " << EPOLL_CTL_MOD << '\n';
	std::cout << "Value of EPOLL_CTL_DEL: " << EPOLL_CTL_DEL << '\n';

	enclose_text("stat struct");
    std::cout << "Size of dev_t: " << sizeof(dev_t) << "\n";
	std::cout << "Offset of st_dev: " << offsetof(struct stat, st_dev) << "\n";
    std::cout << "Size of ino_t: " << sizeof(ino_t) << "\n";
	std::cout << "Offset of st_ino: " << offsetof(struct stat, st_ino) << "\n";
    std::cout << "Size of mode_t: " << sizeof(mode_t) << "\n";
	std::cout << "Offset of st_mode: " << offsetof(struct stat, st_mode) << "\n";
    std::cout << "Size of nlink_t: " << sizeof(nlink_t) << "\n";
	std::cout << "Offset of st_nlink: " << offsetof(struct stat, st_nlink) << "\n";
    std::cout << "Size of uid_t: " << sizeof(uid_t) << "\n";
	std::cout << "Offset of st_uid: " << offsetof(struct stat, st_uid) << "\n";
    std::cout << "Size of gid_t: " << sizeof(gid_t) << "\n";
	std::cout << "Offset of st_gid: " << offsetof(struct stat, st_gid) << "\n";
    std::cout << "Size of dev_t (rdev): " << sizeof(dev_t)     << "\n";
	std::cout << "Offset of st_rdev: " << offsetof(struct stat, st_rdev) << "\n";
    std::cout << "Size of off_t: " << sizeof(off_t) << "\n";
	std::cout << "Offset of st_size: " << offsetof(struct stat, st_size) << "\n";
    std::cout << "Size of blksize_t: " << sizeof(blksize_t) << "\n";
	std::cout << "Offset of st_blksize: " << offsetof(struct stat, st_blksize) << "\n";
    std::cout << "Size of blkcnt_t: " << sizeof(blkcnt_t) << "\n";
	std::cout << "Offset of st_blocks: " << offsetof(struct stat, st_blocks) << "\n";
	std::cout << "Offset of __pad0: " << offsetof(struct stat, __pad0) << "\n";
	std::cout << "Offset of st_atim: " << offsetof(struct stat, st_atim) << "\n";
	std::cout << "Offset of st_mtim: " << offsetof(struct stat, st_mtim) << "\n";
	std::cout << "Offset of st_ctim: " << offsetof(struct stat, st_ctim) << "\n";
    std::cout << "Size of stat struct: " << sizeof(struct stat) << "\n";

	enclose_text("sigaction struct");
	std::cout << "Size of sigaction: " << sizeof(struct sigaction) << '\n';
	std::cout << "Offset of sa_handler: " << offsetof(struct sigaction, sa_handler) << '\n';
	std::cout << "Offset of sa_sigaction: " << offsetof(struct sigaction, sa_sigaction) << '\n';
	std::cout << "Size of sigset_t: " << sizeof(sigset_t) << '\n';
	std::cout << "Offset of sa_mask: " << offsetof(struct sigaction, sa_mask) << '\n';
	std::cout << "Offset of sa_flags: " << offsetof(struct sigaction, sa_flags) << '\n';
	std::cout << "Offset of sa_restorer: " << offsetof(struct sigaction, sa_restorer) << '\n';
	std::cout << "Value of SIG_DLF: " << SIG_DFL << '\n';
	std::cout << "Value of SIG_IGN: " << SIG_IGN << '\n';
	std::cout << "Value of SIGINT: " << SIGINT << '\n';
	std::cout << "Value of SIGPIPE: " << SIGPIPE << '\n';
	std::cout << "Value of SA_RESTART: " << SA_RESTART << '\n';
	std::cout << "Value of SA_SIGINFO: " << SA_SIGINFO << '\n';


	return 0;
}
