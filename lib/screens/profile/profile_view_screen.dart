import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/supabase_user.dart';
import '../../models/donation.dart';
import '../../models/need.dart';
import '../../providers/supabase_app_state.dart';
import '../../services/profile_service.dart';
import '../donor/donation_details_screen.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? userName; // Optional, for display while loading

  const ProfileViewScreen({
    Key? key,
    required this.userId,
    this.userName,
  }) : super(key: key);

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SupabaseUser? _user;
  List<Donation> _userDonations = [];
  List<Need> _userNeeds = [];
  bool _isLoading = true;
  bool _hasEndorsed = false;
  bool _isLoadingEndorsement = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProfileData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appState = context.read<SupabaseAppState>();
      
      // Load user profile
      final user = await ProfileService.getUserProfile(widget.userId);
      
      // Load user's donations
      final donations = appState.donations
          .where((d) => d.donorId == widget.userId)
          .toList();
      
      // Load user's needs
      final needs = appState.needs
          .where((n) => n.recipientId == widget.userId)
          .toList();
      
      // Check if current user has endorsed this profile
      final currentUserId = appState.currentUser?.id;
      bool hasEndorsed = false;
      if (currentUserId != null) {
        hasEndorsed = await ProfileService.hasUserEndorsed(currentUserId, widget.userId);
      }
      
      setState(() {
        _user = user;
        _userDonations = donations;
        _userNeeds = needs;
        _hasEndorsed = hasEndorsed;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleEndorsement() async {
    final appState = context.read<SupabaseAppState>();
    final currentUserId = appState.currentUser?.id;
    
    if (currentUserId == null || currentUserId == widget.userId) return;
    
    setState(() {
      _isLoadingEndorsement = true;
    });

    try {
      if (_hasEndorsed) {
        await ProfileService.removeEndorsement(currentUserId, widget.userId);
      } else {
        await ProfileService.addEndorsement(currentUserId, widget.userId);
      }
      
      setState(() {
        _hasEndorsed = !_hasEndorsed;
        if (_user != null) {
          _user = _user!.copyWith(
            endorsementCount: _hasEndorsed 
                ? _user!.endorsementCount + 1 
                : _user!.endorsementCount - 1
          );
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating endorsement: $e')),
      );
    } finally {
      setState(() {
        _isLoadingEndorsement = false;
      });
    }
  }

  Future<void> _showReportDialog() async {
    final appState = context.read<SupabaseAppState>();
    final currentUserId = appState.currentUser?.id;
    
    if (currentUserId == null || currentUserId == widget.userId) return;

    String selectedReason = 'inappropriate_content';
    String description = '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Report User'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Why are you reporting this user?'),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  border: OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(value: 'inappropriate_content', child: Text('Inappropriate Content')),
                  DropdownMenuItem(value: 'spam', child: Text('Spam')),
                  DropdownMenuItem(value: 'harassment', child: Text('Harassment')),
                  DropdownMenuItem(value: 'fake_profile', child: Text('Fake Profile')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Description (optional)',
                  border: OutlineInputBorder(),
                  hintText: 'Provide additional details...',
                ),
                maxLines: 3,
                onChanged: (value) => description = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text('Report'),
          ),
        ],
      ),
    );

    if (result == true) {
      try {
        await ProfileService.reportUser(
          currentUserId,
          widget.userId,
          selectedReason,
          description.isNotEmpty ? description : null,
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report submitted successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error submitting report: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<SupabaseAppState>();
    final currentUserId = appState.currentUser?.id;
    final isOwnProfile = currentUserId == widget.userId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.userName ?? 'Profile'),
        actions: [
          if (!isOwnProfile && !_isLoading && _user != null) ...[
            IconButton(
              icon: Icon(
                _hasEndorsed ? Icons.favorite : Icons.favorite_border,
                color: _hasEndorsed ? Colors.red : null,
              ),
              onPressed: _isLoadingEndorsement ? null : _toggleEndorsement,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.report, color: Colors.red),
                    title: Text('Report User'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                }
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text('Error loading profile'),
                      Text(_error!, style: TextStyle(color: Colors.grey)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadProfileData,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _user == null
                  ? Center(child: Text('User not found'))
                  : Column(
                      children: [
                        // Profile Header
                        Container(
                          padding: EdgeInsets.all(16),
                          color: Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Column(
                            children: [
                              // Profile Picture
                              CircleAvatar(
                                radius: 50,
                                backgroundImage: _user!.profilePictureUrl != null
                                    ? NetworkImage(_user!.profilePictureUrl!)
                                    : null,
                                child: _user!.profilePictureUrl == null
                                    ? Icon(Icons.person, size: 50)
                                    : null,
                              ),
                              SizedBox(height: 16),
                              
                              // Name and Verification
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _user!.name,
                                    style: Theme.of(context).textTheme.headlineSmall,
                                  ),
                                  if (_user!.isVerified) ...[
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.verified,
                                      color: Colors.blue,
                                      size: 20,
                                    ),
                                  ],
                                ],
                              ),
                              
                              // User Type and City
                              SizedBox(height: 8),
                              Text(
                                '${_user!.userType.toUpperCase()}${_user!.city != null ? ' • ${_user!.city}' : ''}',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                              
                              // Bio
                              if (_user!.bio != null) ...[
                                SizedBox(height: 12),
                                Text(
                                  _user!.bio!,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                              
                              // Stats
                              SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStatItem(
                                    'Donations',
                                    _userDonations.length.toString(),
                                    Icons.volunteer_activism,
                                  ),
                                  _buildStatItem(
                                    'Needs',
                                    _userNeeds.length.toString(),
                                    Icons.help_outline,
                                  ),
                                  _buildStatItem(
                                    'Endorsements',
                                    _user!.endorsementCount.toString(),
                                    Icons.favorite,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        
                        // Tabs
                        TabBar(
                          controller: _tabController,
                          tabs: [
                            Tab(text: 'Donations (${_userDonations.length})'),
                            Tab(text: 'Needs (${_userNeeds.length})'),
                            Tab(text: 'About'),
                          ],
                        ),
                        
                        // Tab Content
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              _buildDonationsTab(),
                              _buildNeedsTab(),
                              _buildAboutTab(),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).primaryColor),
        SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildDonationsTab() {
    if (_userDonations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.volunteer_activism_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No donations yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _userDonations.length,
      itemBuilder: (context, index) {
        final donation = _userDonations[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundImage: donation.imageUrl.isNotEmpty
                  ? NetworkImage(donation.imageUrl)
                  : null,
              child: donation.imageUrl.isEmpty
                  ? Icon(Icons.card_giftcard)
                  : null,
            ),
            title: Text(donation.itemName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(donation.description),
                SizedBox(height: 4),
                Text(
                  'Status: ${donation.status.name.toUpperCase()}',
                  style: TextStyle(
                    color: donation.status == DonationStatus.available
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => DonationDetailsScreen(donation: donation),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNeedsTab() {
    if (_userNeeds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.help_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No needs posted yet'),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _userNeeds.length,
      itemBuilder: (context, index) {
        final need = _userNeeds[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getUrgencyColor(need.urgency),
              child: Icon(
                Icons.help_outline,
                color: Colors.white,
              ),
            ),
            title: Text(need.title),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(need.description),
                SizedBox(height: 4),
                Text(
                  'Urgency: ${need.urgency.name.toUpperCase()}',
                  style: TextStyle(
                    color: _getUrgencyColor(need.urgency),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 16),
          
          _buildInfoRow('Email', _user!.email),
          _buildInfoRow('Phone', _user!.phone ?? 'Not provided'),
          _buildInfoRow('City', _user!.city ?? 'Not specified'),
          _buildInfoRow('User Type', _user!.userType.toUpperCase()),
          _buildInfoRow('Verified', _user!.isVerified ? 'Yes' : 'No'),
          _buildInfoRow('Member Since', 
              '${_user!.createdAt.day}/${_user!.createdAt.month}/${_user!.createdAt.year}'),
          
          if (_user!.bio != null) ...[
            SizedBox(height: 20),
            Text(
              'Bio',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 8),
            Text(_user!.bio!),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
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
          Expanded(child: Text(value)),
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
}
