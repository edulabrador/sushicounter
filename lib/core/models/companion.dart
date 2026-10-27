/// Someone else at the table, counted on the same phone.
class Companion {
  const Companion({required this.name, this.count = 0});

  final String name;
  final int count;

  /// Most people besides you at one table.
  static const maxPerTable = 8;

  /// Longest name accepted from the UI and from backups.
  static const maxNameLength = 30;

  /// Trims [name]; blank names are null.
  static String? normalizeName(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Companion copyWith({int? count}) =>
      Companion(name: name, count: count ?? this.count);

  Map<String, Object> toMap() => {'name': name, 'count': count};

  /// Reads what [toMap] wrote. Throws [FormatException] for anything else.
  static Companion fromMap(Object? raw) {
    if (raw is! Map) throw const FormatException('Bad companion');
    final name = raw['name'];
    final count = raw['count'];
    if (name is! String ||
        normalizeName(name) != name ||
        name.length > maxNameLength ||
        count is! int ||
        count < 0 ||
        count > 9999) {
      throw const FormatException('Bad companion');
    }
    return Companion(name: name, count: count);
  }

  static List<Companion> listFromRaw(Object? raw) {
    if (raw == null) return const [];
    if (raw is! List || raw.length > maxPerTable) {
      throw const FormatException('Bad companions');
    }
    return List.unmodifiable(raw.map(fromMap));
  }

  @override
  bool operator ==(Object other) =>
      other is Companion && other.name == name && other.count == count;

  @override
  int get hashCode => Object.hash(name, count);

  @override
  String toString() => 'Companion($name, $count)';
}

/// Total pieces of [companions].
int companionsTotal(List<Companion> companions) =>
    companions.fold(0, (sum, companion) => sum + companion.count);
