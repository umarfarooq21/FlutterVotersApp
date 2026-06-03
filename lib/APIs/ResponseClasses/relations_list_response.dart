/// One row from staging `GET /getRelations` (JSON array).
class RelationItem {
  final int id;
  final String relationName;

  const RelationItem({
    required this.id,
    required this.relationName,
  });

  factory RelationItem.fromJson(Map<String, dynamic> json) {
    final idRaw = json['id'];
    final id = idRaw is int
        ? idRaw
        : int.tryParse(idRaw?.toString() ?? '') ?? 0;
    return RelationItem(
      id: id,
      relationName: json['relation_name']?.toString().trim() ?? '',
    );
  }

  /// Parses a root JSON array (actual API shape).
  static List<RelationItem> listFromDecoded(dynamic decoded) {
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((e) => RelationItem.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.relationName.isNotEmpty)
        .toList();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RelationItem && id == other.id && relationName == other.relationName;

  @override
  int get hashCode => Object.hash(id, relationName);
}
