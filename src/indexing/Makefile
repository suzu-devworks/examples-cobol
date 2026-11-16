# Makefile for indexing/
BUILD_DIR = build

include ../_build-rules/cobol.common.mk

# for DEBUG
COBFLAGS += -O0 -debug -DDEBUG -g

$(OBJ_DIR)/build_emp_isam.o $(OBJ_DIR)/update_salary_isam.o \
	$(OBJ_DIR)/export_emp_isam.o: $(COPY_DIR)/emp_salary_rec.cpy \
	$(COPY_DIR)/emp_rec.cpy
