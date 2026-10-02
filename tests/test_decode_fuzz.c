/*
 * Robustness of the safe decoder against damaged input.
 *
 * Compresses a synthetic input at every level, then feeds LZ5_decompress_safe
 * thousands of corrupted variants: random byte changes, truncation and output
 * buffers that are too small. The decoder may reject them (negative return) or
 * decode something, but it must never write past the output buffer, and the
 * undamaged stream must still decode exactly.
 *
 * Input and output are allocated at their exact size, so under AddressSanitizer
 * any read past the input or write past the output is reported. Without a
 * sanitizer the canary bytes behind the output buffer still catch overwrites.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lz5.h"
#include "lz5hc.h"

#define CANARY      0xA5
#define CANARY_SIZE 64

static unsigned long long rng = 0x2545F4914F6CDD1DULL;
static unsigned rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return (unsigned)(rng >> 32);
}

static size_t make_input(char* dst, size_t cap)
{
    static const char* const words[] = { "the", "lz5", "offset", "match", "literal",
                                         "token", "block", "frame" };
    size_t n = 0;
    while (n + 256 < cap) {   /* the longest single step writes 200 bytes */
        switch (rnd() % 3) {
        case 0:  {   /* argument evaluation order is unspecified: draw in a fixed order */
                     const char* const w1 = words[rnd() % 8];
                     const char* const w2 = words[rnd() % 8];
                     const unsigned v = rnd() % 1000;
                     n += (size_t)sprintf(dst + n, "%s %s %u\n", w1, w2, v);
                 } break;
        case 1:  { int k, r = 1 + (int)(rnd() % 40); for (k = 0; k < r; k++) dst[n++] = (char)rnd(); } break;   /* incompressible run */
        default: { int k, r = 1 + (int)(rnd() % 200); for (k = 0; k < r; k++) dst[n++] = 'z'; } break;      /* long repeat */
        }
    }
    return n;
}

int main(void)
{
    const size_t cap = 1 << 16;
    const int iters = 400;
    char* const src = (char*)malloc(cap);
    size_t n;
    int lvl, it, bad = 0, rejected = 0, decoded = 0;

    if (!src) { printf("out of memory\n"); return 2; }
    n = make_input(src, cap);

    for (lvl = 0; lvl <= LZ5HC_MAX_CLEVEL; lvl++) {
        const int bound = LZ5_compressBound((int)n);
        char* const comp = (char*)malloc((size_t)bound);
        int cs;
        if (!comp) { printf("out of memory\n"); return 2; }
        cs = lvl ? LZ5_compress_HC(src, comp, (int)n, bound, lvl) : LZ5_compress_default(src, comp, (int)n, bound);
        if (cs <= 0) { printf("  level %d: compression failed\n", lvl); bad++; free(comp); continue; }

        /* the undamaged stream decodes exactly */
        {
            char* const out = (char*)malloc(n);
            if (!out || LZ5_decompress_safe(comp, out, cs, (int)n) != (int)n || memcmp(out, src, n)) {
                printf("  level %d: clean stream does not round-trip\n", lvl); bad++;
            }
            free(out);
        }

        for (it = 0; it < iters; it++) {
            int len = cs, k, r;
            const int nmut = 1 + (int)(rnd() % 4);
            size_t osz = n;
            char* in;
            unsigned char* out;

            if (rnd() % 3 == 0) len = 1 + (int)(rnd() % (unsigned)cs);              /* truncated */
            if (rnd() % 4 == 0) osz = 1 + rnd() % (unsigned)n;                       /* output too small */

            in = (char*)malloc((size_t)len);                                         /* exact size */
            out = (unsigned char*)malloc(osz + CANARY_SIZE);
            if (!in || !out) { printf("out of memory\n"); return 2; }
            memcpy(in, comp, (size_t)len);
            for (k = 0; k < nmut; k++) in[rnd() % (unsigned)len] = (char)rnd();
            memset(out + osz, CANARY, CANARY_SIZE);

            r = LZ5_decompress_safe(in, (char*)out, len, (int)osz);

            if (r > (int)osz) { printf("  level %d: returned %d for a %lu-byte buffer\n", lvl, r, (unsigned long)osz); bad++; }
            for (k = 0; k < CANARY_SIZE; k++)
                if (out[osz + (size_t)k] != CANARY) { printf("  level %d: wrote past the output buffer\n", lvl); bad++; break; }
            if (r < 0) rejected++; else decoded++;
            free(in); free(out);
        }
        free(comp);
    }

    printf("decoder fuzz: %d damaged streams, %d rejected, %d decoded, %d problems\n",
           (LZ5HC_MAX_CLEVEL + 1) * iters, rejected, decoded, bad);
    free(src);
    if (bad) { printf("FAIL\n"); return 1; }
    printf("PASS\n");
    return 0;
}
