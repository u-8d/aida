import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';

class DonorDashboardScreen extends StatelessWidget {
  const DonorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;
        
        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view your donations'),
          );
        }

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text('Welcome, ${currentUser.name}!'),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.7),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16.0),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    _buildStatsCard(context),
                    const SizedBox(height: 16),
                    _buildRecentDonationsCard(context),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(context),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "donor_simple_fab",
            onPressed: () {
              // TODO: Navigate to donation creation screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation creation coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('New Donation'),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Impact',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'Total Donations',
                    '0', // TODO: Connect to actual data
                    Icons.volunteer_activism,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'People Helped',
                    '0', // TODO: Connect to actual data
                    Icons.people,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecentDonationsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Donations',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            // TODO: Replace with actual donations list
            const ListTile(
              leading: Icon(Icons.info),
              title: Text('No donations yet'),
              subtitle: Text('Start making a difference today!'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to browse needs
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Browse needs coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Browse Needs'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to AI chat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI Chat coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.chat),
                    label: const Text('AI Helper'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
