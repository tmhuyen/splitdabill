# SplitDaBill 💰

A powerful Flutter mobile application designed to simplify bill splitting among groups of friends, roommates, or colleagues. SplitDaBill uses advanced OCR technology to automatically extract bill items and amounts, making it effortless to split expenses and track settlements.

---

## 🌟 Features

### Core Functionality

- **Event Management**: Create and manage multiple events to organize bills and expenses
- **Bill Splitting**: Split bills among multiple people with flexible payment options
- **Smart OCR Integration**: Automatically extract items and amounts from receipt photos using Google ML Kit Text Recognition
- **People Management**: Add and manage participants in your events
- **Settlement Tracking**: Get automatic calculations for who owes whom and simplified settlement suggestions
- **Debt Simplification**: Intelligent algorithm that minimizes the number of transactions needed to settle debts

### Data Management

- **Local Database Storage**: All data is stored locally using Hive for fast, offline access
- **Excel Export**: Export bills and settlement details to Excel for record-keeping
- **Transaction History**: Keep detailed records of all transactions and payments
- **Persistent Storage**: No internet required; all data persists locally on your device

### User Experience

- **Intuitive Interface**: Clean, user-friendly Material Design UI
- **Multi-language Support**: Localized in multiple languages for accessibility
- **Receipt Scanning**: Capture and process receipts with your device camera
- **Real-time Updates**: Instant recalculation of splits and settlements
- **Multiple Export Formats**: Save and share settlement reports in Excel format

---

## 🎬 Demo Video

Watch SplitDaBill in action! Click the video below to see the app features and workflow:

