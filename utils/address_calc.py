client_size = 64

heap_size = 8

initial_address = 0x40a0b4 

client_data_addresses = [initial_address + i*client_size for i in range(0, 11)]

with open("Assembly/nasm-server/gdb_output.txt", "r") as file:
    heap = [int(item, base=16) for line in file.readlines() for item in line.split()[1:]]

print([client_data_addresses.index(item) for item in heap[:heap_size]])
