import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';

enum ResourceType {
  food,
  water,
  medical,
  shelter,
  clothing,
  blankets,
  firstAid,
  equipment,
  volunteers,
  transportation,
}

enum AllocationStatus {
  pending,
  approved,
  inTransit,
  delivered,
  cancelled,
  failed,
}

enum AllocationPriority {
  critical,
  high,
  medium,
  low,
  routine,
}

enum DistributionMethod {
  direct,
  pickup,
  delivery,
  mobile,
  airdrop,
  emergency,
}

class ResourceAllocationService {
  final _supabase = Supabase.instance.client;
  
  // Real-time allocation streams
  StreamController<Map<String, dynamic>>? _allocationStreamController;
  StreamController<Map<String, dynamic>>? _inventoryStreamController;
  
  // Allocation state
  Map<String, dynamic> _allocationRules = {};
  
  // Auto-allocation settings
  bool _autoAllocationEnabled = true;
  Timer? _allocationTimer;

  /// Initialize resource allocation service
  Future<void> initialize() async {
    try {
      // Load current inventory
      await _loadInventory();
      
      // Load pending allocations
      await _loadPendingAllocations();
      
      // Load allocation rules
      await _loadAllocationRules();
      
      // Setup real-time subscriptions
      _setupRealtimeSubscriptions();
      
      // Start auto-allocation timer
      _startAutoAllocation();
      
      print('Resource allocation service initialized');
    } catch (e) {
      print('Error initializing resource allocation service: $e');
    }
  }

  /// Create new resource allocation request
  Future<Map<String, dynamic>> createAllocationRequest({
    required ResourceType resourceType,
    required int quantity,
    required String requestedBy,
    required String deliveryLocation,
    required AllocationPriority priority,
    String? justification,
    DateTime? requestedDelivery,
    Map<String, dynamic>? specialRequirements,
  }) async {
    try {
      final allocationId = DateTime.now().millisecondsSinceEpoch.toString();
      final now = DateTime.now();
      
      // Create allocation request
      final allocationData = {
        'id': allocationId,
        'resource_type': resourceType.name,
        'quantity': quantity,
        'requested_by': requestedBy,
        'delivery_location': deliveryLocation,
        'priority': priority.name,
        'justification': justification,
        'requested_delivery': requestedDelivery?.toIso8601String(),
        'special_requirements': specialRequirements,
        'status': AllocationStatus.pending.name,
        'created_at': now.toIso8601String(),
        'admin_id': _supabase.auth.currentUser?.id,
      };
      
      await _supabase.from('resource_allocations').insert(allocationData);
      
      // Check inventory availability
      final availability = await _checkResourceAvailability(resourceType, quantity);
      
      // Auto-approve if possible and rules allow
      if (availability['available'] && _shouldAutoApprove(priority, quantity, resourceType)) {
        await _approveAllocation(allocationId, 'Auto-approved based on availability and rules');
      }
      
      // Log the request
      await _logAllocationAction('allocation_requested', {
        'allocation_id': allocationId,
        'resource_type': resourceType.name,
        'quantity': quantity,
        'priority': priority.name,
        'auto_approved': availability['available'] && _shouldAutoApprove(priority, quantity, resourceType),
      });
      
      // Broadcast real-time update
      _broadcastAllocationUpdate({
        'allocation_id': allocationId,
        'action': 'created',
        'resource_type': resourceType.name,
        'quantity': quantity,
        'priority': priority.name,
      });
      
      return {
        'success': true,
        'allocation_id': allocationId,
        'status': allocationData['status'],
        'availability': availability,
      };
    } catch (e) {
      print('Error creating allocation request: $e');
      return {
        'success': false,
        'error': 'Failed to create allocation request: $e',
      };
    }
  }

  /// Approve resource allocation
  Future<Map<String, dynamic>> approveAllocation(
    String allocationId,
    String approvedBy, {
    String? notes,
    DistributionMethod? method,
    DateTime? scheduledDelivery,
  }) async {
    try {
      return await _approveAllocation(
        allocationId,
        'Approved by $approvedBy',
        notes: notes,
        method: method,
        scheduledDelivery: scheduledDelivery,
      );
    } catch (e) {
      print('Error approving allocation: $e');
      return {
        'success': false,
        'error': 'Failed to approve allocation: $e',
      };
    }
  }

