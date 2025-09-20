import 'package:flutter/material.dart';
import '../../config/app_theme.dart';

class DisasterZoneMapWidget extends StatefulWidget {
  const DisasterZoneMapWidget({super.key});

  @override
  State<DisasterZoneMapWidget> createState() => _DisasterZoneMapWidgetState();
}

class _DisasterZoneMapWidgetState extends State<DisasterZoneMapWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 280,
      decoration: AppTheme.cardDecoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map Background (simulated with gradient and grid)
            _buildMapBackground(),
            
            // Disaster Zone Overlay
            _buildDisasterZoneOverlay(),
            
            // Location Pins
            _buildLocationPins(),
            
            // Map Header
            _buildMapHeader(),
          ],
        ),
      ),
    );
  }

  Widget _buildMapBackground() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF8F9FA),
            Color(0xFFE9ECEF),
          ],
        ),
      ),
      child: CustomPaint(
        painter: MapGridPainter(),
      ),
    );
  }

  Widget _buildDisasterZoneOverlay() {
    return Positioned(
      left: 60,
      top: 80,
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          color: AppTheme.disasterZoneRed.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppTheme.disasterZoneRed.withOpacity(0.4),
            width: 2,
          ),
        ),
        child: Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.disasterZoneRed.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.warning_rounded,
                color: AppTheme.urgentRed,
                size: 32,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationPins() {
    final List<Map<String, dynamic>> pins = [
      {'x': 80.0, 'y': 120.0, 'priority': 'high'},
      {'x': 140.0, 'y': 140.0, 'priority': 'urgent'},
      {'x': 100.0, 'y': 160.0, 'priority': 'high'},
      {'x': 160.0, 'y': 100.0, 'priority': 'medium'},
      {'x': 200.0, 'y': 180.0, 'priority': 'low'},
      {'x': 240.0, 'y': 120.0, 'priority': 'medium'},
    ];

    return Stack(
      children: pins.map((pin) {
        return Positioned(
          left: pin['x'],
          top: pin['y'],
          child: _buildLocationPin(pin['priority']),
        );
      }).toList(),
    );
  }

  Widget _buildLocationPin(String priority) {
    Color pinColor;
    bool shouldFlash = false;
    
    switch (priority) {
      case 'urgent':
        pinColor = AppTheme.urgentRed;
        shouldFlash = true;
        break;
      case 'high':
        pinColor = AppTheme.urgentRed;
        shouldFlash = true;
        break;
      case 'medium':
        pinColor = AppTheme.warningAmber;
        break;
      default:
        pinColor = AppTheme.accentOrange;
    }

    Widget pin = Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: pinColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: pinColor.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Icon(
        shouldFlash ? Icons.flash_on : Icons.location_on,
        color: Colors.white,
        size: 14,
      ),
    );

    if (shouldFlash) {
      return AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: pin,
          );
        },
      );
    }

    return pin;
  }

  Widget _buildMapHeader() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.darkBlue.withOpacity(0.9),
              AppTheme.darkBlue.withOpacity(0.0),
            ],
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.urgentRed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.crisis_alert,
                    color: Colors.white,
                    size: 14,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Disaster Zone',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '6 urgent needs',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.darkGray,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.neutralGray.withOpacity(0.1)
      ..strokeWidth = 0.5;

    // Draw grid lines to simulate streets
    for (int i = 0; i < size.width; i += 30) {
      canvas.drawLine(
        Offset(i.toDouble(), 0),
        Offset(i.toDouble(), size.height),
        paint,
      );
    }

    for (int i = 0; i < size.height; i += 30) {
      canvas.drawLine(
        Offset(0, i.toDouble()),
        Offset(size.width, i.toDouble()),
        paint,
      );
    }

    // Draw some building-like rectangles
    final buildingPaint = Paint()
      ..color = AppTheme.lightGray
      ..style = PaintingStyle.fill;

    final buildings = [
      Rect.fromLTWH(20, 40, 25, 35),
      Rect.fromLTWH(200, 60, 30, 45),
      Rect.fromLTWH(140, 200, 40, 25),
      Rect.fromLTWH(260, 180, 20, 30),
      Rect.fromLTWH(50, 220, 35, 20),
    ];

    for (final building in buildings) {
      canvas.drawRect(building, buildingPaint);
      canvas.drawRect(
        building,
        Paint()
          ..color = AppTheme.neutralGray.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
