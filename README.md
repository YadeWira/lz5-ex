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
| xz 5.8.4 -9            |      2.4 MB/s |    103.1 MB/s |    48795480 |  23.02 |
| xz 5.8.4 -6            |      2.7 MB/s |    106.8 MB/s |    49408824 |  23.31 |
| brotli 1.2.0 -11       |      0.5 MB/s |    348.4 MB/s |    50328370 |  23.75 |
| zstd 1.5.7 -19         |      2.8 MB/s |    790.1 MB/s |    52891946 |  24.96 |
| bzip2 1.0.8 -9         |     10.2 MB/s |     31.5 MB/s |    54506769 |  25.72 |
| zstd 1.5.7 -9          |     53.4 MB/s |    851.3 MB/s |    59081628 |  27.88 |
| brotli 1.2.0 -5        |     33.3 MB/s |    407.0 MB/s |    59553197 |  28.10 |
| lz5-ex 1.5.1 -15       |      2.1 MB/s |   1042.8 MB/s |    65595195 |  30.95 |
| lz5-ex 1.5.1 -14       |      4.4 MB/s |   1033.0 MB/s |    65938065 |  31.11 |
| zstd 1.5.7 -3          |    163.7 MB/s |    866.6 MB/s |    66137723 |  31.21 |
| zlib 1.3.2 -9          |     10.7 MB/s |    328.9 MB/s |    67643273 |  31.92 |
| lz5-ex 1.5.1 -13       |      6.5 MB/s |    959.6 MB/s |    68066924 |  32.12 |
| lz5-ex 1.5.1 -12       |      9.9 MB/s |    909.4 MB/s |    69498052 |  32.79 |
| lz5-ex 1.5.1 -11       |     13.3 MB/s |    900.3 MB/s |    70334578 |  33.19 |
| lz5-ex 1.5.1 -10       |     19.7 MB/s |    989.8 MB/s |    70898501 |  33.45 |
| lz5-ex 1.5.1 -9        |     25.8 MB/s |    967.8 MB/s |    72730525 |  34.32 |
| zstd 1.5.7 -1          |    358.5 MB/s |   1212.7 MB/s |    73229468 |  34.55 |
| lz5-ex 1.5.1 -8        |     40.1 MB/s |    928.4 MB/s |    76188482 |  35.95 |
| lz5-ex 1.5.1 -7        |     42.8 MB/s |    938.7 MB/s |    76941338 |  36.30 |
| lz4hc 1.10.0 -9        |     29.1 MB/s |   3544.0 MB/s |    77884211 |  36.75 |
| lz5-ex 1.5.1 -6        |     46.8 MB/s |    962.5 MB/s |    78524092 |  37.05 |
| lz5-ex 1.5.1 -5        |    121.5 MB/s |    924.6 MB/s |    82568425 |  38.96 |
| lz5-ex 1.5.1 -4        |    162.6 MB/s |    973.2 MB/s |    84353607 |  39.80 |
| lz5-ex 1.5.1 -0        |    228.6 MB/s |    941.9 MB/s |    88218423 |  41.62 |
| lz5-ex 1.5.1 -3        |    185.2 MB/s |    885.9 MB/s |    90306415 |  42.61 |
| lz5-ex 1.5.1 -2        |    291.4 MB/s |   1169.3 MB/s |    95928768 |  45.26 |
| lizard 2.1 -20         |    313.9 MB/s |   1755.9 MB/s |    96927713 |  45.73 |
| lz4 1.10.0             |    546.9 MB/s |   3664.4 MB/s |   100880147 |  47.60 |
| lz5-ex 1.5.1 -1        |    486.8 MB/s |   1496.5 MB/s |   108809515 |  51.34 |

`Ratio` is the compressed size as a percentage of the original, so lower is
better. Sizes are exact; the speeds are single-thread figures from one machine
and will differ on other hardware.

`-0` is the plain fast path; `-1` to `-15` are the high-compression parsers. The
levels are not one smooth curve: `-1` to `-3` are the "fast" HC profiles, which
trade ratio for speed and sit above `-0` on the speed axis, which is why `-0`
compresses better than any of them. From `-4` upwards the ratio improves
monotonically with the level.

Levels `-1` to `-3` were reworked in lz5-ex. The 1.5.x strategy checked a
single candidate from an 8K-entry hash table and never indexed the positions
it skipped, so `-1` compressed worse than the default while being barely
faster (53.56% at 501 MB/s). The reworked parser walks forward with an
accelerating step and indexes every position it tests, and its candidate
finder follows the lz6 line: the main hash first, then - only when that finds
nothing, where they are pure upside - the previous offset (the one-byte
codeword of the format) and a 3-byte index that the 1.5.x fast parser never
used. A bare 3-byte match is only taken when its encoded price beats the
literals it replaces. The next probe's hash load is prefetched, which is
output-neutral and buys ~10% encode speed on its own. Result on Silesia,
against the 1.5.1 table: `-1` 53.56% -> 51.34%, `-2` 49.11% -> 45.26%, `-3`
45.09% -> 42.61%, with encode speed at 92%, 70% and 60% of the original.
Output remains decodable by LZ5 1.5.0 in both directions (see
`tests/test_compat_lz5_15.sh`).

