import 'package:hive/hive.dart';
import 'split_entry.dart';

part 'bill.g.dart';

@HiveType(typeId: 2)
class Bill extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late double totalAmount;

  @HiveField(4)
  late DateTime date;

  @HiveField(5)
  late String payerId;

  @HiveField(6)
  late List<SplitEntry> splits;

  @HiveField(7)
  late String imageUrl;

  @HiveField(8)
  late String category;

  Bill({
    required this.id,
    required this.title,
    required this.description,
    required this.totalAmount,
    required this.date,
    required this.payerId,
    required this.splits,
    this.imageUrl = '',
    this.category = 'General',
  });

  Bill.empty()
      : id = '',
        title = '',
        description = '',
        totalAmount = 0.0,
        date = DateTime.now(),
        payerId = '',
        splits = [],
        imageUrl = '',
        category = 'General';

  double get totalSplit => splits.fold(0.0, (sum, split) => sum + split.amount);

  double get remaining => totalAmount - totalSplit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bill && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
