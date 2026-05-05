import 'package:hive_flutter/hive_flutter.dart';
import '../models/index.dart';

class HiveSetupService {
  static Future<void> init() async {
    // Register adapters
    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(SplitEntryAdapter());
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(TransactionAdapter());

    // Open boxes
    await Hive.openBox<Event>('events');
    await Hive.openBox<Person>('people');
    await Hive.openBox<Transaction>('transactions');
  }

  static Future<void> deleteAll() async {
    await Hive.deleteBoxFromDisk('events');
    await Hive.deleteBoxFromDisk('people');
    await Hive.deleteBoxFromDisk('transactions');
  }
}
