# Makefile for database/
BUILD_DIR = build
SHARE_DIR = ./shared

include ../_build-rules/cobol.common.mk

COBFLAGS += -l:libsqlite3.so.0

$(OBJ_DIR)/read_dept_summary_db.o $(OBJ_DIR)/write_dept_summary_db.o: \
	$(COPY_DIR)/sqlite.cpy

SQLITE_OBJS = $(OBJ_DIR)/sqlite_open.o $(OBJ_DIR)/sqlite_close.o \
	$(OBJ_DIR)/sqlite_exec.o $(OBJ_DIR)/sqlite_prepare.o \
	$(OBJ_DIR)/sqlite_step.o $(OBJ_DIR)/sqlite_set_status.o \
	$(OBJ_DIR)/create_dept_summary_table.o

$(SQLITE_OBJS): $(COPY_DIR)/sqlite.cpy

$(BIN_DIR)/read_dept_summary_db: $(SQLITE_OBJS)
$(BIN_DIR)/write_dept_summary_db: $(SQLITE_OBJS)

.PHONY: test
test: $(BIN_DIR)/test_sqlite_wrappers
	$<

$(BIN_DIR)/test_sqlite_wrappers: tests/test_sqlite_wrappers.cbl \
		$(SQLITE_OBJS) | $(BIN_DIR)
	$(COBC) -x $(COBFLAGS) -I $(COPY_DIR) -o $@ $^
