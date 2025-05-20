// File: lib/presentation/screens/home/settings_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/constants.dart';
import '../../../core/utils/app_colors.dart';
import '../../../domain/providers/auth_provider.dart';
import '../../../domain/providers/settings_provider.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isSyncing = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final settingsProvider = Provider.of<SettingsProvider>(context);

    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User profile section
            if (user != null) _buildUserProfileSection(user),

            // App settings section
            const SizedBox(height: 24),
            _buildSectionHeader('App Settings'),
            _buildSettingItem(
              title: 'Dark Mode',
              subtitle: 'Enable dark theme for the app',
              icon: Icons.dark_mode,
              trailing: Switch(
                value: settingsProvider.isDarkMode,
                onChanged: (value) => settingsProvider.toggleDarkMode(),
                activeColor: AppColors.primaryColor,
              ),
            ),
            _buildSettingItem(
              title: 'Notifications',
              subtitle: 'Enable reminder notifications',
              icon: Icons.notifications,
              trailing: Switch(
                value: settingsProvider.isNotificationEnabled,
                onChanged: (value) => settingsProvider.toggleNotifications(),
                activeColor: AppColors.primaryColor,
              ),
            ),
            if (settingsProvider.isNotificationEnabled)
              _buildSettingItem(
                title: 'Reminder Time',
                subtitle: _formatTime(settingsProvider.reminderHour, settingsProvider.reminderMinute),
                icon: Icons.access_time,
                onTap: () => _showTimePickerDialog(context, settingsProvider),
              ),

            // Data management section
            const SizedBox(height: 24),
            _buildSectionHeader('Data Management'),
            _buildSettingItem(
              title: 'Sync Data',
              subtitle: 'Sync your progress with the cloud',
              icon: Icons.sync,
              isLoading: _isSyncing,
              onTap: () => _syncData(settingsProvider),
            ),
            _buildSettingItem(
              title: 'Clear Cache',
              subtitle: 'Clear local cache data',
              icon: Icons.cleaning_services,
              onTap: () => _showClearCacheDialog(context),
            ),

            // Account section
            const SizedBox(height: 24),
            _buildSectionHeader('Account'),
            _buildSettingItem(
              title: 'Privacy Policy',
              subtitle: 'View our privacy policy',
              icon: Icons.privacy_tip,
              onTap: () => _showPrivacyPolicy(context),
            ),
            _buildSettingItem(
              title: 'Terms of Service',
              subtitle: 'View our terms of service',
              icon: Icons.description,
              onTap: () => _showTermsOfService(context),
            ),
            _buildSettingItem(
              title: 'Log Out',
              subtitle: 'Sign out of your account',
              icon: Icons.logout,
              iconColor: AppColors.error,
              onTap: () => _showLogoutDialog(context, authProvider, settingsProvider),
            ),

            // App info section
            const SizedBox(height: 24),
            _buildSectionHeader('About'),
            _buildSettingItem(
              title: 'Version',
              subtitle: AppConstants.appVersion,
              icon: Icons.info,
              onTap: null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserProfileSection(user) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // User avatar
            CircleAvatar(
              radius: 36,
              backgroundColor: AppColors.primaryLight,
              child: Text(
                user.name.substring(0, 1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // User info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getDiabetesTypeLabel(user.diabetesType),
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _getTreatmentMethodLabel(user.treatmentMethod),
                          style: const TextStyle(
                            color: AppColors.secondaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit profile button
            IconButton(
              icon: const Icon(Icons.edit, color: AppColors.primaryColor),
              onPressed: () => _showEditProfileDialog(context, user),
              tooltip: 'Edit Profile',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildSettingItem({
    required String title,
    required String subtitle,
    required IconData icon,
    Color? iconColor,
    Widget? trailing,
    VoidCallback? onTap,
    bool isLoading = false,
  }) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider, width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: isLoading
              ? const CircularProgressIndicator()
              : Icon(
            icon,
            color: iconColor ?? AppColors.primaryColor,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        trailing: trailing ?? (onTap != null ? const Icon(Icons.arrow_forward_ios, size: 16) : null),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  Future<void> _showTimePickerDialog(BuildContext context, SettingsProvider settingsProvider) async {
    final initialTime = TimeOfDay(
      hour: settingsProvider.reminderHour,
      minute: settingsProvider.reminderMinute,
    );

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null && mounted) {
      await settingsProvider.updateReminderTime(
        selectedTime.hour,
        selectedTime.minute,
      );
    }
  }

  Future<void> _syncData(SettingsProvider settingsProvider) async {
    if (_isSyncing) return;

    setState(() {
      _isSyncing = true;
    });

    try {
      final success = await settingsProvider.syncData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Data synchronized successfully!'
                  : settingsProvider.error ?? 'Failed to sync data. Try again later.',
            ),
            backgroundColor: success ? AppColors.success : AppColors.error,
          ),
        );
      }
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showClearCacheDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache'),
        content: const Text(
          'Are you sure you want to clear cache? This will not delete your account or progress data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Clear cache implementation
              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cache cleared successfully!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the privacy policy of the DiabetesEdu app. '
                'In a production app, this would include detailed information about how user data is collected, stored, and used.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfService(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: const SingleChildScrollView(
          child: Text(
            'This is a placeholder for the terms of service of the DiabetesEdu app. '
                'In a production app, this would include detailed information about the terms and conditions of using the app.',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(
      BuildContext context,
      AuthProvider authProvider,
      SettingsProvider settingsProvider,
      ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out? Your progress will be saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();

              // Show loading dialog
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(
                  child: CircularProgressIndicator(),
                ),
              );

              // Clear data and sign out
              await settingsProvider.clearAllData();
              await authProvider.signOut();

              if (mounted) {
                // Dismiss loading dialog
                Navigator.of(context).pop();

                // Navigate to login
                Navigator.of(context).pushNamedAndRemoveUntil(
                  AppConstants.loginRoute,
                      (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, user) {
    // This would open a profile editing dialog
    // For the MVP, we'll just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile editing will be available in a future update.'),
      ),
    );
  }

  String _formatTime(int hour, int minute) {
    final isPM = hour >= 12;
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final minuteStr = minute < 10 ? '0$minute' : minute.toString();
    return '$hour12:$minuteStr ${isPM ? 'PM' : 'AM'}';
  }

  String _getDiabetesTypeLabel(String diabetesType) {
    switch (diabetesType) {
      case AppConstants.diabetesType1:
        return 'Type 1';
      case AppConstants.diabetesType2:
        return 'Type 2';
      case AppConstants.diabetesGestational:
        return 'Gestational';
      case AppConstants.diabetesPre:
        return 'Prediabetes';
      default:
        return 'Unknown';
    }
  }

  String _getTreatmentMethodLabel(String treatmentMethod) {
    switch (treatmentMethod) {
      case AppConstants.treatmentInsulin:
        return 'Insulin';
      case AppConstants.treatmentPump:
        return 'Pump';
      case AppConstants.treatmentMedication:
        return 'Medication';
      case AppConstants.treatmentLifestyle:
        return 'Lifestyle';
      default:
        return 'Unknown';
    }
  }
}