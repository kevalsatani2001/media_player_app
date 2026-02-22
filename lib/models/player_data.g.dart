// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_data.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PlayerStateAdapter extends TypeAdapter<PlayerState> {
  @override
  final int typeId = 3;

  @override
  PlayerState read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PlayerState()
      ..paths = (fields[0] as List).cast<String>()
      ..currentIndex = fields[1] as int
      ..currentType = fields[2] as String
      ..currentPositionMs = fields[3] as int;
  }

  @override
  void write(BinaryWriter writer, PlayerState obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.paths)
      ..writeByte(1)
      ..write(obj.currentIndex)
      ..writeByte(2)
      ..write(obj.currentType)
      ..writeByte(3)
      ..write(obj.currentPositionMs);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlayerStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
