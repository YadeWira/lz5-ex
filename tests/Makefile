# Makefile for the LZ5 maintenance regression tests.
#
# These tests are specific to the lz5-ex maintenance work; they are not part of
# the upstream test suite. Run with:  make -C tests && make -C tests test
#
#   test_hc_tables    HC tables are zeroed: same output under a poisoned heap
#   test_stream       linked-block streaming round trip, every HC level
#   test_decode_fuzz  the safe decoder against damaged input (best under ASan:
#                     make -C tests test MOREFLAGS="-g -fsanitize=address,undefined")
#   test_bound        no level writes past maxDstSize = LZ5_compressBound(), and
#                     each still succeeds there
#   test_destsize     LZ5_compress_destSize stays within targetDstSize and its
#                     output decodes to the prefix it reports

CC       ?= cc
CFLAGS   ?= -O2 -std=gnu99
WFLAGS   ?= -Wall -Wextra -Wundef -Wshadow -Wcast-align -Wcast-qual -Wstrict-prototypes -pedantic
LZ5DIR   := ../lib
CPPFLAGS := -I$(LZ5DIR) -DXXH_NAMESPACE=LZ5_

LIB_SRC  := $(LZ5DIR)/lz5.c $(LZ5DIR)/lz5hc.c $(LZ5DIR)/lz5frame.c $(LZ5DIR)/xxhash.c
TESTS    := test_hc_tables test_stream test_decode_fuzz test_bound test_destsize

.PHONY: all test clean

all: $(TESTS)

# The library headers are prerequisites too: lz5common.h carries the per-level
# parameter table, and a header-only change must rebuild the tests. Only the .c
# files go to the compiler.
$(TESTS): %: %.c $(LIB_SRC) $(wildcard $(LZ5DIR)/*.h)
	$(CC) $(CFLAGS) $(CPPFLAGS) $(WFLAGS) $(MOREFLAGS) $(LDFLAGS) $(filter %.c,$^) -o $@

# test_hc_tables also runs twice with a poisoned heap, which is the condition
# that exposes uninitialised tables: MALLOC_PERTURB_ makes glibc fill freshly
# allocated blocks with a non-zero pattern.
test: $(TESTS)
	./test_hc_tables
	MALLOC_PERTURB_=170 ./test_hc_tables
	MALLOC_PERTURB_=85  ./test_hc_tables
	./test_stream
	./test_decode_fuzz
	./test_bound
	./test_destsize

clean:
	rm -f $(TESTS)
