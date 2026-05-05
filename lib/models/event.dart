import 'package:hive/hive.dart';
import 'bill.dart';

part 'event.g.dart';

@HiveType(typeId: 3)
class Event extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late String description;

  @HiveField(3)
  late DateTime createdAt;

  @HiveField(4)
  late DateTime updatedAt;

  @HiveField(5)
  late List<String> memberIds;

  @HiveField(6)
  late List<Bill> bills;

  @HiveField(7)
  late String color;

  @HiveField(8)
  late String currencyCode;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    required this.memberIds,
    required this.bills,
    this.color = '#FF9999',
    this.currencyCode = 'USD',
  });

  Event.empty()
      : id = '',
        title = '',
        description = '',
        createdAt = DateTime.now(),
        updatedAt = DateTime.now(),
        memberIds = [],
        bills = [],
        color = '#FF9999',
        currencyCode = 'USD';

  double get totalAmount =>
      bills.fold(0.0, (sum, bill) => sum + bill.totalAmount);

  int get billCount => bills.length;

  int get memberCount => memberIds.length;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Event && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
