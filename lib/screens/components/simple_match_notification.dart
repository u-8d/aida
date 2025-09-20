import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class SimpleMatchNotificationWidget extends StatefulWidget {
  final String title;
  final String description;
  final String urgencyLevel;
  final String distance;
  final String timeEstimate;
  final VoidCallback? onTap;

  const SimpleMatchNotificationWidget({
    super.key,
    required this.title,
    required this.description,
    required this.urgencyLevel,
    required this.distance,
    required this.timeEstimate,
    this.onTap,
  });

  @override
  State<SimpleMatchNotificationWidget> createState() => _SimpleMatchNotificationWidgetState();
}

class _SimpleMatchNotificationWidgetState extends State<SimpleMatchNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeIn),
    ));

    // Start animation on mount
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return FractionalTranslation(
          translation: Offset(0.0, _slideAnimation.value),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: AppTheme.cardDecoration.copyWith(
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.successGreen.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Header with match indicator
                        _buildHeader(),
                        
                        const SizedBox(height: 12),
                        
                        // Content
                        _buildContent(),
                        
                        const SizedBox(height: 12),
                        
                        // Footer with action
                        _buildFooter(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: const BoxDecoration(
            color: AppTheme.successGreen,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.handshake_rounded,
            color: Colors.white,
            size: 16,
          ),
        ),
        
        const SizedBox(width: 12),
        
        Expanded(
          child: Text(
            widget.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.darkGray,
            ),
          ),
        ),
        
        _buildUrgencyBadge(),
      ],
    );
  }

  Widget _buildContent() {
    return Text(
      widget.description,
      style: const TextStyle(
        fontSize: 12,
        color: AppTheme.neutralGray,
        height: 1.4,
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Icon(
          Icons.location_on,
          size: 12,
          color: AppTheme.neutralGray.withOpacity(0.7),
        ),
        const SizedBox(width: 4),
        
        Expanded(
          child: Text(
            '${widget.distance} • ${widget.timeEstimate}',
            style: TextStyle(
              fontSize: 10,
              color: AppTheme.neutralGray.withOpacity(0.8),
            ),
          ),
        ),
        
        TextButton(
          onPressed: widget.onTap,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'View Details',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUrgencyBadge() {
    Color badgeColor;
    
    switch (widget.urgencyLevel.toLowerCase()) {
      case 'urgent':
        badgeColor = AppTheme.urgentRed;
        break;
      case 'high':
        badgeColor = AppTheme.urgentRed;
        break;
      case 'medium':
        badgeColor = AppTheme.accentOrange;
        break;
      default:
        badgeColor = AppTheme.successGreen;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        widget.urgencyLevel.toUpperCase(),
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class SimpleMatchNotificationsList extends StatelessWidget {
  const SimpleMatchNotificationsList({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SimpleMatchNotificationWidget(
          title: 'Water bottles matched!',
          description: 'Your donation of 50 water bottles has been matched with Flood Relief Center.',
          urgencyLevel: 'urgent',
          distance: '2.5 km away',
          timeEstimate: 'Expected delivery: Tomorrow',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening match details...')),
            );
          },
        ),
        
        SimpleMatchNotificationWidget(
          title: 'Blankets matched!',
          description: 'Your donation of 20 blankets has been matched with Emergency Shelter.',
          urgencyLevel: 'high',
          distance: '1.2 km away',
          timeEstimate: 'Expected delivery: Today',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening match details...')),
            );
          },
        ),
        
        SimpleMatchNotificationWidget(
          title: 'Food supplies matched!',
          description: 'Your donation of canned food has been matched with Community Kitchen.',
          urgencyLevel: 'medium',
          distance: '3.8 km away',
          timeEstimate: 'Expected delivery: This week',
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening match details...')),
            );
          },
        ),
      ],
    );
  }
}
