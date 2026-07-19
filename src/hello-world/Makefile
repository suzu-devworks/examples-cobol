# Compiler and flag settings
COBC = cobc
COBFLAGS = -x -O2

# directory to store the compiled binary
BIN_DIR = bin

# Targets and dependencies
SOURCES = $(wildcard *.cbl)
TARGET = $(BIN_DIR)/hello

.PHONY: all
all: $(TARGET)

$(TARGET): $(SOURCES)
	mkdir -p $(BIN_DIR)
	$(COBC) $(COBFLAGS) -o $@ $^

.PHONY: clean
clean:
	rm -fr $(BIN_DIR)
