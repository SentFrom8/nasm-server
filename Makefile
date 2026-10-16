BUILD_DIR ?= ./build
INCLUDES_DIR ?= ./includes
OBJS = 	main.o \
	listener_event.o \
	client_event.o \
	timer.o \
	min_heap.o \
	conn_handler.o \
	req_handler.o \
	req_parser.o \
	route_parser.o \
	res_handler.o \
	string_handler.o \
	jailer.o \
	file_handler.o \
	signal_handler.o \
	mime_search.o \

TARGET = server

all: $(BUILD_DIR)/$(TARGET)


$(BUILD_DIR)/$(TARGET): $(foreach obj, $(OBJS), $(BUILD_DIR)/$(obj))
	ld -o $@ $^

$(BUILD_DIR)/%.o: %.asm $(BUILD_DIR) $(INCLUDES_DIR)
	nasm -felf64 -g -i $(INCLUDES_DIR) -o $@ $<

$(BUILD_DIR):
	mkdir -p $@

clean:
	rm -rf $(BUILD_DIR)
