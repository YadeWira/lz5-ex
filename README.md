lz5-ex
=========================

**lz5-ex** is the *extended* line of [LZ5][LZ5], built on the last maintained
release of the original code base. It is where further work on that lineage
happens.

The intent behind the "ex" is extension, not replacement: the project keeps the
original LZ5 API and the original block and frame formats exactly as they are, so
anything built against LZ5 can link against lz5-ex unchanged. New capabilities
are added on top, opt-in, without forcing existing users to migrate.

- **Drop-in compatible.** Public symbols keep their `LZ5_*` names, headers keep
  their names, and the byte format is unchanged. Data written by LZ5
  decompresses identically, in both directions.

| Component | Status |
|-----------|--------|
| CI (Linux/macOS/Windows) | [![CI][ciBadge]][ciLink] |

[ciBadge]: https://github.com/YadeWira/lz5-ex/actions/workflows/ci.yml/badge.svg "Continuous Integration"
[ciLink]: https://github.com/YadeWira/lz5-ex/actions/workflows/ci.yml
[LZ5]: https://github.com/inikep/lz5

### Relationship to LZ5 and Lizard

LZ5 was renamed and continued as [Lizard][Lizard]. lz5-ex does *not* track
Lizard: it stays on the LZ5 API and format, which Lizard diverged from. If you
want the LZ5 API as it was, this is that lineage.

[Lizard]: https://github.com/inikep/lizard

License
-------------------------

The library (`lib/`) is BSD 2-clause; the command line tools (`programs/`) are
GPLv2. See `lib/LICENSE` and `programs/COPYING`.


Benchmarks
-------------------------

[Silesia corpus][silesia] — 12 files, 211,938,580 bytes — measured with
[lzbench] 2.4.1 on one core of an Intel Xeon E5-2697A v4 @ 2.60 GHz, 64-bit
Linux, GCC 14.2.0. Sorted by compression ratio, best first.

| Compressor name | Compression | Decompress. | Compr. size | Ratio |
| --------------- | ----------- | ----------- | ----------- | ----- |
| xz 5.8.4 -9            |      2.3 MB/s |    105.5 MB/s |    48795480 |  23.02 |
| xz 5.8.4 -6            |      2.5 MB/s |    105.7 MB/s |    49408824 |  23.31 |
| brotli 1.2.0 -11       |      0.5 MB/s |    328.6 MB/s |    50328370 |  23.75 |
| zstd 1.5.7 -19         |      2.5 MB/s |    726.8 MB/s |    52891946 |  24.96 |
| bzip2 1.0.8 -9         |     10.7 MB/s |     31.6 MB/s |    54506769 |  25.72 |
| zstd 1.5.7 -9          |     48.9 MB/s |    793.4 MB/s |    59081628 |  27.88 |
| brotli 1.2.0 -5        |     30.6 MB/s |    383.8 MB/s |    59553197 |  28.10 |
| lz5-ex 1.5.1 -15       |      2.1 MB/s |   1222.7 MB/s |    65595195 |  30.95 |
| lz5-ex 1.5.1 -14       |      4.2 MB/s |   1250.3 MB/s |    65938065 |  31.11 |
| zstd 1.5.7 -3          |    155.9 MB/s |    777.6 MB/s |    66137723 |  31.21 |
| zlib 1.3.2 -9          |     10.3 MB/s |    322.9 MB/s |    67643273 |  31.92 |
| lz5-ex 1.5.1 -13       |      6.0 MB/s |   1219.0 MB/s |    68066924 |  32.12 |
| lz5-ex 1.5.1 -12       |     10.1 MB/s |   1152.6 MB/s |    69498052 |  32.79 |
| lz5-ex 1.5.1 -11       |     13.0 MB/s |   1117.7 MB/s |    70891340 |  33.45 |
| lz5-ex 1.5.1 -10       |     17.7 MB/s |   1229.7 MB/s |    70898501 |  33.45 |
| lz5-ex 1.5.1 -9        |     25.7 MB/s |   1229.0 MB/s |    72730525 |  34.32 |
| zstd 1.5.7 -1          |    339.6 MB/s |   1142.8 MB/s |    73229468 |  34.55 |
| lz5-ex 1.5.1 -8        |     39.2 MB/s |   1185.2 MB/s |    76188482 |  35.95 |
| lz5-ex 1.5.1 -7        |     45.3 MB/s |   1196.5 MB/s |    76941338 |  36.30 |
| lz4hc 1.10.0 -9        |     27.4 MB/s |   3353.3 MB/s |    77884211 |  36.75 |
| lz5-ex 1.5.1 -6        |     47.8 MB/s |   1243.2 MB/s |    78524092 |  37.05 |
| lz5-ex 1.5.1 -5        |    128.4 MB/s |   1137.5 MB/s |    82882713 |  39.11 |
| lz5-ex 1.5.1 -4        |    170.7 MB/s |   1255.1 MB/s |    86018599 |  40.59 |
| lz5-ex 1.5.1 -0        |    228.8 MB/s |   1067.4 MB/s |    88218423 |  41.62 |
| lz5-ex 1.5.1 -3        |    356.2 MB/s |   1511.1 MB/s |    95027228 |  44.84 |
| lizard 2.1 -20         |    304.7 MB/s |   1733.8 MB/s |    96927713 |  45.73 |
| lz4 1.10.0             |    510.8 MB/s |   3410.7 MB/s |   100880147 |  47.60 |
| lz5-ex 1.5.1 -2        |    436.9 MB/s |   1722.2 MB/s |   102870177 |  48.54 |
| lz5-ex 1.5.1 -1        |    561.8 MB/s |   1812.9 MB/s |   113212615 |  53.42 |

