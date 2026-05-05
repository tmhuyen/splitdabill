import 'package:hive/hive.dart';

part 'transaction.g.dart';

@HiveType(typeId: 4)
class Transaction extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String fromPersonId;

  @HiveField(2)
  late String toPersonId;

  @HiveField(3)
  late double amount;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  late bool isPaid;

  Transaction({
    required this.id,
    required this.fromPersonId,
    required this.toPersonId,
    required this.amount,
    required this.date,
    this.isPaid = false,
  });

  Transaction.empty()
      : id = '',
        fromPersonId = '',
        toPersonId = '',
        amount = 0.0,
        date = DateTime.now(),
        isPaid = false;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Transaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
