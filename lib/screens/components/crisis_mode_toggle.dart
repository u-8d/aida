import 'package:flutter/material.dart';
import '../../models/admin_user.dart';
import '../../config/app_theme.dart';

class CrisisModeToggle extends StatefulWidget {
  final bool isEnabled;
  final CrisisLevel? currentLevel;
  final Function(bool enabled, CrisisLevel? level) onToggle;

  const CrisisModeToggle({
    super.key,
    required this.isEnabled,
    required this.currentLevel,
    required this.onToggle,
  });

  @override
  State<CrisisModeToggle> createState() => _CrisisModeToggleState();
}

class _CrisisModeToggleState extends State<CrisisModeToggle> {
  bool _isLoading = false;
  CrisisLevel _selectedLevel = CrisisLevel.moderate;

  @override
  void initState() {
    super.initState();
    _selectedLevel = widget.currentLevel ?? CrisisLevel.moderate;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(
          color: widget.isEnabled ? AppTheme.urgentRed : Colors.grey.shade300,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        color: widget.isEnabled 
            ? AppTheme.urgentRed.withOpacity(0.1)
            : Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isEnabled ? Icons.crisis_alert : Icons.shield,
                color: widget.isEnabled ? AppTheme.urgentRed : Colors.grey,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crisis Mode',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: widget.isEnabled ? AppTheme.urgentRed : Colors.black87,
                      ),
                    ),
                    Text(
                      widget.isEnabled 
                          ? 'Emergency protocols are active'
                          : 'Normal operations mode',
                      style: TextStyle(
                        fontSize: 14,
                        color: widget.isEnabled ? AppTheme.urgentRed : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: widget.isEnabled,
                onChanged: _isLoading ? null : (value) => _toggleCrisisMode(value),
                activeColor: AppTheme.urgentRed,
              ),
            ],
          ),
          
          if (widget.isEnabled) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            const Text(
              'Crisis Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildCrisisLevelSelector(),
            
            const SizedBox(height: 16),
            _buildCrisisLevelDescription(_selectedLevel),
          ],
          
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCrisisLevelSelector() {
    return Column(
      children: CrisisLevel.values.map((level) {
        final isSelected = _selectedLevel == level;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedLevel = level;
              });
              _updateCrisisLevel(level);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected 
                    ? _getCrisisLevelColor(level).withOpacity(0.2)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected 
                      ? _getCrisisLevelColor(level)
                      : Colors.grey.shade300,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getCrisisLevelIcon(level),
                    color: _getCrisisLevelColor(level),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getCrisisLevelDisplayName(level),
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected 
                            ? _getCrisisLevelColor(level)
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: _getCrisisLevelColor(level),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCrisisLevelDescription(CrisisLevel level) {
    final description = _getCrisisLevelDescription(level);
    final color = _getCrisisLevelColor(level);
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              description,
              style: TextStyle(
                fontSize: 13,
                color: color.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleCrisisMode(bool enabled) async {
    setState(() {
      _isLoading = true;
    });

    await widget.onToggle(enabled, enabled ? _selectedLevel : null);

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateCrisisLevel(CrisisLevel level) async {
    if (!widget.isEnabled) return;

    setState(() {
      _isLoading = true;
    });

    await widget.onToggle(true, level);

    setState(() {
      _isLoading = false;
    });
  }

  Color _getCrisisLevelColor(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.low:
        return Colors.yellow.shade700;
      case CrisisLevel.moderate:
        return Colors.orange;
      case CrisisLevel.high:
        return Colors.deepOrange;
      case CrisisLevel.critical:
        return Colors.red;
      case CrisisLevel.emergency:
        return Colors.purple;
    }
  }

  IconData _getCrisisLevelIcon(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.low:
        return Icons.info;
      case CrisisLevel.moderate:
        return Icons.warning;
      case CrisisLevel.high:
        return Icons.priority_high;
      case CrisisLevel.critical:
        return Icons.dangerous;
      case CrisisLevel.emergency:
        return Icons.emergency;
    }
  }

  String _getCrisisLevelDisplayName(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.low:
        return 'Low Alert';
      case CrisisLevel.moderate:
        return 'Moderate Alert';
      case CrisisLevel.high:
        return 'High Alert';
      case CrisisLevel.critical:
        return 'Critical Alert';
      case CrisisLevel.emergency:
        return 'Emergency Alert';
    }
  }

  String _getCrisisLevelDescription(CrisisLevel level) {
    switch (level) {
      case CrisisLevel.low:
        return 'Monitoring situation. Standard response protocols apply. Minimal service impact expected.';
      case CrisisLevel.moderate:
        return 'Enhanced monitoring active. Prepare response teams. Some service prioritization may occur.';
      case CrisisLevel.high:
        return 'Active response required. Resource prioritization in effect. Increased coordination needed.';
      case CrisisLevel.critical:
        return 'Severe situation. Emergency protocols activated. Significant resource reallocation required.';
      case CrisisLevel.emergency:
        return 'Maximum alert level. All emergency protocols active. Full resource mobilization in progress.';
    }
  }
}
