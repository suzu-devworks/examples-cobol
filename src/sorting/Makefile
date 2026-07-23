# Compiler and flag settings
COBC = cobc
COBFLAGS = -Wall -Wextra -Wstrict-typing -Wno-terminator -fstatic-call
# for DEBUG
COBFLAGS += -O0 -debug -DDEBUG -g

# Directory settings
COPY_DIR  = ../copies
SHARE_DIR = ../shared

BUILD_DIR = build
OBJ_DIR   = $(BUILD_DIR)
BIN_DIR   = $(BUILD_DIR)/bin

# Directory paths relative to OBJ_DIR (paths used after `cd $(OBJ_DIR)`)s
REL_COPY  = ../$(COPY_DIR)
REL_SHARE = ../$(SHARE_DIR)

# Targets and dependencies
SOURCES = $(wildcard *.cbl)
OBJS    = $(SOURCES:%.cbl=$(OBJ_DIR)/%.o)
TARGETS = $(SOURCES:%.cbl=$(BIN_DIR)/%)

.PHONY: all
all: $(TARGETS)

$(BIN_DIR)/%: $(OBJ_DIR)/%.o | $(BIN_DIR)
	$(COBC) -x $(COBFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: %.cbl | $(OBJ_DIR)
	cd $(OBJ_DIR) && $(COBC) -x -c $(COBFLAGS) -I $(REL_COPY) -o $(notdir $@) $(CURDIR)/$<

$(OBJ_DIR)/%.o: $(SHARE_DIR)/%.cbl | $(OBJ_DIR)
	cd $(OBJ_DIR) && $(COBC) -c $(COBFLAGS) -I $(REL_COPY) -o $(notdir $@) $(CURDIR)/$<

$(OBJ_DIR) $(BIN_DIR):
	mkdir -p $@

$(BIN_DIR)/sort_records_legacy: $(OBJ_DIR)/sort_records_legacy.o  $(OBJ_DIR)/quick_sort.o

.SECONDARY: $(SOURCES:%.cbl=$(OBJ_DIR)/%.o)

.PHONY: clean
clean:
	rm -fr $(BIN_DIR) $(OBJ_DIR)
