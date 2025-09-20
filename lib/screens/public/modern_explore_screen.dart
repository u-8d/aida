import 'package:flutter/material.dart';
import '../components/disaster_zone_map.dart';
import '../components/campaign_progress.dart';
import '../components/simple_match_notification.dart';
import '../../config/app_theme.dart';

class ModernExploreScreen extends StatelessWidget {
  const ModernExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero Section with disaster zone map
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppTheme.neutralGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.urgentRed.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.urgentRed.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.crisis_alert,
                              size: 16,
                              color: AppTheme.urgentRed,
                            ),
                            SizedBox(width: 6),
                            Text(
                              'Active Emergency',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.urgentRed,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () {
                          // Navigate to full map view
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Opening full map view...')),
                          );
                        },
                        icon: const Icon(Icons.fullscreen, size: 16),
                        label: const Text('Full Map'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppTheme.primaryBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const DisasterZoneMapWidget(),
                ],
              ),
            ),
            
            // Multi-panel content section
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Panel layout: Progress tracker and quick stats
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Campaign Progress (left panel)
                      const Expanded(
                        flex: 3,
                        child: CampaignProgressWidget(
                          campaignTitle: 'Water & Blankets Needed',
                          currentAmount: 750,
                          targetAmount: 1000,
                          itemType: 'Blankets',
                          progressColor: AppTheme.campaignProgress,
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Quick stats (right panel)
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildQuickStatCard(
                              'Active Donations',
                              '127',
                              Icons.volunteer_activism,
                              AppTheme.primaryBlue,
                            ),
                            const SizedBox(height: 12),
                            _buildQuickStatCard(
                              'Urgent Needs',
                              '23',
                              Icons.priority_high,
                              AppTheme.urgentRed,
                            ),
                            const SizedBox(height: 12),
                            _buildQuickStatCard(
                              'Matches Today',
                              '15',
                              Icons.handshake,
                              AppTheme.successGreen,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Match notifications section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: AppTheme.cardDecoration,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.successGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.notifications_active,
                                color: AppTheme.successGreen,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Recent Matches',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.darkGray,
                                    ),
                                  ),
                                  Text(
                                    'Donations matched with urgent needs',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.neutralGray,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                // View all matches
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Opening all matches...')),
                                );
                              },
                              child: const Text('View All'),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Match notifications
                        const SimpleMatchNotificationsList(),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons section
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening donation form...')),
                            );
                          },
                          icon: const Icon(Icons.volunteer_activism),
                          label: const Text('Donate Items'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Opening needs form...')),
                            );
                          },
                          icon: const Icon(Icons.campaign),
                          label: const Text('Request Help'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.primaryBlue,
                            side: const BorderSide(color: AppTheme.primaryBlue),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.neutralGray,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
