# Shared GNU COBOL build rules for src/*/Makefile.
#
# How to use from each module Makefile:
# 1) Set local overrides before include.
# 2) Keep only module-specific dependencies after include.
#
# Minimal examples:
# - One executable per source file (default):
#     COBFLAGS = -O2 -Wall -Wextra -Wstrict-typing -Wno-terminator
#     include ../_build-rules/cobol.common.mk
#
# Overridable variables (set before include):
# - COBC               : COBOL compiler command (default: cobc)
# - COBFLAGS           : Compiler/linker flags
# - COPY_DIR           : Copybook directory for -I
# - SHARE_DIR          : Shared source directory used by shared rule
# - BUILD_DIR          : If set, OBJ_DIR=$(BUILD_DIR), BIN_DIR=$(BUILD_DIR)/bin
# - OBJ_DIR, BIN_DIR   : Output directories (can be set explicitly)
# - SOURCES            : Source list (default: *.cbl)
# - TARGETS, OBJS      : Generated lists (advanced override)
# - CLEAN_DIRS         : Directories removed by clean
# - REL_COPY, REL_SHARE: Paths used from $(OBJ_DIR); default switches by BUILD_DIR

# Compiler defaults
COBC ?= cobc
COBFLAGS ?= -O2 -Wall -Wextra -Wstrict-typing -Wno-terminator

# Directory defaults
COPY_DIR ?= ../copies
SHARE_DIR ?= ../shared
BUILD_DIR ?=

OBJ_DIR ?= $(if $(BUILD_DIR),$(BUILD_DIR),obj)
BIN_DIR ?= $(if $(BUILD_DIR),$(BUILD_DIR)/bin,bin)

# Compile from $(OBJ_DIR) and switch REL_* paths by BUILD_DIR.
# - BUILD_DIR empty  : obj/   -> ../copies, ../shared
# - BUILD_DIR set    : build/ -> ../../copies, ../../shared (via extra ../ prefix)
REL_COPY ?= $(if $(BUILD_DIR),../$(COPY_DIR),$(COPY_DIR))
REL_SHARE ?= $(if $(BUILD_DIR),../$(SHARE_DIR),$(SHARE_DIR))

SOURCES ?= $(wildcard *.cbl)
OBJS ?= $(SOURCES:%.cbl=$(OBJ_DIR)/%.o)
TARGETS ?= $(SOURCES:%.cbl=$(BIN_DIR)/%)

.PHONY: all clean

all: $(TARGETS)

$(BIN_DIR)/%: $(OBJ_DIR)/%.o | $(BIN_DIR)
	$(COBC) -x $(COBFLAGS) -o $@ $^

$(OBJ_DIR)/%.o: %.cbl | $(OBJ_DIR)
	cd $(OBJ_DIR) && $(COBC) -x -c $(COBFLAGS) -I $(REL_COPY) -o $(notdir $@) $(CURDIR)/$<

$(OBJ_DIR)/%.o: $(SHARE_DIR)/%.cbl | $(OBJ_DIR)
	cd $(OBJ_DIR) && $(COBC) -c $(COBFLAGS) -I $(REL_COPY) -o $(notdir $@) $(CURDIR)/$<

$(BIN_DIR) $(OBJ_DIR):
	mkdir -p $@

.SECONDARY: $(OBJS)

CLEAN_DIRS ?= $(BIN_DIR) $(OBJ_DIR)

clean:
	rm -fr $(CLEAN_DIRS)
