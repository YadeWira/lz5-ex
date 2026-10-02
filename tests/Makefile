# Makefile for the LZ5 maintenance regression tests.
#
# These tests are specific to the 1.5.1 maintenance work; they are not part of
# the upstream test suite. Run with:  make -C tests && make -C tests test

CC       ?= cc
CFLAGS   ?= -O2 -std=gnu99
WFLAGS   ?= -Wall -Wextra -Wundef -Wshadow -Wcast-align -Wcast-qual -Wstrict-prototypes -pedantic
LZ5DIR   := ../lib
CPPFLAGS := -I$(LZ5DIR) -DXXH_NAMESPACE=LZ5_

LIB_SRC  := $(LZ5DIR)/lz5.c $(LZ5DIR)/lz5hc.c $(LZ5DIR)/lz5frame.c $(LZ5DIR)/xxhash.c
TESTS    := test_hc_tables

.PHONY: all test clean

all: $(TESTS)

# The library headers are prerequisites too: lz5common.h carries the per-level
# parameter table, and a header-only change must rebuild the test. Only the .c
# files go to the compiler.
test_hc_tables: test_hc_tables.c $(LIB_SRC) $(wildcard $(LZ5DIR)/*.h)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(WFLAGS) $(LDFLAGS) $(filter %.c,$^) -o $@

# Runs the tests twice with a poisoned heap, which is the condition that
# exposes uninitialised tables. MALLOC_PERTURB_ makes glibc fill freshly
# allocated blocks with a non-zero pattern.
test: $(TESTS)
	./$(TESTS)
	MALLOC_PERTURB_=170 ./$(TESTS)
	MALLOC_PERTURB_=85  ./$(TESTS)

clean:
	rm -f $(TESTS)
