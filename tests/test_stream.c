/*
 * Streaming round trip through the linked-block HC API.
 *
 * Compresses a synthetic input with LZ5_compress_HC_continue in blocks of random
 * size, decodes every block with LZ5_decompress_safe_continue, and compares the
 * result with the input, at every HC level and for three block-size regimes.
 *
 * This is the test that found the repeat-offset bug: the encoder kept the last
 * offset across LZ5_compress_HC_continue calls while the decoder restarts every
 * block with last_off == 1, so a block that began with a "repeat the last offset"
 * codeword decoded to the wrong bytes. The input is built to make the parsers use
 * that codeword a lot: fixed-format records whose fields repeat at a constant
 * distance, interleaved with text.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "lz5.h"
#include "lz5hc.h"

static unsigned long long rng = 0x9E3779B97F4A7C15ULL;
static unsigned rnd(void)
{
    rng ^= rng << 13; rng ^= rng >> 7; rng ^= rng << 17;
    return (unsigned)(rng >> 32);
}

static size_t make_input(char* dst, size_t cap)
{
    static const char* const words[] = {
        "alpha", "bravo", "charlie", "delta", "echo", "foxtrot", "golf", "hotel",
        "india", "juliett", "kilo", "lima", "mike", "november", "oscar", "papa" };
    size_t n = 0;
    unsigned id = 0;
    while (n + 128 < cap) {
        if (rnd() % 4) {   /* a record: same layout every time, so the offsets repeat */
            /* argument evaluation order is unspecified: draw in a fixed order,
             * so gcc and clang build the same input */
            const char* const name = words[rnd() % 16];
            const unsigned value = rnd() % 100000;
            const char flag = "YN"[rnd() % 2];
            n += (size_t)sprintf(dst + n, "id=%06u;name=%-8s;value=%5u;flag=%c\n", id++, name, value, flag);
        } else {           /* free text */
            int k, w = 3 + (int)(rnd() % 12);
            for (k = 0; k < w; k++) n += (size_t)sprintf(dst + n, "%s ", words[rnd() % 16]);
            dst[n++] = '\n';
        }
    }
    return n;
}

int main(void)
{
    const size_t cap = 1 << 20;
    char* const src = (char*)malloc(cap);
    char* const out = (char*)malloc(cap + 64);
    char* const cbuf = (char*)malloc((size_t)LZ5_compressBound(1 << 17));
    const long maxBlock[3] = { 4096, 65536, 1 << 17 };
    int lvl, mode, failures = 0, runs = 0;
    size_t n;

    if (!src || !out || !cbuf) { printf("out of memory\n"); return 2; }
    n = make_input(src, cap);

    for (lvl = 1; lvl <= LZ5HC_MAX_CLEVEL; lvl++) {
        for (mode = 0; mode < 3; mode++) {
            LZ5_streamHC_t* const cs = LZ5_createStreamHC(lvl);
            LZ5_streamDecode_t* const ds = LZ5_createStreamDecode();
            size_t pos = 0;
            int ok = (cs != NULL) && (ds != NULL);
            while (ok && pos < n) {
                int bs = 1 + (int)(rnd() % (unsigned)maxBlock[mode]);
                int csize, dsize;
                if ((size_t)bs > n - pos) bs = (int)(n - pos);
                csize = LZ5_compress_HC_continue(cs, src + pos, cbuf, bs, LZ5_compressBound(bs));
                if (csize <= 0) { ok = 0; break; }
                dsize = LZ5_decompress_safe_continue(ds, cbuf, out + pos, csize, bs);
                if (dsize != bs) { ok = 0; break; }
                pos += (size_t)bs;
            }
            if (ok && memcmp(out, src, n)) ok = 0;
            runs++;
            if (!ok) { failures++; printf("  FAIL level %2d, blocks up to %ld bytes\n", lvl, maxBlock[mode]); }
            LZ5_freeStreamHC(cs);
            LZ5_freeStreamDecode(ds);
        }
    }

    /* A dictionary loaded with LZ5_loadDictHC, and the next block compressed
     * against it, each in its own buffer of exactly its size. Indexing the
     * dictionary must not read past its end (the 5- to 7-byte hashes of levels
     * 1-3 read 8 bytes), the parsers must not read before the block for a
     * repeat-offset candidate (that memory is not the dictionary), and the
     * block must decode against the dictionary. AddressSanitizer reports the
     * reads; without it, the round trip still catches a wrong match. */
    for (lvl = 1; lvl <= LZ5HC_MAX_CLEVEL; lvl++) {
        const int dsz = 65536, bs = 65536;
        char* const dict = (char*)malloc((size_t)dsz);
        char* const blk = (char*)malloc((size_t)bs);
        LZ5_streamHC_t* const cs = LZ5_createStreamHC(lvl);
        int ok = (dict != NULL) && (blk != NULL) && (cs != NULL) && (n >= (size_t)(dsz + bs));
        if (ok) {
            int csize, dsize;
            memcpy(dict, src, (size_t)dsz);
            memcpy(blk, src + dsz, (size_t)bs);
            LZ5_loadDictHC(cs, dict, dsz);
            csize = LZ5_compress_HC_continue(cs, blk, cbuf, bs, LZ5_compressBound(bs));
            dsize = (csize > 0) ? LZ5_decompress_safe_usingDict(cbuf, out, csize, bs, dict, dsz) : -1;
            ok = (dsize == bs) && !memcmp(out, blk, (size_t)bs);
        }
        runs++;
        if (!ok) { failures++; printf("  FAIL level %2d, block compressed against LZ5_loadDictHC\n", lvl); }
        LZ5_freeStreamHC(cs);
        free(dict);
        free(blk);
    }

    printf("streaming round trip: %d runs, %d failures (%lu bytes of input)\n", runs, failures, (unsigned long)n);
    free(src); free(out); free(cbuf);
    if (failures) { printf("FAIL\n"); return 1; }
    printf("PASS\n");
    return 0;
}
