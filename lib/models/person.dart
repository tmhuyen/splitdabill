import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String email;

  @HiveField(3)
  late String avatar;

  Person({
    required this.id,
    required this.name,
    required this.email,
    this.avatar = '',
  });

  Person.empty()
      : id = '',
        name = '',
        email = '',
        avatar = '';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Person && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
