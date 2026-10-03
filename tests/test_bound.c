/*
 * The compressors must never write past maxDstSize, at any level, even when
 * maxDstSize is the documented LZ5_compressBound(srcSize).
 *
 * LZ5_compressBound() is LZ4's bound, and LZ5's codewords can exceed it: a
 * 3-byte match with a 24-bit offset takes 4 output bytes. On base64 - 64
 * symbols, so almost every 3- and 4-byte string has occurred somewhere in a
 * multi-megabyte window - the price-based parsers of levels 9-13 produced
 * about 2% more than the bound on 2 MB of input, and with the output checks
 * switched off for buffers >= LZ5_compressBound() that was a heap overflow.
 *
 * Each level compresses 2 MB of base64 into a buffer of exactly
 * LZ5_compressBound() bytes, followed by canary bytes. The result must be
 * either 0 (it did not fit) or a size within the bound that round-trips, and
 * the canary must be intact. Under AddressSanitizer the overflow is also
 * reported directly.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lz5.h"
#include "lz5hc.h"

#define CANARY      0x5A
#define CANARY_SIZE 4096

static unsigned long long rng = 0x6A09E667F3BCC908ULL;
static unsigned rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return (unsigned)(rng >> 32);
}

int main(void)
{
    static const char b64[] = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    const int n = 2 << 20;
    const int bound = LZ5_compressBound(n);
    char* const src = (char*)malloc((size_t)n);
    char* const back = (char*)malloc((size_t)n);
    unsigned char* const dst = (unsigned char*)malloc((size_t)bound + CANARY_SIZE);
    int i, lvl, bad = 0, didNotFit = 0;

    if (!src || !back || !dst) { printf("out of memory\n"); return 2; }
    for (i = 0; i < n; i++) src[i] = ((i % 77) == 76) ? '\n' : b64[rnd() % 64];

    for (lvl = 0; lvl <= LZ5HC_MAX_CLEVEL; lvl++) {
        int cs, k;
        memset(dst + bound, CANARY, CANARY_SIZE);
        cs = lvl ? LZ5_compress_HC(src, (char*)dst, n, bound, lvl)
                 : LZ5_compress_default(src, (char*)dst, n, bound);
        for (k = 0; k < CANARY_SIZE; k++)
            if (dst[bound + k] != CANARY) { printf("  level %2d: wrote past maxDstSize\n", lvl); bad++; break; }
        if (cs > bound) { printf("  level %2d: returned %d, more than maxDstSize %d\n", lvl, cs, bound); bad++; }
        else if (cs == 0) didNotFit++;
        else if (LZ5_decompress_safe((const char*)dst, back, cs, n) != n || memcmp(back, src, (size_t)n)) {
            printf("  level %2d: does not round-trip\n", lvl); bad++;
        }
    }

    printf("output bound: %d levels, %d did not fit in LZ5_compressBound() (returned 0), %d problems\n",
           LZ5HC_MAX_CLEVEL + 1, didNotFit, bad);
    free(src); free(back); free(dst);
    if (bad) { printf("FAIL\n"); return 1; }
    printf("PASS\n");
    return 0;
}