`Ratio` is the compressed size as a percentage of the original, so lower is
better. Sizes are exact; the speeds are single-thread figures from one machine
and will differ on other hardware.

`-0` is the plain fast path; `-1` to `-15` are the high-compression parsers. The
levels are not one smooth curve: `-1` to `-3` are the "fast" HC profiles, which
trade ratio for speed and sit above `-0` on the speed axis, which is why `-0`
compresses better than any of them. From `-4` upwards the ratio improves
monotonically with the level.

What lz5-ex changed, in short (the full list is in `NEWS`):

- **Levels `-1` to `-3`** use a parser that walks forward with an accelerating
  step and indexes every position it tests, with small hash tables (8-16K entries,
  sized to stay in cache) and 6- or 7-byte hashes. The 1.5.x parser checked one
  candidate and never indexed the positions it skipped.
- **Every HC parser emits the one-byte repeat-offset codeword**: the price
  parsers of `-4` to `-10` were already pricing it, and `-1` to `-3` use it when a
  match repeats the last offset. In 1.5.x only level 0 and `-11` to `-15` wrote it.
- **The decoder** decodes short sequences on a fast path with fixed-size copies,
  and the 16-bit, 24-bit and repeat offsets without a data-dependent branch.
- **The HC parsers** run on a local copy of their context, are specialised for the
  parameters of `-4` to `-15`, and the optimal parser computes the fixed part of a
  match's price once per match.
- **Safety:** compressing with `LZ5_compressBound()` no longer writes past the
  buffer (some parsers expand base64 by ~4%; such a block is now stored as
  literals), the safe decoder no longer reads past its input,
  `LZ5_compress_destSize` no longer writes past its target, and compressing
  against an external dictionary no longer produces wrong output. Most of these
  are inherited from LZ5 1.5.0; `tests/` covers each of them.

### Comparison with LZ5 1.5.0

The same Silesia corpus, the same lzbench and the same core, with LZ5 1.5.0 (the
upstream `v1.5` tag, unmodified) built into the harness next to lz5-ex. The runs
were interleaved - 1.5.0, lz5-ex, 1.5.0, ... - three rounds each, so machine drift
hits both alike. Sizes are exact and identical across rounds; speeds are the
median of the three rounds, in MB/s, as total bytes over total time.

| Level | Ratio 1.5.0 | Ratio lz5-ex | Size | Encode 1.5.0 | Encode lz5-ex | | Decode 1.5.0 | Decode lz5-ex | |
| ----- | ----------- | ------------ | ---- | ------------ | ------------- | --- | ------------ | ------------- | --- |
| `-0` | 41.62 | 41.62 | +0.0% |  213.5 |  221.4 | +3.7% |   612.5 |  1019.2 | +66% |
| `-1` | 53.57 | 53.42 | -0.3% |  493.1 |  556.9 | +12.9% |  1454.1 |  1769.8 | +22% |
| `-2` | 49.11 | 48.54 | -1.2% |  406.0 |  430.3 | +6.0% |  1334.8 |  1666.3 | +25% |
| `-3` | 45.10 | 44.84 | -0.6% |  304.2 |  340.4 | +11.9% |  1141.1 |  1478.3 | +30% |
| `-4` | 40.82 | 40.59 | -0.6% |  164.3 |  167.4 | +1.9% |   903.1 |  1242.6 | +38% |
| `-5` | 39.85 | 39.11 | -1.9% |  117.1 |  125.7 | +7.4% |   725.2 |  1091.0 | +50% |
| `-6` | 38.02 | 37.05 | -2.5% |   44.4 |   50.0 | +12.8% |   910.5 |  1206.8 | +33% |
| `-7` | 37.21 | 36.30 | -2.4% |   40.2 |   44.6 | +10.9% |   826.2 |  1160.2 | +40% |
| `-8` | 36.80 | 35.95 | -2.3% |   35.8 |   41.4 | +15.8% |   769.1 |  1149.1 | +49% |
| `-9` | 35.03 | 34.32 | -2.0% |   22.8 |   25.8 | +13.5% |   728.8 |  1158.0 | +59% |
| `-10` | 34.10 | 33.45 | -1.9% |   18.0 |   19.4 | +7.7% |   716.2 |  1158.7 | +62% |
| `-11` | 33.53 | 33.45 | -0.2% |   13.4 |   13.9 | +3.9% |   699.5 |  1084.4 | +55% |
| `-12` | 32.79 | 32.79 | +0.0% |   10.1 |   10.3 | +1.7% |   712.7 |  1087.3 | +53% |
| `-13` | 32.12 | 32.12 | +0.0% |    5.7 |    6.0 | +5.7% |   677.2 |  1155.4 | +71% |
| `-14` | 31.11 | 31.11 | +0.0% |    3.9 |    4.3 | +10.9% |   636.3 |  1170.0 | +84% |
| `-15` | 30.95 | 30.95 | +0.0% |    1.8 |    2.0 | +11.5% |   643.5 |  1197.7 | +86% |

