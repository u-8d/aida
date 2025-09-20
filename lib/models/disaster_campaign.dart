import 'dart:math';

/// Types of disasters that can trigger emergency campaigns
enum DisasterType {
  earthquake,
  flood,
  cyclone,
  fire,
  drought,
  landslide,
  tsunami,
  volcanic,
  pandemic,
  industrial,
  other,
}

/// Severity levels for disaster campaigns
enum DisasterSeverity {
  minor,
  moderate,
  major,
  severe,
  catastrophic,
}

/// Status of a disaster campaign
enum CampaignStatus {
  planning,
  active,
  urgent,
  winding_down,
  completed,
  suspended,
}

/// Priority levels for resource allocation
enum ResourcePriority {
  low,
  medium,
  high,
  critical,
  emergency,
}

class DisasterCampaign {
  final String id;
  final String title;
  final String description;
  final DisasterType disasterType;
  final DisasterSeverity severity;
  final CampaignStatus status;
  final String location;
  final List<String> affectedAreas;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? estimatedCompletionDate;
  
  // Campaign metrics
  final int targetBeneficiaries;
  final int currentBeneficiaries;
  final Map<String, int> resourceTargets; // resource type -> target quantity
  final Map<String, int> resourceCollected; // resource type -> collected quantity
  
  // Administrative details
  final String coordinatorId;
  final String coordinatorName;
  final List<String> supportStaffIds;
  final List<String> volunteerIds;
  
  // Geographic and logistics
  final double? latitude;
  final double? longitude;
  final List<String> distributionCenters;
  final Map<String, String> logisticsInfo; // key-value pairs for logistics details
  
  // Urgency and prioritization
  final ResourcePriority overallPriority;
  final Map<String, ResourcePriority> itemPriorities; // item type -> priority
  final bool isEmergencyMode;
  final DateTime? lastUpdated;
  
  // Communication
  final String? publicUpdateMessage;
  final List<String> internalNotes;
  final Map<String, dynamic> contactInfo;
  
  // Automation settings
  final bool autoMatchEnabled;
  final double autoMatchThreshold; // 0.0 to 1.0
  final List<String> priorityTags;
  
  DisasterCampaign({
    required this.id,
    required this.title,
    required this.description,
    required this.disasterType,
    required this.severity,
    required this.status,
    required this.location,
    required this.affectedAreas,
    required this.startDate,
    this.endDate,
    this.estimatedCompletionDate,
    required this.targetBeneficiaries,
    this.currentBeneficiaries = 0,
    this.resourceTargets = const {},
    this.resourceCollected = const {},
    required this.coordinatorId,
    required this.coordinatorName,
    this.supportStaffIds = const [],
    this.volunteerIds = const [],
    this.latitude,
    this.longitude,
    this.distributionCenters = const [],
    this.logisticsInfo = const {},
    this.overallPriority = ResourcePriority.medium,
    this.itemPriorities = const {},
    this.isEmergencyMode = false,
    this.lastUpdated,
    this.publicUpdateMessage,
    this.internalNotes = const [],
    this.contactInfo = const {},
    this.autoMatchEnabled = true,
    this.autoMatchThreshold = 0.8,
    this.priorityTags = const [],
  });

