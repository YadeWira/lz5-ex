/*
 * LZ5_compress_destSize fills a buffer of exactly targetDstSize bytes with as
 * much of the input as fits. Its size estimates came from LZ4, whose length
 * fields are 4 bits (mask 15); LZ5's are 3 bits (7) and, for some codewords,
 * 2 bits (3). So it wrote one byte past targetDstSize when the last literal
 * run was 7 to 14 bytes long, and a clamped match length could need a byte the
 * buffer did not have - giving streams no decoder accepts.
 *
 * For several kinds of input and many target sizes, with dst allocated at
 * exactly targetDstSize plus canary bytes: the result must fit, the canary
 * must be intact, and the output must decode to exactly the prefix of the
 * input the function reports having consumed.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lz5.h"

#define CANARY      0xC3
#define CANARY_SIZE 64

static unsigned long long rng = 0xBB67AE8584CAA73BULL;
static unsigned rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return (unsigned)(rng >> 32);
}

int main(void)
{
    static const int sizes[] = { 7, 8, 15, 16, 100, 1000, 70000 };
    const int maxn = 70000;
    char* const src = (char*)malloc((size_t)maxn);
    char* const back = (char*)malloc((size_t)maxn);
    int kind, si, bad = 0, runs = 0;

    if (!src || !back) { printf("out of memory\n"); return 2; }

    for (kind = 0; kind < 4; kind++) {
        int i;
        for (i = 0; i < maxn; i++)
            src[i] = (kind == 0) ? (char)rnd()                                    /* incompressible */
                   : (kind == 1) ? "abcdefg the lz5 frame "[rnd() % 22]            /* text-like */
                   : (kind == 2) ? (char)((i / 50) % 7)                            /* long runs */
                   : (((rnd() % 5) == 0) ? (char)rnd() : "repeat"[i % 6]);         /* mixed */
        for (si = 0; si < (int)(sizeof(sizes) / sizeof(sizes[0])); si++) {
            const int n = sizes[si];
            const int maxTarget = LZ5_compressBound(n) + 8;
            int target;
            for (target = 1; target <= maxTarget; target += (target < 400) ? 1 : 97) {
                unsigned char* const dst = (unsigned char*)malloc((size_t)target + CANARY_SIZE);
                int consumed = n, cs, k;
                if (!dst) { printf("out of memory\n"); return 2; }
                memset(dst + target, CANARY, CANARY_SIZE);
                cs = LZ5_compress_destSize(src, (char*)dst, &consumed, target);
                runs++;
                for (k = 0; k < CANARY_SIZE; k++)
                    if (dst[target + k] != CANARY) { printf("  kind %d n %d target %d: wrote past targetDstSize\n", kind, n, target); bad++; break; }
                if (cs > target) { printf("  kind %d n %d target %d: returned %d\n", kind, n, target, cs); bad++; }
                else if (cs > 0) {
                    if (consumed < 0 || consumed > n) { printf("  kind %d n %d target %d: consumed %d\n", kind, n, target, consumed); bad++; }
                    else if (LZ5_decompress_safe((const char*)dst, back, cs, consumed) != consumed || memcmp(back, src, (size_t)consumed)) {
                        printf("  kind %d n %d target %d: output does not decode to the consumed prefix\n", kind, n, target); bad++;
                    }
                }
                free(dst);
            }
        }
    }

    printf("destSize: %d runs, %d problems\n", runs, bad);
    free(src); free(back);
    if (bad) { printf("FAIL\n"); return 1; }
    printf("PASS\n");
    return 0;
}
