# Compiler and flag settings
COBC = cobc
COBFLAGS = -O2

# directory to store the compiled binary
BIN_DIR   = bin
OBJ_DIR   = obj
COPY_DIR  = ../copies
SHARE_DIR = ../shared

# Targets and dependencies
SOURCES = $(wildcard *.cbl)
OBJS    = $(SOURCES:%.cbl=$(OBJ_DIR)/%.o)
TARGETS = $(SOURCES:%.cbl=$(BIN_DIR)/%)

.PHONY: all
all: $(TARGETS)

$(BIN_DIR)/%: $(OBJ_DIR)/%.o | $(BIN_DIR)
	$(COBC) -x $(COBFLAGS) -o $@ $<

$(OBJ_DIR)/%.o: %.cbl | $(OBJ_DIR)
	$(COBC) -x -c $(COBFLAGS) -I $(COPY_DIR) -o $@ $<

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

.SECONDARY: $(SOURCES:%.cbl=$(OBJ_DIR)/%.o)

.PHONY: clean
clean:
	rm -fr $(BIN_DIR) $(OBJ_DIR)
