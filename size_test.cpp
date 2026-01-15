#include <iostream>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mount.h>

int main(){
	std::cout << "Size of size_t: " << sizeof(std::size_t) << '\n';
	std::cout << "Size of unshare flags" << sizeof(CLONE_FILES) << '\n';
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
	std::cout << "Value of MNT_DETACH: " << MNT_DETACH << '\n';
	return 0;
}