  /// Get resource allocation recommendations based on current situation
  Future<List<Map<String, dynamic>>> getAllocationRecommendations({
    String? location,
    ResourceType? resourceType,
    AllocationPriority? minimumPriority,
  }) async {
    try {
      final recommendations = <Map<String, dynamic>>[];
      
      // Get pending requests
      var query = _supabase
          .from('resource_allocations')
          .select('*')
          .eq('status', AllocationStatus.pending.name);
      
      if (location != null) {
        query = query.like('delivery_location', '%$location%');
      }
      
      if (resourceType != null) {
        query = query.eq('resource_type', resourceType.name);
      }
      
      final pendingRequests = await query.order('created_at');
      
      // Analyze each request
      for (final request in pendingRequests) {
        final analysis = await _analyzeAllocationRequest(request);
        if (analysis['recommended']) {
          recommendations.add({
            'allocation_id': request['id'],
            'resource_type': request['resource_type'],
            'quantity': request['quantity'],
            'priority': request['priority'],
            'location': request['delivery_location'],
            'urgency_score': analysis['urgency_score'],
            'availability_score': analysis['availability_score'],
            'efficiency_score': analysis['efficiency_score'],
            'recommendation': analysis['recommendation'],
            'suggested_method': analysis['suggested_method'],
            'estimated_delivery': analysis['estimated_delivery'],
          });
        }
      }
      
      // Sort by combined recommendation score
      recommendations.sort((a, b) {
        final scoreA = (a['urgency_score'] * 0.4) + 
                      (a['availability_score'] * 0.3) + 
                      (a['efficiency_score'] * 0.3);
        final scoreB = (b['urgency_score'] * 0.4) + 
                      (b['availability_score'] * 0.3) + 
                      (b['efficiency_score'] * 0.3);
        return scoreB.compareTo(scoreA);
      });
      
      return recommendations;
    } catch (e) {
      print('Error getting allocation recommendations: $e');
      return [];
    }
  }

