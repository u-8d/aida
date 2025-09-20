import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/need.dart';
import 'need_creation_screen.dart';

class RecipientDashboardScreen extends StatelessWidget {
  const RecipientDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;
        
        if (currentUser == null) {
          return const Center(
            child: Text('Please log in to view your needs'),
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
                    _buildActiveNeedsCard(context),
                    const SizedBox(height: 16),
                    _buildQuickActionsCard(context),
                  ]),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "recipient_fab",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NeedCreationScreen(),
                ),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Post Need'),
          ),
        );
      },
    );
  }

  Widget _buildStatsCard(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;
        if (currentUser == null) return const SizedBox();
        
        final userNeeds = appState.getNeedsByUser(currentUser.id);
        final activeNeeds = userNeeds.where((need) => 
          need.status == NeedStatus.unmet || need.status == NeedStatus.partialMatch
        ).length;
        final fulfilledNeeds = userNeeds.where((need) => 
          need.status == NeedStatus.fulfilled
        ).length;
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Activity',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Active Needs',
                        '$activeNeeds',
                        Icons.campaign,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Received Help',
                        '$fulfilledNeeds',
                        Icons.favorite,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
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

  Widget _buildActiveNeedsCard(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final currentUser = appState.currentUser;
        if (currentUser == null) return const SizedBox();
        
        final userNeeds = appState.getNeedsByUser(currentUser.id);
        final activeNeeds = userNeeds.where((need) => 
          need.status == NeedStatus.unmet || need.status == NeedStatus.partialMatch
        ).toList();
        
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your Active Needs',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    if (activeNeeds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${activeNeeds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (activeNeeds.isEmpty)
                  const ListTile(
                    leading: Icon(Icons.info),
                    title: Text('No active needs'),
                    subtitle: Text('Post your first need to get started!'),
                  )
                else
                  ...activeNeeds.take(3).map((need) => _buildNeedTile(context, need)),
                if (activeNeeds.length > 3)
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to full needs list
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Full needs list coming soon!'),
                        ),
                      );
                    },
                    child: Text('View all ${activeNeeds.length} needs'),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNeedTile(BuildContext context, Need need) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getUrgencyColor(need.urgency).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          _getUrgencyIcon(need.urgency),
          color: _getUrgencyColor(need.urgency),
          size: 20,
        ),
      ),
      title: Text(
        need.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            need.description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getStatusColor(need.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getStatusText(need.status),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(need.status),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Qty: ${need.quantity}',
                style: const TextStyle(fontSize: 10),
              ),
            ],
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: () {
        // TODO: Navigate to need details
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('View details for "${need.title}"'),
          ),
        );
      },
    );
  }

  Color _getUrgencyColor(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.urgent:
        return Colors.red;
      case UrgencyLevel.high:
        return Colors.orange;
      case UrgencyLevel.medium:
        return Colors.yellow[700]!;
      case UrgencyLevel.low:
        return Colors.green;
    }
  }

  IconData _getUrgencyIcon(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.urgent:
        return Icons.crisis_alert;
      case UrgencyLevel.high:
        return Icons.priority_high;
      case UrgencyLevel.medium:
        return Icons.warning_amber;
      case UrgencyLevel.low:
        return Icons.schedule;
    }
  }

  Color _getStatusColor(NeedStatus status) {
    switch (status) {
      case NeedStatus.unmet:
        return Colors.orange;
      case NeedStatus.partialMatch:
        return Colors.blue;
      case NeedStatus.fulfilled:
        return Colors.green;
      case NeedStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(NeedStatus status) {
    switch (status) {
      case NeedStatus.unmet:
        return 'Seeking Help';
      case NeedStatus.partialMatch:
        return 'Partially Matched';
      case NeedStatus.fulfilled:
        return 'Fulfilled';
      case NeedStatus.cancelled:
        return 'Cancelled';
    }
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
                      // TODO: Navigate to browse donations
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Browse donations coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.search),
                    label: const Text('Find Help'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Navigate to AI chat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI Helper coming soon!'),
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
