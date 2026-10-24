import 'package:hive_ce/hive.dart';

class GlobalState extends HiveObject {
  int lifetimeTotalTaps;
  int lifetimeTotalSessions;
  final int epoch;

  /// When the current lifetime started, or null if it was never reset.
  final DateTime? lastResetAt;

  GlobalState({
    required this.lifetimeTotalTaps,
    required this.lifetimeTotalSessions,
    this.epoch = 0,
    this.lastResetAt,
  });
}

class GlobalStateAdapter extends TypeAdapter<GlobalState> {
  @override
  final int typeId = 1;

  @override
  GlobalState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    final resetAt = fields[3] as int?;
    return GlobalState(
      lifetimeTotalTaps: fields[0] as int,
      lifetimeTotalSessions: fields[1] as int,
      epoch: fields[2] as int? ?? 0,
      lastResetAt: resetAt == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(resetAt),
    );
  }

  @override
  void write(BinaryWriter writer, GlobalState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.lifetimeTotalTaps)
      ..writeByte(1)
      ..write(obj.lifetimeTotalSessions)
      ..writeByte(2)
      ..write(obj.epoch)
      ..writeByte(3)
      ..write(obj.lastResetAt?.millisecondsSinceEpoch);
  }
}
