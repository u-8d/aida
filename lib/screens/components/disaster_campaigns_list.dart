import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_app_state.dart';
import '../../models/disaster_campaign.dart';
import '../../config/app_theme.dart';

class DisasterCampaignsList extends StatelessWidget {
  const DisasterCampaignsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAppState>(
      builder: (context, adminState, child) {
        final campaigns = adminState.disasterCampaigns;
        final isLoading = adminState.isLoadingCampaigns;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (campaigns.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No disaster campaigns found',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Create a new campaign to get started',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.campaign,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Disaster Campaigns',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${campaigns.length} Total',
                      style: TextStyle(
                        color: AppTheme.primaryBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    return _buildCampaignCard(campaign);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignCard(DisasterCampaign campaign) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getDisasterIcon(campaign.disasterType),
                color: _getStatusColor(campaign.status),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  campaign.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(campaign.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  campaign.location,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${campaign.daysSinceStart}d ago',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progress',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    LinearProgressIndicator(
                      value: campaign.completionPercentage,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(campaign.status),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(campaign.completionPercentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
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
                      fontSize: 10,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${campaign.currentBeneficiaries}/${campaign.targetBeneficiaries}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(CampaignStatus status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusDisplayName(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  IconData _getDisasterIcon(DisasterType type) {
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

  Color _getStatusColor(CampaignStatus status) {
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

  String _getStatusDisplayName(CampaignStatus status) {
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
}
