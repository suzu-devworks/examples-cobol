# src/ の直下にあるすべてのディレクトリを見つける
SUBDIRS := $(wildcard src/*/)

# デフォルトターゲット
all: $(SUBDIRS)

# 各サブディレクトリで make を実行
$(SUBDIRS):
	$(MAKE) -C $@

# 各サブディレクトリの make clean を呼び出す
clean:
	@for dir in $(SUBDIRS); do \
		$(MAKE) -C $$dir clean; \
	done

.PHONY: all clean $(SUBDIRS)

