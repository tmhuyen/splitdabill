import 'package:flutter/foundation.dart';

/// App Version & Build Information Service
///
/// Provides version, build, and data migration status information.
/// Useful for debugging and displaying app info to users.
class VersionInfoService {
  // App version from pubspec.yaml
  static const String APP_VERSION = '1.1.0';
  static const int BUILD_NUMBER = 2;

  // Changelog for version tracking
  static const Map<String, String> CHANGELOG = {
    '1.1.0': '''
- Accessibility contrast improvements
- Centralized semantic color system
- Responsive layouts for large text scaling
- Dark mode-ready theme foundation
    ''',
    '1.0.0': '''
- Initial release
- Bill splitting with OCR
- Event management
- Excel export
- Data migration & versioning system
- Debt simplification algorithm
- Settlement tracking
    ''',
  };

  /// Get full version string
  static String getFullVersion() {
    return '$APP_VERSION+$BUILD_NUMBER';
  }

  /// Get app info as formatted string
  static String getAppInfo() {
    return '''
App: SplitDaBill
Version: $APP_VERSION
Build: $BUILD_NUMBER
Channel: ${kDebugMode ? 'Debug' : 'Release'}
    ''';
  }

  /// Get changelog for a specific version
  static String? getChangelogForVersion(String version) {
    return CHANGELOG[version];
  }

  /// Get latest changelog
  static String getLatestChangelog() {
    return CHANGELOG[APP_VERSION] ?? 'No changelog available';
  }

  /// Check if this is a new version (first install)
  static bool isFirstInstall(String? lastSeenVersion) {
    return lastSeenVersion == null || lastSeenVersion.isEmpty;
  }

  /// Check if version has been updated
  static bool isVersionUpdated(String? lastSeenVersion) {
    if (lastSeenVersion == null || lastSeenVersion.isEmpty) {
      return false; // First install
    }
    return lastSeenVersion != APP_VERSION;
  }

  /// Get update notes for a version jump
  static String getUpdateNotes(String? fromVersion) {
    if (fromVersion == null) {
      return 'Welcome to SplitDaBill!\n\n${getLatestChangelog()}';
    }

    // Build notes from all versions between fromVersion and current
    List<String> notes = [];
    CHANGELOG.forEach((version, changelog) {
      notes.add('## Version $version\n$changelog\n');
    });

    return notes.join('\n');
  }
}
