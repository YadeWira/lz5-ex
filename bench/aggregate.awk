#!/usr/bin/awk -f
# Aggregate lzbench CSV output (one row per codec per file) into one row per
# codec, over the whole corpus.
#
#   codec,orig,csize,ratio,enc_mbs,dec_mbs,files
#
# Sizes are exact sums. Speeds are weighted by bytes, i.e. total bytes divided
# by total time, which is the same aggregation lzbench/other harnesses use.
BEGIN { FS = ","; OFS = ","; print "codec,orig,csize,ratio,enc_mbs,dec_mbs,files" }

NR == 1 { next }                       # header
/^Compressor name/ { next }            # lzbench repeats this per file
NF < 6 { next }

{
    name = $1
    enc  = $2 + 0
    dec  = $3 + 0
    orig = $4 + 0
    csz  = $5 + 0

    if (!(name in seen)) { seen[name] = 1; order[++n] = name }
    o[name] += orig
    c[name] += csz
    f[name] += 1
    if (enc > 0) enct[name] += orig / enc
    if (dec > 0) dect[name] += orig / dec
}

END {
    for (i = 1; i <= n; i++) {
        k = order[i]
        es = (enct[k] > 0) ? o[k] / enct[k] : 0
        ds = (dect[k] > 0) ? o[k] / dect[k] : 0
        printf "%s,%d,%d,%.3f,%.2f,%.2f,%d\n", k, o[k], c[k], 100.0 * c[k] / o[k], es, ds, f[k]
    }
}
