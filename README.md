lz5-ex
=========================

**lz5-ex** is the extended line of [LZ5]: the LZ5 1.5.x code base, kept alive and made
faster, with the original API and the original block and frame formats unchanged.

- **Drop-in compatible.** The same `LZ5_*` functions, header names and `liblz5.so.1`.
  Streams written by lz5-ex decode with LZ5 1.5.0 and the other way round, at every
  level.
- **Better than LZ5 1.5.0 at every level** on the Silesia corpus: the same size or
  smaller output, faster decompression and faster compression (table below).
- **Safer.** Buffer overruns and over-reads inherited from 1.5.0 are fixed and covered
  by tests (`tests/`).
- **Ready-made binaries** for Linux, macOS and Windows on the [releases] page, each
  checked by CI before it is attached.

| Component | Status |
|-----------|--------|
| CI (Linux/macOS/Windows) | [![CI][ciBadge]][ciLink] |

**Documentation is in the [wiki]**: [getting started][wGS], [compression
levels][wCL], [library API][wAPI], [compatibility][wCompat], [benchmarks][wBench],
[safety fixes][wSafe] and [testing][wTest]. What changed in each release is in
[`NEWS`](NEWS).

[LZ5]: https://github.com/inikep/lz5
[releases]: https://github.com/YadeWira/lz5-ex/releases
[ciBadge]: https://github.com/YadeWira/lz5-ex/actions/workflows/ci.yml/badge.svg "Continuous Integration"
[ciLink]: https://github.com/YadeWira/lz5-ex/actions/workflows/ci.yml
[wiki]: https://github.com/YadeWira/lz5-ex/wiki
[wGS]: https://github.com/YadeWira/lz5-ex/wiki/Getting-Started
[wCL]: https://github.com/YadeWira/lz5-ex/wiki/Compression-Levels
[wAPI]: https://github.com/YadeWira/lz5-ex/wiki/Library-API
[wCompat]: https://github.com/YadeWira/lz5-ex/wiki/Compatibility
[wBench]: https://github.com/YadeWira/lz5-ex/wiki/Benchmarks
[wSafe]: https://github.com/YadeWira/lz5-ex/wiki/Safety-Fixes
[wTest]: https://github.com/YadeWira/lz5-ex/wiki/Testing


Quick start
-------------------------

```sh
make                      # lib/liblz5.{a,so} and programs/lz5
make -C tests test        # regression tests
programs/lz5 -9 file      # compress to file.lz5 (levels -0 ... -15)
programs/lz5 -d file.lz5  # decompress
```

```c
#include "lz5hc.h"
int n = LZ5_compress_HC(src, dst, srcSize, LZ5_compressBound(srcSize), 9);
int m = LZ5_decompress_safe(dst, out, n, srcSize);   /* negative on damaged input */
```


Benchmarks
-------------------------

<!-- TABLE -->
How small lz5-ex's output is and how fast it runs at each level, and how that compares
with the original LZ5 1.5.0. From `-1` to `-15`, each level makes smaller files and
compresses more slowly; `-1` is the fastest and `-15` the smallest. `-0`, the default,
is a separate fast mode that lands between `-3` and `-4` in size. Decompression stays
fast at every level.

|  | lz5-ex | | | compared with LZ5 1.5.0 | | |
| :---- | ---: | ---: | ---: | ---: | ---: | ---: |
| **Level** | **Size** | **Compression** | **Decompression** | **Size** | **Compression** | **Decompression** |
| `-0` (default) | 41.62% | 232 MB/s | 1103 MB/s | same | 3% faster | 64% faster |
| `-1` | 53.42% | 590 MB/s | 1866 MB/s | 0.3% smaller | 14% faster | 22% faster |
| `-2` | 48.29% | 448 MB/s | 1567 MB/s | 1.7% smaller | 11% faster | 15% faster |
| `-3` | 44.76% | 344 MB/s | 1518 MB/s | 0.7% smaller | 8% faster | 28% faster |
| `-4` | 39.80% | 187 MB/s | 1245 MB/s | 2.5% smaller | 7% faster | 29% faster |
| `-5` | 39.11% | 146 MB/s | 1174 MB/s | 1.9% smaller | 20% faster | 51% faster |
| `-6` | 37.05% | 55 MB/s | 1296 MB/s | 2.5% smaller | 12% faster | 36% faster |
| `-7` | 36.30% | 50 MB/s | 1261 MB/s | 2.4% smaller | 9% faster | 38% faster |
| `-8` | 35.95% | 45 MB/s | 1240 MB/s | 2.3% smaller | 9% faster | 48% faster |
| `-9` | 34.32% | 28 MB/s | 1238 MB/s | 2.0% smaller | 5% faster | 54% faster |
| `-10` | 33.45% | 21 MB/s | 1280 MB/s | 1.9% smaller | 6% faster | 67% faster |
| `-11` | 33.45% | 16 MB/s | 1190 MB/s | 0.2% smaller | 4% faster | 55% faster |
| `-12` | 32.79% | 12 MB/s | 1203 MB/s | same | 5% faster | 57% faster |
| `-13` | 32.12% | 6.9 MB/s | 1260 MB/s | same | 7% faster | 68% faster |
| `-14` | 31.11% | 4.8 MB/s | 1330 MB/s | same | 6% faster | 87% faster |
| `-15` | 30.95% | 2.2 MB/s | 1330 MB/s | same | 5% faster | 87% faster |

How to read it:
- **Size** is the compressed size as a percentage of the original: 41.62% means a
  100 MB input becomes 41.6 MB. Lower is better.
- **Compression** and **decompression** are speeds in MB of original data per second,
  on one core. Higher is better.
- The last three columns compare lz5-ex with LZ5 1.5.0 at the same level: "same" means
  identical size; "2.5% smaller" or "64% faster" are lz5-ex's gains.

Measured on the [Silesia corpus](http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia)
(211,938,580 bytes of mixed files) with [lzbench](https://github.com/inikep/lzbench)
2.4.1, one core of an Intel Xeon E5-2697A v4 @ 2.60 GHz, GCC 14.2.0. LZ5 1.5.0 ran in
the same harness, interleaved with lz5-ex level by level (three rounds, median speed).
The figures are from lz5-ex 1.5.2; 1.5.3 did not change the compressor or the decoder
loop, so they still apply.

The other compressors (zstd, lz4, brotli, xz, ...), the per-level 1.5.0 figures and how
to reproduce the runs are on the wiki's [benchmarks][wBench] page.
<!-- /TABLE -->


License
-------------------------

The library (`lib/`) is BSD 2-clause; the command line tools (`programs/`) are GPLv2.
See `lib/LICENSE` and `programs/COPYING`. The block and frame formats are specified in
[lz5_Block_format.md](lz5_Block_format.md) and [lz5_Frame_format.md](lz5_Frame_format.md).

LZ5 was created by Przemysław Skibiński from LZ4 by Yann Collet. It was later renamed and
continued as [Lizard](https://github.com/inikep/lizard), with a different format; lz5-ex
stays on the LZ5 format and API. The original LZ5 introduction and its 2015 benchmark
are kept on the wiki's [History](https://github.com/YadeWira/lz5-ex/wiki/History) page.
