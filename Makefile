# Get the path where the Makefile is located (src/*/Makefile),
SUBDIRS := $(dir $(wildcard src/*/Makefile))

# default target
all: $(SUBDIRS)

# Run make in each subdirectory
$(SUBDIRS):
	$(MAKE) -C $@

# Call make clean on each subdirectory
clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

.PHONY: all clean $(SUBDIRS)
