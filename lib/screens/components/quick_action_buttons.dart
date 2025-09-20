import 'package:flutter/material.dart';
import '../../models/admin_user.dart';
import '../../config/app_theme.dart';

class QuickActionButtons extends StatelessWidget {
  final AdminUser admin;

  const QuickActionButtons({
    super.key,
    required this.admin,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 2.5,
      children: _buildActionButtons(context),
    );
  }

  List<Widget> _buildActionButtons(BuildContext context) {
    List<Widget> buttons = [];

    // Crisis Management Actions
    if (admin.canManageCrisis()) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.campaign,
          label: 'New Campaign',
          color: AppTheme.primaryBlue,
          onTap: () => _createDisasterCampaign(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.emergency,
          label: 'Emergency Alert',
          color: AppTheme.urgentRed,
          onTap: () => _sendEmergencyAlert(context),
        ),
      ]);
    }

    // User Management Actions
    if (admin.canManageUsers()) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.people,
          label: 'User Verification',
          color: Colors.green,
          onTap: () => _manageUserVerification(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.support_agent,
          label: 'User Support',
          color: Colors.orange,
          onTap: () => _accessUserSupport(context),
        ),
      ]);
    }

    // Analytics Actions
    if (admin.canAccessAnalytics()) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.analytics,
          label: 'Live Analytics',
          color: Colors.purple,
          onTap: () => _viewLiveAnalytics(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.trending_up,
          label: 'System Monitor',
          color: Colors.teal,
          onTap: () => _viewSystemMonitor(context),
        ),
      ]);
    }

    // Content Moderation Actions
    if (admin.canModerateContent()) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.flag,
          label: 'Flagged Content',
          color: Colors.red.shade600,
          onTap: () => _reviewFlaggedContent(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.security,
          label: 'Platform Safety',
          color: Colors.indigo,
          onTap: () => _managePlatformSafety(context),
        ),
      ]);
    }

    // Super Admin Actions
    if (admin.adminRole == AdminRole.superAdmin) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.admin_panel_settings,
          label: 'Admin Users',
          color: Colors.deepPurple,
          onTap: () => _manageAdminUsers(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.settings,
          label: 'System Config',
          color: Colors.grey.shade700,
          onTap: () => _systemConfiguration(context),
        ),
      ]);
    }

    // If no specific permissions, show general actions
    if (buttons.isEmpty) {
      buttons.addAll([
        _buildActionButton(
          context,
          icon: Icons.help,
          label: 'Help & Support',
          color: AppTheme.primaryBlue,
          onTap: () => _showHelp(context),
        ),
        _buildActionButton(
          context,
          icon: Icons.contact_support,
          label: 'Contact Admin',
          color: Colors.orange,
          onTap: () => _contactSupport(context),
        ),
      ]);
    }

    return buttons;
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: color,
                  fontSize: 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Action handlers
  void _createDisasterCampaign(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Create Disaster Campaign - Coming Soon')),
    );
  }

  void _sendEmergencyAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Emergency Alert System - Coming Soon')),
    );
  }

  void _manageUserVerification(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User Verification Management - Coming Soon')),
    );
  }

  void _accessUserSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('User Support Dashboard - Coming Soon')),
    );
  }

  void _viewLiveAnalytics(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Live Analytics Dashboard - Coming Soon')),
    );
  }

  void _viewSystemMonitor(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System Monitor - Coming Soon')),
    );
  }

  void _reviewFlaggedContent(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Flagged Content Review - Coming Soon')),
    );
  }

  void _managePlatformSafety(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Platform Safety Management - Coming Soon')),
    );
  }

  void _manageAdminUsers(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin User Management - Coming Soon')),
    );
  }

  void _systemConfiguration(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('System Configuration - Coming Soon')),
    );
  }

  void _showHelp(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Admin Help'),
          content: Text(
            'Welcome to the AIDA Admin Panel!\n\n'
            'This dashboard provides tools for managing disaster response, '
            'monitoring platform health, and supporting users during crises.\n\n'
            'Your role: ${admin.roleDisplayName}\n'
            'Permissions: Based on your role, you have access to specific '
            'administrative functions.\n\n'
            'For additional support, contact the super administrator.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }

  void _contactSupport(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin Support Contact - Coming Soon')),
    );
  }
}