This table is a separate session from the one above, so its absolute speeds differ
from that table's by a few percent: compare the columns within one table, not across
the two.

`Ratio` is the compressed size as a percentage of the original, so lower is better;
`Size` is how much smaller (negative) lz5-ex's output is. The unlabelled columns are
the change in speed, positive meaning lz5-ex is faster. The raw numbers are in
`bench/compare-lz5-1.5.0.csv`.

**At every level lz5-ex compresses at least as well as LZ5 1.5.0, decompresses
faster and, by this measurement, compresses faster** - see the note on margins
below.

- **`-0`, `-12` to `-15`** write byte for byte what 1.5.0 writes (checked on all
  twelve files). They encode 2% to 12% faster and decode 53% to 86% faster.
- **`-1` to `-11`** compress 0.2% to 2.5% smaller, encode 2% to 16% faster and
  decode 22% to 62% faster. `-1` to `-5` and `-11` were tuned against this table:
  they keep less of the ratio lz5-ex had gained than they could, to be faster
  than 1.5.0 too.
- Four encode margins are small: `-0` (+3.7%), `-4` (+1.9%), `-11` (+3.9%) and
  `-12` (+1.7%) are within the run-to-run noise of this machine, a few percent.
  Other runs of the same code measured `-12` at +4.0% (lzbench) and `-4` at +4.6%
  and `-11` at +5.3% and +6.5% (a direct-call harness).

The compressed streams stay decodable by LZ5 1.5.0 and the other way round at every
level (`tests/test_compat_lz5_15.sh`), so the sizes above are the only thing that
differs for a user who swaps the library.

Reproduce with `bench/run-silesia.sh`. The raw lzbench output is kept in
`bench/silesia.csv` and the per-codec aggregation in
`bench/silesia-aggregated.csv`.

### Historical results (2015)

The original LZ5 README benchmarked the 100 MB `win81` file with the lzbench of
the time. It is kept for reference; every competitor version below is from 2015
and is not comparable with the table above.

