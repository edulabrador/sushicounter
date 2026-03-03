import 'package:hive/hive.dart';

class GlobalState extends HiveObject {
  int lifetimeTotalTaps;
  int lifetimeTotalSessions;

  GlobalState({
    required this.lifetimeTotalTaps,
    required this.lifetimeTotalSessions,
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
    return GlobalState(
      lifetimeTotalTaps: fields[0] as int,
      lifetimeTotalSessions: fields[1] as int,
    );
  }

  @override
  void write(BinaryWriter writer, GlobalState obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.lifetimeTotalTaps)
      ..writeByte(1)
      ..write(obj.lifetimeTotalSessions);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GlobalStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
