import 'package:hive/hive.dart';

class Session extends HiveObject {
  final String id;
  final DateTime startedAt;
  final DateTime endedAt;
  final int count;
  final int durationSeconds;

  Session({
    required this.id,
    required this.startedAt,
    required this.endedAt,
    required this.count,
    required this.durationSeconds,
  });
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
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.endedAt)
      ..writeByte(3)
      ..write(obj.count)
      ..writeByte(4)
      ..write(obj.durationSeconds);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
