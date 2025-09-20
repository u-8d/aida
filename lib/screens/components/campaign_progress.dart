import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../config/app_theme.dart';

class CampaignProgressWidget extends StatefulWidget {
  final String campaignTitle;
  final int currentAmount;
  final int targetAmount;
  final String itemType;
  final Color? progressColor;

  const CampaignProgressWidget({
    super.key,
    required this.campaignTitle,
    required this.currentAmount,
    required this.targetAmount,
    required this.itemType,
    this.progressColor,
  });

  @override
  State<CampaignProgressWidget> createState() => _CampaignProgressWidgetState();
}

class _CampaignProgressWidgetState extends State<CampaignProgressWidget>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    final progress = widget.currentAmount / widget.targetAmount;
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: progress.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutCubic,
    ));
    
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppTheme.cardDecoration.copyWith(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            AppTheme.lightGray.withOpacity(0.3),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildCircularProgress(),
          const SizedBox(height: 20),
          _buildProgressStats(),
          const SizedBox(height: 16),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Active Campaign',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.accentOrange,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.campaignTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkGray,
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress() {
    return Center(
      child: SizedBox(
        width: 120,
        height: 120,
        child: AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Stack(
              children: [
                // Background circle
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.lightGray.withOpacity(0.3),
                  ),
                ),
                
                // Progress circle
                CustomPaint(
                  size: const Size(120, 120),
                  painter: CircularProgressPainter(
                    progress: _progressAnimation.value,
                    progressColor: widget.progressColor ?? AppTheme.campaignProgress,
                    backgroundColor: AppTheme.lightGray,
                  ),
                ),
                
                // Center content
                Positioned.fill(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${(_progressAnimation.value * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.darkGray,
                          ),
                        ),
                        Text(
                          'Complete',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.neutralGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildProgressStats() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildStatItem(
              'Collected',
              widget.currentAmount.toString(),
              AppTheme.successGreen,
              Icons.check_circle,
            ),
            _buildStatItem(
              'Target',
              widget.targetAmount.toString(),
              AppTheme.neutralGray,
              Icons.flag,
            ),
            _buildStatItem(
              'Remaining',
              (widget.targetAmount - widget.currentAmount).toString(),
              AppTheme.accentOrange,
              Icons.schedule,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.lightBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${widget.currentAmount} / ${widget.targetAmount} ${widget.itemType} Collected',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppTheme.neutralGray,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // Navigate to donation screen
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Opening donation form...'),
                ),
              );
            },
            icon: const Icon(Icons.volunteer_activism, size: 16),
            label: const Text('Contribute'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentOrange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            // Show campaign details
            _showCampaignDetails();
          },
          icon: const Icon(Icons.info_outline, size: 16),
          label: const Text('Details'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppTheme.primaryBlue,
            side: const BorderSide(color: AppTheme.primaryBlue),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  void _showCampaignDetails() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CampaignDetailsSheet(
        title: widget.campaignTitle,
        currentAmount: widget.currentAmount,
        targetAmount: widget.targetAmount,
        itemType: widget.itemType,
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color progressColor;
  final Color backgroundColor;

  CircularProgressPainter({
    required this.progress,
    required this.progressColor,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;
    
    // Background arc
    final backgroundPaint = Paint()
      ..color = backgroundColor.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    canvas.drawCircle(center, radius, backgroundPaint);
    
    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class CampaignDetailsSheet extends StatelessWidget {
  final String title;
  final int currentAmount;
  final int targetAmount;
  final String itemType;

  const CampaignDetailsSheet({
    super.key,
    required this.title,
    required this.currentAmount,
    required this.targetAmount,
    required this.itemType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.darkGray,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'This campaign is collecting $itemType for families affected by recent disasters. Every contribution helps provide essential items to those in urgent need.',
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutralGray,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.lightGray.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.people,
                  color: AppTheme.primaryBlue,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Impact',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.darkGray,
                        ),
                      ),
                      Text(
                        'Will help ${(targetAmount / 5).round()} families',
                        style: const TextStyle(
                          color: AppTheme.neutralGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