  /// Get current inventory status
  Future<Map<String, dynamic>> getInventoryStatus() async {
    try {
      final inventory = await _supabase
          .from('resource_inventory')
          .select('*')
          .order('resource_type');
      
      final inventoryMap = <String, Map<String, dynamic>>{};
      var totalValue = 0.0;
      var lowStockItems = 0;
      var outOfStockItems = 0;
      
      for (final item in inventory) {
        final resourceType = item['resource_type'];
        final quantity = item['quantity'] as int? ?? 0;
        final reserved = item['reserved'] as int? ?? 0;
        final available = quantity - reserved;
        final minThreshold = item['min_threshold'] as int? ?? 0;
        final value = (item['unit_value'] as double? ?? 0.0) * quantity;
        
        totalValue += value;
        
        if (available <= 0) {
          outOfStockItems++;
        } else if (available <= minThreshold) {
          lowStockItems++;
        }
        
        inventoryMap[resourceType] = {
          'total_quantity': quantity,
          'reserved': reserved,
          'available': available,
          'min_threshold': minThreshold,
          'unit_value': item['unit_value'],
          'total_value': value,
          'last_updated': item['updated_at'],
          'status': available <= 0 ? 'out_of_stock' : 
                   available <= minThreshold ? 'low_stock' : 'in_stock',
        };
      }
      
      return {
        'inventory': inventoryMap,
        'summary': {
          'total_items': inventory.length,
          'total_value': totalValue,
          'low_stock_items': lowStockItems,
          'out_of_stock_items': outOfStockItems,
          'availability_rate': inventory.isEmpty ? 0.0 : 
                              ((inventory.length - outOfStockItems) / inventory.length) * 100,
        },
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('Error getting inventory status: $e');
      return {'error': 'Failed to get inventory status'};
    }
  }

  /// Get allocation analytics and metrics
  Future<Map<String, dynamic>> getAllocationAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final start = startDate ?? DateTime.now().subtract(const Duration(days: 7));
      final end = endDate ?? DateTime.now();
      
      // Get allocations in date range
      final allocations = await _supabase
          .from('resource_allocations')
          .select('*')
          .gte('created_at', start.toIso8601String())
          .lte('created_at', end.toIso8601String());
      
      // Calculate metrics
      final totalAllocations = allocations.length;
      final allocationsByStatus = <String, int>{};
      final allocationsByType = <String, int>{};
      final allocationsByPriority = <String, int>{};
      final deliveryTimeMetrics = <double>[];
      
      var totalQuantity = 0;
      var approvedAllocations = 0;
      var deliveredAllocations = 0;
      
      for (final allocation in allocations) {
        final status = allocation['status'] as String? ?? 'unknown';
        final type = allocation['resource_type'] as String? ?? 'unknown';
        final priority = allocation['priority'] as String? ?? 'unknown';
        final quantity = allocation['quantity'] as int? ?? 0;
        
        allocationsByStatus[status] = (allocationsByStatus[status] ?? 0) + 1;
        allocationsByType[type] = (allocationsByType[type] ?? 0) + 1;
        allocationsByPriority[priority] = (allocationsByPriority[priority] ?? 0) + 1;
        
        totalQuantity += quantity;
        
        if (status == AllocationStatus.approved.name || 
            status == AllocationStatus.inTransit.name ||
            status == AllocationStatus.delivered.name) {
          approvedAllocations++;
        }
        
        if (status == AllocationStatus.delivered.name) {
          deliveredAllocations++;
          
          // Calculate delivery time
          final createdAt = DateTime.tryParse(allocation['created_at'] ?? '');
          final deliveredAt = DateTime.tryParse(allocation['delivered_at'] ?? '');
          if (createdAt != null && deliveredAt != null) {
            final deliveryTime = deliveredAt.difference(createdAt).inHours.toDouble();
            deliveryTimeMetrics.add(deliveryTime);
          }
        }
      }
      
      // Calculate efficiency metrics
      final approvalRate = totalAllocations > 0 ? (approvedAllocations / totalAllocations) * 100 : 0.0;
      final deliveryRate = approvedAllocations > 0 ? (deliveredAllocations / approvedAllocations) * 100 : 0.0;
      final avgDeliveryTime = deliveryTimeMetrics.isNotEmpty ? 
                             deliveryTimeMetrics.reduce((a, b) => a + b) / deliveryTimeMetrics.length : 0.0;
      
      // Get current inventory levels
      final inventory = await getInventoryStatus();
      
      return {
        'period': {
          'start': start.toIso8601String(),
          'end': end.toIso8601String(),
        },
        'totals': {
          'allocations': totalAllocations,
          'quantity': totalQuantity,
          'approved': approvedAllocations,
          'delivered': deliveredAllocations,
          'approval_rate': approvalRate,
          'delivery_rate': deliveryRate,
          'avg_delivery_time_hours': avgDeliveryTime,
        },
        'breakdown': {
          'by_status': allocationsByStatus,
          'by_type': allocationsByType,
          'by_priority': allocationsByPriority,
        },
        'inventory_summary': inventory['summary'],
        'efficiency_metrics': {
          'resource_utilization': _calculateResourceUtilization(),
          'allocation_accuracy': _calculateAllocationAccuracy(),
          'supply_chain_efficiency': _calculateSupplyChainEfficiency(),
        },
      };
    } catch (e) {
      print('Error getting allocation analytics: $e');
      return {'error': 'Failed to get allocation analytics'};
    }
  }

  /// Execute automated resource distribution
  Future<Map<String, dynamic>> executeAutomatedDistribution({
    AllocationPriority? minimumPriority,
    List<ResourceType>? resourceTypes,
    int? maxAllocations,
  }) async {
    try {
      final recommendations = await getAllocationRecommendations(
        minimumPriority: minimumPriority,
      );
      
      var processedCount = 0;
      var successCount = 0;
      var failureCount = 0;
      
      final limit = maxAllocations ?? recommendations.length;
      
      for (var i = 0; i < recommendations.length && i < limit; i++) {
        final recommendation = recommendations[i];
        final allocationId = recommendation['allocation_id'];
        
        try {
          final result = await _approveAllocation(
            allocationId,
            'Auto-approved by automated distribution',
            method: _parseDistributionMethod(recommendation['suggested_method']),
          );
          
          if (result['success']) {
            successCount++;
          } else {
            failureCount++;
          }
          
          processedCount++;
        } catch (e) {
          failureCount++;
          processedCount++;
        }
      }
      
      // Log automated distribution execution
      await _logAllocationAction('automated_distribution_executed', {
        'processed': processedCount,
        'successful': successCount,
        'failed': failureCount,
        'minimum_priority': minimumPriority?.name,
        'resource_types': resourceTypes?.map((t) => t.name).toList(),
      });
      
      return {
        'success': true,
        'processed': processedCount,
        'successful': successCount,
        'failed': failureCount,
        'recommendations_available': recommendations.length,
      };
    } catch (e) {
      print('Error executing automated distribution: $e');
      return {
        'success': false,
        'error': 'Failed to execute automated distribution: $e',
      };
    }
  }

  /// Update resource inventory
  Future<Map<String, dynamic>> updateInventory({
    required ResourceType resourceType,
    required int quantityChange,
    required String reason,
    String? batchNumber,
    DateTime? expirationDate,
  }) async {
    try {
      // Get current inventory
      final currentItem = await _supabase
          .from('resource_inventory')
          .select('*')
          .eq('resource_type', resourceType.name)
          .maybeSingle();
      
      final currentQuantity = currentItem?['quantity'] as int? ?? 0;
      final newQuantity = currentQuantity + quantityChange;
      
      if (newQuantity < 0) {
        return {
          'success': false,
          'error': 'Insufficient inventory. Current: $currentQuantity, Requested: ${quantityChange.abs()}',
        };
      }
      
      // Update inventory
      final updateData = {
        'resource_type': resourceType.name,
        'quantity': newQuantity,
        'updated_at': DateTime.now().toIso8601String(),
        'last_change_reason': reason,
        'last_change_amount': quantityChange,
      };
      
      if (currentItem != null) {
        await _supabase
            .from('resource_inventory')
            .update(updateData)
            .eq('resource_type', resourceType.name);
      } else {
        await _supabase
            .from('resource_inventory')
            .insert({
              ...updateData,
              'min_threshold': _getDefaultMinThreshold(resourceType),
              'unit_value': _getDefaultUnitValue(resourceType),
            });
      }
      
      // Log inventory change
      await _supabase.from('inventory_log').insert({
        'resource_type': resourceType.name,
        'change_amount': quantityChange,
        'previous_quantity': currentQuantity,
        'new_quantity': newQuantity,
        'reason': reason,
        'batch_number': batchNumber,
        'expiration_date': expirationDate?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'admin_id': _supabase.auth.currentUser?.id,
      });
      
      // Check if low stock alert needed
      final minThreshold = currentItem?['min_threshold'] as int? ?? 0;
      if (newQuantity <= minThreshold) {
        await _sendLowStockAlert(resourceType, newQuantity, minThreshold);
      }
      
      // Broadcast inventory update
      _broadcastInventoryUpdate({
        'resource_type': resourceType.name,
        'quantity': newQuantity,
        'change': quantityChange,
        'reason': reason,
      });
      
      return {
        'success': true,
        'previous_quantity': currentQuantity,
        'new_quantity': newQuantity,
        'change': quantityChange,
      };
    } catch (e) {
      print('Error updating inventory: $e');
      return {
        'success': false,
        'error': 'Failed to update inventory: $e',
      };
    }
  }

  /// Get supply chain optimization suggestions
  Future<List<Map<String, dynamic>>> getSupplyChainOptimizations() async {
    try {
      final optimizations = <Map<String, dynamic>>[];
      
      // Analyze inventory levels
      final inventory = await getInventoryStatus();
      final inventoryMap = inventory['inventory'] as Map<String, dynamic>? ?? {};
      
      for (final entry in inventoryMap.entries) {
        final resourceType = entry.key;
        final data = entry.value as Map<String, dynamic>;
        final available = data['available'] as int? ?? 0;
        final minThreshold = data['min_threshold'] as int? ?? 0;
        
        if (available <= minThreshold) {
          final urgency = available <= 0 ? 'critical' : 'high';
          final suggestedOrder = _calculateOptimalOrderQuantity(resourceType, available, minThreshold);
          
          optimizations.add({
            'type': 'restock',
            'resource_type': resourceType,
            'current_quantity': available,
            'min_threshold': minThreshold,
            'suggested_order_quantity': suggestedOrder,
            'urgency': urgency,
            'estimated_cost': _estimateOrderCost(resourceType, suggestedOrder),
            'delivery_time_days': _getExpectedDeliveryTime(resourceType),
          });
        }
      }
      
      // Analyze allocation patterns
      final allocationPatterns = await _analyzeAllocationPatterns();
      optimizations.addAll(allocationPatterns);
      
      // Analyze distribution efficiency
      final distributionOptimizations = await _analyzeDistributionEfficiency();
      optimizations.addAll(distributionOptimizations);
      
      // Sort by urgency and impact
      optimizations.sort((a, b) {
        final urgencyA = a['urgency'] == 'critical' ? 3 : a['urgency'] == 'high' ? 2 : 1;
        final urgencyB = b['urgency'] == 'critical' ? 3 : b['urgency'] == 'high' ? 2 : 1;
        return urgencyB.compareTo(urgencyA);
      });
      
      return optimizations;
    } catch (e) {
      print('Error getting supply chain optimizations: $e');
      return [];
    }
  }

  // Stream getters
  Stream<Map<String, dynamic>> get allocationUpdates {
    _allocationStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _allocationStreamController!.stream;
  }

  Stream<Map<String, dynamic>> get inventoryUpdates {
    _inventoryStreamController ??= StreamController<Map<String, dynamic>>.broadcast();
    return _inventoryStreamController!.stream;
  }

  // Private helper methods
  Future<void> _loadInventory() async {
    try {
      // Load current inventory for caching if needed
      await getInventoryStatus();
    } catch (e) {
      print('Error loading inventory: $e');
    }
  }

  Future<void> _loadPendingAllocations() async {
    try {
      // Load pending allocations for caching if needed
      await _supabase
          .from('resource_allocations')
          .select('*')
          .eq('status', AllocationStatus.pending.name);
    } catch (e) {
      print('Error loading pending allocations: $e');
    }
  }

  Future<void> _loadAllocationRules() async {
    try {
      final rules = await _supabase
          .from('allocation_rules')
          .select('*');
      
      _allocationRules = {};
      for (final rule in rules) {
        _allocationRules[rule['rule_type']] = rule;
      }
    } catch (e) {
      print('Error loading allocation rules: $e');
    }
  }

  void _setupRealtimeSubscriptions() {
    // Setup real-time subscriptions for allocations and inventory
    // This would integrate with Supabase real-time subscriptions
  }

  void _startAutoAllocation() {
    _allocationTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (_autoAllocationEnabled) {
        _processAutoAllocations();
      }
    });
  }

  Future<void> _processAutoAllocations() async {
    try {
      final recommendations = await getAllocationRecommendations();
      
      for (final recommendation in recommendations) {
        final urgencyScore = recommendation['urgency_score'] as double? ?? 0.0;
        
        // Auto-approve high urgency allocations
        if (urgencyScore >= 0.8) {
          await _approveAllocation(
            recommendation['allocation_id'],
            'Auto-approved by system due to high urgency',
          );
        }
      }
    } catch (e) {
      print('Error processing auto allocations: $e');
    }
  }

  Future<Map<String, dynamic>> _checkResourceAvailability(ResourceType resourceType, int quantity) async {
    try {
      final item = await _supabase
          .from('resource_inventory')
          .select('*')
          .eq('resource_type', resourceType.name)
          .maybeSingle();
      
      if (item == null) {
        return {
          'available': false,
          'reason': 'Resource not in inventory',
          'current_stock': 0,
          'requested': quantity,
        };
      }
      
      final totalQuantity = item['quantity'] as int? ?? 0;
      final reserved = item['reserved'] as int? ?? 0;
      final available = totalQuantity - reserved;
      
      return {
        'available': available >= quantity,
        'current_stock': totalQuantity,
        'reserved': reserved,
        'available_stock': available,
        'requested': quantity,
        'shortage': available < quantity ? quantity - available : 0,
      };
    } catch (e) {
      print('Error checking resource availability: $e');
      return {
        'available': false,
        'error': e.toString(),
      };
    }
  }

  bool _shouldAutoApprove(AllocationPriority priority, int quantity, ResourceType resourceType) {
    final rules = _allocationRules['auto_approval'] as Map<String, dynamic>?;
    if (rules == null) return false;
    
    final maxQuantity = rules['max_quantity_per_type']?[resourceType.name] as int? ?? 0;
    final allowedPriorities = rules['allowed_priorities'] as List<dynamic>? ?? [];
    
    return quantity <= maxQuantity && allowedPriorities.contains(priority.name);
  }

  Future<Map<String, dynamic>> _approveAllocation(
    String allocationId,
    String reason, {
    String? notes,
    DistributionMethod? method,
    DateTime? scheduledDelivery,
  }) async {
    try {
      // Get allocation details
      final allocation = await _supabase
          .from('resource_allocations')
          .select('*')
          .eq('id', allocationId)
          .single();
      
      final resourceType = ResourceType.values.firstWhere(
        (type) => type.name == allocation['resource_type'],
        orElse: () => ResourceType.equipment,
      );
      
      final quantity = allocation['quantity'] as int;
      
      // Check availability again
      final availability = await _checkResourceAvailability(resourceType, quantity);
      if (!availability['available']) {
        return {
          'success': false,
          'error': 'Insufficient resources available',
          'availability': availability,
        };
      }
      
      // Reserve the resources
      await _reserveResources(resourceType, quantity);
      
      // Update allocation status
      await _supabase.from('resource_allocations').update({
        'status': AllocationStatus.approved.name,
        'approved_at': DateTime.now().toIso8601String(),
        'approved_by': _supabase.auth.currentUser?.id,
        'approval_reason': reason,
        'notes': notes,
        'distribution_method': method?.name,
        'scheduled_delivery': scheduledDelivery?.toIso8601String(),
      }).eq('id', allocationId);
      
      // Log approval
      await _logAllocationAction('allocation_approved', {
        'allocation_id': allocationId,
        'resource_type': resourceType.name,
        'quantity': quantity,
        'reason': reason,
      });
      
      // Broadcast update
      _broadcastAllocationUpdate({
        'allocation_id': allocationId,
        'action': 'approved',
        'resource_type': resourceType.name,
        'quantity': quantity,
      });
      
      return {
        'success': true,
        'allocation_id': allocationId,
        'status': AllocationStatus.approved.name,
      };
    } catch (e) {
      print('Error approving allocation: $e');
      return {
        'success': false,
        'error': 'Failed to approve allocation: $e',
      };
    }
  }

  Future<void> _reserveResources(ResourceType resourceType, int quantity) async {
    try {
      final current = await _supabase
          .from('resource_inventory')
          .select('reserved')
          .eq('resource_type', resourceType.name)
          .single();
      
      final currentReserved = current['reserved'] as int? ?? 0;
      
      await _supabase
          .from('resource_inventory')
          .update({'reserved': currentReserved + quantity})
          .eq('resource_type', resourceType.name);
    } catch (e) {
      print('Error reserving resources: $e');
    }
  }

  Future<Map<String, dynamic>> _analyzeAllocationRequest(Map<String, dynamic> request) async {
    try {
      final resourceType = ResourceType.values.firstWhere(
        (type) => type.name == request['resource_type'],
        orElse: () => ResourceType.equipment,
      );
      
      final priority = AllocationPriority.values.firstWhere(
        (p) => p.name == request['priority'],
        orElse: () => AllocationPriority.medium,
      );
      
      final quantity = request['quantity'] as int;
      final createdAt = DateTime.tryParse(request['created_at'] ?? '') ?? DateTime.now();
      
      // Calculate urgency score (0.0 - 1.0)
      final urgencyScore = _calculateUrgencyScore(priority, createdAt);
      
      // Calculate availability score (0.0 - 1.0)
      final availability = await _checkResourceAvailability(resourceType, quantity);
      final availabilityScore = availability['available'] ? 1.0 : 
                               (availability['available_stock'] as int? ?? 0) / quantity;
      
      // Calculate efficiency score (0.0 - 1.0)
      final efficiencyScore = _calculateEfficiencyScore(resourceType, quantity, request['delivery_location']);
      
      // Determine if recommended
      final combinedScore = (urgencyScore * 0.4) + (availabilityScore * 0.3) + (efficiencyScore * 0.3);
      final recommended = combinedScore >= 0.6;
      
      return {
        'recommended': recommended,
        'urgency_score': urgencyScore,
        'availability_score': availabilityScore,
        'efficiency_score': efficiencyScore,
        'combined_score': combinedScore,
        'recommendation': _getRecommendationText(combinedScore),
        'suggested_method': _suggestDistributionMethod(resourceType, request['delivery_location']),
        'estimated_delivery': _estimateDeliveryTime(resourceType, request['delivery_location']),
      };
    } catch (e) {
      print('Error analyzing allocation request: $e');
      return {
        'recommended': false,
        'error': e.toString(),
      };
    }
  }

  double _calculateUrgencyScore(AllocationPriority priority, DateTime createdAt) {
    // Base urgency from priority
    double baseUrgency = switch (priority) {
      AllocationPriority.critical => 1.0,
      AllocationPriority.high => 0.8,
      AllocationPriority.medium => 0.5,
      AllocationPriority.low => 0.3,
      AllocationPriority.routine => 0.1,
    };
    
    // Time factor (older requests get higher urgency)
    final hoursOld = DateTime.now().difference(createdAt).inHours;
    final timeFactor = min(hoursOld / 24.0, 1.0); // Max 1.0 for requests older than 24 hours
    
    return min(baseUrgency + (timeFactor * 0.2), 1.0);
  }

  double _calculateEfficiencyScore(ResourceType resourceType, int quantity, String? location) {
    // Simplified efficiency calculation
    double score = 0.5; // Base score
    
    // Quantity efficiency (smaller quantities are generally more efficient to process)
    if (quantity <= 10) score += 0.3;
    else if (quantity <= 50) score += 0.2;
    else if (quantity <= 100) score += 0.1;
    
    // Location efficiency (would be based on distance from warehouses)
    // Simplified for demo
    score += 0.2;
    
    return min(score, 1.0);
  }

  String _getRecommendationText(double score) {
    if (score >= 0.8) return 'Highly recommended - immediate approval suggested';
    if (score >= 0.6) return 'Recommended - approve when resources available';
    if (score >= 0.4) return 'Consider approval based on additional factors';
    return 'Not recommended - review requirements';
  }

  DistributionMethod _suggestDistributionMethod(ResourceType resourceType, String? location) {
    // Simplified suggestion logic
    switch (resourceType) {
      case ResourceType.medical:
      case ResourceType.firstAid:
        return DistributionMethod.emergency;
      case ResourceType.food:
      case ResourceType.water:
        return DistributionMethod.mobile;
      case ResourceType.equipment:
        return DistributionMethod.pickup;
      default:
        return DistributionMethod.delivery;
    }
  }

  String _estimateDeliveryTime(ResourceType resourceType, String? location) {
    // Simplified estimation
    switch (resourceType) {
      case ResourceType.medical:
      case ResourceType.firstAid:
        return '2-4 hours';
      case ResourceType.food:
      case ResourceType.water:
        return '4-8 hours';
      default:
        return '1-2 days';
    }
  }

  DistributionMethod _parseDistributionMethod(dynamic method) {
    if (method is String) {
      return DistributionMethod.values.firstWhere(
        (m) => m.name == method,
        orElse: () => DistributionMethod.delivery,
      );
    }
    return DistributionMethod.delivery;
  }

  double _calculateResourceUtilization() {
    // Simplified calculation
    return 0.75; // 75% utilization
  }

  double _calculateAllocationAccuracy() {
    // Simplified calculation
    return 0.92; // 92% accuracy
  }

  double _calculateSupplyChainEfficiency() {
    // Simplified calculation
    return 0.88; // 88% efficiency
  }

  int _getDefaultMinThreshold(ResourceType resourceType) {
    switch (resourceType) {
      case ResourceType.medical:
      case ResourceType.firstAid:
        return 20;
      case ResourceType.food:
      case ResourceType.water:
        return 100;
      case ResourceType.blankets:
      case ResourceType.clothing:
        return 50;
      default:
        return 25;
    }
  }

  double _getDefaultUnitValue(ResourceType resourceType) {
    switch (resourceType) {
      case ResourceType.medical:
        return 15.0;
      case ResourceType.food:
        return 3.0;
      case ResourceType.water:
        return 1.0;
      case ResourceType.blankets:
        return 12.0;
      case ResourceType.clothing:
        return 8.0;
      case ResourceType.equipment:
        return 50.0;
      default:
        return 5.0;
    }
  }

  Future<void> _sendLowStockAlert(ResourceType resourceType, int currentQuantity, int threshold) async {
    try {
      await _supabase.from('stock_alerts').insert({
        'resource_type': resourceType.name,
        'current_quantity': currentQuantity,
        'threshold': threshold,
        'alert_type': 'low_stock',
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error sending low stock alert: $e');
    }
  }

  int _calculateOptimalOrderQuantity(String resourceType, int current, int minThreshold) {
    // Economic Order Quantity (EOQ) simplified
    final demandRate = _getAverageDemandRate(resourceType);
    final optimalQuantity = (demandRate * 30).ceil(); // 30 days supply
    return max(optimalQuantity, minThreshold * 2);
  }

  int _getAverageDemandRate(String resourceType) {
    // Simplified demand rate calculation
    switch (resourceType) {
      case 'food':
      case 'water':
        return 20; // per day
      case 'medical':
        return 5;
      case 'blankets':
        return 8;
      default:
        return 10;
    }
  }

  double _estimateOrderCost(String resourceType, int quantity) {
    final unitValue = _getDefaultUnitValue(ResourceType.values.firstWhere(
      (type) => type.name == resourceType,
      orElse: () => ResourceType.equipment,
    ));
    return quantity * unitValue;
  }

  int _getExpectedDeliveryTime(String resourceType) {
    // Days
    switch (resourceType) {
      case 'medical':
        return 1;
      case 'food':
      case 'water':
        return 2;
      default:
        return 3;
    }
  }

  Future<List<Map<String, dynamic>>> _analyzeAllocationPatterns() async {
    // Analyze historical allocation patterns and suggest improvements
    return [];
  }

  Future<List<Map<String, dynamic>>> _analyzeDistributionEfficiency() async {
    // Analyze distribution routes and methods for optimization
    return [];
  }

  Future<void> _logAllocationAction(String action, Map<String, dynamic> details) async {
    try {
      await _supabase.from('allocation_activity_log').insert({
        'action': action,
        'details': details,
        'created_at': DateTime.now().toIso8601String(),
        'admin_id': _supabase.auth.currentUser?.id,
      });
    } catch (e) {
      print('Error logging allocation action: $e');
    }
  }

  void _broadcastAllocationUpdate(Map<String, dynamic> updateData) {
    if (_allocationStreamController != null && !_allocationStreamController!.isClosed) {
      _allocationStreamController!.add({
        'type': 'allocation_update',
        'data': updateData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  void _broadcastInventoryUpdate(Map<String, dynamic> updateData) {
    if (_inventoryStreamController != null && !_inventoryStreamController!.isClosed) {
      _inventoryStreamController!.add({
        'type': 'inventory_update',
        'data': updateData,
        'timestamp': DateTime.now().toIso8601String(),
      });
    }
  }

  /// Dispose resources
  void dispose() {
    _allocationStreamController?.close();
    _inventoryStreamController?.close();
    _allocationStreamController = null;
    _inventoryStreamController = null;
    _allocationTimer?.cancel();
  }
}
