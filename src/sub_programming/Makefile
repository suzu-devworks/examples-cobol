# Makefile for sub_programming/
SHARE_DIR = ./shared
BUILD_DIR = build

include ../_build-rules/cobol.common.mk

COBFLAGS += -fstatic-call -Wno-prototypes

$(BIN_DIR)/call_static_subroutine: $(OBJ_DIR)/call_static_subroutine.o $(OBJ_DIR)/subroutine.o
$(BIN_DIR)/call_static_function: $(OBJ_DIR)/call_static_function.o $(OBJ_DIR)/user_defined_function.o
