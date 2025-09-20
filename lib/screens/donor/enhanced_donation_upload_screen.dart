import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/donation.dart';
import '../../models/need.dart';
import '../../models/match.dart' as app_match;
import '../../services/gemini_service.dart';
import '../../services/matching_service.dart';

class EnhancedDonationUploadScreen extends StatefulWidget {
  const EnhancedDonationUploadScreen({super.key});

  @override
  State<EnhancedDonationUploadScreen> createState() => _EnhancedDonationUploadScreenState();
}

class _EnhancedDonationUploadScreenState extends State<EnhancedDonationUploadScreen> 
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _itemNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contextDescriptionController = TextEditingController();
  
  List<File> _selectedImages = [];
  ImageAnalysisResult? _analysisResult;
  bool _isAnalyzing = false;
  bool _isUploading = false;
  int _currentImageIndex = 0;
  
  late AnimationController _uploadAnimationController;
  late Animation<double> _uploadAnimation;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _uploadAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _uploadAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _uploadAnimationController,
      curve: Curves.easeInOut,
    ));
    
    // Add listener to item name controller to update button state
    _itemNameController.addListener(() {
      if (mounted) {
        setState(() {}); // Rebuild to update button state
      }
    });
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _descriptionController.dispose();
    _contextDescriptionController.dispose();
    _uploadAnimationController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedImages.add(File(image.path));
          _analysisResult = null;
          _currentImageIndex = _selectedImages.length - 1;
        });
        
        // Show immediate feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check, color: Colors.white),
                const SizedBox(width: 12),
                Text('Image added! ${_selectedImages.length} photo${_selectedImages.length > 1 ? 's' : ''} ready.'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  Future<void> _pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultipleMedia(
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        List<File> validImages = [];
        int oversizedCount = 0;
        
        for (XFile image in images) {
          final File imageFile = File(image.path);
          
          // Check file size (limit to 10MB)
          final bytes = await imageFile.readAsBytes();
          if (bytes.length > 10 * 1024 * 1024) {
            oversizedCount++;
            continue;
          }
          
          validImages.add(imageFile);
        }
        
        if (validImages.isNotEmpty) {
          setState(() {
            _selectedImages.addAll(validImages);
            _currentImageIndex = _selectedImages.length - 1;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check, color: Colors.white),
                  const SizedBox(width: 12),
                  Text('Added ${validImages.length} photos!'),
                ],
              ),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        
        if (oversizedCount > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$oversizedCount image(s) were too large (over 10MB) and skipped.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      _showErrorSnackBar('Error selecting images: $e');
    }
  }

  Future<void> _analyzeImages() async {
    if (_selectedImages.isEmpty || _isAnalyzing) return;

    setState(() {
      _isAnalyzing = true;
    });

    try {
      final userContext = _contextDescriptionController.text.trim().isNotEmpty 
          ? _contextDescriptionController.text.trim() 
          : null;

      final result = await GeminiService.analyzeMultipleImages(
        _selectedImages,
        userDescription: userContext,
      );
      
      setState(() {
        _analysisResult = result;
        _isAnalyzing = false;
      });

      // Auto-fill form with AI suggestions
      if (_itemNameController.text.isEmpty) {
        _itemNameController.text = result.title;
      }
      if (_descriptionController.text.isEmpty) {
        _descriptionController.text = result.description;
      }
      
      // Show success with detailed feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.white),
                    const SizedBox(width: 8),
                    const Text('AI Analysis Complete!'),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Identified: ${result.title} (${result.category})',
                  style: const TextStyle(fontSize: 12),
                ),
                if (result.tags.isNotEmpty)
                  Text(
                    'Tags: ${result.tags.take(3).join(', ')}...',
                    style: const TextStyle(fontSize: 12),
                  ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
      });
      
      String errorMessage = 'AI analysis failed';
      IconData errorIcon = Icons.error;
      
      if (e.toString().contains('API key not configured')) {
        errorMessage = 'AI unavailable: Setup required. Fill details manually.';
        errorIcon = Icons.settings;
      } else if (e.toString().contains('quota exceeded')) {
        errorMessage = 'AI temporarily unavailable: Quota exceeded.';
        errorIcon = Icons.schedule;
      } else if (e.toString().contains('invalid')) {
        errorMessage = 'AI configuration error. Please check setup.';
        errorIcon = Icons.warning;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(errorIcon, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
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
    // Enhanced validation with better user feedback
    if (_selectedImages.isEmpty) {
      _showErrorSnackBar('Please add at least one photo of your donation item');
      return;
    }
    
    if (_itemNameController.text.trim().isEmpty) {
      _showErrorSnackBar('Please enter the name of the item you want to donate');
      return;
    }
    
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Prevent multiple concurrent uploads
    if (_isUploading) {
      return;
    }

    setState(() {
      _isUploading = true;
    });
    
    _uploadAnimationController.forward();

    try {
      final currentUser = context.read<SupabaseAppState>().currentUser;
      if (currentUser == null) {
        _showErrorSnackBar('Please log in to upload donations');
        setState(() => _isUploading = false);
        _uploadAnimationController.reset();
        return;
      }

      String imageUrl = '';
      
      // Try to upload image to Supabase Storage, fallback to local storage if it fails
      try {
        final imageFile = _selectedImages.first;
        final imageExtension = imageFile.path.split('.').last;
        final imagePath = '${currentUser.id}/${DateTime.now().millisecondsSinceEpoch}.$imageExtension';
        
        if (kDebugMode) {
          print('Attempting to upload image to path: $imagePath');
        }
        
        final uploadResult = await Supabase.instance.client.storage
            .from('donations')
            .upload(imagePath, imageFile);
        
        if (kDebugMode) {
          print('Upload result: $uploadResult');
        }
        
        imageUrl = Supabase.instance.client.storage
            .from('donations')
            .getPublicUrl(imagePath);
            
        if (kDebugMode) {
          print('Generated image URL: $imageUrl');
        }
      } catch (storageError) {
        if (kDebugMode) {
          print('Storage upload failed: $storageError');
        }
        
        // Fallback: use local file path if storage upload fails
        imageUrl = _selectedImages.first.path;
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Note: Image stored locally. Online backup unavailable.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }

      // Create a new Donation object
      final newDonation = Donation(
        id: '', // ID will be generated by Supabase
        donorId: currentUser.id,
        itemName: _itemNameController.text.trim(),
        description: _descriptionController.text.trim(),
        contextDescription: _contextDescriptionController.text.trim().isNotEmpty 
            ? _contextDescriptionController.text.trim() 
            : null,
        tags: _analysisResult?.tags ?? [],
        imageUrl: imageUrl,
        city: currentUser.city ?? 'Unknown',
        status: DonationStatus.available, // Changed from pendingMatch to available
        createdAt: DateTime.now(),
      );

      if (kDebugMode) {
        print('Creating donation: ${newDonation.itemName}');
      }

      // Add donation to Supabase database via the provider
      final createdDonation = await context.read<SupabaseAppState>().addDonation(newDonation);

      if (kDebugMode) {
        print('Donation created with ID: ${createdDonation.id}');
      }

      // Find matches (simplified to prevent crashes)
      final availableNeeds = context.read<SupabaseAppState>().getAvailableNeeds();
      List<app_match.Match> matches = [];
      
      try {
        if (availableNeeds.isNotEmpty) {
          matches = MatchingService.findMatches(createdDonation, availableNeeds);
          
          // Add matches to app state
          for (final match in matches) {
            context.read<SupabaseAppState>().addMatch(match);
          }
        } else {
          if (kDebugMode) {
            print('No available needs to match against');
          }
        }
      } catch (matchingError) {
        if (kDebugMode) {
          print('Error finding matches: $matchingError');
        }
        // Continue without matches if matching service fails
      }

      // Update donation status only if we have successful matches
      if (matches.isNotEmpty && availableNeeds.isNotEmpty) {
        try {
          // Find the need that was matched
          final matchedNeed = availableNeeds.where((n) => n.id == matches.first.needId).firstOrNull;
          
          final updatedDonation = createdDonation.copyWith(
            status: DonationStatus.matchFound,
            matchedAt: DateTime.now(),
            matchedRecipientId: matches.first.recipientId,
            matchedRecipientName: matchedNeed?.recipientName ?? 'Unknown',
          );
          await context.read<SupabaseAppState>().updateDonation(createdDonation.id, updatedDonation);
        } catch (updateError) {
          if (kDebugMode) {
            print('Error updating donation status: $updateError');
          }
          // Continue even if status update fails
        }
      }

      // Show success with match info
      final matchCount = matches.length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.celebration, color: Colors.white),
                    SizedBox(width: 8),
                    Text('Donation uploaded successfully!'),
                  ],
                ),
                if (matchCount > 0) ...[
                  const SizedBox(height: 4),
                  Text(
                    '🎯 Found $matchCount potential match${matchCount > 1 ? 'es' : ''}!',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ],
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }

      // Navigate back after short delay
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        // Use Navigator.pop instead of pushing to avoid navigation stack issues
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error in _uploadDonation: $e');
        print('Stack trace: ${StackTrace.current}');
      }
      
      // Provide user-friendly error messages
      String errorMessage = 'Failed to upload donation';
      
      if (e.toString().contains('network') || e.toString().contains('connection')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().contains('auth') || e.toString().contains('unauthorized')) {
        errorMessage = 'Authentication error. Please log in again and try.';
      } else if (e.toString().contains('storage') || e.toString().contains('upload')) {
        errorMessage = 'Image upload failed. Please try again or use a different image.';
      } else if (e.toString().contains('database') || e.toString().contains('insert')) {
        errorMessage = 'Database error. Please try again later.';
      }
      
      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        _uploadAnimationController.reset();
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
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
        elevation: 0,
        actions: [
          if (_selectedImages.isNotEmpty && !_isUploading)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Clear all images',
              onPressed: () {
                setState(() {
                  _selectedImages.clear();
                  _analysisResult = null;
                  _currentImageIndex = 0;
                });
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Progress indicator
            if (_isUploading)
              AnimatedBuilder(
                animation: _uploadAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _uploadAnimation.value,
                    backgroundColor: Colors.grey[200],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  );
                },
              ),
            
            // Main content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Upload Section
                    _buildEnhancedImageSection(),
                    const SizedBox(height: 24),

                    // Context Description Field
                    if (_selectedImages.isNotEmpty) ...[
                      _buildContextField(),
                      const SizedBox(height: 20),
                    ],

                    // AI Analysis Button
                    if (_selectedImages.isNotEmpty) ...[
                      _buildAnalysisButton(),
                      const SizedBox(height: 24),
                    ],

                    // AI Analysis Results
                    if (_analysisResult != null) ...[
                      _buildEnhancedAnalysisResults(),
                      const SizedBox(height: 24),
                    ],

                    // Matching Requests
                    if (_analysisResult != null) ...[
                      _buildEnhancedMatchingRequests(),
                      const SizedBox(height: 24),
                    ],

                    // Form Fields
                    _buildFormFields(),
                    const SizedBox(height: 32),

                    // Upload Button
                    _buildUploadButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.camera_alt,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Item Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Take clear photos from different angles for better AI analysis',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        
        if (_selectedImages.isEmpty)
          _buildImageUploadPrompt()
        else
          _buildImageCarousel(),
      ],
    );
  }

  Widget _buildImageUploadPrompt() {
    return Container(
      width: double.infinity,
      height: 240,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.primary.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_a_photo,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add Photos of Your Donation',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Multiple angles help AI identify your item better',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildImageSourceButton(
                icon: Icons.camera_alt,
                label: 'Camera',
                onPressed: () => _pickImage(ImageSource.camera),
                isPrimary: true,
              ),
              _buildImageSourceButton(
                icon: Icons.photo_library,
                label: 'Gallery',
                onPressed: _pickMultipleImages,
                isPrimary: false,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary 
            ? Theme.of(context).colorScheme.primary
            : Colors.grey[600],
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildImageCarousel() {
    return Column(
      children: [
        // Main image display with enhanced UI
        Stack(
          children: [
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _selectedImages[_currentImageIndex],
                  fit: BoxFit.cover,
                ),
              ),
            ),
            
            // Analysis overlay
            if (_isAnalyzing)
              Container(
                width: double.infinity,
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'AI is analyzing your photos...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Processing ${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Image counter
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1} / ${_selectedImages.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            
            // Navigation arrows
            if (_selectedImages.length > 1) ...[
              if (_currentImageIndex > 0)
                Positioned(
                  left: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _currentImageIndex--;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
              if (_currentImageIndex < _selectedImages.length - 1)
                Positioned(
                  right: 12,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () {
                          setState(() {
                            _currentImageIndex++;
                          });
                        },
                        icon: const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            
            // Remove current image button
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
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
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        // Thumbnails and add button
        const SizedBox(height: 16),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _selectedImages.length + 1,
            itemBuilder: (context, index) {
              if (index == _selectedImages.length) {
                return _buildAddMoreButton();
              }
              return _buildThumbnail(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(int index) {
    final isSelected = index == _currentImageIndex;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentImageIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected ? [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              Image.file(
                _selectedImages[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                top: 4,
                right: 4,
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
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 80,
      height: 80,
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _pickMultipleImages,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
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
                  size: 32,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          GestureDetector(
            onTap: () => _pickImage(ImageSource.camera),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.camera_alt,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextField() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.psychology_outlined,
                color: Colors.blue[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Help AI Understand Better',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contextDescriptionController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Provide context: size (XL, 32"), condition (new, gently used), brand, special features, intended use...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue.withOpacity(0.3)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.blue, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '💡 Example: "XL men\'s winter jacket, North Face brand, excellent condition, bought last year"',
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisButton() {
    final hasContext = _contextDescriptionController.text.trim().isNotEmpty;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isAnalyzing ? null : _analyzeImages,
        icon: _isAnalyzing 
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Icon(hasContext ? Icons.auto_awesome : Icons.psychology),
        label: Text(_isAnalyzing 
            ? 'AI is analyzing...' 
            : hasContext
                ? 'Analyze with AI + Your Context'
                : 'Analyze with AI'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: hasContext ? 4 : 2,
        ),
      ),
    );
  }

  Widget _buildEnhancedAnalysisResults() {
    if (_analysisResult == null) return const SizedBox.shrink();
    
    final hasUserContext = _contextDescriptionController.text.trim().isNotEmpty;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF2E7D32).withOpacity(0.1),
            const Color(0xFF2E7D32).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2E7D32).withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF2E7D32),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'AI Analysis Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const Spacer(),
              if (hasUserContext)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Context Applied:',
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
          
          const SizedBox(height: 16),
          
          _buildAnalysisItem('Item', _analysisResult!.title, Icons.inventory),
          _buildAnalysisItem('Description', _analysisResult!.description, Icons.description),
          _buildAnalysisItem('Category', _analysisResult!.category, Icons.category),
          _buildAnalysisItem('Condition', _analysisResult!.condition, Icons.star_rate),
          
          if (_analysisResult!.size.isNotEmpty)
            _buildAnalysisItem('Size/Details', _analysisResult!.size, Icons.straighten),
          
          _buildAnalysisItem('Target Audience', _analysisResult!.targetAudience, Icons.people),
          _buildAnalysisItem('Seasonality', _analysisResult!.seasonality, Icons.wb_sunny),
          _buildAnalysisItem('Urgency Level', _analysisResult!.urgencyLevel, Icons.priority_high),
          
          const SizedBox(height: 16),
          
          const Text(
            'Suggested Tags:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _analysisResult!.tags.map((tag) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  tag,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

  Widget _buildAnalysisItem(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMatchingRequests() {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, child) {
        final availableNeeds = appState.getAvailableNeeds();
        final matchingNeeds = _findMatchingNeeds(availableNeeds);
        
        if (matchingNeeds.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.orange.withOpacity(0.1),
                Colors.orange.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.orange.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Perfect Matches Found!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎯 Your donation matches ${matchingNeeds.length} existing request${matchingNeeds.length != 1 ? 's' : ''}! These people really need what you\'re offering.',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 16),
              ...matchingNeeds.take(3).map((need) => _buildEnhancedMatchingNeedCard(need)),
              if (matchingNeeds.length > 3) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '... and ${matchingNeeds.length - 3} more matching requests waiting for your donation!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEnhancedMatchingNeedCard(Need need) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  need.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getUrgencyColor(need.urgency).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _getUrgencyText(need.urgency),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _getUrgencyColor(need.urgency),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            need.description,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
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
              Text(
                'Match Score: ${(_calculateNeedMatchScore(need) * 100).round()}%',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Need> _findMatchingNeeds(List<Need> needs) {
    if (_analysisResult == null) return [];
    
    List<Need> matches = [];
    for (var need in needs) {
      double score = _calculateNeedMatchScore(need);
      if (score > 0.4) {
        matches.add(need);
      }
    }
    
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
        return 'Low Priority';
      case UrgencyLevel.medium:
        return 'Medium';
      case UrgencyLevel.high:
        return 'High Priority';
      case UrgencyLevel.urgent:
        return 'URGENT';
    }
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // Item Name Field
        TextFormField(
          controller: _itemNameController,
          decoration: InputDecoration(
            labelText: 'Item Name *',
            hintText: 'Enter the name of the item',
            prefixIcon: const Icon(Icons.inventory),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter item name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),

        // Description Field (Optional)
        TextFormField(
          controller: _descriptionController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details (Optional)',
            hintText: 'Add any extra details not covered by AI analysis',
            prefixIcon: const Icon(Icons.description),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadButton() {
    // Check if form can be submitted
    final bool canSubmit = _selectedImages.isNotEmpty && 
                          _itemNameController.text.trim().isNotEmpty &&
                          !_isUploading;
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: canSubmit ? _uploadDonation : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isUploading 
              ? Colors.grey[400] 
              : canSubmit
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey[400],
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: canSubmit && !_isUploading ? 4 : 0,
        ),
        child: _isUploading
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(width: 16),
                  AnimatedBuilder(
                    animation: _uploadAnimation,
                    builder: (context, child) {
                      return Text(
                        _uploadAnimation.value < 0.3 
                            ? 'Uploading donation...'
                            : _uploadAnimation.value < 0.7
                                ? 'Finding matches...'
                                : 'Almost done...',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      );
                    },
                  ),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.upload),
                  const SizedBox(width: 8),
                  Text(
                    _selectedImages.isEmpty 
                        ? 'Add Photos First'
                        : _itemNameController.text.trim().isEmpty
                            ? 'Enter Item Name'
                            : 'Upload Donation',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
