ASM = nasm
LD = ld
ASMFLAGS = -felf64
OBJS = main.o req_handler.o
TARGET = server

all: $(TARGET)

$(TARGET): $(OBJS)
	$(LD) -o $@ $^

%.o: %.asm
	$(ASM) $(ASMFLAGS) $<

clean:
	rm -f $(OBJS) $(TARGET)