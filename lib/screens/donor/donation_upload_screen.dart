import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/donation.dart';
import '../../models/need.dart';
import '../../services/gemini_service.dart';
import '../../services/matching_service.dart';

class DonationUploadScreen extends StatefulWidget {
  const DonationUploadScreen({super.key});

  @override
  State<DonationUploadScreen> createState() => _DonationUploadScreenState();
}

class _DonationUploadScreenState extends State<DonationUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contextDescriptionController = TextEditingController(); // New context field
  
  List<File> _selectedImages = []; // Changed to support multiple images
  ImageAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  Timer? _debounceTimer;
  int _currentImageIndex = 0; // Track which image is being viewed

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Listen to context description changes to update button text
    _contextDescriptionController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to update button text
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _contextDescriptionController.dispose(); // Dispose new controller
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 70,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _analysisResult = null;
          _currentImageIndex = _selectedImages.length - 1; // Focus on new image
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 70,
      );
      
      if (images.isNotEmpty) {
        List<File> validImages = [];
        
        for (XFile image in images) {
          final File imageFile = File(image.path);
          
          // Check file size
          final bytes = await imageFile.readAsBytes();
          if (bytes.length > 10 * 1024 * 1024) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Image ${image.name} is too large. Please select images under 10MB.'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
            continue; // Skip this image but continue with others
          }
          
          validImages.add(imageFile);
        }
        
        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validImages);
            _currentImageIndex = _selectedImages.length - 1; // Focus on last added image
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking images: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _analyzeImages() async {
    if (_selectedImages.isEmpty || _isAnalyzing) return; // Prevent multiple concurrent calls

    setState(() {
      _isAnalyzing = true;
    });

    try {
      // Get user context description if provided
      final userContext = _contextDescriptionController.text.trim().isNotEmpty 
          ? _contextDescriptionController.text.trim() 
          : null;

      final result = await GeminiService.analyzeMultipleImages(
        _selectedImages,
        userDescription: userContext, // Pass user context to AI
      );
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      // Pre-fill form with AI suggestions
      if (_itemNameController.text.isEmpty) {
        _itemNameController.text = result.title;
      }
      if (_descriptionController.text.isEmpty) {
        _descriptionController.text = result.description;
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userContext != null 
                ? '✅ Image analyzed with your context! Review the details below.'
                : '✅ Image analyzed successfully! Review the details below.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      String errorMessage = 'Failed to analyze image';
      if (e.toString().contains('API key not configured')) {
        errorMessage = 'AI analysis unavailable: API key not configured. Please fill details manually.';
      } else if (e.toString().contains('quota exceeded')) {
        errorMessage = 'AI analysis temporarily unavailable: Quota exceeded. Please fill details manually.';
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'AI analysis unavailable: Invalid API configuration. Please fill details manually.';
      } else {
        errorMessage = 'AI analysis failed: ${e.toString().replaceAll('Exception: ', '')}. Please fill details manually.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ $errorMessage'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  Future<void> _uploadDonation() async {
    if (_formKey.currentState!.validate() && _selectedImages.isNotEmpty) {
      setState(() {
        _isUploading = true;
      });

      try {
        final currentUser = context.read<SupabaseAppState>().currentUser;
        if (currentUser == null) {
          _showErrorSnackBar('Please log in to upload donations');
          return;
        }

        // Create donation object
        final donation = Donation(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          donorId: currentUser.id,
          itemName: _itemNameController.text.trim(),
          description: _descriptionController.text.trim(),
          contextDescription: _contextDescriptionController.text.trim().isNotEmpty 
              ? _contextDescriptionController.text.trim() 
              : null, // Include context description if provided
          tags: _analysisResult?.tags ?? [],
          imageUrl: _selectedImages.first.path, // In real app, upload to cloud storage
          city: currentUser.city ?? '',
          status: DonationStatus.pendingMatch,
          createdAt: DateTime.now(),
        );

        // Add donation to app state
        context.read<SupabaseAppState>().addDonation(donation);

        // Find matches
        final availableNeeds = context.read<SupabaseAppState>().getAvailableNeeds();
        final matches = MatchingService.findMatches(donation, availableNeeds);
        
        // Add matches to app state
        for (final match in matches) {
          context.read<SupabaseAppState>().addMatch(match);
        }

        // Update donation status if matches found
        if (matches.isNotEmpty) {
          final updatedDonation = Donation(
            id: donation.id,
            donorId: donation.donorId,
            itemName: donation.itemName,
            description: donation.description,
            contextDescription: donation.contextDescription, // Include context description
            tags: donation.tags,
            imageUrl: donation.imageUrl,
            city: donation.city,
            status: DonationStatus.matchFound,
            createdAt: donation.createdAt,
            matchedAt: DateTime.now(),
            matchedRecipientId: matches.first.recipientId,
            matchedRecipientName: availableNeeds
                .firstWhere((n) => n.id == matches.first.needId)
                .recipientName,
          );
          context.read<SupabaseAppState>().updateDonation(donation.id, updatedDonation);
        }

        _showSuccessSnackBar('Donation uploaded successfully!');
        Navigator.pop(context);
      } catch (e) {
        _showErrorSnackBar('Failed to upload donation: $e');
      } finally {
        setState(() {
          _isUploading = false;
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
        title: const Text('Donate Item'),
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
              // Image Upload Section
              _buildImageUploadSection(),
              const SizedBox(height: 24),

              // AI Analysis Results
              if (_analysisResult != null) _buildAnalysisResults(),
              if (_analysisResult != null) const SizedBox(height: 24),

              // Matching Requests
              if (_analysisResult != null) _buildMatchingRequests(),
              if (_analysisResult != null) const SizedBox(height: 24),

              // Item Name Field
              _buildTextField(
                controller: _itemNameController,
                label: 'Item Name',
                hint: 'Enter the name of the item',
                icon: Icons.inventory,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Description Field (Optional)
              _buildTextField(
                controller: _descriptionController,
                label: 'Description (Optional)',
                hint: 'Add any additional details about the item if needed',
                icon: Icons.description,
                maxLines: 3,
                validator: null, // Removed validation to make it optional
              ),
              const SizedBox(height: 32),

              // Upload Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isUploading ? null : _uploadDonation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isUploading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Upload Donation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Item Photo',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        const SizedBox(height: 12),
        
        if (_selectedImages.isEmpty)
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              border: Border.all(
                color: Colors.grey[300]!,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 12),
                Text(
                  'Take a photo or select multiple images from gallery',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text('Camera'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _pickMultipleImages,
                      icon: const Icon(Icons.collections),
                      label: const Text('Select Images'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[600],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          _buildImageCarousel(),
          
          // Context Description Field (Optional)
          const SizedBox(height: 16),
          _buildTextField(
            controller: _contextDescriptionController,
            label: 'Context for AI (Optional)',
            hint: 'Provide details like size, condition, brand, intended use, etc. to help AI analyze better',
            icon: Icons.psychology_outlined,
            maxLines: 2,
            validator: null, // Optional field
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '💡 Help AI understand your item better: mention size (XL, 32"), condition (new, gently used), brand names, or special features.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          
          // AI Analysis Button
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isAnalyzing ? null : _analyzeImages,
              icon: _isAnalyzing 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.psychology),
              label: Text(_isAnalyzing 
                  ? 'Analyzing with AI...' 
                  : _contextDescriptionController.text.trim().isNotEmpty
                      ? 'Analyze with AI + Context'
                      : 'Analyze with AI'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAnalysisResults() {
    final hasUserContext = _contextDescriptionController.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2E7D32).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                hasUserContext ? 'AI Analysis with Your Context' : 'AI Analysis Results',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (hasUserContext)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Enhanced',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
            ],
          ),
          if (hasUserContext) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Context:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _contextDescriptionController.text.trim(),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          
          Text(
            'Item: ${_analysisResult!.title}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Description: ${_analysisResult!.description}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Category: ${_analysisResult!.category}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          
          Text(
            'Condition: ${_analysisResult!.condition}',
            style: const TextStyle(fontSize: 14),
          ),
          if (_analysisResult!.size.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Size: ${_analysisResult!.size}',
              style: const TextStyle(fontSize: 14),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Target Audience: ${_analysisResult!.targetAudience}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Seasonality: ${_analysisResult!.seasonality}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Text(
            'Urgency Level: ${_analysisResult!.urgencyLevel}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          const Text(
            'Suggested Tags:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _analysisResult!.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchingRequests() {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final availableNeeds = appState.getAvailableNeeds();
        final matchingNeeds = _findMatchingNeeds(availableNeeds);
        
        if (matchingNeeds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.favorite,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Matching Requests Found!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Your donation matches ${matchingNeeds.length} existing request${matchingNeeds.length != 1 ? 's' : ''}. Consider donating to these specific needs:',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              ...matchingNeeds.take(3).map((need) => _buildMatchingNeedCard(need)),
              if (matchingNeeds.length > 3) ...[
                const SizedBox(height: 8),
                Text(
                  '... and ${matchingNeeds.length - 3} more requests',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  List<Need> _findMatchingNeeds(List<Need> needs) {
    if (_analysisResult == null) return [];
    
    List<Need> matches = [];
    for (var need in needs) {
      double score = _calculateNeedMatchScore(need);
      if (score > 0.4) { // Higher threshold for showing matches
        matches.add(need);
      }
    }
    
    // Sort by match score (highest first)
    matches.sort((a, b) {
      double scoreA = _calculateNeedMatchScore(a);
      double scoreB = _calculateNeedMatchScore(b);
      return scoreB.compareTo(scoreA);
    });
    
    return matches;
  }

  double _calculateNeedMatchScore(Need need) {
    if (_analysisResult == null) return 0.0;
    
    double score = 0.0;
    
    // Tag matching (50% weight)
    double tagScore = _calculateTagSimilarity(_analysisResult!.tags, need.requiredTags);
    score += tagScore * 0.5;
    
    // Category matching (20% weight)
    if (need.requiredTags.any((tag) => 
        tag.toLowerCase().contains(_analysisResult!.category.toLowerCase()) ||
        _analysisResult!.category.toLowerCase().contains(tag.toLowerCase()))) {
      score += 0.2;
    }
    
    // Urgency bonus (20% weight)
    if (need.urgency == UrgencyLevel.urgent) {
      score += 0.2;
    } else if (need.urgency == UrgencyLevel.high) {
      score += 0.15;
    } else if (need.urgency == UrgencyLevel.medium) {
      score += 0.1;
    }
    
    // Target audience matching (10% weight)
    if (need.requiredTags.any((tag) => 
        tag.toLowerCase().contains(_analysisResult!.targetAudience.toLowerCase()))) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  double _calculateTagSimilarity(List<String> donationTags, List<String> needTags) {
    if (donationTags.isEmpty || needTags.isEmpty) return 0.0;
    
    int matches = 0;
    for (String donationTag in donationTags) {
      for (String needTag in needTags) {
        if (donationTag.toLowerCase().contains(needTag.toLowerCase()) ||
            needTag.toLowerCase().contains(donationTag.toLowerCase())) {
          matches++;
          break;
        }
      }
    }
    
    return matches / needTags.length;
  }

  Widget _buildMatchingNeedCard(Need need) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            need.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            need.description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 12,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                need.city,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(need.urgency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getUrgencyText(need.urgency),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _getUrgencyColor(need.urgency),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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

  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Main image display
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: FileImage(_selectedImages[_currentImageIndex]),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Analysis overlay
            if (_isAnalyzing)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 12),
                      Text(
                        'Analyzing all images...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Image counter
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${_selectedImages.length}',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            
            // Navigation arrows (if multiple images)
            if (_selectedImages.length > 1) ...[
              if (_currentImageIndex > 0)
                Positioned(
                  left: 8,
                  top: 88,
                  child: FloatingActionButton.small(
                    heroTag: "image_prev_fab",
                    onPressed: () {
                      setState(() {
                        _currentImageIndex--;
                      });
                    },
                    backgroundColor: Colors.black.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.arrow_back_ios, size: 16),
                  ),
                ),
              if (_currentImageIndex < _selectedImages.length - 1)
                Positioned(
                  right: 8,
                  top: 88,
                  child: FloatingActionButton.small(
                    heroTag: "image_next_fab",
                    onPressed: () {
                      setState(() {
                        _currentImageIndex++;
                      });
                    },
                    backgroundColor: Colors.black.withOpacity(0.7),
                    foregroundColor: Colors.white,
                    child: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                ),
            ],
            
            // Remove current image button
            Positioned(
              top: 8,
              right: 8,
              child: FloatingActionButton.small(
                heroTag: "image_remove_fab",
                onPressed: () {
                  setState(() {
                    _selectedImages.removeAt(_currentImageIndex);
                    if (_currentImageIndex >= _selectedImages.length && _selectedImages.isNotEmpty) {
                      _currentImageIndex = _selectedImages.length - 1;
                    }
                    if (_selectedImages.isEmpty) {
                      _analysisResult = null;
                    }
                  });
                },
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: const Icon(Icons.close, size: 16),
              ),
            ),
          ],
        ),
        
        // Image thumbnails and add button
        if (_selectedImages.isNotEmpty) ...[
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length + 1, // +1 for add button
              itemBuilder: (context, index) {
                // Add button at the end
                if (index == _selectedImages.length) {
                  return Tooltip(
                    message: 'Add more images',
                    child: GestureDetector(
                      onTap: _pickMultipleImages,
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary,
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate,
                          color: Theme.of(context).colorScheme.primary,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }

                // Regular image thumbnail
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentImageIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: index == _currentImageIndex 
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade300,
                        width: index == _currentImageIndex ? 3 : 1,
                      ),
                      image: DecorationImage(
                        image: FileImage(_selectedImages[index]),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Delete button
                        Positioned(
                          top: -4,
                          right: -4,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedImages.removeAt(index);
                                if (_currentImageIndex >= _selectedImages.length && _selectedImages.isNotEmpty) {
                                  _currentImageIndex = _selectedImages.length - 1;
                                } else if (_selectedImages.isEmpty) {
                                  _currentImageIndex = 0;
                                  _analysisResult = null;
                                }
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Camera button
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      onChanged: onChanged,
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
}
