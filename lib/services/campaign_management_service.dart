import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/disaster_campaign.dart';
import '../models/admin_user.dart';

class CampaignManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a new disaster campaign
  Future<DisasterCampaign> createCampaign(DisasterCampaign campaign) async {
    try {
      final response = await _supabase
          .from('disaster_campaigns')
          .insert(campaign.toJson())
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create campaign: $e');
    }
  }

  /// Update an existing campaign
  Future<DisasterCampaign> updateCampaign(String campaignId, Map<String, dynamic> updates) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update campaign: $e');
    }
  }

  /// Get campaign by ID
  Future<DisasterCampaign> getCampaign(String campaignId) async {
    try {
      final response = await _supabase
          .from('disaster_campaigns')
          .select()
          .eq('id', campaignId)
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get campaign: $e');
    }
  }

  /// Get all campaigns with optional filters
  Future<List<DisasterCampaign>> getCampaigns({
    CampaignStatus? status,
    DisasterType? disasterType,
    ResourcePriority? priority,
    String? coordinatorId,
    bool? isEmergencyMode,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('disaster_campaigns').select();

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }
      if (disasterType != null) {
        query = query.eq('disaster_type', disasterType.toString().split('.').last);
      }
      if (priority != null) {
        query = query.eq('overall_priority', priority.toString().split('.').last);
      }
      if (coordinatorId != null) {
        query = query.eq('coordinator_id', coordinatorId);
      }
      if (isEmergencyMode != null) {
        query = query.eq('is_emergency_mode', isEmergencyMode);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => DisasterCampaign.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get campaigns: $e');
    }
  }

  /// Get active campaigns (for public display)
  Future<List<DisasterCampaign>> getActiveCampaigns({int limit = 20}) async {
    try {
      final response = await _supabase
          .from('disaster_campaigns')
          .select()
          .or('status.eq.active,status.eq.urgent')
          .order('overall_priority', ascending: false)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List)
          .map((json) => DisasterCampaign.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get active campaigns: $e');
    }
  }

  /// Get urgent campaigns requiring immediate attention
  Future<List<DisasterCampaign>> getUrgentCampaigns() async {
    try {
      final response = await _supabase
          .from('disaster_campaigns')
          .select()
          .eq('status', 'urgent')
          .or('overall_priority.eq.critical,overall_priority.eq.emergency')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => DisasterCampaign.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to get urgent campaigns: $e');
    }
  }

  /// Update campaign status
  Future<DisasterCampaign> updateCampaignStatus(String campaignId, CampaignStatus newStatus) async {
    try {
      final updates = {
        'status': newStatus.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update campaign status: $e');
    }
  }

  /// Update campaign priority
  Future<DisasterCampaign> updateCampaignPriority(String campaignId, ResourcePriority newPriority) async {
    try {
      final updates = {
        'overall_priority': newPriority.toString().split('.').last,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update campaign priority: $e');
    }
  }

  /// Update resource collection for a campaign
  Future<DisasterCampaign> updateResourceCollection(
    String campaignId, 
    Map<String, int> resourceUpdates
  ) async {
    try {
      // Get current campaign to merge resource data
      final currentCampaign = await getCampaign(campaignId);
      final updatedResourceCollected = Map<String, int>.from(currentCampaign.resourceCollected);
      
      // Merge updates
      for (final entry in resourceUpdates.entries) {
        updatedResourceCollected[entry.key] = 
            (updatedResourceCollected[entry.key] ?? 0) + entry.value;
      }

      final updates = {
        'resource_collected': updatedResourceCollected,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update resource collection: $e');
    }
  }

  /// Update beneficiary count
  Future<DisasterCampaign> updateBeneficiaryCount(String campaignId, int newCount) async {
    try {
      final updates = {
        'current_beneficiaries': newCount,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update beneficiary count: $e');
    }
  }

  /// Assign coordinator to campaign
  Future<DisasterCampaign> assignCoordinator(String campaignId, AdminUser coordinator) async {
    try {
      final updates = {
        'coordinator_id': coordinator.id,
        'coordinator_name': coordinator.name,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to assign coordinator: $e');
    }
  }

  /// Add support staff to campaign
  Future<DisasterCampaign> addSupportStaff(String campaignId, List<String> staffIds) async {
    try {
      final currentCampaign = await getCampaign(campaignId);
      final updatedStaffIds = List<String>.from(currentCampaign.supportStaffIds);
      
      for (final staffId in staffIds) {
        if (!updatedStaffIds.contains(staffId)) {
          updatedStaffIds.add(staffId);
        }
      }

      final updates = {
        'support_staff_ids': updatedStaffIds,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add support staff: $e');
    }
  }

  /// Add internal note to campaign
  Future<DisasterCampaign> addInternalNote(String campaignId, String note) async {
    try {
      final currentCampaign = await getCampaign(campaignId);
      final updatedNotes = List<String>.from(currentCampaign.internalNotes);
      
      final timestampedNote = '[${DateTime.now().toIso8601String()}] $note';
      updatedNotes.add(timestampedNote);

      final updates = {
        'internal_notes': updatedNotes,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to add internal note: $e');
    }
  }

  /// Update public message for campaign
  Future<DisasterCampaign> updatePublicMessage(String campaignId, String message) async {
    try {
      final updates = {
        'public_update_message': message,
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update public message: $e');
    }
  }

  /// Toggle emergency mode for campaign
  Future<DisasterCampaign> toggleEmergencyMode(String campaignId, bool isEmergency) async {
    try {
      final updates = {
        'is_emergency_mode': isEmergency,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // If activating emergency mode, also set status to urgent if not already
      if (isEmergency) {
        updates['status'] = 'urgent';
        updates['overall_priority'] = 'critical';
      }

      final response = await _supabase
          .from('disaster_campaigns')
          .update(updates)
          .eq('id', campaignId)
          .select()
          .single();

      return DisasterCampaign.fromJson(response);
    } catch (e) {
      throw Exception('Failed to toggle emergency mode: $e');
    }
  }

  /// Delete campaign (admin only)
  Future<void> deleteCampaign(String campaignId) async {
    try {
      await _supabase
          .from('disaster_campaigns')
          .delete()
          .eq('id', campaignId);
    } catch (e) {
      throw Exception('Failed to delete campaign: $e');
    }
  }

  /// Get campaign statistics
  Future<Map<String, dynamic>> getCampaignStatistics() async {
    try {
      final activeCampaigns = await _supabase
          .from('disaster_campaigns')
          .select('id')
          .or('status.eq.active,status.eq.urgent');

      final completedCampaigns = await _supabase
          .from('disaster_campaigns')
          .select('id')
          .eq('status', 'completed');

      final urgentCampaigns = await _supabase
          .from('disaster_campaigns')
          .select('id')
          .eq('status', 'urgent');

      final emergencyModeCampaigns = await _supabase
          .from('disaster_campaigns')
          .select('id')
          .eq('is_emergency_mode', true);

      return {
        'total_active': activeCampaigns.length,
        'total_completed': completedCampaigns.length,
        'urgent_campaigns': urgentCampaigns.length,
        'emergency_mode_campaigns': emergencyModeCampaigns.length,
      };
    } catch (e) {
      throw Exception('Failed to get campaign statistics: $e');
    }
  }

  /// Auto-match donations to urgent campaigns
  Future<List<Map<String, dynamic>>> getAutoMatchCandidates(String campaignId) async {
    try {
      final campaign = await getCampaign(campaignId);
      
      if (!campaign.autoMatchEnabled) {
        return [];
      }

      // Get available donations that could match this campaign's needs
      final donations = await _supabase
          .from('donations')
          .select('*, users(*)')
          .eq('status', 'active')
          .not('category', 'is', null);

      // Simple matching algorithm based on priority tags and resource needs
      List<Map<String, dynamic>> matches = [];
      
      for (final donation in donations) {
        double matchScore = _calculateMatchScore(campaign, donation);
        
        if (matchScore >= campaign.autoMatchThreshold) {
          matches.add({
            'donation': donation,
            'match_score': matchScore,
            'campaign_id': campaignId,
          });
        }
      }

      // Sort by match score (highest first)
      matches.sort((a, b) => (b['match_score'] as double)
          .compareTo(a['match_score'] as double));

      return matches;
    } catch (e) {
      throw Exception('Failed to get auto-match candidates: $e');
    }
  }

  /// Calculate match score between campaign and donation
  double _calculateMatchScore(DisasterCampaign campaign, Map<String, dynamic> donation) {
    double score = 0.0;
    
    // Basic category matching
    final donationCategory = donation['category'] as String?;
    if (donationCategory != null) {
      // Priority-based scoring
      if (campaign.overallPriority == ResourcePriority.emergency ||
          campaign.overallPriority == ResourcePriority.critical) {
        score += 0.4;
      }
      
      // Emergency mode bonus
      if (campaign.isEmergencyMode) {
        score += 0.3;
      }
      
      // Geographic proximity (if available)
      final donorLocation = donation['users']['city'] as String?;
      if (donorLocation != null && campaign.affectedAreas.contains(donorLocation)) {
        score += 0.2;
      }
      
      // Urgency bonus
      if (campaign.status == CampaignStatus.urgent) {
        score += 0.1;
      }
    }
    
    return score;
  }

  /// Bulk update campaigns (for emergency operations)
  Future<List<DisasterCampaign>> bulkUpdateCampaigns(
    List<String> campaignIds, 
    Map<String, dynamic> updates
  ) async {
    try {
      updates['updated_at'] = DateTime.now().toIso8601String();
      
      List<DisasterCampaign> updatedCampaigns = [];
      
      // Update each campaign individually for simplicity
      for (final campaignId in campaignIds) {
        final response = await _supabase
            .from('disaster_campaigns')
            .update(updates)
            .eq('id', campaignId)
            .select()
            .single();
        
        updatedCampaigns.add(DisasterCampaign.fromJson(response));
      }

      return updatedCampaigns;
    } catch (e) {
      throw Exception('Failed to bulk update campaigns: $e');
    }
  }

  /// Get campaigns by disaster type for analytics
  Future<Map<String, int>> getCampaignsByDisasterType() async {
    try {
      final response = await _supabase
          .from('disaster_campaigns')
          .select('disaster_type');

      Map<String, int> counts = {};
      for (final item in response) {
        final type = item['disaster_type'] as String;
        counts[type] = (counts[type] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      throw Exception('Failed to get campaigns by disaster type: $e');
    }
  }
}