  factory DisasterCampaign.fromJson(Map<String, dynamic> json) {
    return DisasterCampaign(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      disasterType: DisasterType.values.firstWhere(
        (type) => type.toString().split('.').last == json['disaster_type'],
        orElse: () => DisasterType.other,
      ),
      severity: DisasterSeverity.values.firstWhere(
        (sev) => sev.toString().split('.').last == json['severity'],
        orElse: () => DisasterSeverity.moderate,
      ),
      status: CampaignStatus.values.firstWhere(
        (stat) => stat.toString().split('.').last == json['status'],
        orElse: () => CampaignStatus.active,
      ),
      location: json['location'] as String,
      affectedAreas: (json['affected_areas'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: json['end_date'] != null 
          ? DateTime.parse(json['end_date'] as String) 
          : null,
      estimatedCompletionDate: json['estimated_completion_date'] != null
          ? DateTime.parse(json['estimated_completion_date'] as String)
          : null,
      targetBeneficiaries: json['target_beneficiaries'] as int,
      currentBeneficiaries: json['current_beneficiaries'] as int? ?? 0,
      resourceTargets: Map<String, int>.from(json['resource_targets'] ?? {}),
      resourceCollected: Map<String, int>.from(json['resource_collected'] ?? {}),
      coordinatorId: json['coordinator_id'] as String,
      coordinatorName: json['coordinator_name'] as String,
      supportStaffIds: (json['support_staff_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      volunteerIds: (json['volunteer_ids'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distributionCenters: (json['distribution_centers'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      logisticsInfo: Map<String, String>.from(json['logistics_info'] ?? {}),
      overallPriority: ResourcePriority.values.firstWhere(
        (prio) => prio.toString().split('.').last == json['overall_priority'],
        orElse: () => ResourcePriority.medium,
      ),
      itemPriorities: (json['item_priorities'] as Map<String, dynamic>?)
          ?.map((key, value) => MapEntry(
              key, 
              ResourcePriority.values.firstWhere(
                (prio) => prio.toString().split('.').last == value,
                orElse: () => ResourcePriority.medium,
              )
            )) ?? {},
      isEmergencyMode: json['is_emergency_mode'] as bool? ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
      publicUpdateMessage: json['public_update_message'] as String?,
      internalNotes: (json['internal_notes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      contactInfo: Map<String, dynamic>.from(json['contact_info'] ?? {}),
      autoMatchEnabled: json['auto_match_enabled'] as bool? ?? true,
      autoMatchThreshold: (json['auto_match_threshold'] as num?)?.toDouble() ?? 0.8,
      priorityTags: (json['priority_tags'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'disaster_type': disasterType.toString().split('.').last,
      'severity': severity.toString().split('.').last,
      'status': status.toString().split('.').last,
      'location': location,
      'affected_areas': affectedAreas,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'estimated_completion_date': estimatedCompletionDate?.toIso8601String(),
      'target_beneficiaries': targetBeneficiaries,
      'current_beneficiaries': currentBeneficiaries,
      'resource_targets': resourceTargets,
      'resource_collected': resourceCollected,
      'coordinator_id': coordinatorId,
      'coordinator_name': coordinatorName,
      'support_staff_ids': supportStaffIds,
      'volunteer_ids': volunteerIds,
      'latitude': latitude,
      'longitude': longitude,
      'distribution_centers': distributionCenters,
      'logistics_info': logisticsInfo,
      'overall_priority': overallPriority.toString().split('.').last,
      'item_priorities': itemPriorities.map((key, value) => 
          MapEntry(key, value.toString().split('.').last)),
      'is_emergency_mode': isEmergencyMode,
      'last_updated': lastUpdated?.toIso8601String(),
      'public_update_message': publicUpdateMessage,
      'internal_notes': internalNotes,
      'contact_info': contactInfo,
      'auto_match_enabled': autoMatchEnabled,
      'auto_match_threshold': autoMatchThreshold,
      'priority_tags': priorityTags,
    };
  }

  /// Calculate overall completion percentage
  double get completionPercentage {
    if (resourceTargets.isEmpty) return 0.0;
    
    double totalTarget = resourceTargets.values.fold(0, (sum, target) => sum + target);
    double totalCollected = resourceCollected.values.fold(0, (sum, collected) => sum + collected);
    
    if (totalTarget == 0) return 0.0;
    return min(1.0, totalCollected / totalTarget);
  }

  /// Calculate beneficiary completion percentage
  double get beneficiaryPercentage {
    if (targetBeneficiaries == 0) return 0.0;
    return min(1.0, currentBeneficiaries / targetBeneficiaries);
  }

  /// Check if campaign is currently active and urgent
  bool get isUrgentAndActive {
    return (status == CampaignStatus.active || status == CampaignStatus.urgent) &&
           (overallPriority == ResourcePriority.critical || overallPriority == ResourcePriority.emergency);
  }

  /// Get human-readable disaster type name
  String get disasterTypeDisplayName {
    switch (disasterType) {
      case DisasterType.earthquake:
        return 'Earthquake';
      case DisasterType.flood:
        return 'Flood';
      case DisasterType.cyclone:
        return 'Cyclone/Hurricane';
      case DisasterType.fire:
        return 'Wildfire';
      case DisasterType.drought:
        return 'Drought';
      case DisasterType.landslide:
        return 'Landslide';
      case DisasterType.tsunami:
        return 'Tsunami';
      case DisasterType.volcanic:
        return 'Volcanic Eruption';
      case DisasterType.pandemic:
        return 'Pandemic/Health Crisis';
      case DisasterType.industrial:
        return 'Industrial Accident';
      case DisasterType.other:
        return 'Other Emergency';
    }
  }

  /// Get human-readable severity name
  String get severityDisplayName {
    switch (severity) {
      case DisasterSeverity.minor:
        return 'Minor';
      case DisasterSeverity.moderate:
        return 'Moderate';
      case DisasterSeverity.major:
        return 'Major';
      case DisasterSeverity.severe:
        return 'Severe';
      case DisasterSeverity.catastrophic:
        return 'Catastrophic';
    }
  }

  /// Get human-readable status name
  String get statusDisplayName {
    switch (status) {
      case CampaignStatus.planning:
        return 'Planning';
      case CampaignStatus.active:
        return 'Active';
      case CampaignStatus.urgent:
        return 'Urgent';
      case CampaignStatus.winding_down:
        return 'Winding Down';
      case CampaignStatus.completed:
        return 'Completed';
      case CampaignStatus.suspended:
        return 'Suspended';
    }
  }

  /// Get days since campaign started
  int get daysSinceStart {
    return DateTime.now().difference(startDate).inDays;
  }

  /// Get estimated days remaining (if estimatedCompletionDate is set)
  int? get daysRemaining {
    if (estimatedCompletionDate == null) return null;
    final remaining = estimatedCompletionDate!.difference(DateTime.now()).inDays;
    return remaining < 0 ? 0 : remaining;
  }

  /// Create a copy with updated fields
  DisasterCampaign copyWith({
    String? id,
    String? title,
    String? description,
    DisasterType? disasterType,
    DisasterSeverity? severity,
    CampaignStatus? status,
    String? location,
    List<String>? affectedAreas,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? estimatedCompletionDate,
    int? targetBeneficiaries,
    int? currentBeneficiaries,
    Map<String, int>? resourceTargets,
    Map<String, int>? resourceCollected,
    String? coordinatorId,
    String? coordinatorName,
    List<String>? supportStaffIds,
    List<String>? volunteerIds,
    double? latitude,
    double? longitude,
    List<String>? distributionCenters,
    Map<String, String>? logisticsInfo,
    ResourcePriority? overallPriority,
    Map<String, ResourcePriority>? itemPriorities,
    bool? isEmergencyMode,
    DateTime? lastUpdated,
    String? publicUpdateMessage,
    List<String>? internalNotes,
    Map<String, dynamic>? contactInfo,
    bool? autoMatchEnabled,
    double? autoMatchThreshold,
    List<String>? priorityTags,
  }) {
    return DisasterCampaign(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      disasterType: disasterType ?? this.disasterType,
      severity: severity ?? this.severity,
      status: status ?? this.status,
      location: location ?? this.location,
      affectedAreas: affectedAreas ?? this.affectedAreas,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      estimatedCompletionDate: estimatedCompletionDate ?? this.estimatedCompletionDate,
      targetBeneficiaries: targetBeneficiaries ?? this.targetBeneficiaries,
      currentBeneficiaries: currentBeneficiaries ?? this.currentBeneficiaries,
      resourceTargets: resourceTargets ?? this.resourceTargets,
      resourceCollected: resourceCollected ?? this.resourceCollected,
      coordinatorId: coordinatorId ?? this.coordinatorId,
      coordinatorName: coordinatorName ?? this.coordinatorName,
      supportStaffIds: supportStaffIds ?? this.supportStaffIds,
      volunteerIds: volunteerIds ?? this.volunteerIds,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distributionCenters: distributionCenters ?? this.distributionCenters,
      logisticsInfo: logisticsInfo ?? this.logisticsInfo,
      overallPriority: overallPriority ?? this.overallPriority,
      itemPriorities: itemPriorities ?? this.itemPriorities,
      isEmergencyMode: isEmergencyMode ?? this.isEmergencyMode,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      publicUpdateMessage: publicUpdateMessage ?? this.publicUpdateMessage,
      internalNotes: internalNotes ?? this.internalNotes,
      contactInfo: contactInfo ?? this.contactInfo,
      autoMatchEnabled: autoMatchEnabled ?? this.autoMatchEnabled,
      autoMatchThreshold: autoMatchThreshold ?? this.autoMatchThreshold,
      priorityTags: priorityTags ?? this.priorityTags,
    );
  }
}
