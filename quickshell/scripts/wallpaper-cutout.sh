#!/bin/sh
set -eu

CACHE="${XDG_CACHE_HOME:-$HOME/.cache}"
CACHE="${CACHE%/}/quickshell"
OUT_PNG="$CACHE/wallpaper-cutout.png"
OUT_JSON="$CACHE/wallpaper-cutout.json"

TARGET_W=2560
TARGET_H=1440
FUZZ=4%
FEATHER=2
SEED=
SRC=

while [ $# -gt 0 ]; do
    case "$1" in
        --seed)   SEED="$2"; shift 2 ;;
        --fuzz)   FUZZ="$2"; shift 2 ;;
        --feather) FEATHER="$2"; shift 2 ;;
        --target) TARGET_W="${2%x*}"; TARGET_H="${2#*x}"; shift 2 ;;
        -h|--help) sed -n '2,31p' "$0" | sed 's/^# \?//'; exit 0 ;;
        *)        SRC="$1"; shift ;;
    esac
done

if [ -z "$SRC" ]; then
    SRC=$(swww query 2>/dev/null | sed -n 's/.*currently displaying: image: //p' | head -1)
fi
[ -n "$SRC" ] && [ -f "$SRC" ] || { echo "wallpaper-cutout: no source image" >&2; exit 1; }

mkdir -p "$CACHE"
TMP=$(mktemp -d "$CACHE/.build.XXXXXX"); trap 'rm -rf "$TMP"' EXIT

SRC_W=$(magick identify -format '%w' "$SRC[0]")
SRC_H=$(magick identify -format '%h' "$SRC[0]")

read -r OUT_W OUT_H <<EOF
$(awk -v w="$SRC_W" -v h="$SRC_H" -v tw="$TARGET_W" -v th="$TARGET_H" 'BEGIN {
    s = tw / w; if (th / h > s) s = th / h;
    if (s > 1) s = 1;
    printf "%d %d", int(w * s + 0.5), int(h * s + 0.5);
}')
EOF

magick "$SRC[0]" -resize "${OUT_W}x${OUT_H}!" "$TMP/wp.png"

