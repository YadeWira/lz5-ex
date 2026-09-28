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
| xz 5.8.4 -9            |      2.6 MB/s |    112.2 MB/s |    48795480 |  23.02 |
| xz 5.8.4 -6            |      3.0 MB/s |    111.9 MB/s |    49408824 |  23.31 |
| brotli 1.2.0 -11       |      0.5 MB/s |    366.9 MB/s |    50328370 |  23.75 |
| zstd 1.5.7 -19         |      2.8 MB/s |    765.6 MB/s |    52891946 |  24.96 |
| bzip2 1.0.8 -9         |     11.1 MB/s |     33.3 MB/s |    54506769 |  25.72 |
| zstd 1.5.7 -9          |     52.2 MB/s |    818.4 MB/s |    59081628 |  27.88 |
| brotli 1.2.0 -5        |     33.5 MB/s |    401.3 MB/s |    59553197 |  28.10 |
| lz5-ex 1.5.1 -15       |      2.1 MB/s |    711.3 MB/s |    65595195 |  30.95 |
| lz5-ex 1.5.1 -14       |      4.5 MB/s |    714.0 MB/s |    65938065 |  31.11 |
| zstd 1.5.7 -3          |    167.6 MB/s |    823.7 MB/s |    66137723 |  31.21 |
| zlib 1.3.2 -9          |     11.0 MB/s |    330.0 MB/s |    67643273 |  31.92 |
| lz5-ex 1.5.1 -13       |      6.4 MB/s |    747.1 MB/s |    68066924 |  32.12 |
| lz5-ex 1.5.1 -12       |     11.3 MB/s |    769.5 MB/s |    69498052 |  32.79 |
| lz5-ex 1.5.1 -11       |     14.8 MB/s |    761.8 MB/s |    71067136 |  33.53 |
| lz5-ex 1.5.1 -10       |     20.1 MB/s |    770.6 MB/s |    72273640 |  34.10 |
| zstd 1.5.7 -1          |    348.3 MB/s |   1176.9 MB/s |    73229468 |  34.55 |
| lz5-ex 1.5.1 -9        |     26.6 MB/s |    797.6 MB/s |    74233427 |  35.03 |
| lz4hc 1.10.0 -9        |     28.5 MB/s |   3459.1 MB/s |    77884211 |  36.75 |
| lz5-ex 1.5.1 -8        |     39.9 MB/s |    827.2 MB/s |    77999308 |  36.80 |
| lz5-ex 1.5.1 -7        |     43.7 MB/s |    888.6 MB/s |    78856564 |  37.21 |
| lz5-ex 1.5.1 -6        |     47.0 MB/s |    946.5 MB/s |    80576517 |  38.02 |
| lz5-ex 1.5.1 -5        |    128.6 MB/s |    775.2 MB/s |    84455921 |  39.85 |
| lz5-ex 1.5.1 -4        |    168.6 MB/s |    943.3 MB/s |    86505387 |  40.82 |
| lz5-ex 1.5.1 -0        |    238.2 MB/s |    676.7 MB/s |    88218423 |  41.62 |
| lz5-ex 1.5.1 -3        |    307.5 MB/s |   1182.5 MB/s |    95574729 |  45.09 |
| lizard 2.1 -20         |    321.3 MB/s |   1770.7 MB/s |    96927713 |  45.73 |
| lz4 1.10.0             |    533.2 MB/s |   3586.2 MB/s |   100880147 |  47.60 |
| lz5-ex 1.5.1 -2        |    407.7 MB/s |   1383.7 MB/s |   104073879 |  49.11 |
| lz5-ex 1.5.1 -1        |    500.7 MB/s |   1504.3 MB/s |   113525877 |  53.56 |

`Ratio` is the compressed size as a percentage of the original, so lower is
better. Sizes are exact; the speeds are single-thread figures from one machine
and will differ on other hardware.

`-0` is the plain fast path; `-1` to `-15` are the high-compression parsers. The
levels are not one smooth curve: `-1` to `-3` are the "fast" HC profiles tuned
for speed, which is why `-0` compresses better than `-1` while also being
faster. From `-4` upwards the ratio improves monotonically with the level.

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
