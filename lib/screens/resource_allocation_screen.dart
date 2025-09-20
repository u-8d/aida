import 'package:flutter/material.dart';
import '../services/resource_allocation_service.dart';
import 'dart:async';

class ResourceAllocationScreen extends StatefulWidget {
  const ResourceAllocationScreen({super.key});

  @override
  State<ResourceAllocationScreen> createState() => _ResourceAllocationScreenState();
}

class _ResourceAllocationScreenState extends State<ResourceAllocationScreen>
    with TickerProviderStateMixin {
  final ResourceAllocationService _allocationService = ResourceAllocationService();
  
  // Animation controllers
  late AnimationController _pulseController;
  
  // Data state
  Map<String, dynamic> _inventoryStatus = {};
  Map<String, dynamic> _analytics = {};
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _optimizations = [];
  bool _isLoading = true;
  
  // UI state
  int _selectedTabIndex = 0;
  final PageController _pageController = PageController();
  
  // Form controllers for new allocation
  final _quantityController = TextEditingController();
  final _locationController = TextEditingController();
  final _justificationController = TextEditingController();
  
  // Selected options
  ResourceType _selectedResourceType = ResourceType.food;
  AllocationPriority _selectedPriority = AllocationPriority.medium;
  
  // Form controllers for inventory update
  final _inventoryQuantityController = TextEditingController();
  final _inventoryReasonController = TextEditingController();
  ResourceType _selectedInventoryResource = ResourceType.food;
  bool _isAddingToInventory = true;
  
  // Real-time subscriptions
  StreamSubscription? _allocationSubscription;
  StreamSubscription? _inventorySubscription;
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
    
    _pulseController.repeat(reverse: true);
  }

  Future<void> _initializeService() async {
    await _allocationService.initialize();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);
      
      final inventory = await _allocationService.getInventoryStatus();
      final analytics = await _allocationService.getAllocationAnalytics();
      final recommendations = await _allocationService.getAllocationRecommendations();
      final optimizations = await _allocationService.getSupplyChainOptimizations();
      
      setState(() {
        _inventoryStatus = inventory;
        _analytics = analytics;
        _recommendations = recommendations;
        _optimizations = optimizations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading resource allocation data: $e');
      setState(() => _isLoading = false);
    }
  }

  void _setupRealTimeSubscriptions() {
    _allocationSubscription = _allocationService.allocationUpdates.listen((updateData) {
      _handleRealTimeAllocationUpdate(updateData);
    });
    
    _inventorySubscription = _allocationService.inventoryUpdates.listen((updateData) {
      _handleRealTimeInventoryUpdate(updateData);
    });
  }

  void _setupAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      _loadData();
    });
  }

  void _handleRealTimeAllocationUpdate(Map<String, dynamic> updateData) {
    // Handle real-time allocation updates
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Allocation ${updateData['data']['action']}: ${updateData['data']['resource_type']}'),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  void _handleRealTimeInventoryUpdate(Map<String, dynamic> updateData) {
    // Handle real-time inventory updates
    if (mounted) {
      final data = updateData['data'];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventory updated: ${data['resource_type']} (${data['change'] > 0 ? '+' : ''}${data['change']})'),
          backgroundColor: data['change'] > 0 ? Colors.green : Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resource Allocation'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: _executeAutomatedDistribution,
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
                      _buildAllocationTab(),
                      _buildInventoryTab(),
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
          Tab(icon: Icon(Icons.assignment), text: 'Allocations'),
          Tab(icon: Icon(Icons.inventory), text: 'Inventory'),
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
          _buildInventorySummaryCard(),
          const SizedBox(height: 16),
          _buildQuickStatsGrid(),
          const SizedBox(height: 16),
          _buildRecommendationsCard(),
          const SizedBox(height: 16),
          _buildOptimizationsCard(),
        ],
      ),
    );
  }

  Widget _buildInventorySummaryCard() {
    final summary = _inventoryStatus['summary'] ?? {};
    final totalItems = summary['total_items'] ?? 0;
    final lowStockItems = summary['low_stock_items'] ?? 0;
    final outOfStockItems = summary['out_of_stock_items'] ?? 0;
    final availabilityRate = summary['availability_rate'] ?? 0.0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory,
                  color: outOfStockItems > 0 ? Colors.red : 
                         lowStockItems > 0 ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Text(
                  'Inventory Summary',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: availabilityRate >= 80 ? Colors.green : 
                           availabilityRate >= 60 ? Colors.orange : Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${availabilityRate.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryMetric('Total Items', '$totalItems', Icons.category),
                ),
                Expanded(
                  child: _buildSummaryMetric('Low Stock', '$lowStockItems', Icons.warning, Colors.orange),
                ),
                Expanded(
                  child: _buildSummaryMetric('Out of Stock', '$outOfStockItems', Icons.error, Colors.red),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon, [Color? color]) {
    return Column(
      children: [
        Icon(icon, color: color ?? Colors.grey[600], size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
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
          'Total Allocations',
          '${totals['allocations'] ?? 0}',
          Icons.assignment,
          Colors.blue,
        ),
        _buildStatCard(
          'Approved',
          '${totals['approved'] ?? 0}',
          Icons.check_circle,
          Colors.green,
        ),
        _buildStatCard(
          'Approval Rate',
          '${(totals['approval_rate'] ?? 0).toStringAsFixed(1)}%',
          Icons.trending_up,
          Colors.orange,
        ),
        _buildStatCard(
          'Avg Delivery Time',
          '${(totals['avg_delivery_time_hours'] ?? 0).toStringAsFixed(1)}h',
          Icons.schedule,
          Colors.purple,
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

  Widget _buildRecommendationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.recommend, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Allocation Recommendations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => setState(() => _selectedTabIndex = 1),
                  child: const Text('View All'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_recommendations.isEmpty)
              const Text('No pending recommendations')
            else
              ..._recommendations.take(3).map((rec) => _buildRecommendationItem(rec)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationItem(Map<String, dynamic> recommendation) {
    final urgencyScore = recommendation['urgency_score'] as double? ?? 0.0;
    final resourceType = recommendation['resource_type'] ?? 'Unknown';
    final quantity = recommendation['quantity'] ?? 0;
    
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: urgencyScore >= 0.8 ? Colors.red : 
                        urgencyScore >= 0.6 ? Colors.orange : Colors.blue,
        child: Icon(
          _getResourceTypeIcon(resourceType),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text('$resourceType ($quantity units)'),
      subtitle: Text(recommendation['recommendation'] ?? 'No description'),
      trailing: Text('${(urgencyScore * 100).toStringAsFixed(0)}%'),
      onTap: () => _showRecommendationDetails(recommendation),
    );
  }

  Widget _buildOptimizationsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.tune, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Supply Chain Optimizations',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_optimizations.isEmpty)
              const Text('No optimizations available')
            else
              ..._optimizations.take(2).map((opt) => _buildOptimizationItem(opt)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildOptimizationItem(Map<String, dynamic> optimization) {
    final urgency = optimization['urgency'] ?? 'medium';
    final type = optimization['type'] ?? 'Unknown';
    
    return ListTile(
      leading: Icon(
        _getOptimizationIcon(type),
        color: urgency == 'critical' ? Colors.red : 
               urgency == 'high' ? Colors.orange : Colors.blue,
      ),
      title: Text(optimization['resource_type'] ?? 'Optimization'),
      subtitle: Text('${optimization['suggested_order_quantity'] ?? 0} units needed'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: urgency == 'critical' ? Colors.red : 
                 urgency == 'high' ? Colors.orange : Colors.blue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          urgency.toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildAllocationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCreateAllocationCard(),
          const SizedBox(height: 16),
          _buildRecommendationsList(),
        ],
      ),
    );
  }

  Widget _buildCreateAllocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create New Allocation',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            _buildResourceTypeSelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                labelText: 'Delivery Location',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            _buildPrioritySelector(),
            const SizedBox(height: 16),
            TextField(
              controller: _justificationController,
              decoration: const InputDecoration(
                labelText: 'Justification (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _createAllocation,
                icon: const Icon(Icons.add),
                label: const Text('Create Allocation'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Resource Type',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<ResourceType>(
          value: _selectedResourceType,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: ResourceType.values.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Row(
                children: [
                  Icon(_getResourceTypeIcon(type.name), size: 20),
                  const SizedBox(width: 8),
                  Text(_getResourceTypeDisplayName(type)),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedResourceType = value);
            }
          },
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
          children: AllocationPriority.values.map((priority) {
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

  Widget _buildRecommendationsList() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Allocation Recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_recommendations.isEmpty)
              const Center(child: Text('No recommendations available'))
            else
              ..._recommendations.map((rec) => _buildDetailedRecommendationItem(rec)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedRecommendationItem(Map<String, dynamic> recommendation) {
    final urgencyScore = recommendation['urgency_score'] as double? ?? 0.0;
    final availabilityScore = recommendation['availability_score'] as double? ?? 0.0;
    final efficiencyScore = recommendation['efficiency_score'] as double? ?? 0.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getResourceTypeIcon(recommendation['resource_type']),
                  color: urgencyScore >= 0.8 ? Colors.red : 
                         urgencyScore >= 0.6 ? Colors.orange : Colors.blue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${recommendation['resource_type']} - ${recommendation['quantity']} units',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => _approveRecommendation(recommendation),
                  child: const Text('Approve'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${recommendation['location']}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildScoreIndicator('Urgency', urgencyScore, Colors.red),
                const SizedBox(width: 16),
                _buildScoreIndicator('Availability', availabilityScore, Colors.green),
                const SizedBox(width: 16),
                _buildScoreIndicator('Efficiency', efficiencyScore, Colors.blue),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              recommendation['recommendation'] ?? 'No description',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreIndicator(String label, double score, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Colors.grey[300],
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: score,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: color,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildInventoryTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInventoryUpdateCard(),
          const SizedBox(height: 16),
          _buildInventoryList(),
        ],
      ),
    );
  }

  Widget _buildInventoryUpdateCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Inventory',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ResourceType>(
              value: _selectedInventoryResource,
              decoration: const InputDecoration(
                labelText: 'Resource Type',
                border: OutlineInputBorder(),
              ),
              items: ResourceType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getResourceTypeIcon(type.name), size: 20),
                      const SizedBox(width: 8),
                      Text(_getResourceTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedInventoryResource = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inventoryQuantityController,
                    decoration: InputDecoration(
                      labelText: 'Quantity',
                      border: const OutlineInputBorder(),
                      prefixText: _isAddingToInventory ? '+' : '-',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  children: [
                    const Text('Operation'),
                    ToggleButtons(
                      isSelected: [_isAddingToInventory, !_isAddingToInventory],
                      onPressed: (index) {
                        setState(() => _isAddingToInventory = index == 0);
                      },
                      children: const [
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Add'),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16),
                          child: Text('Remove'),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _inventoryReasonController,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateInventory,
                icon: Icon(_isAddingToInventory ? Icons.add : Icons.remove),
                label: Text('${_isAddingToInventory ? 'Add to' : 'Remove from'} Inventory'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: _isAddingToInventory ? Colors.green : Colors.orange,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    final inventory = _inventoryStatus['inventory'] as Map<String, dynamic>? ?? {};
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Inventory',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (inventory.isEmpty)
              const Center(child: Text('No inventory data available'))
            else
              ...inventory.entries.map((entry) => _buildInventoryItem(entry.key, entry.value)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItem(String resourceType, Map<String, dynamic> data) {
    final available = data['available'] as int? ?? 0;
    final totalQuantity = data['total_quantity'] as int? ?? 0;
    final reserved = data['reserved'] as int? ?? 0;
    final status = data['status'] as String? ?? 'unknown';
    
    Color statusColor = switch (status) {
      'out_of_stock' => Colors.red,
      'low_stock' => Colors.orange,
      'in_stock' => Colors.green,
      _ => Colors.grey,
    };
    
    return ListTile(
      leading: Icon(
        _getResourceTypeIcon(resourceType),
        color: statusColor,
      ),
      title: Text(_getResourceTypeDisplayName(
        ResourceType.values.firstWhere(
          (type) => type.name == resourceType,
          orElse: () => ResourceType.equipment,
        ),
      )),
      subtitle: Text('Available: $available | Reserved: $reserved | Total: $totalQuantity'),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: statusColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          status.replaceAll('_', ' ').toUpperCase(),
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final breakdown = _analytics['breakdown'] ?? {};
    final efficiency = _analytics['efficiency_metrics'] ?? {};
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAnalyticsCard(
            'Allocations by Status',
            breakdown['by_status'] ?? {},
            Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Allocations by Type',
            breakdown['by_type'] ?? {},
            Colors.green,
          ),
          const SizedBox(height: 16),
          _buildAnalyticsCard(
            'Allocations by Priority',
            breakdown['by_priority'] ?? {},
            Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildEfficiencyMetricsCard(efficiency),
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
                final total = data.values.fold<int>(0, (sum, value) => sum + (value as int));
                final percentage = total > 0 ? (entry.value as int) / total * 100 : 0.0;
                
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

  Widget _buildEfficiencyMetricsCard(Map<String, dynamic> efficiency) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Efficiency Metrics',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Resource Utilization',
                    efficiency['resource_utilization'] ?? 0.0,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Allocation Accuracy',
                    efficiency['allocation_accuracy'] ?? 0.0,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildEfficiencyMetric(
                    'Supply Chain Efficiency',
                    efficiency['supply_chain_efficiency'] ?? 0.0,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEfficiencyMetric(String label, double value, Color color) {
    return Column(
      children: [
        CircularProgressIndicator(
          value: value,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
        const SizedBox(height: 8),
        Text(
          '${(value * 100).toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: _executeAutomatedDistribution,
      icon: const Icon(Icons.auto_awesome),
      label: const Text('Auto Distribute'),
      backgroundColor: Colors.green,
    );
  }

  // Helper methods
  IconData _getResourceTypeIcon(String resourceType) {
    switch (resourceType.toLowerCase()) {
      case 'food':
        return Icons.restaurant;
      case 'water':
        return Icons.water_drop;
      case 'medical':
        return Icons.medical_services;
      case 'shelter':
        return Icons.home;
      case 'clothing':
        return Icons.checkroom;
      case 'blankets':
        return Icons.airline_seat_flat;
      case 'firstaid':
        return Icons.healing;
      case 'equipment':
        return Icons.build;
      case 'volunteers':
        return Icons.people;
      case 'transportation':
        return Icons.directions_car;
      default:
        return Icons.inventory;
    }
  }

  IconData _getOptimizationIcon(String type) {
    switch (type.toLowerCase()) {
      case 'restock':
        return Icons.add_shopping_cart;
      case 'distribution':
        return Icons.local_shipping;
      case 'efficiency':
        return Icons.speed;
      default:
        return Icons.tune;
    }
  }

  String _getResourceTypeDisplayName(ResourceType type) {
    switch (type) {
      case ResourceType.food:
        return 'Food';
      case ResourceType.water:
        return 'Water';
      case ResourceType.medical:
        return 'Medical Supplies';
      case ResourceType.shelter:
        return 'Shelter';
      case ResourceType.clothing:
        return 'Clothing';
      case ResourceType.blankets:
        return 'Blankets';
      case ResourceType.firstAid:
        return 'First Aid';
      case ResourceType.equipment:
        return 'Equipment';
      case ResourceType.volunteers:
        return 'Volunteers';
      case ResourceType.transportation:
        return 'Transportation';
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
      case 'routine':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  // Action methods
  Future<void> _createAllocation() async {
    if (_quantityController.text.trim().isEmpty || _locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity and location'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final quantity = int.tryParse(_quantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final result = await _allocationService.createAllocationRequest(
      resourceType: _selectedResourceType,
      quantity: quantity,
      requestedBy: 'Admin User', // Would get from auth
      deliveryLocation: _locationController.text.trim(),
      priority: _selectedPriority,
      justification: _justificationController.text.trim().isEmpty ? null : _justificationController.text.trim(),
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Allocation request created (ID: ${result['allocation_id']})'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _quantityController.clear();
      _locationController.clear();
      _justificationController.clear();
      
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to create allocation: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateInventory() async {
    if (_inventoryQuantityController.text.trim().isEmpty || _inventoryReasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter quantity and reason'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final quantity = int.tryParse(_inventoryQuantityController.text.trim());
    if (quantity == null || quantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid quantity'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    final quantityChange = _isAddingToInventory ? quantity : -quantity;
    
    final result = await _allocationService.updateInventory(
      resourceType: _selectedInventoryResource,
      quantityChange: quantityChange,
      reason: _inventoryReasonController.text.trim(),
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Inventory updated: ${result['change']} units'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Clear form
      _inventoryQuantityController.clear();
      _inventoryReasonController.clear();
      
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update inventory: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _executeAutomatedDistribution() async {
    final result = await _allocationService.executeAutomatedDistribution(
      minimumPriority: AllocationPriority.medium,
      maxAllocations: 10,
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Automated distribution completed: ${result['successful']} successful, ${result['failed']} failed'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Automated distribution failed: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _approveRecommendation(Map<String, dynamic> recommendation) async {
    final result = await _allocationService.approveAllocation(
      recommendation['allocation_id'],
      'Admin User', // Would get from auth
      notes: 'Approved from recommendations',
    );
    
    if (result['success']) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Allocation approved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _loadData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve allocation: ${result['error']}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showRecommendationDetails(Map<String, dynamic> recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recommendation Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Resource: ${recommendation['resource_type']}'),
              const SizedBox(height: 8),
              Text('Quantity: ${recommendation['quantity']} units'),
              const SizedBox(height: 8),
              Text('Location: ${recommendation['location']}'),
              const SizedBox(height: 8),
              Text('Priority: ${recommendation['priority']}'),
              const SizedBox(height: 8),
              Text('Urgency Score: ${(recommendation['urgency_score'] * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Availability Score: ${(recommendation['availability_score'] * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Efficiency Score: ${(recommendation['efficiency_score'] * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              Text('Suggested Method: ${recommendation['suggested_method']}'),
              const SizedBox(height: 8),
              Text('Estimated Delivery: ${recommendation['estimated_delivery']}'),
              const SizedBox(height: 8),
              Text('Recommendation: ${recommendation['recommendation']}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _approveRecommendation(recommendation);
            },
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    _quantityController.dispose();
    _locationController.dispose();
    _justificationController.dispose();
    _inventoryQuantityController.dispose();
    _inventoryReasonController.dispose();
    _allocationSubscription?.cancel();
    _inventorySubscription?.cancel();
    _refreshTimer?.cancel();
    _allocationService.dispose();
    super.dispose();
  }
}
