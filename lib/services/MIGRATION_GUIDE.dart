// Data Migration & Versioning Implementation Guide
//
// This guide explains how to use the new Data Migration system
// to manage schema changes and ensure data persistence across app updates.

// OVERVIEW
/// ========
/// 
/// The Data Migration system provides:
/// 1. Automatic version tracking
/// 2. Data migration functions for schema changes
/// 3. Data integrity validation
/// 4. Version information management
/// 5. Safe data preservation across updates

/// ARCHITECTURE
/// =============
///
/// 1. DataMigrationService
///    - Handles version tracking and migrations
///    - Validates data integrity
///    - Manages metadata storage
///
/// 2. HiveSetupService
///    - Initializes Hive adapters
///    - Opens boxes (preserves data!)
///    - Calls DataMigrationService
///
/// 3. VersionInfoService
///    - Tracks app version and changelog
///    - Helps display version info to users
///    - Manages version-specific announcements

/// USAGE EXAMPLES
/// ==============

/// EXAMPLE 1: Basic Setup (Already done in main.dart)
/// ---
/// void main() async {
///   WidgetsFlutterBinding.ensureInitialized();
///   await Hive.initFlutter();
///   await HiveSetupService.init();  // This now handles migrations!
///   runApp(const MyApp());
/// }

/// EXAMPLE 2: Check App Status
/// ---
/// // In a settings or debug screen:
/// import 'services/services.dart';
///
/// Future<void> showAppStatus() async {
///   final status = await HiveSetupService.getStatus();
///   print('Data Version: ${status['dataVersion']}');
///   print('Events: ${status['eventsCount']}');
///   print('People: ${status['peopleCount']}');
///   print('Transactions: ${status['transactionsCount']}');
/// }

/// EXAMPLE 3: Display Version Info
/// ---
/// void showVersionDialog() {
///   showAboutDialog(
///     context: context,
///     applicationName: 'SplitDaBill',
///     applicationVersion: VersionInfoService.getFullVersion(),
///     children: [
///       Text(VersionInfoService.getLatestChangelog()),
///     ],
///   );
/// }

/// EXAMPLE 4: Handle First Install / Update
/// ---
/// // In main.dart or splash screen:
/// Future<void> handleAppVersion() async {
///   final prefs = await SharedPreferences.getInstance();
///   final lastSeenVersion = prefs.getString('last_app_version');
///
///   if (VersionInfoService.isFirstInstall(lastSeenVersion)) {
///     // Show welcome screen
///     showWelcomeDialog();
///   } else if (VersionInfoService.isVersionUpdated(lastSeenVersion)) {
///     // Show what's new dialog
///     showWhatsNewDialog();
///   }
///
///   // Update stored version
///   await prefs.setString(
///     'last_app_version',
///     VersionInfoService.APP_VERSION,
///   );
/// }

/// HOW TO ADD A NEW MIGRATION
/// ==========================
///
/// When you need to change the data model (e.g., add a field to Event):
///
/// STEP 1: Update the Dart Model
/// ---
/// // In models/event.dart
/// @HiveType(typeId: 1)
/// class Event {
///   @HiveField(0)
///   String id;
///   
///   @HiveField(1)
///   String name;
///   
///   @HiveField(2)
///   List<String> memberIds;
///   
///   @HiveField(3)
///   List<Bill> bills;
///   
///   @HiveField(4)
///   DateTime createdAt;
///   
///   @HiveField(5)
///   DateTime updatedAt;
///   
///   // NEW FIELD:
///   @HiveField(6)
///   String? description;  // New field added in v1.1.0
/// }
///
/// Then generate the adapter:
/// $ flutter pub run build_runner build

/// STEP 2: Increment Data Version
/// ---
/// // In data_migration_service.dart
/// static const int CURRENT_DATA_VERSION = 2;  // Changed from 1 to 2

/// STEP 3: Add Validation Logic
/// ---
/// // In data_migration_service.dart, update _validateEvent():
/// static bool _validateEvent(Event event) {
///   try {
///     if (event.id.isEmpty || event.name.isEmpty) {
///       return false;
///     }
///     // New validation: description can be null, but if present must not be empty
///     if (event.description != null && event.description!.isEmpty) {
///       return false;
///     }
///     return true;
///   } catch (e) {
///     return false;
///   }
/// }

