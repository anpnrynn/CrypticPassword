# Top-level helper Makefile for algorithm tests and source packaging.
# Platform GUI builds live under windows/, linux/, and mac/.

CC ?= gcc
CFLAGS ?= -O2 -Wall -Wextra -std=c11
OUTDIR := build

.PHONY: all core-test mac-swift mac-swift-test mac-java package clean

all: core-test

$(OUTDIR):
	mkdir -p $(OUTDIR)

core-test: $(OUTDIR)
	$(CC) $(CFLAGS) -Icommon tests/test_core.c common/crypticpassword_core.c -o $(OUTDIR)/crypticpassword_core_test
	$(OUTDIR)/crypticpassword_core_test

mac-swift:
	$(MAKE) -C mac app

mac-swift-test:
	$(MAKE) -C mac swift-core-test

mac-java:
	$(MAKE) -C mac/swing all

package:
	./scripts/package_source.sh

clean:
	rm -rf $(OUTDIR)
	$(MAKE) -C mac clean || true
	$(MAKE) -C linux clean || true