| Compressor name             | Compression| Decompress.| Compr. size | Ratio |
| ---------------             | -----------| -----------| ----------- | ----- |
| memcpy                      |  8533 MB/s |  8533 MB/s |   104857600 |100.00 |
| lz4 r131                    |   480 MB/s |  2275 MB/s |    64872315 | 61.87 |
| lz4hc r131 -1               |    82 MB/s |  1896 MB/s |    59448496 | 56.69 |
| lz4hc r131 -3               |    54 MB/s |  1932 MB/s |    56343753 | 53.73 |
| lz4hc r131 -5               |    41 MB/s |  1969 MB/s |    55271312 | 52.71 |
| lz4hc r131 -7               |    31 MB/s |  1969 MB/s |    54889301 | 52.35 |
| lz4hc r131 -9               |    24 MB/s |  1969 MB/s |    54773517 | 52.24 |
| lz4hc r131 -11              |    20 MB/s |  1969 MB/s |    54751363 | 52.21 |
| lz4hc r131 -13              |    17 MB/s |  1969 MB/s |    54744790 | 52.21 |
| lz4hc r131 -15              |    14 MB/s |  2007 MB/s |    54741827 | 52.21 |
| lz5 v1.4                    |   191 MB/s |   892 MB/s |    56183327 | 53.58 |
| lz5hc v1.4 level 1          |   468 MB/s |  1682 MB/s |    68770655 | 65.58 |
| lz5hc v1.4 level 2          |   337 MB/s |  1574 MB/s |    65201626 | 62.18 |
| lz5hc v1.4 level 3          |   232 MB/s |  1330 MB/s |    61423270 | 58.58 |
| lz5hc v1.4 level 4          |   129 MB/s |   894 MB/s |    55011906 | 52.46 |
| lz5hc v1.4 level 5          |    99 MB/s |   840 MB/s |    52790905 | 50.35 |
| lz5hc v1.4 level 6          |    41 MB/s |   894 MB/s |    52561673 | 50.13 |
| lz5hc v1.4 level 7          |    35 MB/s |   875 MB/s |    50947061 | 48.59 |
| lz5hc v1.4 level 8          |    23 MB/s |   812 MB/s |    50049555 | 47.73 |
| lz5hc v1.4 level 9          |    17 MB/s |   727 MB/s |    48718531 | 46.46 |
| lz5hc v1.4 level 10         |    13 MB/s |   728 MB/s |    48109030 | 45.88 |
| lz5hc v1.4 level 11         |  9.18 MB/s |   719 MB/s |    47438817 | 45.24 |
| lz5hc v1.4 level 12         |  7.96 MB/s |   752 MB/s |    47063261 | 44.88 |
| lz5hc v1.4 level 13         |  5.38 MB/s |   710 MB/s |    46383307 | 44.23 |
| lz5hc v1.4 level 14         |  4.12 MB/s |   669 MB/s |    45843096 | 43.72 |
| lz5hc v1.4 level 15         |  2.16 MB/s |   619 MB/s |    45767126 | 43.65 |
| zstd v0.5.0 level 1         |   249 MB/s |   569 MB/s |    51121791 | 48.75 |
| zstd v0.5.0 level 2         |   177 MB/s |   523 MB/s |    49692088 | 47.39 |
| zstd v0.5.0 level 5         |    72 MB/s |   491 MB/s |    46373509 | 44.23 |
| zstd v0.5.0 level 9         |    17 MB/s |   523 MB/s |    43876466 | 41.84 |
| zstd v0.5.0 level 13        |    10 MB/s |   524 MB/s |    42305338 | 40.35 |
| zstd v0.5.0 level 17        |  3.21 MB/s |   524 MB/s |    41990713 | 40.05 |
| zstd v0.5.0 level 20        |  2.76 MB/s |   495 MB/s |    41862877 | 39.92 |
| brotli 2015-10-29 -1        |    86 MB/s |   208 MB/s |    47882059 | 45.66 |
| brotli 2015-10-29 -3        |    60 MB/s |   214 MB/s |    47451223 | 45.25 |
| brotli 2015-10-29 -5        |    17 MB/s |   217 MB/s |    43363897 | 41.36 |
| brotli 2015-10-29 -7        |  4.80 MB/s |   227 MB/s |    41222719 | 39.31 |
| brotli 2015-10-29 -9        |  2.23 MB/s |   222 MB/s |    40839209 | 38.95 |

The 2015 results were obtained with [lzbench] using 1 core of a Core i5-4300U,
Windows 10 64-bit (MinGW-w64, GCC 4.8.3), 3 iterations. The `win81` file is a
concatenation of files from an installed Windows 8.1 64-bit.

[lzbench]: https://github.com/inikep/lzbench
[silesia]: http://sun.aei.polsl.pl/~sdeor/index.php?page=silesia


Documentation
-------------------------

The [wiki](https://github.com/YadeWira/lz5-ex/wiki) covers the compression levels,
the library API, compatibility with LZ5 1.5.0, benchmarks and the safety fixes.

The raw LZ5 block compression format is detailed within [lz5_Block_format].

To compress an arbitrarily long file or data stream, multiple blocks are required.
Organizing these blocks and providing a common header format to handle their content
is the purpose of the Frame format, defined into [lz5_Frame_format].
Interoperable versions of LZ5 must respect this frame format.

[lz5_Block_format]: lz5_Block_format.md
[lz5_Frame_format]: lz5_Frame_format.md


Original LZ5 introduction
-------------------------

LZ5 is a modification of [LZ4] which gives a better ratio at cost of slower compression and decompression speed. 
**In my experiments there is no open-source bytewise compressor that gives better ratio than lz5hc.**
The improvement in compression ratio is caused mainly because of:
- 22-bit dictionary instead of 16-bit in LZ4
- using 4 new parsers (including an optimal parser) optimized for a bigger dictionary
- support for 3-byte long matches (MINMATCH = 3)
- a special 1-byte codeword for the last occured offset

[LZ4]: https://github.com/Cyan4973/lz4
