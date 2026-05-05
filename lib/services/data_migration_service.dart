import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/index.dart';

/// Data Migration & Versioning Service
///
/// Manages data schema versions and handles migrations between versions.
/// Ensures data integrity across app updates.
class DataMigrationService {
  // Current data version - increment when schema changes
  static const int CURRENT_DATA_VERSION = 1;

  // Version box key
  static const String _VERSION_BOX = 'app_metadata';
  static const String _DATA_VERSION_KEY = 'data_version';
  static const String _LAST_MIGRATION_KEY = 'last_migration_timestamp';

  /// Initialize data migration - call this after Hive setup
  static Future<void> initializeMigrations() async {
    try {
      // Open metadata box
      late Box<dynamic> metadataBox;
      if (!Hive.isBoxOpen(_VERSION_BOX)) {
        metadataBox = await Hive.openBox(_VERSION_BOX);
      } else {
        metadataBox = Hive.box(_VERSION_BOX);
      }

      // Get current data version
      final currentVersion =
          metadataBox.get(_DATA_VERSION_KEY, defaultValue: 0) as int;

      if (kDebugMode) {
        print('🔄 DataMigration: Current version=$currentVersion, '
            'Target version=$CURRENT_DATA_VERSION');
      }

      // Run migrations if needed
      if (currentVersion < CURRENT_DATA_VERSION) {
        await _runMigrations(currentVersion, CURRENT_DATA_VERSION);
        await metadataBox.put(_DATA_VERSION_KEY, CURRENT_DATA_VERSION);
        await metadataBox.put(_LAST_MIGRATION_KEY, DateTime.now().toString());

        if (kDebugMode) {
          print('✅ DataMigration: Migration completed successfully');
        }
      } else {
        if (kDebugMode) {
          print('✅ DataMigration: Data version is up to date');
        }
      }

      // Validate data integrity after migrations
      await validateDataIntegrity();
    } catch (e) {
      if (kDebugMode) {
        print('❌ DataMigration Error: $e');
      }
      rethrow;
    }
  }

  /// Run all necessary migrations
  static Future<void> _runMigrations(int fromVersion, int toVersion) async {
    if (fromVersion < 1) {
      await _migrateToV1();
    }
    // Add future migrations here:
    // if (fromVersion < 2) {
    //   await _migrateToV2();
    // }
  }

  /// Migration to V1 (Initial version)
  /// Initializes version tracking if upgrading from pre-versioned app
  static Future<void> _migrateToV1() async {
    if (kDebugMode) {
      print('🔄 Running migration: V1 (Initial versioning)');
    }

    try {
      // Add any V1-specific migrations here
      // This ensures backward compatibility

      if (kDebugMode) {
        print('✅ V1 Migration: Completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ V1 Migration Failed: $e');
      }
      rethrow;
    }
  }

  /// Validate data integrity across all boxes
  static Future<void> validateDataIntegrity() async {
    if (kDebugMode) {
      print('🔍 Validating data integrity...');
    }

    try {
      // Validate Events
      if (Hive.isBoxOpen('events')) {
        final eventsBox = Hive.box<Event>('events');
        int eventCount = 0;
        int invalidEvents = 0;

        for (var event in eventsBox.values) {
          eventCount++;
          if (!_validateEvent(event)) {
            invalidEvents++;
            if (kDebugMode) {
              print('⚠️  Invalid event detected: ${event.id}');
            }
          }
        }

        if (kDebugMode) {
          print('✅ Events: $eventCount valid, $invalidEvents invalid');
        }
      }

      // Validate People
      if (Hive.isBoxOpen('people')) {
        final peopleBox = Hive.box<Person>('people');
        int personCount = 0;
        int invalidPeople = 0;

        for (var person in peopleBox.values) {
          personCount++;
          if (!_validatePerson(person)) {
            invalidPeople++;
            if (kDebugMode) {
              print('⚠️  Invalid person detected: ${person.id}');
            }
          }
        }

        if (kDebugMode) {
          print('✅ People: $personCount valid, $invalidPeople invalid');
        }
      }

      // Validate Transactions
      if (Hive.isBoxOpen('transactions')) {
        final transactionsBox = Hive.box<Transaction>('transactions');
        int transactionCount = 0;
        int invalidTransactions = 0;

        for (var transaction in transactionsBox.values) {
          transactionCount++;
          if (!_validateTransaction(transaction)) {
            invalidTransactions++;
            if (kDebugMode) {
              print('⚠️  Invalid transaction detected: ${transaction.id}');
            }
          }
        }

        if (kDebugMode) {
          print('✅ Transactions: $transactionCount valid, '
              '$invalidTransactions invalid');
        }
      }

      if (kDebugMode) {
        print('✅ Data integrity check completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Data integrity validation failed: $e');
      }
      // Don't rethrow - allow app to continue with warning
    }
  }

  /// Validate Event model
  static bool _validateEvent(Event event) {
    try {
      // Check required fields
      if (event.id.isEmpty || event.title.isEmpty) {
        return false;
      }

      // Check bill consistency
      for (var bill in event.bills) {
        if (bill.id.isEmpty || bill.totalAmount <= 0) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate Person model
  static bool _validatePerson(Person person) {
    try {
      // Check required fields
      if (person.id.isEmpty || person.name.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Validate Transaction model
  static bool _validateTransaction(Transaction transaction) {
    try {
      // Check required fields
      if (transaction.id.isEmpty || transaction.amount <= 0) {
        return false;
      }

      if (transaction.fromPersonId.isEmpty || transaction.toPersonId.isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get current data version
  static Future<int> getDataVersion() async {
    late Box<dynamic> metadataBox;
    if (!Hive.isBoxOpen(_VERSION_BOX)) {
      metadataBox = await Hive.openBox(_VERSION_BOX);
    } else {
      metadataBox = Hive.box(_VERSION_BOX);
    }

    return metadataBox.get(_DATA_VERSION_KEY, defaultValue: 0) as int;
  }

  /// Get last migration timestamp
  static Future<String?> getLastMigrationTime() async {
    late Box<dynamic> metadataBox;
    if (!Hive.isBoxOpen(_VERSION_BOX)) {
      metadataBox = await Hive.openBox(_VERSION_BOX);
    } else {
      metadataBox = Hive.box(_VERSION_BOX);
    }

    return metadataBox.get(_LAST_MIGRATION_KEY) as String?;
  }

  /// Clear all data (use with caution - for testing/reset only)
  static Future<void> clearAllData() async {
    if (kDebugMode) {
      print('⚠️  WARNING: Clearing all app data');
    }

    await Future.wait([
      Hive.deleteBoxFromDisk('events'),
      Hive.deleteBoxFromDisk('people'),
      Hive.deleteBoxFromDisk('transactions'),
      Hive.deleteBoxFromDisk(_VERSION_BOX),
    ]);

    if (kDebugMode) {
      print('✅ All data cleared');
    }
  }
}
