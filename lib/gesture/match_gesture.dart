import 'dart:ui';

class GestureUtils {
  static bool isGestureSimilar(List<Offset?> a, List<Offset?> b) {
    List<Offset> cleanA = a.whereType<Offset>().toList();
    List<Offset> cleanB = b.whereType<Offset>().toList();

    if (cleanA.isEmpty || cleanB.isEmpty) return false;

    List<Offset> normA = _normalizeGesture(cleanA, 50);
    List<Offset> normB = _normalizeGesture(cleanB, 50);

    double totalDist = 0;
    for (int i = 0; i < normA.length; i++) {
      totalDist += (normA[i] - normB[i]).distance;
    }

    double avgDist = totalDist / normA.length;

    return avgDist < 35.0;
  }

  static List<Offset> _resampleGesture(List<Offset> points, int targetLength) {
    List<Offset> resampled = [];
    for (int i = 0; i < targetLength; i++) {
      double t = i * (points.length - 1) / (targetLength - 1);
      int idx = t.floor();
      double frac = t - idx;

      if (idx + 1 < points.length) {
        double x = points[idx].dx * (1 - frac) + points[idx + 1].dx * frac;
        double y = points[idx].dy * (1 - frac) + points[idx + 1].dy * frac;
        resampled.add(Offset(x, y));
      } else {
        resampled.add(points[idx]);
      }
    }
    return resampled;
  }

  static List<Offset> _normalizeGesture(List<Offset> points, int targetLength) {
    List<Offset> resampled = _resampleGesture(points, targetLength);

    double cx = resampled.map((p) => p.dx).reduce((a, b) => a + b) / resampled.length;
    double cy = resampled.map((p) => p.dy).reduce((a, b) => a + b) / resampled.length;
    resampled = resampled.map((p) => Offset(p.dx - cx, p.dy - cy)).toList();

    double minX = resampled.map((p) => p.dx).reduce((a, b) => a < b ? a : b);
    double maxX = resampled.map((p) => p.dx).reduce((a, b) => a > b ? a : b);
    double minY = resampled.map((p) => p.dy).reduce((a, b) => a < b ? a : b);
    double maxY = resampled.map((p) => p.dy).reduce((a, b) => a > b ? a : b);

    double scale = 200 /
        ((maxX - minX).abs() > (maxY - minY).abs()
            ? (maxX - minX).abs()
            : (maxY - minY).abs());

    resampled = resampled.map((p) => Offset(p.dx * scale, p.dy * scale)).toList();

    return resampled;
  }
}
