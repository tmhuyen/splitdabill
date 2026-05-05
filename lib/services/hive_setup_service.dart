import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';
import 'data_migration_service.dart';

class HiveSetupService {
  static Future<void> init() async {
    if (kDebugMode) {
      print('🚀 HiveSetupService: Initializing...');
    }

    try {
      // Step 1: Register all adapters
      _registerAdapters();

      // Step 2: Open all boxes (preserves existing data)
      await _openBoxes();

      // Step 3: Run migrations and version checks
      await DataMigrationService.initializeMigrations();

      if (kDebugMode) {
        print('✅ HiveSetupService: Initialization completed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ HiveSetupService Error: $e');
      }
      rethrow;
    }
  }

  /// Register all Hive adapters
  static void _registerAdapters() {
    if (kDebugMode) {
      print('📝 Registering Hive adapters...');
    }

    Hive.registerAdapter(PersonAdapter());
    Hive.registerAdapter(SplitEntryAdapter());
    Hive.registerAdapter(BillAdapter());
    Hive.registerAdapter(EventAdapter());
    Hive.registerAdapter(TransactionAdapter());

    if (kDebugMode) {
      print('✅ All adapters registered');
    }
  }

  /// Open all Hive boxes - PRESERVES existing data
  /// This is crucial for maintaining data across app updates
  static Future<void> _openBoxes() async {
    if (kDebugMode) {
      print('📦 Opening Hive boxes...');
    }

    // Only open boxes if not already open
    if (!Hive.isBoxOpen('events')) {
      await Hive.openBox<Event>('events');
      if (kDebugMode) {
        print('✅ Opened events box');
      }
    }

    if (!Hive.isBoxOpen('people')) {
      await Hive.openBox<Person>('people');
      if (kDebugMode) {
        print('✅ Opened people box');
      }
    }

    if (!Hive.isBoxOpen('transactions')) {
      await Hive.openBox<Transaction>('transactions');
      if (kDebugMode) {
        print('✅ Opened transactions box');
      }
    }
  }

  /// Reset all data - USE WITH CAUTION
  /// This is for development/testing purposes only
  static Future<void> deleteAll() async {
    if (kDebugMode) {
      print('⚠️  WARNING: Deleting all app data');
    }

    await DataMigrationService.clearAllData();

    if (kDebugMode) {
      print('✅ All data deleted');
    }
  }

  /// Get initialization status
  static Future<Map<String, dynamic>> getStatus() async {
    return {
      'dataVersion': await DataMigrationService.getDataVersion(),
      'lastMigration': await DataMigrationService.getLastMigrationTime(),
      'eventsCount':
          Hive.isBoxOpen('events') ? Hive.box<Event>('events').length : 0,
      'peopleCount':
          Hive.isBoxOpen('people') ? Hive.box<Person>('people').length : 0,
      'transactionsCount': Hive.isBoxOpen('transactions')
          ? Hive.box<Transaction>('transactions').length
          : 0,
    };
  }
}
