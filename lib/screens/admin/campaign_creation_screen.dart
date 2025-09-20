import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/disaster_campaign.dart';
import '../../services/campaign_management_service.dart';
import '../../providers/admin_app_state.dart';
import '../../config/app_theme.dart';

class CampaignCreationScreen extends StatefulWidget {
  final DisasterCampaign? existingCampaign;
  const CampaignCreationScreen({super.key, this.existingCampaign});

  @override
  State<CampaignCreationScreen> createState() => _CampaignCreationScreenState();
}

class _CampaignCreationScreenState extends State<CampaignCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _campaignService = CampaignManagementService();
  
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _targetBeneficiariesController = TextEditingController();
  final _estimatedDaysController = TextEditingController();
  
  // Form state
  DisasterType _selectedDisasterType = DisasterType.earthquake;
  DisasterSeverity _selectedSeverity = DisasterSeverity.moderate;
  CampaignStatus _selectedStatus = CampaignStatus.planning;
  ResourcePriority _selectedPriority = ResourcePriority.medium;
  
  bool _isEmergencyMode = false;
  bool _autoMatchEnabled = true;
  double _autoMatchThreshold = 0.8;
  bool _isLoading = false;
  
  List<String> _affectedAreas = [];
  List<String> _distributionCenters = [];
  List<String> _priorityTags = [];
  Map<String, int> _resourceTargets = {};
  
  final _affectedAreaController = TextEditingController();
  final _distributionCenterController = TextEditingController();
  final _priorityTagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.existingCampaign != null) {
      _populateExistingCampaign();
    }
  }

  void _populateExistingCampaign() {
    final campaign = widget.existingCampaign!;
    _titleController.text = campaign.title;
    _descriptionController.text = campaign.description;
    _locationController.text = campaign.location;
    _targetBeneficiariesController.text = campaign.targetBeneficiaries.toString();
    
    if (campaign.estimatedCompletionDate != null) {
      final days = campaign.estimatedCompletionDate!.difference(DateTime.now()).inDays;
      _estimatedDaysController.text = days > 0 ? days.toString() : '0';
    }
    
    _selectedDisasterType = campaign.disasterType;
    _selectedSeverity = campaign.severity;
    _selectedStatus = campaign.status;
    _selectedPriority = campaign.overallPriority;
    _isEmergencyMode = campaign.isEmergencyMode;
    _autoMatchEnabled = campaign.autoMatchEnabled;
    _autoMatchThreshold = campaign.autoMatchThreshold;
    
    _affectedAreas = List.from(campaign.affectedAreas);
    _distributionCenters = List.from(campaign.distributionCenters);
    _priorityTags = List.from(campaign.priorityTags);
    _resourceTargets = Map.from(campaign.resourceTargets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingCampaign != null ? 'Edit Campaign' : 'Create Campaign'),
        backgroundColor: AppTheme.primaryBlue,
        foregroundColor: Colors.white,
        actions: [
          if (widget.existingCampaign != null)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _deleteCampaign,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBasicInformationSection(),
                    const SizedBox(height: 24),
                    _buildDisasterDetailsSection(),
                    const SizedBox(height: 24),
                    _buildLocationAndAreasSection(),
                    const SizedBox(height: 24),
                    _buildResourceTargetsSection(),
                    const SizedBox(height: 24),
                    _buildAutomationSettingsSection(),
                    const SizedBox(height: 32),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildBasicInformationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Campaign Title *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a campaign title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _targetBeneficiariesController,
              decoration: const InputDecoration(
                labelText: 'Target Beneficiaries *',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target beneficiaries';
                }
                if (int.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _estimatedDaysController,
              decoration: const InputDecoration(
                labelText: 'Estimated Duration (days)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisasterDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Disaster Details', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            DropdownButtonFormField<DisasterType>(
              value: _selectedDisasterType,
              decoration: const InputDecoration(
                labelText: 'Disaster Type',
                border: OutlineInputBorder(),
              ),
              items: DisasterType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(_getDisasterTypeDisplay(type)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedDisasterType = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DisasterSeverity>(
              value: _selectedSeverity,
              decoration: const InputDecoration(
                labelText: 'Severity Level',
                border: OutlineInputBorder(),
              ),
              items: DisasterSeverity.values.map((severity) {
                return DropdownMenuItem(
                  value: severity,
                  child: Text(_getSeverityDisplay(severity)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedSeverity = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CampaignStatus>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                labelText: 'Initial Status',
                border: OutlineInputBorder(),
              ),
              items: CampaignStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusDisplay(status)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedStatus = value!),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ResourcePriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority Level',
                border: OutlineInputBorder(),
              ),
              items: ResourcePriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityDisplay(priority)),
                );
              }).toList(),
              onChanged: (value) => setState(() => _selectedPriority = value!),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Emergency Mode'),
              subtitle: const Text('Activate for immediate attention and priority matching'),
              value: _isEmergencyMode,
              onChanged: (value) => setState(() => _isEmergencyMode = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationAndAreasSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location & Areas', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Primary Location *',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter primary location';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildStringListEditor(
              title: 'Affected Areas',
              list: _affectedAreas,
              controller: _affectedAreaController,
              hintText: 'Add affected area...',
            ),
            const SizedBox(height: 16),
            _buildStringListEditor(
              title: 'Distribution Centers',
              list: _distributionCenters,
              controller: _distributionCenterController,
              hintText: 'Add distribution center...',
            ),
            const SizedBox(height: 16),
            _buildStringListEditor(
              title: 'Priority Tags',
              list: _priorityTags,
              controller: _priorityTagController,
              hintText: 'Add priority tag...',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTargetsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Resource Targets', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            if (_resourceTargets.isNotEmpty) ...[
              for (final entry in _resourceTargets.entries)
                ListTile(
                  title: Text(entry.key),
                  subtitle: Text('Target: ${entry.value}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => setState(() => _resourceTargets.remove(entry.key)),
                  ),
                ),
              const SizedBox(height: 16),
            ],
            ElevatedButton.icon(
              onPressed: _addResourceTarget,
              icon: const Icon(Icons.add),
              label: const Text('Add Resource Target'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutomationSettingsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Automation Settings', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Auto-Match Donations'),
              subtitle: const Text('Automatically match incoming donations to this campaign'),
              value: _autoMatchEnabled,
              onChanged: (value) => setState(() => _autoMatchEnabled = value),
            ),
            if (_autoMatchEnabled) ...[
              const SizedBox(height: 16),
              Text('Match Threshold: ${(_autoMatchThreshold * 100).round()}%'),
              Slider(
                value: _autoMatchThreshold,
                min: 0.5,
                max: 1.0,
                divisions: 10,
                label: '${(_autoMatchThreshold * 100).round()}%',
                onChanged: (value) => setState(() => _autoMatchThreshold = value),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStringListEditor({
    required String title,
    required List<String> list,
    required TextEditingController controller,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (list.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            children: list.map((item) => Chip(
              label: Text(item),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted: () => setState(() => list.remove(item)),
            )).toList(),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: hintText,
                  border: const OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addToStringList(list, controller),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => _addToStringList(list, controller),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveCampaign,
            child: Text(widget.existingCampaign != null ? 'Update Campaign' : 'Create Campaign'),
          ),
        ),
      ],
    );
  }

  void _addToStringList(List<String> list, TextEditingController controller) {
    if (controller.text.isNotEmpty && !list.contains(controller.text)) {
      setState(() {
        list.add(controller.text);
        controller.clear();
      });
    }
  }

  void _addResourceTarget() {
    showDialog(
      context: context,
      builder: (context) {
        final resourceNameController = TextEditingController();
        final resourceTargetController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Add Resource Target'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: resourceNameController,
                decoration: const InputDecoration(
                  labelText: 'Resource Type',
                  hintText: 'e.g., Food, Water, Medicine',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: resourceTargetController,
                decoration: const InputDecoration(
                  labelText: 'Target Quantity',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (resourceNameController.text.isNotEmpty && 
                    resourceTargetController.text.isNotEmpty) {
                  final target = int.tryParse(resourceTargetController.text);
                  if (target != null) {
                    setState(() {
                      _resourceTargets[resourceNameController.text] = target;
                    });
                    Navigator.pop(context);
                  }
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final adminState = Provider.of<AdminAppState>(context, listen: false);
      final currentAdmin = adminState.currentAdmin!;

      final estimatedDays = int.tryParse(_estimatedDaysController.text);
      final estimatedCompletionDate = estimatedDays != null
          ? DateTime.now().add(Duration(days: estimatedDays))
          : null;

      final campaignData = DisasterCampaign(
        id: widget.existingCampaign?.id ?? '',
        title: _titleController.text,
        description: _descriptionController.text,
        disasterType: _selectedDisasterType,
        severity: _selectedSeverity,
        status: _selectedStatus,
        location: _locationController.text,
        affectedAreas: _affectedAreas,
        startDate: widget.existingCampaign?.startDate ?? DateTime.now(),
        estimatedCompletionDate: estimatedCompletionDate,
        targetBeneficiaries: int.parse(_targetBeneficiariesController.text),
        resourceTargets: _resourceTargets,
        coordinatorId: currentAdmin.id,
        coordinatorName: currentAdmin.name,
        distributionCenters: _distributionCenters,
        overallPriority: _selectedPriority,
        isEmergencyMode: _isEmergencyMode,
        autoMatchEnabled: _autoMatchEnabled,
        autoMatchThreshold: _autoMatchThreshold,
        priorityTags: _priorityTags,
      );

      if (widget.existingCampaign != null) {
        await _campaignService.updateCampaign(
          widget.existingCampaign!.id,
          campaignData.toJson(),
        );
      } else {
        await _campaignService.createCampaign(campaignData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingCampaign != null 
                ? 'Campaign updated successfully!' 
                : 'Campaign created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteCampaign() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Campaign'),
        content: const Text('Are you sure you want to delete this campaign? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && widget.existingCampaign != null) {
      setState(() => _isLoading = true);
      
      try {
        await _campaignService.deleteCampaign(widget.existingCampaign!.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Campaign deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting campaign: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
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

  String _getSeverityDisplay(DisasterSeverity severity) {
    switch (severity) {
      case DisasterSeverity.minor: return 'Minor';
      case DisasterSeverity.moderate: return 'Moderate';
      case DisasterSeverity.major: return 'Major';
      case DisasterSeverity.severe: return 'Severe';
      case DisasterSeverity.catastrophic: return 'Catastrophic';
    }
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

  String _getPriorityDisplay(ResourcePriority priority) {
    switch (priority) {
      case ResourcePriority.low: return 'Low';
      case ResourcePriority.medium: return 'Medium';
      case ResourcePriority.high: return 'High';
      case ResourcePriority.critical: return 'Critical';
      case ResourcePriority.emergency: return 'Emergency';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _targetBeneficiariesController.dispose();
    _estimatedDaysController.dispose();
    _affectedAreaController.dispose();
    _distributionCenterController.dispose();
    _priorityTagController.dispose();
    super.dispose();
  }
}
