import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/admin_app_state.dart';
import '../../config/app_theme.dart';

class RealTimeAnalyticsPanel extends StatelessWidget {
  const RealTimeAnalyticsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AdminAppState>(
      builder: (context, adminState, child) {
        final analyticsData = adminState.analyticsData;
        final isLoading = adminState.isLoadingAnalytics;

        if (isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (analyticsData.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.analytics,
                  size: 48,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No analytics data available',
                  style: TextStyle(
                    fontSize: 16,
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
                    Icons.analytics,
                    color: AppTheme.primaryBlue,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Real-Time Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Live',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    _buildMetricCard(
                      'Active Users',
                      '${analyticsData['user_surge']?['current_active_users'] ?? 0}',
                      Icons.people,
                      Colors.blue,
                    ),
                    _buildMetricCard(
                      'Donations Today',
                      '${analyticsData['donation_velocity']?['total_today'] ?? 0}',
                      Icons.volunteer_activism,
                      Colors.green,
                    ),
                    _buildMetricCard(
                      'Matches/Hour',
                      '${analyticsData['matching_efficiency']?['matches_per_hour'] ?? 0}',
                      Icons.link,
                      Colors.orange,
                    ),
                    _buildMetricCard(
                      'System Health',
                      adminState.systemHealthStatus,
                      Icons.health_and_safety,
                      _getHealthStatusColor(adminState.systemHealthStatus),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 20,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getHealthStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'degraded':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
