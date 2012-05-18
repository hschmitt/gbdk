CC = lcc -Wa-l

OBJS = mem.o #malloc.o free.o realloc.o calloc.o main.o
BIN = mem.gb

all: $(BIN)

$(BIN): $(OBJS)
	$(CC) -o $(BIN) $(OBJS)

clean:
	rm $(BIN) $(OBJS)
