import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/point_type.dart';
import '../../models/user_preferences.dart';
import '../../providers/settings_provider.dart';
import '../../providers/card_list_provider.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Payment Mode
              _buildSectionHeader(context, 'Payment Mode'),
              _buildCard(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Enable Apple Pay'),
                      subtitle: Text(
                        settings.useApplePay
                            ? 'Tap to pay directly from the app'
                            : 'Just shows which card to use',
                        style: const TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                      ),
                      value: settings.useApplePay,
                      onChanged: (_) => settings.toggleApplePay(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Notifications
              _buildSectionHeader(context, 'Notifications'),
              _buildCard(
                child: SwitchListTile(
                  title: const Text('Spending Alerts'),
                  subtitle: const Text(
                    'Get notified when approaching spending limits',
                    style: TextStyle(fontSize: 12, color: AppTheme.textTertiary),
                  ),
                  value: settings.notificationsEnabled,
                  onChanged: (_) => settings.toggleNotifications(),
                ),
              ),
              const SizedBox(height: 20),

              // Preferred Point System
              _buildSectionHeader(context, 'Preferred Points'),
              _buildCard(
                child: Column(
                  children: PointType.values.map((pt) {
                    return RadioListTile<PointType>(
                      title: Text(pt.displayName, style: const TextStyle(fontSize: 14)),
                      value: pt,
                      groupValue: settings.preferredPointSystem,
                      activeColor: AppTheme.accent,
                      onChanged: (v) {
                        if (v != null) settings.setPreferredPointSystem(v);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Language
              _buildSectionHeader(context, 'Language'),
              _buildCard(
                child: Column(
                  children: Language.values.map((lang) {
                    return RadioListTile<Language>(
                      title: Text(lang.displayName, style: const TextStyle(fontSize: 14)),
                      value: lang,
                      groupValue: settings.preferences.language,
                      activeColor: AppTheme.accent,
                      onChanged: (v) {
                        if (v != null) settings.setLanguage(v);
                      },
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),

              // Data
              _buildSectionHeader(context, 'Data'),
              _buildCard(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.download, color: AppTheme.accent),
                      title: const Text('Load Sample Cards'),
                      subtitle: const Text('Add 5 popular credit cards', style: TextStyle(fontSize: 12, color: AppTheme.textTertiary)),
                      onTap: () async {
                        await context.read<CardListProvider>().loadSampleData();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sample cards loaded!')),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // About
              Center(
                child: Text(
                  '${AppConstants.appName} v${AppConstants.appVersion}',
                  style: const TextStyle(color: AppTheme.textTertiary, fontSize: 12),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium),
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}
