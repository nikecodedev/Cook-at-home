"""
Remove red annotation overlays from a screenshot (e.g., pure-red rectangles).

Default behavior targets *pure red* pixels (high R, low G/B) to avoid touching
normal UI accent colors. Use --all-red to remove broader red/orange UI colors too.

Usage (PowerShell):
  python tools/remove_red_overlays.py --in path\to\image.png --out path\to\clean.png
  python tools/remove_red_overlays.py --in in.png --out out.png --all-red
"""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List, Optional, Sequence, Tuple

from PIL import Image


RGB = Tuple[int, int, int]


@dataclass(frozen=True)
class RedThreshold:
    r_min: int
    g_max: int
    b_max: int
    r_margin: int


PURE_RED = RedThreshold(r_min=200, g_max=80, b_max=80, r_margin=80)
# More aggressive threshold that also picks up many red/orange UI accents.
ALL_RED = RedThreshold(r_min=160, g_max=140, b_max=140, r_margin=50)


def _is_target_red(r: int, g: int, b: int, t: RedThreshold) -> bool:
    if r < t.r_min or g > t.g_max or b > t.b_max:
        return False
    return r - max(g, b) >= t.r_margin


def _iter_coords(w: int, h: int) -> Iterable[Tuple[int, int, int]]:
    # yields x,y,idx (flattened index)
    idx = 0
    for y in range(h):
        for x in range(w):
            yield x, y, idx
            idx += 1


def _avg(colors: Sequence[RGB]) -> Optional[RGB]:
    if not colors:
        return None
    rs = sum(c[0] for c in colors)
    gs = sum(c[1] for c in colors)
    bs = sum(c[2] for c in colors)
    n = len(colors)
    return (rs // n, gs // n, bs // n)


def remove_red_overlays(
    img: Image.Image,
    *,
    threshold: RedThreshold,
    search_radius: int = 30,
    expand_mask_px: int = 1,
) -> Image.Image:
    """
    Removes target red pixels by filling them from nearby non-red neighbors.
    This is a lightweight inpainting-ish approach that works well for overlay boxes.
    """
    src = img.convert("RGBA")
    w, h = src.size
    px = src.load()

    # Build initial mask: 1 = remove, 0 = keep.
    mask = bytearray(w * h)
    for x, y, idx in _iter_coords(w, h):
        r, g, b, a = px[x, y]
        if a == 0:
            continue
        if _is_target_red(r, g, b, threshold):
            mask[idx] = 1

    if expand_mask_px > 0:
        # Expand slightly to catch anti-aliased edges around the red overlay.
        expanded = bytearray(mask)
        for x, y, idx in _iter_coords(w, h):
            if mask[idx] == 0:
                continue
            for dy in range(-expand_mask_px, expand_mask_px + 1):
                ny = y + dy
                if ny < 0 or ny >= h:
                    continue
                row_base = ny * w
                for dx in range(-expand_mask_px, expand_mask_px + 1):
                    nx = x + dx
                    if nx < 0 or nx >= w:
                        continue
                    expanded[row_base + nx] = 1
        mask = expanded

    # Precompute nearest non-masked pixel indices in each row (left & right).
    # This gives fast fill for the long horizontal parts of rectangles.
    left_nearest: List[List[int]] = [[-1] * w for _ in range(h)]
    right_nearest: List[List[int]] = [[-1] * w for _ in range(h)]

    for y in range(h):
        row_base = y * w
        last = -1
        for x in range(w):
            if mask[row_base + x] == 0:
                last = x
            left_nearest[y][x] = last

        last = -1
        for x in range(w - 1, -1, -1):
            if mask[row_base + x] == 0:
                last = x
            right_nearest[y][x] = last

    out = Image.new("RGBA", (w, h))
    out_px = out.load()

    # Fill masked pixels.
    for x, y, idx in _iter_coords(w, h):
        if mask[idx] == 0:
            out_px[x, y] = px[x, y]
            continue

        candidates: List[RGB] = []

        lx = left_nearest[y][x]
        if lx != -1 and (x - lx) <= search_radius:
            r, g, b, _ = px[lx, y]
            candidates.append((r, g, b))

        rx = right_nearest[y][x]
        if rx != -1 and (rx - x) <= search_radius:
            r, g, b, _ = px[rx, y]
            candidates.append((r, g, b))

        # Vertical scan (cheap because overlays are thin; radius limits work).
        for dy in range(1, search_radius + 1):
            ny = y - dy
            if ny < 0:
                break
            if mask[ny * w + x] == 0:
                r, g, b, _ = px[x, ny]
                candidates.append((r, g, b))
                break

        for dy in range(1, search_radius + 1):
            ny = y + dy
            if ny >= h:
                break
            if mask[ny * w + x] == 0:
                r, g, b, _ = px[x, ny]
                candidates.append((r, g, b))
                break

        fill = _avg(candidates)
        if fill is None:
            # Fallback: keep original pixel if we couldn't find neighbors.
            out_px[x, y] = px[x, y]
        else:
            out_px[x, y] = (fill[0], fill[1], fill[2], 255)

    return out


def main() -> int:
    parser = argparse.ArgumentParser(description="Remove red overlays from an image.")
    parser.add_argument("--in", dest="in_path", required=True, help="Input image path")
    parser.add_argument("--out", dest="out_path", required=True, help="Output image path")
    parser.add_argument(
        "--all-red",
        action="store_true",
        help="Also remove broader red/orange UI colors (more aggressive).",
    )
    parser.add_argument(
        "--radius",
        type=int,
        default=30,
        help="Neighbor search radius for filling removed pixels (default: 30).",
    )
    parser.add_argument(
        "--expand",
        type=int,
        default=1,
        help="Mask expansion in pixels to catch anti-aliased edges (default: 1).",
    )
    args = parser.parse_args()

    in_path = Path(args.in_path)
    out_path = Path(args.out_path)
    if not in_path.exists():
        raise SystemExit(f"Input file not found: {in_path}")

    threshold = ALL_RED if args.all_red else PURE_RED
    img = Image.open(in_path)
    cleaned = remove_red_overlays(
        img,
        threshold=threshold,
        search_radius=max(1, args.radius),
        expand_mask_px=max(0, args.expand),
    )
    out_path.parent.mkdir(parents=True, exist_ok=True)
    cleaned.save(out_path)
    print(f"Wrote: {out_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())