/// STEP 4: Create Migration Function
/// ---
/// // In data_migration_service.dart
/// 
/// static Future<void> _runMigrations(int fromVersion, int toVersion) async {
///   if (fromVersion < 1) {
///     await _migrateToV1();
///   }
///   if (fromVersion < 2) {
///     await _migrateToV2();  // ADD THIS
///   }
/// }
///
/// static Future<void> _migrateToV2() async {
///   if (kDebugMode) {
///     print('🔄 Running migration: V2 (Add event description)');
///   }
///
///   try {
///     // Access the events box
///     final eventsBox = Hive.box<Event>('events');
///
///     // Iterate through all events and update them
///     for (final event in eventsBox.values) {
///       // Set description to null if not present (safe default)
///       event.description ??= null;
///       await event.save();
///     }
///
///     if (kDebugMode) {
///       print('✅ V2 Migration: Added description field to ${eventsBox.length} events');
///     }
///   } catch (e) {
///     if (kDebugMode) {
///       print('❌ V2 Migration Failed: $e');
///     }
///     rethrow;
///   }
/// }

/// STEP 5: Update Version Info
/// ---
/// // In version_info_service.dart
/// static const String APP_VERSION = '1.1.0';  // Update version
/// static const int BUILD_NUMBER = 2;
///
/// static const Map<String, String> CHANGELOG = {
///   '1.1.0': '''
/// - Added event descriptions
/// - Improved event management UI
/// - Data migration system with versioning
///   ''',
///   '1.0.0': '''
/// - Initial release
/// ...
///   ''',
/// };

/// STEP 6: Test the Migration
/// ---
/// // Run on a device with existing data:
/// 1. Install old version (v1.0.0)
/// 2. Create some events and data
/// 3. Update to new version (v1.1.0)
/// 4. Verify all data still exists and new fields are initialized
/// 5. Check console output for migration logs

/// KEY PRINCIPLES
/// ==============
///
/// ✅ DO:
/// - Increment CURRENT_DATA_VERSION for each schema change
/// - Create a migration function for each version jump
/// - Validate data after migrations
/// - Test migrations with real data
/// - Keep migration functions simple and focused
/// - Log migration progress (use kDebugMode)
/// - Set sensible defaults for new fields
///
/// ❌ DON'T:
/// - Delete data on app startup
/// - Skip validation steps
/// - Forget to regenerate Hive adapters
/// - Make breaking changes without migration
/// - Forget to update version constants
/// - Release without testing migrations

/// DATA PRESERVATION ACROSS UPDATES
/// =================================
///
/// The system automatically preserves data because:
/// 1. HiveSetupService checks if boxes are already open
/// 2. Boxes are only created if they don't exist
/// 3. Existing box data is never touched unless migration runs
/// 4. Migrations only modify data when schema changes
/// 5. Version tracking ensures migrations run at most once per version

/// DEBUGGING MIGRATIONS
/// ====================
///
/// Check migration status:
/// ---
/// Future<void> debugMigrations() async {
///   final version = await DataMigrationService.getDataVersion();
///   final timestamp = await DataMigrationService.getLastMigrationTime();
///   
///   print('Current Data Version: $version');
///   print('Last Migration: $timestamp');
///   
///   // Validate data
///   await DataMigrationService.validateDataIntegrity();
/// }
///
/// Reset data (development only):
/// ---
/// await HiveSetupService.deleteAll();
/// await HiveSetupService.init();

/// COMMON MIGRATION PATTERNS
/// =========================
///
/// Pattern 1: Adding a new field
/// ---
/// event.newField ??= defaultValue;
/// await event.save();
///
/// Pattern 2: Removing a field (just stop using it)
/// ---
/// // Field remains in stored data but isn't accessed
///
/// Pattern 3: Changing field type
/// ---
/// if (event.oldStringField is int) {
///   // Handle old type
/// }
/// // Use new type going forward
///
/// Pattern 4: Splitting a model
/// ---
/// // Create new model and migrate data
/// for (final oldItem in oldBox.values) {
///   final newItem1 = NewModel1.fromOld(oldItem);
///   final newItem2 = NewModel2.fromOld(oldItem);
///   await newBox1.put(newItem1.id, newItem1);
///   await newBox2.put(newItem2.id, newItem2);
/// }

/// MONITORING IN PRODUCTION
/// =========================
///
/// Add analytics events:
/// ---
/// Future<void> initializeMigrations() async {
///   // ... existing code ...
///   
///   if (currentVersion < CURRENT_DATA_VERSION) {
///     // Track migration in analytics
///     analytics.logEvent(
///       name: 'data_migration',
///       parameters: {
///         'from_version': currentVersion,
///         'to_version': CURRENT_DATA_VERSION,
///         'timestamp': DateTime.now().toString(),
///       },
///     );
///   }
/// }

/// PERFORMANCE CONSIDERATIONS
/// ==========================
///
/// - Migrations run once on app startup
/// - Validation runs on every startup (quick check)
/// - For large datasets, migrations may take a few seconds
/// - Avoid heavy computation in migrations
/// - Use batch operations for bulk updates
/// - Consider background processing for very large migrations

/// For more information, see README.md - Data Migration & Versioning section
