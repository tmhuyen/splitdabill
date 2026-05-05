import 'package:flutter/material.dart';
import '../services/data_migration_service.dart';
import '../services/hive_setup_service.dart';
import '../services/version_info_service.dart';
import '../theme/app_colors.dart';

/// Example Debug & Info Screen
///
/// This screen demonstrates how to use DataMigrationService and VersionInfoService
/// to display app information, data status, and version details to users.
///
/// You can add this as a route in your app for debugging or settings.
class AppInfoDebugScreen extends StatefulWidget {
  const AppInfoDebugScreen({Key? key}) : super(key: key);

  @override
  State<AppInfoDebugScreen> createState() => _AppInfoDebugScreenState();
}

class _AppInfoDebugScreenState extends State<AppInfoDebugScreen> {
  late Future<Map<String, dynamic>> _statusFuture;
  late Future<int> _versionFuture;
  late Future<String?> _lastMigrationFuture;

  @override
  void initState() {
    super.initState();
    _statusFuture = HiveSetupService.getStatus();
    _versionFuture = DataMigrationService.getDataVersion();
    _lastMigrationFuture = DataMigrationService.getLastMigrationTime();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('App Info & Debug'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Version Section
            _buildSection(
              title: 'App Version',
              children: [
                _buildInfoRow('Version', VersionInfoService.APP_VERSION),
                _buildInfoRow(
                    'Build', VersionInfoService.BUILD_NUMBER.toString()),
                _buildInfoRow(
                    'Full Version', VersionInfoService.getFullVersion()),
              ],
            ),
            const SizedBox(height: 24),

            // Data Version Section
            _buildSection(
              title: 'Data & Migrations',
              children: [
                FutureBuilder<int>(
                  future: _versionFuture,
                  builder: (context, snapshot) {
                    return _buildInfoRow(
                      'Data Version',
                      snapshot.data?.toString() ?? 'Loading...',
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
                FutureBuilder<String?>(
                  future: _lastMigrationFuture,
                  builder: (context, snapshot) {
                    return _buildInfoRow(
                      'Last Migration',
                      snapshot.data ?? 'Never',
                      isLoading:
                          snapshot.connectionState == ConnectionState.waiting,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Data Status Section
            _buildSection(
              title: 'Data Storage',
              children: [
                FutureBuilder<Map<String, dynamic>>(
                  future: _statusFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Text('Unable to load status');
                    }

                    final status = snapshot.data!;
                    return Column(
                      children: [
                        _buildInfoRow(
                          'Events',
                          '${status['eventsCount']} records',
                        ),
                        _buildInfoRow(
                          'People',
                          '${status['peopleCount']} records',
                        ),
                        _buildInfoRow(
                          'Transactions',
                          '${status['transactionsCount']} records',
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Changelog Section
            _buildSection(
              title: 'Latest Changelog',
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    VersionInfoService.getLatestChangelog(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions Section
            _buildSection(
              title: 'Actions',
              children: [
                _buildActionButton(
                  onPressed: _validateDataIntegrity,
                  icon: Icons.check_circle,
                  label: 'Validate Data Integrity',
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  onPressed: _showAppInfo,
                  icon: Icons.info,
                  label: 'Show App Info',
                ),
                const SizedBox(height: 8),
                _buildActionButton(
                  onPressed: _refreshStatus,
                  icon: Icons.refresh,
                  label: 'Refresh Status',
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Developer Notes
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.infoContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.info, width: 1.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ℹ️ Developer Notes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'This screen shows app version, data migration status, '
                    'and storage information. Use "Validate Data Integrity" '
                    'to check for any data consistency issues.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'For more information, see MIGRATION_GUIDE.dart in the '
                    'services directory.',
                    style: TextStyle(
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isLoading = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
          const SizedBox(height: 4),
          if (isLoading)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          else
            Text(
              value,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontFamily: 'monospace',
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _validateDataIntegrity() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Validating data integrity...')),
    );

    try {
      await DataMigrationService.validateDataIntegrity();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Data integrity validation completed. Check logs.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Validation error: $e')),
        );
      }
    }
  }

  void _showAppInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('App Information'),
        content: Text(VersionInfoService.getAppInfo()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _refreshStatus() {
    setState(() {
      _statusFuture = HiveSetupService.getStatus();
      _versionFuture = DataMigrationService.getDataVersion();
      _lastMigrationFuture = DataMigrationService.getLastMigrationTime();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Status refreshed')),
    );
  }
}