[![SplitDaBill Demo](https://img.youtube.com/vi/VIDEO_ID/maxresdefault.jpg)](Splitdabill_demo.mp4)

[📹 Watch Full Demo Video](Splitdabill_demo.mp4)

---

## 🛠️ Tech Stack

### Frontend Framework

- **Flutter 3.x** - Cross-platform mobile app framework (supports iOS, Android, Web, Windows, macOS, Linux)
- **Dart 3.4.1+** - Modern programming language with null safety

### State Management

- **Provider 6.1.5+** - Efficient state management and dependency injection

### Database & Storage

- **Hive 2.2.3** - Fast, local NoSQL database
- **Hive Flutter 1.1.0** - Flutter integration for Hive
- **Path Provider 2.1.0** - Access file system paths
- **Permission Handler 11.3.1** - Manage app permissions

### ML & OCR

- **Google ML Kit Text Recognition 0.6.0** - Advanced OCR for receipt scanning

### Export & File Handling

- **Excel 2.1.0** - Generate and export Excel spreadsheets
- **Open FileX 4.5.0** - Open generated files with native apps
- **Image Picker 1.0.0** - Select images from device gallery or camera

### Utilities

- **Intl 0.19.0** - Internationalization and localization
- **UUID 4.0.0** - Generate unique identifiers
- **Flutter Localizations** - Built-in localization support

### Development Tools

- **Hive Generator 2.0.0** - Code generation for Hive models
- **Build Runner 2.4.0** - Dart code generation
- **Flutter Lints 3.0.0** - Code quality and style guidelines

---

## 📋 Prerequisites

- Flutter SDK: >= 3.4.1 < 4.0.0
- Dart SDK: >= 3.4.1 < 4.0.0
- Android SDK (for Android development)
- Xcode (for iOS development)
- A mobile device or emulator

---

## 🚀 Getting Started

### Installation

1. **Clone the Repository**

   ```bash
   git clone <repository-url>
   cd splitdabill
   ```

2. **Install Dependencies**

   ```bash
   flutter pub get
   ```

3. **Generate Code (for Hive models)**

   ```bash
   flutter pub run build_runner build
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

### Building for Production

**Android:**

```bash
flutter build apk
# or for app bundle
flutter build appbundle
```

**iOS:**

```bash
flutter build ios
```

**Web:**

```bash
flutter build web
```

---

## � Data Migration & Versioning

### Overview

SplitDaBill uses **Hive** for local data storage. Your data persists across app updates automatically, ensuring you never lose your bills, events, or settlements. This section explains how we manage data compatibility across versions.

### How Data Persists

- **Automatic Persistence**: Hive stores data in local files that survive app updates
- **No Data Loss**: Data is preserved during app updates unless the app is completely uninstalled
- **Platform Coverage**: Works on Android, iOS, Web, and Desktop platforms

### Recommended Update Strategy

#### ✅ Keep Hive Boxes Open (Don't Delete on Startup)

Ensure the database initialization preserves existing data:

```dart
// ✅ CORRECT: Initialize boxes if they don't exist
if (!Hive.isBoxOpen('events')) {
  await Hive.openBox<Event>('events');
}

// ❌ WRONG: Never delete on every startup
// await Hive.deleteBoxFromDisk('events');
```

#### ✅ Add Version Tracking to Detect Schema Changes

Implement versioning to handle data model updates:

```dart
// In your database service
const int CURRENT_DATA_VERSION = 2;

Future<void> initializeDatabase() async {
  final versionBox = await Hive.openBox('app_metadata');
  final currentVersion = versionBox.get('data_version') ?? 0;

  if (currentVersion < CURRENT_DATA_VERSION) {
    await migrateData(currentVersion, CURRENT_DATA_VERSION);
    await versionBox.put('data_version', CURRENT_DATA_VERSION);
  }
}
```

#### ✅ Implement Migration Functions for Schema Updates

Create migration functions when data models change:

```dart
Future<void> migrateData(int fromVersion, int toVersion) async {
  if (fromVersion < 2) {
    await migrateToV2();
  }
  if (fromVersion < 3) {
    await migrateToV3();
  }
}

Future<void> migrateToV2() async {
  // Example: Add new field to existing records
  final eventsBox = await Hive.openBox<Event>('events');
  for (var event in eventsBox.values) {
    // Update event with new fields or format
    event.updatedAt = DateTime.now();
    await event.save();
  }
}
```

#### ✅ Test Updates Locally Before Release

- Always test the app on a device with existing data
- Verify all data is readable after model changes
- Run migrations in a staging environment first
- Test both fresh installs and upgrades

#### ✅ Document Breaking Changes in Release Notes

For each release, document:

- New features and improvements
- Any data schema changes
- Migration instructions if needed
- Minimum supported app version for updates

Example release notes:

```
v1.1.0
------
✨ New Features:
  - Added recurring bills support
  - Improved OCR accuracy

⚠️ Breaking Changes:
  - Bill model structure updated (auto-migrated)
  - Minimum app version: 1.0.0+1

🔄 Data Migration:
  - All existing bills auto-migrated to new format
  - No user action required
```

### Platform-Specific Behavior

**Android:**

- Data stored in `/data/data/<package>/files/`
- Persists across app updates
- Lost only if user explicitly clears app data or uninstalls

**iOS:**

- Data stored in app sandbox
- Persists across App Store updates
- Lost only if user deletes and reinstalls the app

### Backup & Export

Users should consider exporting their data periodically:

1. Go to an event and tap **"Export to Excel"**
2. Save the file to device storage
3. Use these backups before major app updates

### Data Integrity Checks

Add validation on app startup:

```dart
Future<void> validateDataIntegrity() async {
  try {
    final eventsBox = await Hive.openBox<Event>('events');
    for (var event in eventsBox.values) {
      // Validate required fields exist
      if (event.name == null || event.participants == null) {
        // Log error or attempt repair
        logger.error('Invalid event detected: ${event.key}');
      }
    }
  } catch (e) {
    logger.error('Data integrity check failed: $e');
  }
}
```

---

## �📱 Project Structure

```
lib/
├── main.dart                 # App entry point
├── models/                   # Data models
│   ├── bill.dart            # Bill model
│   ├── event.dart           # Event model
│   ├── person.dart          # Person model
│   ├── split_entry.dart     # Split entry model
│   └── transaction.dart     # Transaction model
├── screens/                  # UI screens
│   ├── home_screen.dart
│   ├── create_event_screen.dart
│   ├── event_detail_screen.dart
│   ├── create_bill_screen.dart
│   ├── split_bill_screen.dart
│   ├── settlement_screen.dart
│   └── add_people_screen.dart
├── services/                 # Business logic
│   ├── database_service.dart
│   ├── ocr_service.dart
│   ├── bill_calculation_service.dart
│   ├── debt_simplification_service.dart
│   ├── excel_export_service.dart
│   └── hive_setup_service.dart
├── providers/                # State management
│   └── data_providers.dart
├── widgets/                  # Reusable widgets
├── theme/                    # App theme & styling
└── utils/                    # Utility functions
```

---

## 🔧 Key Services

### OCR Service

Leverages Google ML Kit to automatically extract text and item information from receipt images, making bill entry quick and accurate.

### Bill Calculation Service

Handles complex calculations for splitting bills among multiple people with various payment methods.

### Debt Simplification Service

Uses an intelligent algorithm to minimize the number of transactions needed to settle all debts among group members.

### Excel Export Service

Generates professional Excel reports with settlement details, transaction history, and payment summaries.

### Database Service

Manages all local data operations with Hive, ensuring fast and reliable data persistence.

---

## 📝 Usage Examples

### Creating an Event

1. Open the app and tap "Create Event"
2. Enter event name and select participants
3. Start adding bills to the event

### Adding a Bill with OCR

1. Tap "Add Bill" in an event
2. Use "Scan Receipt" to capture a receipt
3. Review and adjust extracted items
4. Select how to split the bill
5. Confirm and save

### Viewing Settlements

1. Go to "Settlement" tab in an event
2. View who owes whom
3. Tap "Settle" to mark payments as complete
4. Export settlement report to Excel if needed

---

## 🌍 Localization

The app supports multiple languages. Language files are located in `lib/src/localization/`. To add a new language:

1. Create a new `.arb` file in the localization directory
2. Copy strings from the base language file
3. Translate the strings
4. Run `flutter pub get` to generate localized strings

---

## 📦 Dependencies Overview

| Package                       | Version | Purpose              |
| ----------------------------- | ------- | -------------------- |
| provider                      | 6.1.5+  | State management     |
| hive                          | 2.2.3   | Local database       |
| google_mlkit_text_recognition | 0.6.0   | OCR functionality    |
| excel                         | 2.1.0   | Excel export         |
| image_picker                  | 1.0.0   | Photo capture        |
| intl                          | 0.19.0  | Internationalization |
| uuid                          | 4.0.0   | Unique IDs           |

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 👥 Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

---

## 📞 Support

For issues, questions, or suggestions, please open an issue in the repository or contact the development team.

---

## 🎯 Future Enhancements

- Cloud sync functionality
- Receipt history and storage
- Advanced reporting and analytics
- Group settings and preferences
- Payment gateway integration
- Recurring bills
- User authentication and multi-device sync

---

**Happy Bill Splitting! 🎉**
