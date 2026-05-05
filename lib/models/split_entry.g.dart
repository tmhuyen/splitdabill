// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'split_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SplitEntryAdapter extends TypeAdapter<SplitEntry> {
  @override
  final int typeId = 1;

  @override
  SplitEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SplitEntry(
      personId: fields[0] as String,
      amount: fields[1] as double,
    );
  }

  @override
  void write(BinaryWriter writer, SplitEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.personId)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SplitEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
