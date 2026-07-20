# Compiler and flag settings
COBC = cobc
COBFLAGS = -x -O2

# directory to store the compiled binary
BIN_DIR = bin
COPY_DIR = ../copies

# Targets and dependencies
SOURCES = $(wildcard *.cbl)
TARGETS := $(SOURCES:%.cbl=$(BIN_DIR)/%)

.PHONY: all
all: $(TARGETS)

$(BIN_DIR)/%: %.cbl | $(BIN_DIR)
	$(COBC) $(COBFLAGS) -I $(COPY_DIR) -o $@ $<

$(BIN_DIR):
	mkdir -p $(BIN_DIR)

.PHONY: clean
clean:
	rm -fr $(BIN_DIR)
