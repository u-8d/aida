import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/donation.dart';
import '../../models/need.dart';

class PublicFeedScreen extends StatelessWidget {
  const PublicFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            body: Column(
              children: [
                Container(
                  color: Theme.of(context).primaryColor,
                  child: const TabBar(
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.volunteer_activism),
                        text: 'Donations',
                      ),
                      Tab(
                        icon: Icon(Icons.campaign),
                        text: 'Needs',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      DonationsTab(donations: appState.donations),
                      NeedsTab(needs: appState.needs),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class DonationsTab extends StatelessWidget {
  final List<Donation> donations;
  
  const DonationsTab({super.key, required this.donations});

  @override
  Widget build(BuildContext context) {
    if (donations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No donations available',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to donate!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: donations.length,
      itemBuilder: (context, index) {
        final donation = donations[index];
        return _buildDonationCard(context, donation, index);
      },
    );
  }

  Widget _buildDonationCard(BuildContext context, Donation donation, int index) {
    // Determine status color and icon
    Color statusColor;
    IconData statusIcon;
    
    switch (donation.status) {
      case DonationStatus.available:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case DonationStatus.matchFound:
        statusColor = Colors.blue;
        statusIcon = Icons.people;
        break;
      case DonationStatus.readyForPickup:
        statusColor = Colors.orange;
        statusIcon = Icons.local_shipping;
        break;
      case DonationStatus.donationCompleted:
        statusColor = Colors.purple;
        statusIcon = Icons.done_all;
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.hourglass_empty;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing details for ${donation.itemName}'),
              backgroundColor: statusColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            if (donation.imageUrl.isNotEmpty)
              Stack(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      color: Colors.grey[100],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Image.network(
                        donation.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey[200],
                            child: const Icon(
                              Icons.image_not_supported,
                              size: 50,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  // Status overlay (THIS IS THE MATCH FOUND OVERLAY!)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, color: Colors.white, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            _getStatusText(donation.status),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            
            // Content section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    donation.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    donation.description,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  
                  // Tags
                  if (donation.tags.isNotEmpty)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: donation.tags.take(3).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  
                  const SizedBox(height: 12),
                  
                  // Location and time
                  Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        donation.city,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(donation.createdAt),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
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

  String _getStatusText(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return 'Available';
      case DonationStatus.matchFound:
        return 'Matched';
      case DonationStatus.readyForPickup:
        return 'Ready';
      case DonationStatus.donationCompleted:
        return 'Completed';
      case DonationStatus.pendingMatch:
        return 'Pending';
      case DonationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

class NeedsTab extends StatelessWidget {
  final List<Need> needs;
  
  const NeedsTab({super.key, required this.needs});

  @override
  Widget build(BuildContext context) {
    if (needs.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.campaign, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No needs posted',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Check back later for requests!',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: needs.length,
      itemBuilder: (context, index) {
        final need = needs[index];
        return _buildNeedCard(context, need, index);
      },
    );
  }

  Widget _buildNeedCard(BuildContext context, Need need, int index) {
    Color urgencyColor;
    IconData urgencyIcon;
    
    switch (need.urgency) {
      case UrgencyLevel.urgent:
        urgencyColor = Colors.red;
        urgencyIcon = Icons.priority_high;
        break;
      case UrgencyLevel.high:
        urgencyColor = Colors.orange;
        urgencyIcon = Icons.warning;
        break;
      case UrgencyLevel.medium:
        urgencyColor = Colors.blue;
        urgencyIcon = Icons.info;
        break;
      case UrgencyLevel.low:
        urgencyColor = Colors.green;
        urgencyIcon = Icons.low_priority;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Viewing details for ${need.title}'),
              backgroundColor: urgencyColor,
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Urgency indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: urgencyColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(urgencyIcon, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          need.urgency.name.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Qty: ${need.quantity}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Text(
                need.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                need.description,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Tags
              if (need.requiredTags.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: need.requiredTags.take(3).map((tag) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: urgencyColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: urgencyColor.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        tag,
                        style: TextStyle(
                          color: urgencyColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              
              const SizedBox(height: 12),
              
              // Location and recipient info
              Row(
                children: [
                  Icon(Icons.location_on, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    need.city,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.person, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      need.recipientName,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(Icons.access_time, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _getTimeAgo(need.createdAt),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
