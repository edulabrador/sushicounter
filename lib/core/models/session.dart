import 'package:hive_ce/hive.dart';

import 'companion.dart';

export 'companion.dart';

const _keep = Object();

class Session extends HiveObject {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int count;
  final int durationSeconds;
  final int contributionEpoch;

  /// What the meal cost, in hundredths of the local currency, if recorded.
  final int? priceCents;

  /// Where the session happened, if recorded.
  final String? restaurant;

  /// Others counted at the same table; your own pieces are [count].
  final List<Companion> companions;

  /// Most pieces a session can be edited to.
  static const maxCount = 9999;

  /// Longest restaurant name accepted from the UI and from backups.
  static const maxRestaurantLength = 60;

  /// Trims [name] and turns blank names into null.
  static String? normalizeRestaurant(String? name) {
    final trimmed = name?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  Session({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.count,
    required this.durationSeconds,
    this.contributionEpoch = 0,
    this.priceCents,
    this.restaurant,
    this.companions = const [],
  });

  Session copyWith({
    int? count,
    DateTime? startedAt,
    DateTime? endedAt,
    int? contributionEpoch,
    Object? priceCents = _keep,
    Object? restaurant = _keep,
    List<Companion>? companions,
  }) => Session(
    id: id,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt ?? this.endedAt,
    count: count ?? this.count,
    durationSeconds: durationSeconds,
    contributionEpoch: contributionEpoch ?? this.contributionEpoch,
    priceCents: identical(priceCents, _keep)
        ? this.priceCents
        : priceCents as int?,
    restaurant: identical(restaurant, _keep)
        ? this.restaurant
        : restaurant as String?,
    companions: companions ?? this.companions,
  );

  /// Epoch of legacy history whose totals could not be attributed safely.
  static const unattributedEpoch = -1;

  /// Whether this session belongs to the lifetime shown for [epoch]. Legacy
  /// history is shown as part of the first lifetime, but deleting it never
  /// changes totals (see [HiveRepository.deleteSessionWithTotals]).
  bool isInLifetime(int epoch) =>
      contributionEpoch == epoch ||
      (epoch == 0 && contributionEpoch == unattributedEpoch);

  /// Taps per minute, or null when the session is too short to be meaningful.
  double? get tapsPerMinute =>
      durationSeconds < 60 ? null : count / (durationSeconds / 60);
}

/// A deleted session plus the exact totals its delete removed, so undo can
/// put back precisely what was taken even when the delete was clamped at 0.
class DeletedSession {
  const DeletedSession(
    this.session, {
    required this.tapsRemoved,
    required this.sessionsRemoved,
  });

  final Session session;
  final int tapsRemoved;
  final int sessionsRemoved;
}

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 0;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      startedAt: fields[1] as DateTime,
      endedAt: fields[2] as DateTime,
      count: fields[3] as int,
      durationSeconds: fields[4] as int,
      contributionEpoch: fields[5] as int? ?? 0,
      priceCents: fields[6] as int?,
      restaurant: fields[7] as String?,
      companions: Companion.listFromRaw(fields[8]),
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.endedAt)
      ..writeByte(3)
      ..write(obj.count)
      ..writeByte(4)
      ..write(obj.durationSeconds)
      ..writeByte(5)
      ..write(obj.contributionEpoch)
      ..writeByte(6)
      ..write(obj.priceCents)
      ..writeByte(7)
      ..write(obj.restaurant)
      ..writeByte(8)
      ..write([for (final companion in obj.companions) companion.toMap()]);
  }
}