if [ -z "$SEED" ]; then
    PROXY_W=480
    PROXY_H=$(( SRC_H * PROXY_W / SRC_W ))
    SEED=$(magick "$TMP/wp.png" -filter point -resize "${PROXY_W}x${PROXY_H}!" -depth 8 rgb:- |
        PROXY_W=$PROXY_W PROXY_H=$PROXY_H OUT_W=$OUT_W OUT_H=$OUT_H python3 -c '
import os, sys, collections
w, h = int(os.environ["PROXY_W"]), int(os.environ["PROXY_H"])
ow, oh = int(os.environ["OUT_W"]), int(os.environ["OUT_H"])
d = sys.stdin.buffer.read()
top = int(h * 0.45)
count = collections.Counter()
for y in range(top):
    row = d[y * w * 3:(y + 1) * w * 3]
    for x in range(w):
        count[row[x * 3:x * 3 + 3]] += 1
if not count:
    sys.exit(1)
colour, _ = count.most_common(1)[0]
pts = [(x, y) for y in range(top) for x in range(w)
       if d[(y * w + x) * 3:(y * w + x) * 3 + 3] == colour]
mx = sorted(p[0] for p in pts)[len(pts) // 2]
my = sorted(p[1] for p in pts)[len(pts) // 2]
sx, sy = min(pts, key=lambda p: (p[0] - mx) ** 2 + (p[1] - my) ** 2)
print("%d,%d" % (sx * ow // w, sy * oh // h))
')
fi
[ -n "$SEED" ] || { echo "wallpaper-cutout: could not pick a seed point" >&2; exit 1; }

SKY_HEX=$(magick "$TMP/wp.png" -format "%[hex:p{${SEED%,*},${SEED#*,}}]" info:)

magick "$TMP/wp.png" -alpha set -fuzz "$FUZZ" \
    -fill none -draw "color ${SEED%,*},${SEED#*,} floodfill" \
    PNG32:"$TMP/cutout.png"

ANALYSIS_W=640
ANALYSIS_H=$(( OUT_H * ANALYSIS_W / OUT_W ))

magick "$TMP/cutout.png" -alpha extract -filter point \
    -resize "${ANALYSIS_W}x${ANALYSIS_H}!" -depth 8 gray:- >"$TMP/alpha.gray"

AW=$ANALYSIS_W AH=$ANALYSIS_H OUT_W=$OUT_W OUT_H=$OUT_H \
    SRC="$SRC" OUT_PNG="$OUT_PNG" SEED="$SEED" FUZZ="$FUZZ" SKY_HEX="$SKY_HEX" \
    OUT_JSON_TMP="$TMP/out.json" \
    python3 -c '
import json, os, sys, time
aw, ah = int(os.environ["AW"]), int(os.environ["AH"])
ow, oh = int(os.environ["OUT_W"]), int(os.environ["OUT_H"])
d = sys.stdin.buffer.read()

top, bottom = {}, {}
for y in range(ah):
    row = d[y * aw:(y + 1) * aw]
    for x in range(aw):
        if row[x] < 128:
            if x not in top:
                top[x] = y
            bottom[x] = y

if not bottom:
    print("wallpaper-cutout: the fill found no sky", file=sys.stderr)
    sys.exit(2)

area = sum(bottom[x] - top[x] + 1 for x in bottom)
if area < aw * ah * 0.01:
    print("wallpaper-cutout: sky is under 1%% of the frame, refusing", file=sys.stderr)
    sys.exit(2)

roof = [bottom.get(x, -1) + 1 for x in range(aw)]
best = (0, 0, 0, 0)
stack = []
for x in range(aw + 1):
    hgt = roof[x] if x < aw else 0
    start = x
    while stack and stack[-1][1] >= hgt:
        sx, sh = stack.pop()
        a = sh * (x - sx)
        if a > best[0]:
            best = (a, sx, x - 1, sh)
        start = sx
    stack.append((start, hgt))

_, x0, x1, depth = best
pocket_top = max(top.get(x, 0) for x in range(x0, x1 + 1))

sx0, sx1 = min(bottom), max(bottom)
sky_top = min(top.values())
sky_bottom = max(bottom.values())

fx, fy = ow / aw, oh / ah
def rect(x0, y0, x1, y1):
    return {"x": round(x0 * fx), "y": round(y0 * fy),
            "width": round((x1 - x0 + 1) * fx), "height": round((y1 - y0 + 1) * fy)}

step = max(1, (x1 - x0 + 1) // 96)
line = [round((bottom.get(x, top.get(x, 0)) + 1) * fy)
        for x in range(x0, x1 + 1, step)]

row_step = max(1, (sky_bottom - sky_top + 1) // 96)
left, right = [], []
for y in range(sky_top, sky_bottom + 1, row_step):
    row = d[y * aw:(y + 1) * aw]
    xs = [x for x in range(aw) if row[x] < 128]
    left.append(round((xs[0] * fx) if xs else 0))
    right.append(round((xs[-1] * fx) if xs else -1))

out = {
    "source": os.environ["SRC"],
    "cutout": os.environ["OUT_PNG"],
    "seed": os.environ["SEED"],
    "fuzz": os.environ["FUZZ"],
    "generated": int(time.time()),
    "skyColour": "#" + os.environ["SKY_HEX"][:6],
    "width": ow,
    "height": oh,
    "sky": rect(sx0, sky_top, sx1, sky_bottom),
    "pocket": rect(x0, pocket_top, x1, depth - 1),
    "roofline": {"x": round(x0 * fx), "step": round(step * fx), "y": line},
    "rows": {"y": round(sky_top * fy), "step": round(row_step * fy),
             "left": left, "right": right},
}
json.dump(out, open(os.environ["OUT_JSON_TMP"], "w"), indent=2)
print("pocket %(x)d,%(y)d %(width)dx%(height)d" % out["pocket"])
' <"$TMP/alpha.gray" || STATUS=$?
STATUS=${STATUS:-0}

if [ "$STATUS" -eq 2 ]; then
    rm -f "$OUT_PNG" "$OUT_JSON"
    echo "wallpaper-cutout: $SRC has nowhere to hide a clock - cutout cleared"
    exit 0
fi
[ "$STATUS" -eq 0 ] || exit "$STATUS"

if [ "$FEATHER" -gt 0 ]; then
    WP="$TMP/wp.png" CUT="$TMP/cutout.png" OUT="$TMP/final.png" \
    SKY_HEX="$SKY_HEX" FUZZ="$FUZZ" FEATHER="$FEATHER" \
    python3 -c '
import os
from statistics import median
from PIL import Image, ImageChops, ImageFilter

wp = Image.open(os.environ["WP"]).convert("RGB")
cut = Image.open(os.environ["CUT"]).convert("RGBA")
W, H = wp.size
sky = tuple(int(os.environ["SKY_HEX"][i:i + 2], 16) for i in (0, 2, 4))
feather = int(os.environ["FEATHER"])

fz = os.environ["FUZZ"].strip()
tol = float(fz[:-1]) * 255 / 100 if fz.endswith("%") else float(fz)
while tol > 255:
    tol /= 257.0

OFF_LINE = 24

hard = cut.split()[3].point(lambda v: 255 if v < 128 else 0)

dist = ImageChops.difference(wp, Image.new("RGB", (W, H), sky)).split()
dist = ImageChops.lighter(ImageChops.lighter(dist[0], dist[1]), dist[2])
same = dist.point(lambda v: 255 if v <= tol else 0)
x0, y0, x1, y1 = hard.getbbox()
pad = max(1, W // 100)
box = (max(0, x0 - pad), max(0, y0 - pad), min(W, x1 + pad), min(H, y1 + pad))
walled = Image.new("L", (W, H), 0)
walled.paste(same.crop(box), box[:2])
skym = ImageChops.lighter(hard, walled)

out = wp.convert("RGBA")
out.putalpha(ImageChops.invert(skym))

grown = skym.filter(ImageFilter.MaxFilter(2 * feather + 1))
band = ImageChops.subtract(grown, skym)
solid = ImageChops.invert(ImageChops.lighter(skym, band))

edge = band.getbbox()
if edge:
    px, bp, fp, op = wp.load(), band.load(), solid.load(), out.load()
    rim = [(x, y) for y in range(edge[1], edge[3])
                  for x in range(edge[0], edge[2]) if bp[x, y]]
    near = [(dx, dy) for dy in range(-feather, feather + 1)
                     for dx in range(-feather, feather + 1) if dx or dy]

    def foreground(x, y):
        tot, wsum = [0.0, 0.0, 0.0], 0.0
        for dx, dy in near:
            xx, yy = x + dx, y + dy
            if 0 <= xx < W and 0 <= yy < H and fp[xx, yy]:
                k = 1.0 / (dx * dx + dy * dy)
                c = px[xx, yy]
                tot[0] += c[0] * k; tot[1] += c[1] * k; tot[2] += c[2] * k
                wsum += k
        return tuple(t / wsum for t in tot) if wsum else None

    seen = [foreground(x, y) for x, y in rim]
    known = [f for f in seen if f]
    spare = tuple(median(f[i] for f in known) for i in range(3)) if known else None

    for (x, y), fg in zip(rim, seen):
        fg = fg or spare
        if fg is None:
            continue
        run = [fg[i] - sky[i] for i in range(3)]
        span = sum(v * v for v in run)
        if span < 1:
            continue
        c = px[x, y]
        off = [c[i] - sky[i] for i in range(3)]
        a = sum(off[i] * run[i] for i in range(3)) / span
        if a >= 1:
            continue
        if a <= 0.02:
            op[x, y] = (0, 0, 0, 0)
            continue
        if max(abs(off[i] - a * run[i]) for i in range(3)) > OFF_LINE:
            continue
        op[x, y] = tuple(max(0, min(255, round(sky[i] + off[i] / a)))
                         for i in range(3)) + (round(a * 255),)

out.save(os.environ["OUT"])
' || {
        echo "wallpaper-cutout: could not soften the edge, keeping the hard cut" >&2
        cp "$TMP/cutout.png" "$TMP/final.png"
    }
else
    cp "$TMP/cutout.png" "$TMP/final.png"
fi

mv "$TMP/final.png" "$OUT_PNG"
mv "$TMP/out.json" "$OUT_JSON"
echo "wallpaper-cutout: $SRC -> $OUT_PNG (seed $SEED, fuzz $FUZZ)"
