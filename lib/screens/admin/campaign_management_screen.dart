import 'package:flutter/material.dart';
import '../../models/disaster_campaign.dart';
import '../../services/campaign_management_service.dart';
import '../../config/app_theme.dart';
import 'campaign_creation_screen.dart';

class CampaignManagementScreen extends StatefulWidget {
  const CampaignManagementScreen({super.key});

  @override
  State<CampaignManagementScreen> createState() => _CampaignManagementScreenState();
}

class _CampaignManagementScreenState extends State<CampaignManagementScreen> {
  final _campaignService = CampaignManagementService();
  List<DisasterCampaign> _campaigns = [];
  bool _isLoading = true;
  
  // Filters
  CampaignStatus? _selectedStatus;
  DisasterType? _selectedDisasterType;
  ResourcePriority? _selectedPriority;
  bool _emergencyOnly = false;

  @override
  void initState() {
    super.initState();
    _loadCampaigns();
  }

  Future<void> _loadCampaigns() async {
    setState(() => _isLoading = true);
    
    try {
      final campaigns = await _campaignService.getCampaigns(
        status: _selectedStatus,
        disasterType: _selectedDisasterType,
        priority: _selectedPriority,
        isEmergencyMode: _emergencyOnly ? true : null,
        limit: 100,
      );
      
      setState(() {
        _campaigns = campaigns;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading campaigns: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Campaign Management'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadCampaigns,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildQuickStats(),
          if (_hasActiveFilters()) _buildFilterChips(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _campaigns.isEmpty
                    ? _buildEmptyState()
                    : _buildCampaignsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewCampaign,
        backgroundColor: AppTheme.accentOrange,
        icon: const Icon(Icons.add),
        label: const Text('New Campaign'),
      ),
    );
  }

  Widget _buildQuickStats() {
    final totalCampaigns = _campaigns.length;
    final activeCampaigns = _campaigns.where((c) => c.status == CampaignStatus.active || c.status == CampaignStatus.urgent).length;
    final emergencyCampaigns = _campaigns.where((c) => c.isEmergencyMode).length;
    final completedCampaigns = _campaigns.where((c) => c.status == CampaignStatus.completed).length;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(child: _buildStatItem('Total', totalCampaigns, Colors.blue)),
            Expanded(child: _buildStatItem('Active', activeCampaigns, Colors.green)),
            Expanded(child: _buildStatItem('Emergency', emergencyCampaigns, Colors.red)),
            Expanded(child: _buildStatItem('Completed', completedCampaigns, Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
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

  Widget _buildFilterChips() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Text('Filters: ', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                if (_selectedStatus != null)
                  _buildFilterChip(
                    'Status: ${_getStatusDisplay(_selectedStatus!)}',
                    () => setState(() => _selectedStatus = null),
                  ),
                if (_selectedDisasterType != null)
                  _buildFilterChip(
                    'Type: ${_getDisasterTypeDisplay(_selectedDisasterType!)}',
                    () => setState(() => _selectedDisasterType = null),
                  ),
                if (_selectedPriority != null)
                  _buildFilterChip(
                    'Priority: ${_getPriorityDisplay(_selectedPriority!)}',
                    () => setState(() => _selectedPriority = null),
                  ),
                if (_emergencyOnly)
                  _buildFilterChip(
                    'Emergency Only',
                    () => setState(() => _emergencyOnly = false),
                  ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: ActionChip(
                    label: const Text('Clear All'),
                    onPressed: _clearAllFilters,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onDelete) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: () {
          onDelete();
          _loadCampaigns();
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.campaign,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No campaigns found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first disaster response campaign',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewCampaign,
            icon: const Icon(Icons.add),
            label: const Text('Create Campaign'),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (context, index) {
        final campaign = _campaigns[index];
        return _buildCampaignCard(campaign);
      },
    );
  }

  Widget _buildCampaignCard(DisasterCampaign campaign) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _editCampaign(campaign),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                campaign.title,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            _buildStatusBadge(campaign.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          campaign.disasterTypeDisplayName,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    onSelected: (action) => _handleCampaignAction(campaign, action),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('Edit'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'status',
                        child: ListTile(
                          leading: Icon(Icons.update),
                          title: Text('Update Status'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'emergency',
                        child: ListTile(
                          leading: Icon(Icons.warning),
                          title: Text('Toggle Emergency'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('Delete', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                campaign.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      campaign.location,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  if (campaign.isEmergencyMode) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'EMERGENCY',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: campaign.completionPercentage,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            campaign.completionPercentage > 0.8
                                ? Colors.green
                                : campaign.completionPercentage > 0.5
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(campaign.completionPercentage * 100).round()}% complete',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Beneficiaries',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${campaign.currentBeneficiaries}/${campaign.targetBeneficiaries}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coordinator: ${campaign.coordinatorName}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  Text(
                    '${campaign.daysSinceStart} days ago',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(CampaignStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case CampaignStatus.planning:
        color = Colors.grey;
        text = 'Planning';
        break;
      case CampaignStatus.active:
        color = Colors.green;
        text = 'Active';
        break;
      case CampaignStatus.urgent:
        color = Colors.red;
        text = 'Urgent';
        break;
      case CampaignStatus.winding_down:
        color = Colors.orange;
        text = 'Winding Down';
        break;
      case CampaignStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case CampaignStatus.suspended:
        color = Colors.grey;
        text = 'Suspended';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter Campaigns'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<CampaignStatus?>(
                  value: _selectedStatus,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Statuses')),
                    ...CampaignStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Text(_getStatusDisplay(status)),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedStatus = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<DisasterType?>(
                  value: _selectedDisasterType,
                  decoration: const InputDecoration(labelText: 'Disaster Type'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Types')),
                    ...DisasterType.values.map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(_getDisasterTypeDisplay(type)),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedDisasterType = value),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ResourcePriority?>(
                  value: _selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('All Priorities')),
                    ...ResourcePriority.values.map((priority) => DropdownMenuItem(
                      value: priority,
                      child: Text(_getPriorityDisplay(priority)),
                    )),
                  ],
                  onChanged: (value) => setDialogState(() => _selectedPriority = value),
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Emergency Mode Only'),
                  value: _emergencyOnly,
                  onChanged: (value) => setDialogState(() => _emergencyOnly = value!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {});
                _loadCampaigns();
              },
              child: const Text('Apply Filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearAllFilters() {
    setState(() {
      _selectedStatus = null;
      _selectedDisasterType = null;
      _selectedPriority = null;
      _emergencyOnly = false;
    });
    _loadCampaigns();
  }

  bool _hasActiveFilters() {
    return _selectedStatus != null || 
           _selectedDisasterType != null || 
           _selectedPriority != null || 
           _emergencyOnly;
  }

  Future<void> _createNewCampaign() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CampaignCreationScreen(),
      ),
    );
    
    if (result == true) {
      _loadCampaigns();
    }
  }

  Future<void> _editCampaign(DisasterCampaign campaign) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CampaignCreationScreen(existingCampaign: campaign),
      ),
    );
    
    if (result == true) {
      _loadCampaigns();
    }
  }

  void _handleCampaignAction(DisasterCampaign campaign, String action) {
    switch (action) {
      case 'edit':
        _editCampaign(campaign);
        break;
      case 'status':
        _updateCampaignStatus(campaign);
        break;
      case 'emergency':
        _toggleEmergencyMode(campaign);
        break;
      case 'delete':
        _deleteCampaign(campaign);
        break;
    }
  }

  void _updateCampaignStatus(DisasterCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) {
        CampaignStatus newStatus = campaign.status;
        
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Update Status'),
            content: DropdownButtonFormField<CampaignStatus>(
              value: newStatus,
              decoration: const InputDecoration(labelText: 'New Status'),
              items: CampaignStatus.values.map((status) => DropdownMenuItem(
                value: status,
                child: Text(_getStatusDisplay(status)),
              )).toList(),
              onChanged: (value) => setDialogState(() => newStatus = value!),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  try {
                    await _campaignService.updateCampaignStatus(campaign.id, newStatus);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Status updated successfully!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    _loadCampaigns();
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating status: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _toggleEmergencyMode(DisasterCampaign campaign) async {
    try {
      await _campaignService.toggleEmergencyMode(campaign.id, !campaign.isEmergencyMode);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(campaign.isEmergencyMode 
              ? 'Emergency mode deactivated' 
              : 'Emergency mode activated'),
          backgroundColor: Colors.green,
        ),
      );
      _loadCampaigns();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error toggling emergency mode: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _deleteCampaign(DisasterCampaign campaign) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: Text('Are you sure you want to delete "${campaign.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _campaignService.deleteCampaign(campaign.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Campaign deleted successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
                _loadCampaigns();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting campaign: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _getStatusDisplay(CampaignStatus status) {
    switch (status) {
      case CampaignStatus.planning: return 'Planning';
      case CampaignStatus.active: return 'Active';
      case CampaignStatus.urgent: return 'Urgent';
      case CampaignStatus.winding_down: return 'Winding Down';
      case CampaignStatus.completed: return 'Completed';
      case CampaignStatus.suspended: return 'Suspended';
    }
  }

  String _getDisasterTypeDisplay(DisasterType type) {
    switch (type) {
      case DisasterType.earthquake: return 'Earthquake';
      case DisasterType.flood: return 'Flood';
      case DisasterType.cyclone: return 'Cyclone/Hurricane';
      case DisasterType.fire: return 'Wildfire';
      case DisasterType.drought: return 'Drought';
      case DisasterType.landslide: return 'Landslide';
      case DisasterType.tsunami: return 'Tsunami';
      case DisasterType.volcanic: return 'Volcanic Eruption';
      case DisasterType.pandemic: return 'Pandemic/Health Crisis';
      case DisasterType.industrial: return 'Industrial Accident';
      case DisasterType.other: return 'Other Emergency';
    }
  }

  String _getPriorityDisplay(ResourcePriority priority) {
    switch (priority) {
      case ResourcePriority.low: return 'Low';
      case ResourcePriority.medium: return 'Medium';
      case ResourcePriority.high: return 'High';
      case ResourcePriority.critical: return 'Critical';
      case ResourcePriority.emergency: return 'Emergency';
    }
  }
}
