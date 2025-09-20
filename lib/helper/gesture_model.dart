import 'dart:convert';
import 'dart:ui';

class GestureModel {
  int? id;
  int? folderId;
  List<Offset?> points;
  DateTime createdAt;

  GestureModel({
    this.id,
    this.folderId,
    required this.points,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'folderId': folderId,
      'gesturePoints': jsonEncode(
        points.map((p) => p == null ? null : {'dx': p.dx, 'dy': p.dy}).toList(),
      ),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory GestureModel.fromMap(Map<String, dynamic> map) {
    final List<dynamic> decodedPoints = jsonDecode(map['gesturePoints']);
    final List<Offset?> pointList = decodedPoints.map((item) {
      if (item == null) return null;
      return Offset(item['dx'], item['dy']);
    }).toList();

    return GestureModel(
      id: map['id'],
      folderId: map['folderId'],
      points: pointList,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  String encodePoints() {
    return jsonEncode(points.map((p) =>
    p == null ? null : {'dx': p.dx, 'dy': p.dy}
    ).toList());
  }

  static List<Offset?> decodePoints(String data) {
    final raw = jsonDecode(data) as List;
    return raw.map((p) {
      if (p == null) return null;
      return Offset(p['dx'], p['dy']);
    }).toList();
  }
}
