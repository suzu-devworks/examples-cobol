# Makefile for generating/
BUILD_DIR = build

include ../_build-rules/cobol.common.mk

COBFLAGS += -fstatic-call

# for DEBUG
COBFLAGS += -O0 -debug -DDEBUG -g

$(BIN_DIR)/generate_uuid: private COBFLAGS += -luuid
$(BIN_DIR)/generate_uuid: $(OBJ_DIR)/generate_uuid.o $(OBJ_DIR)/gen_uuid.o
