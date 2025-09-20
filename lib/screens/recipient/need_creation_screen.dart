import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/need.dart';
import '../../models/user.dart';

class NeedCreationScreen extends StatefulWidget {
  const NeedCreationScreen({super.key});

  @override
  State<NeedCreationScreen> createState() => _NeedCreationScreenState();
}

class _NeedCreationScreenState extends State<NeedCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _quantityController = TextEditingController();
  
  UrgencyLevel _selectedUrgency = UrgencyLevel.medium;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _submitNeed() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final currentUser = context.read<SupabaseAppState>().currentUser;
        if (currentUser == null) {
          _showErrorSnackBar('Please log in to post needs');
          return;
        }

        // Parse tags from comma-separated string
        final tags = _tagsController.text
            .split(',')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();

        // Create need object
        final need = Need(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          recipientId: currentUser.id,
          recipientName: currentUser.name,
          recipientType: currentUser is NGO ? 'ngo' : 'individual',
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          requiredTags: tags,
          city: currentUser.city ?? 'Unknown',
          urgency: _selectedUrgency,
          status: NeedStatus.unmet,
          createdAt: DateTime.now(),
          quantity: int.tryParse(_quantityController.text) ?? 1,
        );

        // Add need to app state
        context.read<SupabaseAppState>().addNeed(need);

        _showSuccessSnackBar('Need posted successfully!');
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Failed to post need: $e');
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Need'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'What do you need?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Describe the items you need and we\'ll help you find donors',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 32),

              // Title Field
              _buildTextField(
                controller: _titleController,
                label: 'Need Title',
                hint: 'e.g., Winter blankets for children',
                icon: Icons.title,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your need in detail',
                icon: Icons.description,
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Tags Field
              _buildTextField(
                controller: _tagsController,
                label: 'Required Tags',
                hint: 'e.g., blankets, winter clothing, children (comma separated)',
                icon: Icons.tag,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter at least one tag';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Quantity Field
              _buildTextField(
                controller: _quantityController,
                label: 'Quantity Needed',
                hint: '1',
                icon: Icons.numbers,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null || int.parse(value) <= 0) {
                    return 'Please enter a valid quantity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Urgency Level
              _buildUrgencySelector(),
              const SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitNeed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Post Need',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Tips
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips for better matches:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Be specific about item types and sizes'),
                    Text('• Include relevant tags for better matching'),
                    Text('• Set appropriate urgency level'),
                    Text('• Provide clear description of your needs'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
      ),
    );
  }

  Widget _buildUrgencySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Urgency Level',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: UrgencyLevel.values.map((urgency) {
            final isSelected = _selectedUrgency == urgency;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedUrgency = urgency;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _getUrgencyColor(urgency).withOpacity(0.1)
                          : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? _getUrgencyColor(urgency)
                            : Colors.grey[300]!,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getUrgencyIcon(urgency),
                          color: isSelected
                              ? _getUrgencyColor(urgency)
                              : Colors.grey[600],
                          size: 20,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getUrgencyText(urgency),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected
                                ? _getUrgencyColor(urgency)
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Color _getUrgencyColor(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.low:
        return Colors.green;
      case UrgencyLevel.medium:
        return Colors.orange;
      case UrgencyLevel.high:
        return Colors.red;
      case UrgencyLevel.urgent:
        return Colors.purple;
    }
  }

  IconData _getUrgencyIcon(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.low:
        return Icons.trending_down;
      case UrgencyLevel.medium:
        return Icons.trending_flat;
      case UrgencyLevel.high:
        return Icons.trending_up;
      case UrgencyLevel.urgent:
        return Icons.priority_high;
    }
  }

  String _getUrgencyText(UrgencyLevel urgency) {
    switch (urgency) {
      case UrgencyLevel.low:
        return 'Low';
      case UrgencyLevel.medium:
        return 'Medium';
      case UrgencyLevel.high:
        return 'High';
      case UrgencyLevel.urgent:
        return 'Urgent';
    }
  }
}
