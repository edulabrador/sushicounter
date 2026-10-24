import 'package:hive_ce/hive.dart';

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

  Session({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.count,
    required this.durationSeconds,
    this.contributionEpoch = 0,
    this.priceCents,
  });

  Session copyWith({int? contributionEpoch, Object? priceCents = _keep}) =>
      Session(
        id: id,
        startedAt: startedAt,
        endedAt: endedAt,
        count: count,
        durationSeconds: durationSeconds,
        contributionEpoch: contributionEpoch ?? this.contributionEpoch,
        priceCents: identical(priceCents, _keep)
            ? this.priceCents
            : priceCents as int?,
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
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(7)
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
      ..write(obj.priceCents);
  }
}
