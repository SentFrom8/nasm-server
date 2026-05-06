from typing import override
import gdb
import struct

# struc Client
#     .fd: resq 1
#     .read_buff: resq 1
#     .req_len: resq 1
#     .req_file_fd: resq 1
#     .res_headers_iov resb Iovec_size
#     .res_headers_sent resq 1
#     .res_file_sent: resq 1
#     .time: resq 1
#     .heap_index: resd 1
#     .flags: resd 1
# endstruc

def print_client_formatted(client: tuple):
    output = ["struc Client"]
    output.append("    .fd: " + str(client[0]))
    output.append("    .read_buff: " + str(client[1]))
    output.append("    .req_len: " + str(client[2]))
    output.append("    .req_file_fd: " + str(client[3]))
    output.append("    .res_headers_iov_base: " + str(client[4]))
    output.append("    .res_headers_iov_len: " + str(client[5]))
    output.append("    .res_headers_sent: " + str(client[6]))
    output.append("    .res_file_sent: " + str(client[7]))
    output.append("    .time: " + str(client[8]))
    output.append("    .heap_index: " + str(client[9]))
    output.append("    .flags: " + str(client[10]))
    output.append("endstruc")
    print("\n".join(output))

class PrintClient(gdb.Command):
    def __init__(self):
        super(PrintClient, self).__init__("print_client", gdb.COMMAND_USER)

    @override
    def invoke(self, argument: str, from_tty: bool) -> None:
        args = gdb.string_to_argv(argument)
        addr = gdb.parse_and_eval(args[0])

        current = gdb.selected_inferior()
        test = current.read_memory(addr, 80)
        print_client_formatted(struct.unpack("<qqqqqqqqqii", test))

class PrintHeapClients(gdb.Command):
    def __init__(self):
        super(PrintHeapClients, self).__init__("print_heap", gdb.COMMAND_USER)

    @override
    def invoke(self, argument: str, from_tty: bool) -> None:
        args = gdb.string_to_argv(argument)
        heap_addr = int(gdb.execute("info address heap", to_string=True).split()[4], 16)
        if (len(args)): size = int(args[0])
        else:
            size = int(gdb.execute("p (int)heap_size", to_string=True).split()[-1])
        
        for i in range(size):
            client_addr = gdb.execute(f"x/gx {heap_addr + i*8}", to_string=True).split()[-1]
            gdb.execute(f"print_client {client_addr}")
            print("\n==============================\n")


PrintClient()
PrintHeapClients()

