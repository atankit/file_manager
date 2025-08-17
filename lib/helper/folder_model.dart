class Folder {
  int? id;
  String name;
  DateTime createdAt;
  bool isFile;
  String? filePath;
  int? parentId;

  Folder({
    this.id,
    required this.name,
    required this.createdAt,
    this.isFile = false,
    this.filePath,
    this.parentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isFile': isFile ? 1 : 0,
      'filePath': filePath,
      'parentId': parentId,
    };
  }

  factory Folder.fromMap(Map<String, dynamic> map) {
    return Folder(
      id: map['id'],
      name: map['name'],
      createdAt: DateTime.parse(map['createdAt']),
      isFile: map['isFile'] == 1,
      filePath: map['filePath'],
      parentId: map['parentId'],
    );
  }
}
