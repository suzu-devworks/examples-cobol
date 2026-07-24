# Makefile for sorting/
BUILD_DIR = build

include ../_build-rules/cobol.common.mk

COBFLAGS += -fstatic-call

# for DEBUG
COBFLAGS += -O0 -debug -DDEBUG -g

$(BIN_DIR)/sort_records_legacy: $(OBJ_DIR)/sort_records_legacy.o $(OBJ_DIR)/quick_sort.o
