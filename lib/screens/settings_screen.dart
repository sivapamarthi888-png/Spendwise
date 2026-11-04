import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/expense_provider.dart';
import '../providers/theme_provider.dart';
import '../services/storage_service.dart';
import '../utils/app_constants.dart';

/// Screen 5 — Settings: appearance, data export / clearing and about info.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: <Widget>[
          // ---- Identity header ----
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.savings_rounded,
                    color: Theme.of(context).colorScheme.onPrimary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(AppConstants.appName,
                          style: Theme.of(context).textTheme.titleLarge),
                      Text(
                        AppConstants.appTagline,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          const _ThemeModeSelector(),
          const SizedBox(height: 20),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          _SettingsTile(
            icon: Icons.ios_share_rounded,
            title: 'Export to CSV',
            subtitle: kIsWeb
                ? 'Download all transactions as a CSV file'
                : 'Export transactions and save or share them anywhere',
            onTap: () => _exportCsv(context),
          ),
          _SettingsTile(
            icon: Icons.delete_sweep_rounded,
            title: 'Clear all data',
            subtitle: 'Permanently delete every saved transaction',
            destructive: true,
            onTap: () => _confirmClearAll(context),
          ),
          const SizedBox(height: 20),
          Text('About', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _AboutRow(label: 'App', value: 'SpendWise v1.0.0'),
                  const SizedBox(height: 8),
                  const _AboutRow(
                      label: 'Offline', value: 'Works fully without internet'),
                  const SizedBox(height: 8),
                  const _AboutRow(label: 'Currency', value: 'Indian Rupees (₹)'),
                  const SizedBox(height: 8),
                  const _AboutRow(
                      label: 'Storage', value: 'Local SQLite on this device'),
                  const SizedBox(height: 12),
                  Text(
                    'Built with Flutter for the IITM Pravartak & BodhBridge '
                    'Flutter Application Development Programme.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context) async {
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    if (provider.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No transactions to export yet'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      final String path = await const StorageService()
          .exportToCsv(provider.expenses);
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) {
          return AlertDialog(
            icon: const Icon(Icons.check_circle_rounded,
                color: Color(0xFF16A34A), size: 40),
            title: const Text('Export complete'),
            content: Text(
              kIsWeb
                  ? 'Your CSV file "$path" was downloaded to your device.'
                  : 'The share sheet is open — choose where to save your CSV '
                      '(Files, Drive, WhatsApp…).\n\n'
                      'An internal copy is also kept at:\n$path',
              style: const TextStyle(fontSize: 13),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Export failed. Please try again.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final ThemeData theme = Theme.of(context);
    final ExpenseProvider provider = context.read<ExpenseProvider>();
    if (provider.expenses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No data to clear'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          icon: Icon(Icons.warning_amber_rounded,
              color: theme.colorScheme.error, size: 40),
          title: const Text('Clear all data?'),
          content: Text(
            'This permanently deletes all ${provider.expenses.length} saved '
            'transactions. This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Delete All'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final bool ok = await provider.clearAllExpenses();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'All data cleared' : 'Could not clear data. Please try again.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector();

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (BuildContext context, ThemeProvider themeProvider, _) {
        final ThemeMode mode = themeProvider.themeMode;
        return Column(
          children: <Widget>[
            _modeTile(
              context,
              ThemeMode.system,
              'System Default',
              Icons.brightness_auto_rounded,
              mode,
              () => context.read<ThemeProvider>().setMode(ThemeMode.system),
            ),
            _modeTile(
              context,
              ThemeMode.light,
              'Light Mode',
              Icons.light_mode_rounded,
              mode,
              () => context.read<ThemeProvider>().setMode(ThemeMode.light),
            ),
            _modeTile(
              context,
              ThemeMode.dark,
              'Dark Mode',
              Icons.dark_mode_rounded,
              mode,
              () => context.read<ThemeProvider>().setMode(ThemeMode.dark),
            ),
          ],
        );
      },
    );
  }

  Widget _modeTile(
    BuildContext context,
    ThemeMode value,
    String title,
    IconData icon,
    ThemeMode current,
    VoidCallback onSelect,
  ) {
    final bool selected = current == value;
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
          : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onSelect,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text(title)),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A titled settings row.
class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color accent =
        destructive ? theme.colorScheme.error : theme.colorScheme.primary;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color:
                            destructive ? theme.colorScheme.error : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Key / value about-info row.
class _AboutRow extends StatelessWidget {
  const _AboutRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(value, style: theme.textTheme.bodyMedium),
        ),
      ],
    );
  }
}
