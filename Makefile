ASM = nasm
LD = ld
ASMFLAGS = -felf64
OBJS = main.o listener_event.o client_event.o timer.o min_heap_timespec.o conn_handler.o req_handler.o req_parser.o route_parser.o res_handler.o
TARGET = server

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) -o $@ $^

%.o: %.asm
	$(ASM) $(ASMFLAGS) $<

clean:
	rm -f $(OBJS) $(TARGET)