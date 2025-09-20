import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/emergency_communication_service.dart';
import 'dart:async';

class EmergencyCommunicationScreen extends StatefulWidget {
  const EmergencyCommunicationScreen({super.key});

  @override
  State<EmergencyCommunicationScreen> createState() => _EmergencyCommunicationScreenState();
}

class _EmergencyCommunicationScreenState extends State<EmergencyCommunicationScreen>
    with TickerProviderStateMixin {
  final EmergencyCommunicationService _communicationService = EmergencyCommunicationService();
  
  // Animation controllers
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  // Data state
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recentAlerts = [];
  bool _isLoading = true;
  bool _emergencyBroadcastActive = false;
  
  // UI state
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  
  // Selected options
  AlertType _selectedAlertType = AlertType.info;
  AlertPriority _selectedPriority = AlertPriority.medium;
  RecipientGroup _selectedRecipientGroup = RecipientGroup.all;
  List<CommunicationChannel> _selectedChannels = [CommunicationChannel.push];
  
  // Real-time subscriptions
  StreamSubscription? _alertSubscription;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeService();
    _loadData();
    _setupRealTimeSubscriptions();
    _setupAutoRefresh();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeService() async {
    await _communicationService.initialize();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final analytics = await _communicationService.getCommunicationAnalytics();
      final alerts = await _communicationService.getRecentAlerts(limit: 20);
      
      setState(() {
        _analytics = analytics;
        _recentAlerts = alerts;
        _emergencyBroadcastActive = analytics['emergency_broadcast_active'] ?? false;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading communication data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealTimeSubscriptions() {
    _alertSubscription = _communicationService.alertUpdates.listen((alertData) {
      _handleRealTimeAlert(alertData);
    });
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadData();
    });
  }

  void _handleRealTimeAlert(Map<String, dynamic> alertData) {
    setState(() {
      _recentAlerts.insert(0, alertData['data']);
      if (_recentAlerts.length > 20) {
        _recentAlerts.removeRange(20, _recentAlerts.length);
      }
    });
    
    // Show snackbar for new alerts
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('New ${alertData['data']['type']} alert sent'),
          backgroundColor: _getAlertTypeColor(alertData['data']['type']),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Communication'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showChannelSettings,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() => _selectedTabIndex = index);
                    },
                    children: [
                      _buildOverviewTab(),
                      _buildSendAlertTab(),
                      _buildRecentAlertsTab(),
                      _buildAnalyticsTab(),
                    ],
                  ),
                ),
              ],
            ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: TabBar(
        controller: TabController(length: 4, vsync: this, initialIndex: _selectedTabIndex),
        onTap: (index) {
          setState(() => _selectedTabIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
        tabs: const [
          Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
          Tab(icon: Icon(Icons.send), text: 'Send Alert'),
          Tab(icon: Icon(Icons.history), text: 'Recent'),
          Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEmergencyBroadcastCard(),
          const SizedBox(height: 16),
          _buildQuickStatsGrid(),
          const SizedBox(height: 16),
          _buildChannelStatusCard(),
          const SizedBox(height: 16),
          _buildQuickActionsCard(),
        ],
      ),
    );
  }

  Widget _buildEmergencyBroadcastCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _emergencyBroadcastActive
                            ? Colors.red.withOpacity(0.5 + (_pulseAnimation.value * 0.5))
                            : Colors.grey,
                      ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Text(
                  'Emergency Broadcast',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Switch(
                  value: _emergencyBroadcastActive,
                  onChanged: _toggleEmergencyBroadcast,
                  activeColor: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _emergencyBroadcastActive
                  ? 'Emergency broadcast is ACTIVE. All communications have priority routing.'
                  : 'Emergency broadcast is inactive. Normal communication rates apply.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _emergencyBroadcastActive ? Colors.red : Colors.grey[600],
              ),
            ),
            if (_emergencyBroadcastActive) ...[
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _showDeactivateBroadcastDialog(),
                icon: const Icon(Icons.stop),
                label: const Text('Deactivate Emergency Mode'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid() {
    final totals = _analytics['totals'] ?? {};
    
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.2,
      children: [
        _buildStatCard(
          'Total Alerts',
          '${totals['alerts'] ?? 0}',
          Icons.campaign,
          Colors.blue,
        ),
        _buildStatCard(
          'Recipients Reached',
          '${totals['recipients'] ?? 0}',
          Icons.people,
          Colors.green,
        ),
        _buildStatCard(
          'Success Rate',
          '${(totals['delivery_rate'] ?? 0).toStringAsFixed(1)}%',
          Icons.check_circle,
          Colors.orange,
        ),
        _buildStatCard(
          'Failed Deliveries',
          '${totals['failed'] ?? 0}',
          Icons.error,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelStatusCard() {
    final channelStatus = _analytics['channel_status'] ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Communication Channels',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...CommunicationChannel.values.map((channel) {
              final status = channelStatus[channel.name] ?? {};
              final isActive = status['status'] == 'active';
              
              return ListTile(
                leading: Icon(
                  _getChannelIcon(channel),
                  color: isActive ? Colors.green : Colors.grey,
                ),
                title: Text(_getChannelDisplayName(channel)),
                subtitle: Text(status['throughput'] ?? 'No data'),
                trailing: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _sendQuickAlert('Emergency', AlertType.emergency),
                  icon: const Icon(Icons.warning),
                  label: const Text('Emergency Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                ),
                ElevatedButton.icon(
                  onPressed: () => _sendQuickAlert('Weather Warning', AlertType.warning),
                  icon: const Icon(Icons.cloud),
                  label: const Text('Weather Alert'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                ),
                ElevatedButton.icon(
                  onPressed: () => _testAllChannels(),
                  icon: const Icon(Icons.network_check),
                  label: const Text('Test Channels'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendAlertTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Send Emergency Alert',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      labelText: 'Alert Message',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 16),
                  _buildAlertTypeSelector(),
                  const SizedBox(height: 16),
                  _buildPrioritySelector(),
                  const SizedBox(height: 16),
                  _buildRecipientGroupSelector(),
                  const SizedBox(height: 16),
                  _buildChannelSelector(),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _sendCustomAlert,
                      icon: const Icon(Icons.send),
                      label: const Text('Send Alert'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        backgroundColor: _getAlertTypeColor(_selectedAlertType.name),
                      ),
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

  Widget _buildRecentAlertsTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Text(
                'Recent Alerts',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: _recentAlerts.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('No recent alerts'),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _recentAlerts.length,
                  itemBuilder: (context, index) {
                    final alert = _recentAlerts[index];
                    return _buildAlertListItem(alert);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    final breakdown = _analytics['breakdown'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCard(
            'Alerts by Type',
            breakdown['by_type'] ?? {},
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Alerts by Priority',
            breakdown['by_priority'] ?? {},
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Channel Usage',
            breakdown['by_channel'] ?? {},
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsCard(String title, Map<String, dynamic> data, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (data.isEmpty)
              const Text('No data available')
            else
              ...data.entries.map((entry) {
                final percentage = data.values.fold<int>(0, (sum, value) => sum + (value as int)) > 0
                    ? (entry.value as int) / data.values.fold<int>(0, (sum, value) => sum + (value as int)) * 100
                    : 0.0;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Text(entry.key),
                      ),
                      Expanded(
                        flex: 3,
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text('${entry.value} (${percentage.toStringAsFixed(1)}%)'),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertListItem(Map<String, dynamic> alert) {
    final type = alert['type'] ?? 'info';
    final priority = alert['priority'] ?? 'medium';
    final createdAt = DateTime.tryParse(alert['created_at'] ?? '') ?? DateTime.now();
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getAlertTypeColor(type),
          child: Icon(
            _getAlertTypeIcon(type),
            color: Colors.white,
          ),
        ),
        title: Text(alert['title'] ?? 'No title'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(alert['message'] ?? 'No message'),
            const SizedBox(height: 4),
            Text(
              'Recipients: ${alert['total_recipients'] ?? 0} • '
              'Sent: ${alert['total_sent'] ?? 0} • '
              'Failed: ${alert['total_failed'] ?? 0}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: _getPriorityColor(priority),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priority.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () => _showAlertDetails(alert),
      ),
    );
  }

  Widget _buildAlertTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Alert Type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AlertType.values.map((type) {
            final isSelected = _selectedAlertType == type;
            return FilterChip(
              label: Text(type.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedAlertType = type);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: _getAlertTypeColor(type.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Priority',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: AlertPriority.values.map((priority) {
            final isSelected = _selectedPriority == priority;
            return FilterChip(
              label: Text(priority.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                setState(() => _selectedPriority = priority);
              },
              backgroundColor: Colors.grey[200],
              selectedColor: _getPriorityColor(priority.name),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRecipientGroupSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recipients',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<RecipientGroup>(
          value: _selectedRecipientGroup,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: RecipientGroup.values.map((group) {
            return DropdownMenuItem(
              value: group,
              child: Text(_getRecipientGroupDisplayName(group)),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedRecipientGroup = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildChannelSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Communication Channels',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CommunicationChannel.values.map((channel) {
            final isSelected = _selectedChannels.contains(channel);
            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getChannelIcon(channel), size: 16),
                  const SizedBox(width: 4),
                  Text(_getChannelDisplayName(channel)),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedChannels.add(channel);
                  } else {
                    _selectedChannels.remove(channel);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickAlertDialog(),
      icon: const Icon(Icons.add_alert),
      label: const Text('Quick Alert'),
      backgroundColor: Colors.red,
    );
  }

  // Helper methods
  Color _getAlertTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Colors.red;
      case 'urgent':
        return Colors.orange;
      case 'warning':
        return Colors.amber;
      case 'info':
        return Colors.blue;
      case 'update':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  IconData _getAlertTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'emergency':
        return Icons.emergency;
      case 'urgent':
        return Icons.priority_high;
      case 'warning':
        return Icons.warning;
      case 'info':
        return Icons.info;
      case 'update':
        return Icons.update;
      default:
        return Icons.notifications;
    }
  }

  IconData _getChannelIcon(CommunicationChannel channel) {
    switch (channel) {
      case CommunicationChannel.sms:
        return Icons.sms;
      case CommunicationChannel.email:
        return Icons.email;
      case CommunicationChannel.push:
        return Icons.notifications;
      case CommunicationChannel.inApp:
        return Icons.mobile_friendly;
      case CommunicationChannel.social:
        return Icons.share;
      case CommunicationChannel.broadcast:
        return Icons.radio;
    }
  }

  String _getChannelDisplayName(CommunicationChannel channel) {
    switch (channel) {
      case CommunicationChannel.sms:
        return 'SMS';
      case CommunicationChannel.email:
        return 'Email';
      case CommunicationChannel.push:
        return 'Push Notification';
      case CommunicationChannel.inApp:
        return 'In-App';
      case CommunicationChannel.social:
        return 'Social Media';
      case CommunicationChannel.broadcast:
        return 'Emergency Broadcast';
    }
  }

  String _getRecipientGroupDisplayName(RecipientGroup group) {
    switch (group) {
      case RecipientGroup.all:
        return 'All Users';
      case RecipientGroup.volunteers:
        return 'Volunteers';
      case RecipientGroup.donors:
        return 'Donors';
      case RecipientGroup.recipients:
        return 'Recipients';
      case RecipientGroup.admins:
        return 'Administrators';
      case RecipientGroup.crisisAffected:
        return 'Crisis Affected';
      case RecipientGroup.geographic:
        return 'Geographic Region';
      case RecipientGroup.custom:
        return 'Custom Group';
    }
  }

  // Action methods
  Future<void> _toggleEmergencyBroadcast(bool value) async {
    if (value) {
      _showActivateBroadcastDialog();
    } else {
      _showDeactivateBroadcastDialog();
    }
  }

  void _showActivateBroadcastDialog() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Activate Emergency Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will activate emergency broadcast mode with priority routing for all communications.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for activation',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _communicationService.activateEmergencyBroadcast(
                reason: reasonController.text.trim(),
              );
              
              if (success) {
                setState(() => _emergencyBroadcastActive = true);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency broadcast activated'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Activate'),
          ),
        ],
      ),
    );
  }

  void _showDeactivateBroadcastDialog() {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Emergency Broadcast'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'This will deactivate emergency broadcast mode and return to normal communication rates.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for deactivation (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _communicationService.deactivateEmergencyBroadcast(
                reason: reasonController.text.trim().isEmpty ? null : reasonController.text.trim(),
              );
              
              if (success) {
                setState(() => _emergencyBroadcastActive = false);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Emergency broadcast deactivated'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );
  }

  void _showQuickAlertDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send Quick Alert'),
        content: const Text('Select the type of quick alert to send:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendQuickAlert('Emergency Situation', AlertType.emergency);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Emergency'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _sendQuickAlert('Important Update', AlertType.urgent);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Urgent'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendQuickAlert(String title, AlertType type) async {
    final result = await _communicationService.sendEmergencyAlert(
      title: title,
      message: 'This is a $title notification. Please check the app for more details.',
      type: type,
      priority: type == AlertType.emergency ? AlertPriority.critical : AlertPriority.high,
      channels: [CommunicationChannel.push, CommunicationChannel.inApp],
      recipientGroup: RecipientGroup.all,
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert sent to ${result['recipients']} recipients'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendCustomAlert() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both title and message'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    if (_selectedChannels.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one communication channel'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await _communicationService.sendEmergencyAlert(
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      type: _selectedAlertType,
      priority: _selectedPriority,
      channels: _selectedChannels,
      recipientGroup: _selectedRecipientGroup,
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Alert sent to ${result['recipients']} recipients'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _titleController.clear();
      _messageController.clear();
      
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send alert: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _testAllChannels() async {
    final result = await _communicationService.testCommunicationChannels();
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Channel tests completed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Channel tests failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChannelSettings() {
    // Show channel configuration dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Channel Settings'),
        content: const Text('Channel configuration options would be shown here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(Map<String, dynamic> alert) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(alert['title'] ?? 'Alert Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Message: ${alert['message'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Type: ${alert['type'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Priority: ${alert['priority'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Recipients: ${alert['total_recipients'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Sent: ${alert['total_sent'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Failed: ${alert['total_failed'] ?? 0}'),
              const SizedBox(height: 8),
              Text('Created: ${alert['created_at'] ?? 'N/A'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _titleController.dispose();
    _messageController.dispose();
    _alertSubscription?.cancel();
    _refreshTimer?.cancel();
    _communicationService.dispose();
    super.dispose();
  }
}
