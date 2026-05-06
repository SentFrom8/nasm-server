ASM = nasm
LD = ld
ASMFLAGS = -felf64
OBJS = main.o listener_event.o client_event.o timer.o min_heap.o conn_handler.o req_handler.o req_parser.o route_parser.o res_handler.o string_handler.o jailer.o file_handler.o signal_handler.o
TARGET = server

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) -o $@ $^

%.o: %.asm
	$(ASM) $(ASMFLAGS) $<

clean:
	rm -f $(OBJS) $(TARGET)
