import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class MatchNotificationWidget extends StatefulWidget {
  final String donationItem;
  final String recipientNeed;
  final String location;
  final String urgencyLevel;
  final VoidCallback? onViewDetails;
  final VoidCallback? onAcceptMatch;

  const MatchNotificationWidget({
    super.key,
    required this.donationItem,
    required this.recipientNeed,
    required this.location,
    required this.urgencyLevel,
    this.onViewDetails,
    this.onAcceptMatch,
  });

  @override
  State<MatchNotificationWidget> createState() => _MatchNotificationWidgetState();
}

class _MatchNotificationWidgetState extends State<MatchNotificationWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _glowController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));
    
    _glowAnimation = Tween<double>(
      begin: 0.3,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: _buildNotificationDecoration(),
        child: Column(
          children: [
            _buildHeader(),
            _buildMatchContent(),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  BoxDecoration _buildNotificationDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          AppTheme.successGreen.withOpacity(0.05),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: AppTheme.successGreen.withOpacity(0.2),
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 1,
        ),
      ],
      border: Border.all(
        color: AppTheme.successGreen.withOpacity(0.3),
        width: 1,
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.successGreen,
            AppTheme.successGreen.withOpacity(0.8),
          ],
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(_glowAnimation.value),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.handshake_rounded,
                  color: AppTheme.successGreen,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Match Found!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your donation can help someone in need',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildUrgencyBadge(),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge() {
    Color badgeColor;
    IconData badgeIcon;
    
    switch (widget.urgencyLevel.toLowerCase()) {
      case 'urgent':
        badgeColor = AppTheme.urgentRed;
        badgeIcon = Icons.crisis_alert;
        break;
      case 'high':
        badgeColor = AppTheme.urgentRed;
        badgeIcon = Icons.priority_high;
        break;
      case 'medium':
        badgeColor = AppTheme.warningAmber;
        badgeIcon = Icons.warning_amber;
        break;
      default:
        badgeColor = AppTheme.accentOrange;
        badgeIcon = Icons.schedule;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            color: Colors.white,
            size: 10,
          ),
          const SizedBox(width: 3),
          Text(
            widget.urgencyLevel.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchContent() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Match visualization
          Row(
            children: [
              _buildMatchItem(
                'Your Donation',
                widget.donationItem,
                Icons.volunteer_activism,
                AppTheme.primaryBlue,
              ),
              const SizedBox(width: 16),
              _buildMatchArrow(),
              const SizedBox(width: 16),
              _buildMatchItem(
                'Recipient Need',
                widget.recipientNeed,
                Icons.campaign,
                AppTheme.accentOrange,
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // Location and details
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color: AppTheme.primaryBlue,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Location: ${widget.location}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(
                      Icons.timeline,
                      color: AppTheme.successGreen,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Match Score: 95% compatibility',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.darkGray,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchItem(String label, String item, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              item,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.darkGray,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchArrow() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppTheme.successGreen.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: AppTheme.successGreen,
        size: 20,
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.lightGray.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: widget.onAcceptMatch,
              icon: const Icon(Icons.check_circle, size: 18),
              label: const Text('Accept Match'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.successGreen,
                foregroundColor: Colors.white,
                elevation: 2,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onViewDetails,
              icon: const Icon(Icons.info_outline, size: 16),
              label: const Text('Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryBlue,
                side: const BorderSide(color: AppTheme.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget for multiple match notifications
class MatchNotificationsList extends StatelessWidget {
  const MatchNotificationsList({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> mockMatches = [
      {
        'donationItem': 'Warm Blankets',
        'recipientNeed': 'Emergency Shelter Supplies',
        'location': 'Mumbai Central',
        'urgencyLevel': 'urgent',
      },
      {
        'donationItem': 'School Supplies',
        'recipientNeed': 'Educational Materials',
        'location': 'Pune',
        'urgencyLevel': 'high',
      },
      {
        'donationItem': 'Winter Clothes',
        'recipientNeed': 'Clothing for Children',
        'location': 'Delhi',
        'urgencyLevel': 'medium',
      },
    ];

    return Column(
      children: mockMatches.map((match) {
        return MatchNotificationWidget(
          donationItem: match['donationItem'],
          recipientNeed: match['recipientNeed'],
          location: match['location'],
          urgencyLevel: match['urgencyLevel'],
          onViewDetails: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Viewing details for ${match['donationItem']} match'),
              ),
            );
          },
          onAcceptMatch: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Match accepted for ${match['donationItem']}!'),
                backgroundColor: AppTheme.successGreen,
              ),
            );
          },
        );
      }).toList(),
    );
  }
}
