import 'package:hive/hive.dart';

part 'split_entry.g.dart';

@HiveType(typeId: 1)
class SplitEntry extends HiveObject {
  @HiveField(0)
  late String personId;

  @HiveField(1)
  late double amount;

  SplitEntry({
    required this.personId,
    required this.amount,
  });

  SplitEntry.empty()
      : personId = '',
        amount = 0.0;
}
