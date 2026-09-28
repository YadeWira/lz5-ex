/*
 * LZ5 1.5.1 maintenance regression test.
 *
 * Issue: the HC hash tables were allocated with malloc() and left
 * uninitialised. The match search then read stale heap contents as match
 * candidates. This is invisible on a fresh process (the OS hands out
 * already-zeroed pages) but corrupts the match search as soon as the
 * allocator recycles a dirty block, which is what happens on a streaming
 * workload that reuses one LZ5_streamHC_t across many blocks.
 *
 * This test drives exactly that path. It fails (crash or divergent output)
 * on an unpatched build, and passes on a fixed one.
 *
 * Build:  make -C tests
 * Run:    ./tests/test_hc_tables
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lz5.h"
#include "lz5hc.h"

/* One shared stream, many blocks: forces table reuse with dirty memory. */
static int test_stream_reuse(int level)
{
    size_t const nBlocks = 400;
    size_t const srcSize = 200000;
    LZ5_streamHC_t* st;
    char* src;
    char* dst;
    size_t i, total = 0;
    unsigned long long hash = 1469598103934665603ULL;   /* FNV-1a offset basis */

    st = LZ5_createStreamHC(level);
    if (!st) { printf("  createStreamHC(%d) failed\n", level); return 1; }
    src = (char*)malloc(srcSize);
    dst = (char*)malloc(LZ5_compressBound((int)srcSize));
    if (!src || !dst) { printf("  out of memory\n"); free(src); free(dst); LZ5_freeStreamHC(st); return 1; }

    /* Non-trivial, non-repeating content with some internal redundancy so the
     * match search actually has candidates to pick from. */
    for (i = 0; i < srcSize; i++)
        src[i] = (char)(((i * 2654435761u) >> 13) ^ (i >> 9));

    for (i = 0; i < nBlocks; i++) {
        int r = LZ5_compress_HC_continue(st, src, dst, (int)srcSize, (int)LZ5_compressBound((int)srcSize));
        if (r <= 0) {
            printf("  compress_HC_continue failed at block %zu (r=%d)\n", i, r);
            free(src); free(dst); LZ5_freeStreamHC(st);
            return 1;
        }
        { size_t k; for (k = 0; k < (size_t)r; k++) { hash ^= (unsigned char)dst[k]; hash *= 1099511628211ULL; } }
        total += (size_t)r;
    }

    printf("  level %-2d : %zu bytes, hash=%016llx\n", level, total, hash);
    LZ5_freeStreamHC(st);
    free(src); free(dst);
    return 0;
}

/* Repeated one-shot compressions : each call allocates a fresh context, so
 * the recycled block is the previous call's hash table. */
static int test_oneshot_repeat(int level)
{
    size_t const nBlocks = 200;
    size_t const srcSize = 200000;
    char* src;
    char* dst;
    size_t i, total = 0;
    unsigned long long hash = 1469598103934665603ULL;

    src = (char*)malloc(srcSize);
    dst = (char*)malloc(LZ5_compressBound((int)srcSize));
    if (!src || !dst) { printf("  out of memory\n"); free(src); free(dst); return 1; }
    for (i = 0; i < srcSize; i++)
        src[i] = (char)(((i * 2654435761u) >> 13) ^ (i >> 9));

    for (i = 0; i < nBlocks; i++) {
        int r = LZ5_compress_HC(src, dst, (int)srcSize, (int)LZ5_compressBound((int)srcSize), level);
        if (r <= 0) {
            printf("  compress_HC failed at block %zu (r=%d)\n", i, r);
            free(src); free(dst);
            return 1;
        }
        { size_t k; for (k = 0; k < (size_t)r; k++) { hash ^= (unsigned char)dst[k]; hash *= 1099511628211ULL; } }
        total += (size_t)r;
    }

    printf("  level %-2d : %zu bytes, hash=%016llx\n", level, total, hash);
    free(src); free(dst);
    return 0;
}

/* Compress then decompress : the decoded bytes must be identical to the
 * source no matter what the compressor decided. */
static int test_roundtrip(int level)
{
    size_t const srcSize = 300000;
    char* src;
    char* cbuf;
    char* dbuf;
    size_t csize;
    int dsize, rc = 0;

    src  = (char*)malloc(srcSize);
    cbuf = (char*)malloc(LZ5_compressBound((int)srcSize));
    dbuf = (char*)malloc(srcSize);
    if (!src || !cbuf || !dbuf) { printf("  out of memory\n"); rc = 1; goto done; }

    { size_t i; for (i = 0; i < srcSize; i++) src[i] = (char)(((i * 2246822519u) >> 11) ^ (i >> 7)); }

    csize = (size_t)LZ5_compress_HC(src, cbuf, (int)srcSize, (int)LZ5_compressBound((int)srcSize), level);
    if (csize == 0) { printf("  compression failed (r=0)\n"); rc = 1; goto done; }
    dsize = LZ5_decompress_safe(cbuf, dbuf, (int)csize, (int)srcSize);
    if (dsize < 0 || (size_t)dsize != srcSize) { printf("  decompress error: %d\n", dsize); rc = 1; goto done; }
    if (memcmp(src, dbuf, srcSize) != 0) { printf("  ROUND-TRIP MISMATCH\n"); rc = 1; goto done; }
    printf("  level %-2d : %zu -> %zu -> %d bytes, identical\n", level, srcSize, csize, dsize);

done:
    free(src); free(cbuf); free(dbuf);
    return rc;
}

int main(void)
{
    int rc = 0;
    int levels[] = { 1, 6, 9, 12 };
    size_t i;

    printf("HC table initialisation regression tests (LZ5 %d.%d.%d)\n\n",
           LZ5_VERSION_MAJOR, LZ5_VERSION_MINOR, LZ5_VERSION_RELEASE);

    printf("[1] stream reuse (shared LZ5_streamHC_t)\n");
    for (i = 0; i < sizeof(levels)/sizeof(levels[0]); i++)
        rc |= test_stream_reuse(levels[i]);

    printf("\n[2] repeated one-shot (fresh context per block)\n");
    for (i = 0; i < sizeof(levels)/sizeof(levels[0]); i++)
        rc |= test_oneshot_repeat(levels[i]);

    printf("\n[3] compress/decompress round-trip\n");
    for (i = 0; i < sizeof(levels)/sizeof(levels[0]); i++)
        rc |= test_roundtrip(levels[i]);

    printf("\n%s\n", rc ? "FAIL" : "PASS");
    return rc;
}