The format has a one-byte codeword for "same offset as the previous match".
In 1.5.x only level 0 and the optimal parser (`-11` to `-15`) ever wrote it:
the parsers of `-1` to `-10` found repeat-offset candidates and priced them at
the cheap codeword, then encoded them with the full 2-3 byte offset. lz5-ex
emits the codeword from every parser, which shrinks `-1` to `-10` by 0.4% to
2.6% on Silesia and leaves `-0` and `-11` to `-15` untouched. The previous-offset
state is also reset for each block, as the decoder does; without that, the
streaming API (`LZ5_compress_HC_continue`) could produce undecodable output at
`-11` to `-15`. The command line tool compresses independent blocks and was not
affected.

The decoder reads the 16-bit, 24-bit and repeat-offset codewords without a
data-dependent branch, which decodes up to 30% faster depending on the level;
the format and the decoder's behaviour on any input are unchanged.

The fast parser also carries an optional lazy-match pass, off in the shipped
table: a level with `sufficientLength` set looks one and two positions ahead
for a clearly longer match. Measured on Silesia it buys ~1.2 points of ratio
on `-2` for ~19% encode speed, which is why it is left disabled; it is a knob
to be re-measured on the target content.

### Comparison with LZ5 1.5.0

The same Silesia corpus, the same lzbench and the same core, with LZ5 1.5.0 (the
upstream `v1.5` tag, unmodified) built into the harness next to lz5-ex. The runs
were interleaved - 1.5.0, lz5-ex, 1.5.0, ... - three rounds each, so machine drift
hits both alike. Sizes are exact and identical across rounds; speeds are the
median of the three rounds, in MB/s, as total bytes over total time.

| Level | Ratio 1.5.0 | Ratio lz5-ex | Size | Encode 1.5.0 | Encode lz5-ex | | Decode 1.5.0 | Decode lz5-ex | |
| ----- | ----------- | ------------ | ---- | ------------ | ------------- | --- | ------------ | ------------- | --- |
| `-0` | 41.62 | 41.62 | +0.0% |  204.4 |  212.0 | +4% |   608.7 |   867.3 | +42% |
| `-1` | 53.57 | 51.34 | -4.2% |  478.9 |  438.8 | -8% |  1422.3 |  1417.1 | -0% |
| `-2` | 49.11 | 45.26 | -7.8% |  387.1 |  271.5 | -30% |  1270.9 |  1097.0 | -14% |
| `-3` | 45.10 | 42.61 | -5.5% |  292.5 |  175.6 | -40% |  1122.6 |   847.8 | -24% |
| `-4` | 40.82 | 39.80 | -2.5% |  159.4 |  152.7 | -4% |   888.3 |   912.2 | +3% |
| `-5` | 39.85 | 38.96 | -2.2% |  113.7 |  113.5 | -0% |   717.4 |   874.9 | +22% |
| `-6` | 38.02 | 37.05 | -2.5% |   40.6 |   42.7 | +5% |   880.9 |   902.3 | +2% |
| `-7` | 37.21 | 36.30 | -2.4% |   37.3 |   37.3 | -0% |   826.0 |   881.5 | +7% |
| `-8` | 36.80 | 35.95 | -2.3% |   33.7 |   35.4 | +5% |   760.8 |   864.8 | +14% |
| `-9` | 35.03 | 34.32 | -2.0% |   21.9 |   23.0 | +5% |   733.7 |   892.4 | +22% |
| `-10` | 34.10 | 33.45 | -1.9% |   16.5 |   17.9 | +9% |   711.0 |   915.6 | +29% |
| `-11` | 33.53 | 33.19 | -1.0% |   12.5 |   11.9 | -4% |   699.9 |   836.3 | +19% |
| `-12` | 32.79 | 32.79 | +0.0% |    9.4 |   10.1 | +7% |   699.8 |   839.4 | +20% |
| `-13` | 32.12 | 32.12 | +0.0% |    5.3 |    5.6 | +5% |   670.6 |   895.3 | +34% |
| `-14` | 31.11 | 31.11 | +0.0% |    3.7 |    3.9 | +7% |   639.3 |   959.5 | +50% |
| `-15` | 30.95 | 30.95 | +0.0% |    1.8 |    1.8 | +2% |   628.3 |   939.3 | +50% |

This table is a separate, later session from the one above, so its absolute speeds
differ from that table's by a few percent: compare the columns within one table, not
across the two.

`Ratio` is the compressed size as a percentage of the original, so lower is better;
`Size` is how much smaller (negative) lz5-ex's output is. The unlabelled columns are
the change in speed, positive meaning lz5-ex is faster. Differences of a few percent
are within the run-to-run noise of this machine. The raw numbers are in
`bench/compare-lz5-1.5.0.csv`.

How the levels group:

- **`-0`, `-12` to `-15`: the output is byte for byte what 1.5.0 writes** (checked
  on all twelve files). Only the decoder changed, and it decodes 20% to 50% faster.
  Encoding is within a few percent of 1.5.0.
- **`-4` to `-10`: 1.9% to 2.5% smaller**, with encoding between 4% slower and 9%
  faster than 1.5.0 and decoding 2% to 29% faster. This is the repeat-offset change
  described above.
- **`-11`: 1.0% smaller**, about 4% slower to encode, 19% faster to decode. It was
  retuned (`sufficientLength` 12 -> 32, `searchNum` 8 -> 6): with the old values it
  was larger than `-10` on the full corpus.
- **`-1` to `-3` trade speed for ratio.** They are 4.2%, 7.8% and 5.5% smaller, and
  they pay for it: `-1` encodes 8% slower and decodes the same, `-2` encodes 30%
  slower and decodes 14% slower, `-3` encodes 40% slower and decodes 25% slower.
  More matches per byte means more codewords to decode. If speed matters more than
  ratio at these levels, `-0` is the fast path, and it is unchanged.

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
