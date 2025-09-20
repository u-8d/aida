import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/supabase_user.dart';
import '../../providers/supabase_app_state.dart';
import '../../services/profile_service.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _bioController = TextEditingController();
  
  bool _isLoading = false;
  bool _isUploadingImage = false;
  SupabaseUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUser() async {
    final appState = context.read<SupabaseAppState>();
    final userId = appState.currentUser?.id;
    
    if (userId != null) {
      try {
        final user = await ProfileService.getUserProfile(userId);
        setState(() {
          _currentUser = user;
          _nameController.text = user.name;
          _phoneController.text = user.phone ?? '';
          _cityController.text = user.city ?? '';
          _bioController.text = user.bio ?? '';
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading profile: $e')),
        );
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 80,
    );

    if (pickedFile == null) return;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileName = pickedFile.name;
      final userId = _currentUser!.id;

      final imageUrl = await ProfileService.uploadProfilePicture(
        userId,
        bytes,
        fileName,
      );

      setState(() {
        _currentUser = _currentUser!.copyWith(
          profilePictureUrl: imageUrl,
          isVerified: true, // Auto-verify when profile picture is uploaded
        );
      });

      // Update the app state
      final appState = context.read<SupabaseAppState>();
      appState.updateCurrentUser(_currentUser!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile picture updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedUser = _currentUser!.copyWith(
        name: _nameController.text,
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        city: _cityController.text.isNotEmpty ? _cityController.text : null,
        bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      );

      await ProfileService.updateUserProfile(updatedUser);

      setState(() {
        _currentUser = updatedUser;
      });

      // Update the app state
      final appState = context.read<SupabaseAppState>();
      appState.updateCurrentUser(updatedUser);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile Settings')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _updateProfile,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Picture Section
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: _currentUser!.profilePictureUrl != null
                              ? NetworkImage(_currentUser!.profilePictureUrl!)
                              : null,
                          child: _currentUser!.profilePictureUrl == null
                              ? Icon(Icons.person, size: 60)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: _isUploadingImage
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Icon(Icons.camera_alt, color: Colors.white),
                              onPressed: _isUploadingImage ? null : _pickAndUploadImage,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _currentUser!.isVerified ? 'Verified Profile' : 'Unverified Profile',
                          style: TextStyle(
                            color: _currentUser!.isVerified ? Colors.green : Colors.orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_currentUser!.isVerified) ...[
                          SizedBox(width: 4),
                          Icon(Icons.verified, color: Colors.green, size: 16),
                        ],
                      ],
                    ),
                    if (!_currentUser!.isVerified) ...[
                      SizedBox(height: 4),
                      Text(
                        'Upload a profile picture to get verified',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              SizedBox(height: 32),
              
              // Form Fields
              Text(
                'Profile Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_city),
                ),
              ),
              
              SizedBox(height: 16),
              
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Tell others about yourself...',
                ),
                maxLines: 3,
                maxLength: 500,
              ),
              
              SizedBox(height: 24),
              
              // Account Information (Read-only)
              Text(
                'Account Information',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              SizedBox(height: 16),
              
              _buildReadOnlyField('Email', _currentUser!.email),
              SizedBox(height: 12),
              _buildReadOnlyField('User Type', _currentUser!.userType.toUpperCase()),
              SizedBox(height: 12),
              _buildReadOnlyField('Member Since', 
                  '${_currentUser!.createdAt.day}/${_currentUser!.createdAt.month}/${_currentUser!.createdAt.year}'),
              
              SizedBox(height: 32),
              
              // Statistics
              Text(
                'Profile Statistics',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.favorite, color: Colors.red, size: 32),
                            SizedBox(height: 8),
                            Text(
                              _currentUser!.endorsementCount.toString(),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('Endorsements'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.verified_user, 
                                color: _currentUser!.isVerified ? Colors.green : Colors.grey, 
                                size: 32),
                            SizedBox(height: 8),
                            Text(
                              _currentUser!.isVerified ? 'Yes' : 'No',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text('Verified'),
                          ],
                        ),
                      ),
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

  Widget _buildReadOnlyField(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
        Expanded(
          child: Text(value),
        ),
      ],
    );
  }
}
