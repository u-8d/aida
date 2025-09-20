import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/admin_user.dart';
import '../../models/disaster_campaign.dart';
import '../../providers/admin_app_state.dart';
import '../../config/app_theme.dart';
import '../components/crisis_mode_toggle.dart';
import '../components/enhanced_real_time_analytics_panel.dart';
import '../components/quick_action_buttons.dart';
import 'campaign_management_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDashboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshDashboard() async {
    setState(() {
      _isRefreshing = true;
    });

    final adminState = Provider.of<AdminAppState>(context, listen: false);
    await adminState.refreshAnalytics();
    await adminState.refreshDisasterCampaigns();

    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAppState>(
      builder: (context, adminState, child) {
        final currentAdmin = adminState.currentAdmin;
        
        if (currentAdmin == null) {
          return const Scaffold(
            body: Center(
              child: Text('Access denied. Admin authentication required.'),
            ),
          );
        }

        return Scaffold(
          backgroundColor: AppTheme.lightGray,
          body: RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              slivers: [
                _buildAppBar(currentAdmin),
                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _buildWelcomeSection(currentAdmin),
                      const SizedBox(height: 24),
                      _buildCrisisModeSection(currentAdmin, adminState),
                      const SizedBox(height: 24),
                      _buildQuickActionsSection(currentAdmin),
                      const SizedBox(height: 24),
                      _buildTabSection(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppBar(AdminUser admin) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppTheme.primaryBlue,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryBlue,
                AppTheme.primaryBlue.withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 16,
                bottom: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      admin.roleDisplayName,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      admin.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (admin.isCrisisMode)
                Positioned(
                  left: 16,
                  bottom: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.urgentRed,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.crisis_alert,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CRISIS MODE: ${admin.crisisLevelDisplayName}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: _isRefreshing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.refresh, color: Colors.white),
          onPressed: _isRefreshing ? null : _refreshDashboard,
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            switch (value) {
              case 'settings':
                _navigateToAdminSettings();
                break;
              case 'audit_log':
                _navigateToAuditLog();
                break;
              case 'logout':
                _signOut();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Admin Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'audit_log',
              child: Row(
                children: [
                  Icon(Icons.history),
                  SizedBox(width: 8),
                  Text('Audit Log'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sign Out', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeSection(AdminUser admin) {
    return Card(
      elevation: 2,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryBlue.withOpacity(0.1),
              AppTheme.primaryBlue.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppTheme.primaryBlue,
                  child: Text(
                    admin.name.isNotEmpty ? admin.name[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back, ${admin.name}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        admin.roleDisplayName,
                        style: TextStyle(
                          fontSize: 16,
                          color: AppTheme.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (admin.isSessionActive)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Active Session',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'Last active: ${_formatLastActive(admin.lastActiveSession)}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (admin.managedDisasterCampaigns.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Managing ${admin.managedDisasterCampaigns.length} disaster campaign(s)',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCrisisModeSection(AdminUser admin, AdminAppState adminState) {
    if (!admin.canManageCrisis()) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crisis Management',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            CrisisModeToggle(
              isEnabled: admin.isCrisisMode,
              currentLevel: admin.currentCrisisLevel,
              onToggle: (enabled, level) async {
                final success = await adminState.toggleCrisisMode(enabled, level);
                if (!success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to toggle crisis mode'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(AdminUser admin) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            QuickActionButtons(admin: admin),
          ],
        ),
      ),
    );
  }

  Widget _buildTabSection() {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryBlue,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppTheme.primaryBlue,
            tabs: const [
              Tab(
                icon: Icon(Icons.analytics),
                text: 'Analytics',
              ),
              Tab(
                icon: Icon(Icons.campaign),
                text: 'Campaigns',
              ),
              Tab(
                icon: Icon(Icons.people),
                text: 'Users',
              ),
              Tab(
                icon: Icon(Icons.admin_panel_settings),
                text: 'System',
              ),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController,
              children: [
                const EnhancedRealTimeAnalyticsPanel(),
                _buildCampaignManagementTab(),
                _buildUserManagementTab(),
                _buildSystemManagementTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignManagementTab() {
    return Consumer<AdminAppState>(
      builder: (context, adminState, child) {
        final campaigns = adminState.disasterCampaigns;
        final activeCampaigns = campaigns.where((c) => 
          c.status == CampaignStatus.active || c.status == CampaignStatus.urgent).length;
        final emergencyCampaigns = campaigns.where((c) => c.isEmergencyMode).length;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.campaign, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  const Text(
                    'Campaign Overview',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const CampaignManagementScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.manage_search),
                    label: const Text('Manage All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickStat('Total', campaigns.length, Colors.blue),
                  ),
                  Expanded(
                    child: _buildQuickStat('Active', activeCampaigns, Colors.green),
                  ),
                  Expanded(
                    child: _buildQuickStat('Emergency', emergencyCampaigns, Colors.red),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Recent Campaigns',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: campaigns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.campaign, size: 48, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'No campaigns yet',
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const CampaignManagementScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Campaign'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: campaigns.take(3).length, // Show only first 3
                        itemBuilder: (context, index) {
                          final campaign = campaigns[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getCampaignStatusColor(campaign.status),
                                child: Icon(
                                  _getCampaignIcon(campaign.disasterType),
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                campaign.title,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                '${campaign.location} • ${campaign.daysSinceStart}d ago',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getCampaignStatusColor(campaign.status),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      _getCampaignStatusText(campaign.status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${(campaign.completionPercentage * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (campaigns.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Center(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CampaignManagementScreen(),
                          ),
                        );
                      },
                      child: Text('View all ${campaigns.length} campaigns'),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuickStat(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Color _getCampaignStatusColor(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning:
        return Colors.blue;
      case CampaignStatus.active:
        return Colors.green;
      case CampaignStatus.urgent:
        return Colors.red;
      case CampaignStatus.winding_down:
        return Colors.orange;
      case CampaignStatus.completed:
        return Colors.grey;
      case CampaignStatus.suspended:
        return Colors.purple;
    }
  }

  String _getCampaignStatusText(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning:
        return 'PLAN';
      case CampaignStatus.active:
        return 'ACTIVE';
      case CampaignStatus.urgent:
        return 'URGENT';
      case CampaignStatus.winding_down:
        return 'ENDING';
      case CampaignStatus.completed:
        return 'DONE';
      case CampaignStatus.suspended:
        return 'PAUSED';
    }
  }

  IconData _getCampaignIcon(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake:
        return Icons.architecture;
      case DisasterType.flood:
        return Icons.water;
      case DisasterType.cyclone:
        return Icons.cyclone;
      case DisasterType.fire:
        return Icons.local_fire_department;
      case DisasterType.drought:
        return Icons.wb_sunny;
      case DisasterType.landslide:
        return Icons.landscape;
      case DisasterType.tsunami:
        return Icons.waves;
      case DisasterType.volcanic:
        return Icons.terrain;
      case DisasterType.pandemic:
        return Icons.health_and_safety;
      case DisasterType.industrial:
        return Icons.factory;
      case DisasterType.other:
        return Icons.crisis_alert;
    }
  }

  Widget _buildUserManagementTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'User Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('User management features coming soon...'),
        ],
      ),
    );
  }

  Widget _buildSystemManagementTab() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            'System Management',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 16),
          Text('System management features coming soon...'),
        ],
      ),
    );
  }

  String _formatLastActive(DateTime? lastActive) {
    if (lastActive == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastActive);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _navigateToAdminSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Admin settings coming soon...')),
    );
  }

  void _navigateToAuditLog() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audit log coming soon...')),
    );
  }

  void _signOut() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign Out'),
          content: const Text('Are you sure you want to sign out of the admin panel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                
                // Sign out and navigate back to main app
                await Provider.of<AdminAppState>(context, listen: false).signOut();
                
                if (mounted) {
                  // Navigate to the main app home screen
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/',
                    (route) => false,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Successfully signed out of admin panel'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
    );
  }
}
