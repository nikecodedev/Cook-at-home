/// Remove red annotation overlays from a screenshot (e.g., pure-red rectangles).
///
/// Default behavior targets *pure red* pixels (high R, low G/B) to avoid touching
/// normal UI accent colors. Use `--all-red` to remove broader red/orange UI colors.
///
/// Usage (PowerShell):
///   dart run tool/remove_red_overlays.dart --in path\to\image.png --out path\to\clean.png
///   dart run tool/remove_red_overlays.dart --in in.png --out out.png --all-red
library;

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class RedThreshold {
  const RedThreshold({
    required this.rMin,
    required this.gMax,
    required this.bMax,
    required this.rMargin,
  });

  final int rMin;
  final int gMax;
  final int bMax;
  final int rMargin;
}

const pureRed = RedThreshold(rMin: 200, gMax: 80, bMax: 80, rMargin: 80);
const allRed = RedThreshold(rMin: 160, gMax: 140, bMax: 140, rMargin: 50);

bool isTargetRed(int r, int g, int b, RedThreshold t) {
  if (r < t.rMin || g > t.gMax || b > t.bMax) return false;
  final maxGb = g > b ? g : b;
  return (r - maxGb) >= t.rMargin;
}

int parseIntOr(String v, int fallback) => int.tryParse(v) ?? fallback;

({String? input, String? output, bool allRed, int radius, int expand})
parseArgs(List<String> args) {
  String? input;
  String? output;
  var useAllRed = false;
  var radius = 30;
  var expand = 1;

  for (var i = 0; i < args.length; i++) {
    final a = args[i];
    if (a == '--in' && i + 1 < args.length) {
      input = args[++i];
    } else if (a == '--out' && i + 1 < args.length) {
      output = args[++i];
    } else if (a == '--all-red') {
      useAllRed = true;
    } else if (a == '--radius' && i + 1 < args.length) {
      radius = parseIntOr(args[++i], radius);
    } else if (a == '--expand' && i + 1 < args.length) {
      expand = parseIntOr(args[++i], expand);
    } else if (a == '--help' || a == '-h') {
      // handled by main
    }
  }

  return (input: input, output: output, allRed: useAllRed, radius: radius, expand: expand);
}

Never _usage([String? error]) {
  if (error != null && error.isNotEmpty) {
    stderr.writeln('Error: $error');
    stderr.writeln('');
  }
  stderr.writeln('Usage:');
  stderr.writeln(r'  dart run tool/remove_red_overlays.dart --in <input.png> --out <output.png> [--all-red] [--radius 30] [--expand 1]');
  stderr.writeln('');
  stderr.writeln('Notes:');
  stderr.writeln('- Default removes only pure-red annotation boxes (safer).');
  stderr.writeln('- Use --all-red if you *also* want to remove red/orange UI elements.');
  exit(2);
}

img.Image removeRedOverlays(
  img.Image src, {
  required RedThreshold threshold,
  required int searchRadius,
  required int expandMaskPx,
}) {
  final w = src.width;
  final h = src.height;
  final len = w * h;

  // Mask: 1 = remove, 0 = keep
  var mask = Uint8List(len);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final p = src.getPixel(x, y);
      final a = p.a;
      if (a == 0) continue;
      if (isTargetRed(p.r.toInt(), p.g.toInt(), p.b.toInt(), threshold)) {
        mask[y * w + x] = 1;
      }
    }
  }

  if (expandMaskPx > 0) {
    final expanded = Uint8List.fromList(mask);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final idx = y * w + x;
        if (mask[idx] == 0) continue;
        for (var dy = -expandMaskPx; dy <= expandMaskPx; dy++) {
          final ny = y + dy;
          if (ny < 0 || ny >= h) continue;
          final rowBase = ny * w;
          for (var dx = -expandMaskPx; dx <= expandMaskPx; dx++) {
            final nx = x + dx;
            if (nx < 0 || nx >= w) continue;
            expanded[rowBase + nx] = 1;
          }
        }
      }
    }
    mask = expanded;
  }

  // Nearest non-masked pixel in each row (left & right).
  final left = Int32List(len);
  final right = Int32List(len);

  for (var y = 0; y < h; y++) {
    var last = -1;
    final rowBase = y * w;
    for (var x = 0; x < w; x++) {
      final idx = rowBase + x;
      if (mask[idx] == 0) last = x;
      left[idx] = last;
    }

    last = -1;
    for (var x = w - 1; x >= 0; x--) {
      final idx = rowBase + x;
      if (mask[idx] == 0) last = x;
      right[idx] = last;
    }
  }

  final out = img.Image.from(src);

  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final idx = y * w + x;
      if (mask[idx] == 0) continue;

      var rs = 0;
      var gs = 0;
      var bs = 0;
      var count = 0;

      final lx = left[idx];
      if (lx != -1 && (x - lx) <= searchRadius) {
        final p = src.getPixel(lx, y);
        rs += p.r.toInt();
        gs += p.g.toInt();
        bs += p.b.toInt();
        count++;
      }

      final rx = right[idx];
      if (rx != -1 && (rx - x) <= searchRadius) {
        final p = src.getPixel(rx, y);
        rs += p.r.toInt();
        gs += p.g.toInt();
        bs += p.b.toInt();
        count++;
      }

      // Vertical scan (bounded).
      for (var dy = 1; dy <= searchRadius; dy++) {
        final ny = y - dy;
        if (ny < 0) break;
        final nIdx = ny * w + x;
        if (mask[nIdx] == 0) {
          final p = src.getPixel(x, ny);
          rs += p.r.toInt();
          gs += p.g.toInt();
          bs += p.b.toInt();
          count++;
          break;
        }
      }

      for (var dy = 1; dy <= searchRadius; dy++) {
        final ny = y + dy;
        if (ny >= h) break;
        final nIdx = ny * w + x;
        if (mask[nIdx] == 0) {
          final p = src.getPixel(x, ny);
          rs += p.r.toInt();
          gs += p.g.toInt();
          bs += p.b.toInt();
          count++;
          break;
        }
      }

      if (count == 0) continue; // fallback: keep original pixel
      final r = (rs / count).round().clamp(0, 255).toInt();
      final g = (gs / count).round().clamp(0, 255).toInt();
      final b = (bs / count).round().clamp(0, 255).toInt();
      out.setPixelRgba(x, y, r, g, b, 255);
    }
  }

  return out;
}

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _usage();
  }

  final parsed = parseArgs(args);
  if (parsed.input == null || parsed.output == null) {
    _usage('Missing --in or --out.');
  }

  final inPath = File(parsed.input!);
  if (!inPath.existsSync()) {
    _usage('Input file not found: ${inPath.path}');
  }

  final bytes = inPath.readAsBytesSync();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    _usage('Could not decode image: ${inPath.path}');
  }

  final threshold = parsed.allRed ? allRed : pureRed;
  final cleaned = removeRedOverlays(
    decoded,
    threshold: threshold,
    searchRadius: math.max(1, parsed.radius),
    expandMaskPx: math.max(0, parsed.expand),
  );

  final outFile = File(parsed.output!);
  outFile.parent.createSync(recursive: true);
  outFile.writeAsBytesSync(img.encodePng(cleaned));

  stdout.writeln('Wrote: ${outFile.path}');
}


