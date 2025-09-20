import 'package:flutter/material.dart';
import 'dart:async';
import '../services/crisis_mode_service.dart';

class CrisisModeScreen extends StatefulWidget {
  const CrisisModeScreen({super.key});

  @override
  State<CrisisModeScreen> createState() => _CrisisModeScreenState();
}

class _CrisisModeScreenState extends State<CrisisModeScreen> 
    with TickerProviderStateMixin {
  final CrisisModeService _crisisService = CrisisModeService();
  
  // State management
  Map<String, dynamic> _crisisStatus = {};
  Map<String, dynamic> _surgeRecommendations = {};
  List<Map<String, dynamic>> _crisisTimeline = [];
  bool _isLoading = true;
  
  // Real-time updates
  StreamSubscription<Map<String, dynamic>>? _crisisSubscription;
  Timer? _refreshTimer;
  
  // Animation controllers
  late AnimationController _pulseController;
  late AnimationController _levelController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _levelColorAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeCrisisService();
    _loadData();
    _startRealTimeUpdates();
  }

  @override
  void dispose() {
    _crisisSubscription?.cancel();
    _refreshTimer?.cancel();
    _pulseController.dispose();
    _levelController.dispose();
    _crisisService.dispose();
    super.dispose();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _levelController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _levelColorAnimation = ColorTween(
      begin: Colors.green,
      end: Colors.red,
    ).animate(_levelController);
  }

  Future<void> _initializeCrisisService() async {
    await _crisisService.initialize();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _crisisService.getCrisisStatus(),
        _crisisService.getSurgeCapacityRecommendations(),
        _crisisService.getCrisisTimeline(limit: 20),
      ]);
      
      setState(() {
        _crisisStatus = futures[0] as Map<String, dynamic>;
        _surgeRecommendations = futures[1] as Map<String, dynamic>;
        _crisisTimeline = futures[2] as List<Map<String, dynamic>>;
      });
      
      _updateAnimations();
    } catch (e) {
      _showErrorSnackBar('Failed to load crisis data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _startRealTimeUpdates() {
    // Subscribe to crisis updates
    _crisisSubscription = _crisisService.crisisUpdates.listen((update) {
      if (mounted) {
        _loadData(); // Refresh data on crisis updates
      }
    });
    
    // Periodic refresh for metrics
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted && _crisisService.isCrisisModeActive) {
        _loadData();
      }
    });
  }

  void _updateAnimations() {
    final isActive = _crisisStatus['is_active'] as bool? ?? false;
    final level = _crisisStatus['level'] as String? ?? 'none';
    
    if (isActive) {
      _pulseController.repeat(reverse: true);
      
      // Update level animation based on crisis level
      double targetValue = 0.0;
      switch (level) {
        case 'low': targetValue = 0.2; break;
        case 'medium': targetValue = 0.4; break;
        case 'high': targetValue = 0.7; break;
        case 'critical': targetValue = 1.0; break;
      }
      _levelController.animateTo(targetValue);
    } else {
      _pulseController.stop();
      _levelController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crisis Mode Control'),
        backgroundColor: _getAppBarColor(),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          if (_crisisService.isCrisisModeActive)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: IconButton(
                    icon: const Icon(Icons.warning, color: Colors.red),
                    onPressed: () => _showQuickActionsDialog(),
                  ),
                );
              },
            ),
        ],
      ),
      body: _isLoading ? _buildLoadingView() : _buildMainView(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Loading crisis control system...'),
        ],
      ),
    );
  }

  Widget _buildMainView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCrisisStatusCard(),
          const SizedBox(height: 16),
          _buildQuickControlsRow(),
          const SizedBox(height: 16),
          _buildMetricsSection(),
          const SizedBox(height: 16),
          _buildSurgeRecommendationsCard(),
          const SizedBox(height: 16),
          _buildTimelineCard(),
        ],
      ),
    );
  }

  Widget _buildCrisisStatusCard() {
    final isActive = _crisisStatus['is_active'] as bool? ?? false;
    final level = _crisisStatus['level'] as String? ?? 'none';
    final type = _crisisStatus['type'] as String? ?? '';
    final uptimeMinutes = _crisisStatus['uptime_minutes'] as int? ?? 0;
    
    return AnimatedBuilder(
      animation: _levelColorAnimation,
      builder: (context, child) {
        return Card(
          color: isActive ? _levelColorAnimation.value?.withOpacity(0.1) : null,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: isActive ? _pulseAnimation.value : 1.0,
                          child: Icon(
                            isActive ? Icons.warning : Icons.check_circle,
                            size: 32,
                            color: isActive ? Colors.red : Colors.green,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isActive ? 'CRISIS MODE ACTIVE' : 'NORMAL OPERATIONS',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isActive ? Colors.red : Colors.green,
                            ),
                          ),
                          if (isActive) ...[
                            Text(
                              'Level: ${level.toUpperCase()}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (type.isNotEmpty)
                              Text(
                                'Type: ${type.toUpperCase()}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (isActive) ...[
                  const SizedBox(height: 16),
                  _buildCrisisMetrics(uptimeMinutes),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCrisisMetrics(int uptimeMinutes) {
    final metrics = _crisisStatus['metrics'] as Map<String, dynamic>? ?? {};
    final automations = _crisisStatus['active_automations'] as List<dynamic>? ?? [];
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                'Uptime',
                _formatUptime(uptimeMinutes),
                Icons.access_time,
                Colors.blue,
              ),
            ),
            Expanded(
              child: _buildMetricTile(
                'System Load',
                metrics['load_level']?.toString().toUpperCase() ?? 'UNKNOWN',
                Icons.speed,
                _getLoadColor(metrics['load_level']),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (automations.isNotEmpty) ...[
          const Text(
            'Active Automations:',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            children: automations.map<Widget>((automation) {
              return Chip(
                label: Text(
                  automation.toString(),
                  style: const TextStyle(fontSize: 12),
                ),
                backgroundColor: Colors.blue[100],
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickControlsRow() {
    final isActive = _crisisService.isCrisisModeActive;
    
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: isActive ? null : _showActivateCrisisDialog,
            icon: const Icon(Icons.emergency),
            label: const Text('Activate Crisis Mode'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        if (isActive)
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showDeactivateCrisisDialog,
              icon: const Icon(Icons.stop),
              label: const Text('Deactivate'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        if (isActive) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _showUpdateLevelDialog,
              icon: const Icon(Icons.trending_up),
              label: const Text('Update Level'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMetricsSection() {
    final metrics = _crisisStatus['metrics'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Real-time Metrics',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildMetricCard(
                  'User Registrations/hr',
                  '${metrics['user_registration_rate']?.toInt() ?? 0}',
                  Icons.person_add,
                  Colors.blue,
                ),
                _buildMetricCard(
                  'Donations/hr',
                  '${metrics['donation_rate']?.toInt() ?? 0}',
                  Icons.attach_money,
                  Colors.green,
                ),
                _buildMetricCard(
                  'Help Requests/hr',
                  '${metrics['help_request_rate']?.toInt() ?? 0}',
                  Icons.help,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSurgeRecommendationsCard() {
    final recommendations = _surgeRecommendations['recommendations'] as Map<String, dynamic>? ?? {};
    
    if (recommendations.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Surge Capacity',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  const Text('No scaling required - System capacity normal'),
                ],
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Surge Capacity Recommendations',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _executeEmergencyProcedures,
                  icon: const Icon(Icons.bolt),
                  label: const Text('Execute All'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...recommendations.entries.map((entry) {
              final recommendation = entry.value as Map<String, dynamic>;
              return _buildRecommendationTile(
                entry.key,
                recommendation['action'] ?? '',
                recommendation['reason'] ?? '',
                recommendation['recommended_capacity'] ?? '',
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Crisis Timeline',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (_crisisTimeline.isEmpty)
              const Text('No crisis events recorded')
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _crisisTimeline.length,
                separatorBuilder: (context, index) => const Divider(),
                itemBuilder: (context, index) {
                  final event = _crisisTimeline[index];
                  return _buildTimelineItem(event);
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationTile(String service, String action, String reason, String capacity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: const Border(left: BorderSide(width: 4, color: Colors.orange)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.replaceAll('_', ' ').toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '$action${capacity.isNotEmpty ? " ($capacity)" : ""}',
                  style: const TextStyle(color: Colors.orange),
                ),
                Text(
                  reason,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.play_arrow, color: Colors.orange),
            onPressed: () => _executeRecommendation(service, action),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(Map<String, dynamic> event) {
    final action = event['action'] ?? '';
    final details = event['details'] as Map<String, dynamic>? ?? {};
    final createdAt = event['created_at'] ?? '';
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: _getActionColor(action),
        radius: 12,
        child: Icon(
          _getActionIcon(action),
          size: 16,
          color: Colors.white,
        ),
      ),
      title: Text(
        action.replaceAll('_', ' ').toUpperCase(),
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (details.isNotEmpty)
            Text(
              details.toString(),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          Text(
            _formatTimestamp(createdAt),
            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    if (!_crisisService.isCrisisModeActive) return Container();
    
    return FloatingActionButton.extended(
      onPressed: _executeEmergencyProcedures,
      backgroundColor: Colors.red,
      icon: const Icon(Icons.emergency),
      label: const Text('EMERGENCY PROCEDURES'),
    );
  }

  // Helper methods
  Color _getAppBarColor() {
    if (!_crisisService.isCrisisModeActive) return Colors.blue;
    
    switch (_crisisService.currentCrisisLevel) {
      case CrisisLevel.low: return Colors.yellow[700]!;
      case CrisisLevel.medium: return Colors.orange;
      case CrisisLevel.high: return Colors.red[700]!;
      case CrisisLevel.critical: return Colors.red[900]!;
      default: return Colors.blue;
    }
  }

  Color _getLoadColor(String? loadLevel) {
    switch (loadLevel) {
      case 'critical': return Colors.red;
      case 'high': return Colors.orange;
      case 'medium': return Colors.yellow[700]!;
      case 'elevated': return Colors.blue;
      default: return Colors.green;
    }
  }

  Color _getActionColor(String action) {
    if (action.contains('activated')) return Colors.red;
    if (action.contains('deactivated')) return Colors.green;
    if (action.contains('updated')) return Colors.blue;
    return Colors.grey;
  }

  IconData _getActionIcon(String action) {
    if (action.contains('activated')) return Icons.emergency;
    if (action.contains('deactivated')) return Icons.check;
    if (action.contains('updated')) return Icons.update;
    return Icons.info;
  }

  String _formatUptime(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;
    return '${hours}h ${remainingMinutes}m';
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) return 'Just now';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
      if (difference.inHours < 24) return '${difference.inHours}h ago';
      return '${difference.inDays}d ago';
    } catch (e) {
      return timestamp;
    }
  }

  // Action methods
  Future<void> _showActivateCrisisDialog() async {
    CrisisLevel? selectedLevel;
    CrisisType? selectedType;
    final descriptionController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Activate Crisis Mode'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CrisisLevel>(
                  value: selectedLevel,
                  decoration: const InputDecoration(
                    labelText: 'Crisis Level',
                    border: OutlineInputBorder(),
                  ),
                  items: CrisisLevel.values.where((level) => level != CrisisLevel.none).map((level) => 
                    DropdownMenuItem(
                      value: level,
                      child: Text(level.name.toUpperCase()),
                    )
                  ).toList(),
                  onChanged: (level) => setState(() => selectedLevel = level),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<CrisisType>(
                  value: selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Crisis Type',
                    border: OutlineInputBorder(),
                  ),
                  items: CrisisType.values.map((type) => 
                    DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    )
                  ).toList(),
                  onChanged: (type) => setState(() => selectedType = type),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedLevel != null && selectedType != null
                ? () => Navigator.of(context).pop(true)
                : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('ACTIVATE'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true && selectedLevel != null && selectedType != null) {
      final success = await _crisisService.activateCrisisMode(
        level: selectedLevel!,
        type: selectedType!,
        description: descriptionController.text.trim().isNotEmpty 
          ? descriptionController.text.trim() 
          : null,
      );
      
      if (success) {
        _showSuccessSnackBar('Crisis mode activated successfully');
        await _loadData();
      } else {
        _showErrorSnackBar('Failed to activate crisis mode');
      }
    }
  }

  Future<void> _showDeactivateCrisisDialog() async {
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deactivate Crisis Mode'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Are you sure you want to deactivate crisis mode?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('DEACTIVATE'),
          ),
        ],
      ),
    );
    
    if (result == true) {
      final success = await _crisisService.deactivateCrisisMode(
        reason: reasonController.text.trim().isNotEmpty 
          ? reasonController.text.trim() 
          : null,
      );
      
      if (success) {
        _showSuccessSnackBar('Crisis mode deactivated');
        await _loadData();
      } else {
        _showErrorSnackBar('Failed to deactivate crisis mode');
      }
    }
  }

  Future<void> _showUpdateLevelDialog() async {
    CrisisLevel? selectedLevel = _crisisService.currentCrisisLevel;
    final reasonController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update Crisis Level'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<CrisisLevel>(
                value: selectedLevel,
                decoration: const InputDecoration(
                  labelText: 'New Crisis Level',
                  border: OutlineInputBorder(),
                ),
                items: CrisisLevel.values.where((level) => level != CrisisLevel.none).map((level) => 
                  DropdownMenuItem(
                    value: level,
                    child: Text(level.name.toUpperCase()),
                  )
                ).toList(),
                onChanged: (level) => setState(() => selectedLevel = level),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: selectedLevel != null
                ? () => Navigator.of(context).pop(true)
                : null,
              child: const Text('UPDATE'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true && selectedLevel != null) {
      final success = await _crisisService.updateCrisisLevel(
        selectedLevel!,
        reason: reasonController.text.trim().isNotEmpty 
          ? reasonController.text.trim() 
          : null,
      );
      
      if (success) {
        _showSuccessSnackBar('Crisis level updated');
        await _loadData();
      } else {
        _showErrorSnackBar('Failed to update crisis level');
      }
    }
  }

  Future<void> _showQuickActionsDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quick Crisis Actions'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.trending_up, color: Colors.orange),
              title: const Text('Escalate Level'),
              onTap: () {
                Navigator.of(context).pop();
                _showUpdateLevelDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.bolt, color: Colors.red),
              title: const Text('Execute Emergency Procedures'),
              onTap: () {
                Navigator.of(context).pop();
                _executeEmergencyProcedures();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop, color: Colors.grey),
              title: const Text('Deactivate Crisis Mode'),
              onTap: () {
                Navigator.of(context).pop();
                _showDeactivateCrisisDialog();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _executeEmergencyProcedures() async {
    try {
      _showLoadingDialog('Executing emergency procedures...');
      
      final result = await _crisisService.executeEmergencyProcedures();
      
      Navigator.of(context).pop(); // Close loading dialog
      
      if (result['success'] == true) {
        _showSuccessSnackBar('Emergency procedures executed successfully');
        await _loadData();
      } else {
        _showErrorSnackBar('Failed to execute emergency procedures: ${result['error']}');
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Error executing emergency procedures: $e');
    }
  }

  Future<void> _executeRecommendation(String service, String action) async {
    try {
      _showLoadingDialog('Executing $action for $service...');
      
      // Simulate recommendation execution
      await Future.delayed(const Duration(seconds: 2));
      
      Navigator.of(context).pop(); // Close loading dialog
      _showSuccessSnackBar('$action executed for $service');
      await _loadData();
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorSnackBar('Failed to execute recommendation: $e');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
