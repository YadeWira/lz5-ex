/*
 * LZ5F compression context reuse and frame preferences.
 *
 * An LZ5F context keeps its HC stream from one frame to the next. That stream
 * is sized for, and keeps, the level it was created with, so a reused context
 * compressed every later frame at the first frame's level, and in lz5-ex's
 * levels 1-3 the leftover tables also changed which matches were picked. Each
 * HC frame now starts on a new stream: for every pair of levels, a frame from
 * a reused context must be byte-identical to one from a fresh context, and
 * must decode.
 *
 * A blockSizeID above 7 made LZ5F_compressBegin() compute a buffer size from
 * an error code; it now returns ERROR_maxBlockSize_invalid.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lz5frame.h"

static unsigned long long rng = 0x3C6EF372FE94F82BULL;
static unsigned rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return (unsigned)(rng >> 32);
}

/* one frame through compressBegin/Update/End; returns its size, 0 on error */
static size_t frame(LZ5F_compressionContext_t cctx, int level, const char* src, size_t n, char* dst, size_t cap)
{
    LZ5F_preferences_t p;
    size_t c, r;
    memset(&p, 0, sizeof(p));
    p.compressionLevel = level;
    c = LZ5F_compressBegin(cctx, dst, cap, &p);
    if (LZ5F_isError(c)) return 0;
    r = LZ5F_compressUpdate(cctx, dst + c, cap - c, src, n, NULL);
    if (LZ5F_isError(r)) return 0;
    c += r;
    r = LZ5F_compressEnd(cctx, dst + c, cap - c, NULL);
    if (LZ5F_isError(r)) return 0;
    return c + r;
}

static int decodes(const char* frm, size_t fn, const char* src, size_t n, char* out)
{
    LZ5F_decompressionContext_t dctx;
    size_t outSize = n + 1, inSize = fn, r;
    int ok;
    if (LZ5F_isError(LZ5F_createDecompressionContext(&dctx, LZ5F_VERSION))) return 0;
    r = LZ5F_decompress(dctx, out, &outSize, frm, &inSize, NULL);
    ok = !LZ5F_isError(r) && (r == 0) && (outSize == n) && !memcmp(out, src, n);
    LZ5F_freeDecompressionContext(dctx);
    return ok;
}

int main(void)
{
    static const int levels[] = { 0, 1, 2, 3, 4, 6, 9, 11, 13 };
    const int nbLevels = (int)(sizeof(levels) / sizeof(levels[0]));
    const size_t n = 300000;
    char* const src = (char*)malloc(n);
    char* const out = (char*)malloc(n + 1);
    const size_t cap = LZ5F_compressBound(n, NULL) + 64;   /* covers header, buffered data and end */
    char* const a = (char*)malloc(cap);
    char* const b = (char*)malloc(cap);
    size_t i;
    int x, y, bad = 0, runs = 0;

    if (!src || !out || !a || !b) { printf("out of memory\n"); return 2; }
    /* text-like data: words from a small vocabulary, so every level finds matches */
    for (i = 0; i < n; i++) src[i] = (char)((rnd() % 7 == 0) ? ' ' : 'a' + (rnd() % 23) % (1 + (i / 997) % 9));

    for (x = 0; x < nbLevels; x++) {
        for (y = 0; y < nbLevels; y++) {
            LZ5F_compressionContext_t reused, fresh;
            size_t ra, fa;
            if (LZ5F_isError(LZ5F_createCompressionContext(&reused, LZ5F_VERSION))) return 2;
            if (LZ5F_isError(LZ5F_createCompressionContext(&fresh, LZ5F_VERSION))) return 2;
            frame(reused, levels[x], src + 1000, n - 1000, a, cap);   /* a different first frame */
            ra = frame(reused, levels[y], src, n, a, cap);
            fa = frame(fresh, levels[y], src, n, b, cap);
            runs++;
            if (!ra || !fa || ra != fa || memcmp(a, b, ra)) {
                printf("FAIL: level %d after level %d: %u bytes, a fresh context gives %u\n",
                       levels[y], levels[x], (unsigned)ra, (unsigned)fa);
                bad++;
            } else if (!decodes(a, ra, src, n, out)) {
                printf("FAIL: level %d after level %d does not decode\n", levels[y], levels[x]);
                bad++;
            }
            LZ5F_freeCompressionContext(reused);
            LZ5F_freeCompressionContext(fresh);
        }
    }

    {   /* blockSizeID above 7 */
        LZ5F_compressionContext_t cctx;
        LZ5F_preferences_t p;
        unsigned id;
        if (LZ5F_isError(LZ5F_createCompressionContext(&cctx, LZ5F_VERSION))) return 2;
        for (id = 8; id <= 15; id++) {
            size_t r;
            memset(&p, 0, sizeof(p));
            p.frameInfo.blockSizeID = (LZ5F_blockSizeID_t)id;
            p.frameInfo.blockMode = (id & 1) ? LZ5F_blockLinked : LZ5F_blockIndependent;
            r = LZ5F_compressBegin(cctx, a, cap, &p);
            runs++;
            if (!LZ5F_isError(r) || strcmp(LZ5F_getErrorName(r), "ERROR_maxBlockSize_invalid")) {
                printf("FAIL: blockSizeID %u: %s\n", id, LZ5F_isError(r) ? LZ5F_getErrorName(r) : "accepted");
                bad++;
            }
        }
        LZ5F_freeCompressionContext(cctx);
    }

    free(src); free(out); free(a); free(b);
    printf("frame contexts: %d runs, %d problems\n", runs, bad);
    if (bad) return 1;
    printf("PASS\n");
    return 0;
}
