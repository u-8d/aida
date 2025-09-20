import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:aida2/providers/supabase_app_state.dart';
import '../../models/donation.dart';
import '../../models/match.dart';
import '../../models/need.dart';
import '../../widgets/universal_image.dart';
import '../../services/gemini_service.dart';

class DonationDetailsScreen extends StatefulWidget {
  final Donation donation;

  const DonationDetailsScreen({
    super.key,
    required this.donation,
  });

  @override
  State<DonationDetailsScreen> createState() => _DonationDetailsScreenState();
}

class _DonationDetailsScreenState extends State<DonationDetailsScreen> {
  bool _isSearchingMatches = false;

  @override
  void initState() {
    super.initState();
    // Automatically find matches when the screen loads
    _findMatchesForDonation();
  }

  // Method to find and create matches for this specific donation
  void _findMatchesForDonation() async {
    setState(() {
      _isSearchingMatches = true;
    });

    try {
      final appState = context.read<SupabaseAppState>();
      
      // Ensure we have diverse mock needs for better matching
      _ensureExtendedMockNeeds(appState);
      
      // Create matches for this donation if they don't exist
      await _createMatchesForDonation(appState, widget.donation);
      
      await Future.delayed(const Duration(milliseconds: 1500)); // Simulate processing time
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error finding matches: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSearchingMatches = false;
        });
      }
    }
  }

  // Ensure we have extended mock needs for better matching variety
  void _ensureExtendedMockNeeds(SupabaseAppState appState) {
    // Add more diverse mock needs if we don't have enough variety
    if (appState.needs.length < 8) {
      final additionalNeeds = _createExtendedMockNeeds();
      for (final need in additionalNeeds) {
        // Only add if not already present
        if (!appState.needs.any((n) => n.id == need.id)) {
          appState.needs.add(need);
        }
      }
      print('Added ${additionalNeeds.length} additional mock needs for better matching');
    }
  }

  // Create additional mock needs for more diverse matching
  List<Need> _createExtendedMockNeeds() {
    return [
      Need(
        id: 'need_extended_1',
        recipientId: 'ext_ngo_1',
        recipientName: 'Hope Children Center',
        recipientType: 'ngo',
        title: 'Electronics and Gadgets for Digital Learning',
        description: 'Old laptops, tablets, or phones for digital literacy program',
        requiredTags: ['electronics', 'laptop', 'tablet', 'phone', 'technology'],
        city: 'Mumbai',
        urgency: UrgencyLevel.medium,
        status: NeedStatus.unmet,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        quantity: 10,
      ),
      Need(
        id: 'need_extended_2',
        recipientId: 'ext_ind_1',
        recipientName: 'Anita Sharma',
        recipientType: 'individual',
        title: 'Kitchen Utensils and Cookware',
        description: 'Basic kitchen items for new home setup',
        requiredTags: ['kitchen', 'utensils', 'cookware', 'household', 'cooking'],
        city: 'Delhi',
        urgency: UrgencyLevel.high,
        status: NeedStatus.unmet,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        quantity: 5,
      ),
      Need(
        id: 'need_extended_3',
        recipientId: 'ext_ngo_2',
        recipientName: 'Senior Care Foundation',
        recipientType: 'ngo',
        title: 'Comfort Items for Elderly',
        description: 'Blankets, cushions, and comfort items for elderly care',
        requiredTags: ['blankets', 'cushions', 'comfort', 'elderly', 'soft furnishing'],
        city: 'Chennai',
        urgency: UrgencyLevel.medium,
        status: NeedStatus.unmet,
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        quantity: 25,
      ),
      Need(
        id: 'need_extended_4',
        recipientId: 'ext_ind_2',
        recipientName: 'Ramesh Kumar',
        recipientType: 'individual',
        title: 'Books and Reading Materials',
        description: 'Any books, magazines, or reading materials for children',
        requiredTags: ['books', 'reading', 'educational', 'children', 'learning'],
        city: 'Mumbai',
        urgency: UrgencyLevel.low,
        status: NeedStatus.unmet,
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        quantity: 20,
      ),
      Need(
        id: 'need_extended_5',
        recipientId: 'ext_ngo_3',
        recipientName: 'Clean Water Initiative',
        recipientType: 'ngo',
        title: 'Plastic Containers and Storage',
        description: 'Clean plastic containers for water storage in rural areas',
        requiredTags: ['containers', 'plastic', 'storage', 'water', 'household'],
        city: 'Delhi',
        urgency: UrgencyLevel.urgent,
        status: NeedStatus.unmet,
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        quantity: 50,
      ),
    ];
  }

  // Create matches for the specific donation using AI
  Future<void> _createMatchesForDonation(SupabaseAppState appState, Donation donation) async {
    // Check if matches already exist for this donation
    final existingMatches = appState.matches.where((m) => m.donationId == donation.id).toList();
    
    if (existingMatches.isNotEmpty) {
      print('Matches already exist for donation ${donation.id}');
      return; // Matches already exist
    }

    // Get all available needs (using sample data since database has 0 needs)
    final availableNeeds = appState.needs.where((need) => need.status == NeedStatus.unmet).toList();
    
    if (availableNeeds.isEmpty) {
      print('No available needs to match with');
      return;
    }

    print('Using AI to find matches for donation: ${donation.itemName}');
    print('Analyzing against ${availableNeeds.length} available needs...');
    
    try {
      // Use Gemini AI to find intelligent matches
      final aiMatches = await GeminiService.findMatches(donation, availableNeeds);
      
      if (aiMatches.isEmpty) {
        print('AI found no suitable matches for ${donation.itemName}');
        return;
      }
      
      print('AI found ${aiMatches.length} potential matches');
      
      // Convert AI matches to Match objects
      final newMatches = <Match>[];
      
      for (int i = 0; i < aiMatches.length; i++) {
        final aiMatch = aiMatches[i];
        
        // Find the corresponding need
        final need = availableNeeds.firstWhere(
          (n) => n.id == aiMatch.needId,
          orElse: () => availableNeeds.first, // Fallback to first need if not found
        );
        
        // Convert AI confidence to match status
        MatchStatus status;
        DateTime? acceptedAt;
        
        if (aiMatch.matchScore >= 0.85 && aiMatch.confidence == 'high') {
          status = i == 0 ? MatchStatus.accepted : MatchStatus.pending;
          if (status == MatchStatus.accepted) {
            acceptedAt = DateTime.now().subtract(Duration(hours: i + 1));
          }
        } else {
          status = MatchStatus.pending;
        }
        
        final match = Match(
          id: 'ai_match_${donation.id}_${need.id}_${DateTime.now().millisecondsSinceEpoch}_$i',
          donationId: donation.id,
          needId: need.id,
          donorId: donation.donorId,
          recipientId: need.recipientId,
          matchScore: aiMatch.matchScore / 100.0, // Convert percentage to 0-1 scale
          status: status,
          createdAt: DateTime.now().subtract(Duration(minutes: i * 10)),
          acceptedAt: acceptedAt,
        );
        
        newMatches.add(match);
        
        print('AI Match ${i + 1}: ${donation.itemName} -> ${need.title}');
        print('  Score: ${aiMatch.matchScore}%');
        print('  Confidence: ${aiMatch.confidence}');
        print('  Reasoning: ${aiMatch.reasoning}');
        print('  Compatibility: ${aiMatch.compatibilityFactors.join(', ')}');
        if (aiMatch.potentialConcerns.isNotEmpty) {
          print('  Concerns: ${aiMatch.potentialConcerns.join(', ')}');
        }
      }

      // Add the new matches to the app state
      for (final match in newMatches) {
        appState.matches.add(match);
      }
      
      if (newMatches.isNotEmpty) {
        // Trigger UI update
        if (mounted) {
          setState(() {});
        }
        print('✅ Created ${newMatches.length} AI-powered matches for donation ${donation.id}');
      }
      
    } catch (e) {
      print('❌ AI matching failed, falling back to basic matching: $e');
      
      // Fallback to basic matching if AI fails
      await _createBasicMatches(appState, donation, availableNeeds);
    }
  }

  // Fallback method for basic matching when AI fails
  Future<void> _createBasicMatches(SupabaseAppState appState, Donation donation, List<Need> availableNeeds) async {
    final newMatches = <Match>[];
    
    // Sort needs by basic compatibility score
    final scoredNeeds = availableNeeds.map((need) {
      final score = _calculateMatchScore(donation, need);
      return {'need': need, 'score': score};
    }).toList();
    
    scoredNeeds.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    // Create matches for top scoring needs (up to 3)
    for (int i = 0; i < scoredNeeds.length && newMatches.length < 3; i++) {
      final needData = scoredNeeds[i];
      final need = needData['need'] as Need;
      final matchScore = needData['score'] as double;
      
      if (matchScore > 0.4) {
        final match = Match(
          id: 'basic_match_${donation.id}_${need.id}_${DateTime.now().millisecondsSinceEpoch}_$i',
          donationId: donation.id,
          needId: need.id,
          donorId: donation.donorId,
          recipientId: need.recipientId,
          matchScore: matchScore,
          status: MatchStatus.pending,
          createdAt: DateTime.now().subtract(Duration(minutes: i * 15)),
        );
        
        newMatches.add(match);
        print('Basic match: ${donation.itemName} -> ${need.title} (${(matchScore * 100).toInt()}%)');
      }
    }

    // Add the new matches to the app state
    for (final match in newMatches) {
      appState.matches.add(match);
    }
    
    if (newMatches.isNotEmpty && mounted) {
      setState(() {});
      print('Created ${newMatches.length} basic matches as fallback');
    }
  }

  // Calculate match score between donation and need
  double _calculateMatchScore(Donation donation, Need need) {
    double score = 0.0;
    
    // Base score for any match
    score += 0.2;
    
    // City match bonus (very important)
    if (donation.city.toLowerCase() == need.city.toLowerCase()) {
      score += 0.4;
    } else {
      // Penalty for different cities, but still possible
      score += 0.1;
    }
    
    // Tag matching (most important factor)
    final donationTags = donation.tags.map((t) => t.toLowerCase().trim()).toSet();
    final needTags = need.requiredTags.map((t) => t.toLowerCase().trim()).toSet();
    final commonTags = donationTags.intersection(needTags);
    
    if (commonTags.isNotEmpty) {
      // Strong bonus for exact tag matches
      score += (commonTags.length / needTags.length) * 0.5;
      
      // Additional bonus if donation has all required tags
      if (commonTags.length == needTags.length) {
        score += 0.2;
      }
    } else {
      // Check for semantic matches (clothing, electronics, etc.)
      if (_hasSemanticMatch(donationTags, needTags)) {
        score += 0.2;
      }
    }
    
    // Urgency factor (higher urgency needs get priority)
    switch (need.urgency) {
      case UrgencyLevel.urgent:
        score += 0.15;
        break;
      case UrgencyLevel.high:
        score += 0.1;
        break;
      case UrgencyLevel.medium:
        score += 0.05;
        break;
      case UrgencyLevel.low:
        score += 0.02;
        break;
    }
    
    // Recent need bonus (newer needs get slight priority)
    final daysSinceCreated = DateTime.now().difference(need.createdAt).inDays;
    if (daysSinceCreated <= 3) {
      score += 0.1;
    } else if (daysSinceCreated <= 7) {
      score += 0.05;
    }
    
    // Recipient type consideration
    if (need.recipientType == 'ngo') {
      score += 0.05; // Slight bonus for NGOs (they help more people)
    }
    
    // Apply some randomness to make it feel more realistic
    final randomFactor = (DateTime.now().millisecond % 10) / 100.0; // 0.00 to 0.09
    score += randomFactor;
    
    // Clamp score between 0 and 1
    return score.clamp(0.0, 1.0);
  }
  
  // Check for semantic matches between tags
  bool _hasSemanticMatch(Set<String> donationTags, Set<String> needTags) {
    // Define semantic groups
    final clothingKeywords = {'clothing', 'coat', 'jacket', 'shirt', 'pants', 'dress', 'uniform', 'winter', 'summer'};
    final educationKeywords = {'educational', 'school', 'book', 'notebook', 'pen', 'pencil', 'toy', 'learning'};
    final foodKeywords = {'food', 'canned', 'supplies', 'nutrition', 'meal', 'snack'};
    final medicalKeywords = {'medicine', 'medical', 'health', 'first aid', 'bandage'};
    final electronicKeywords = {'electronic', 'computer', 'laptop', 'phone', 'tablet', 'device'};
    
    final semanticGroups = [clothingKeywords, educationKeywords, foodKeywords, medicalKeywords, electronicKeywords];
    
    for (final group in semanticGroups) {
      final donationInGroup = donationTags.any((tag) => group.any((keyword) => tag.contains(keyword)));
      final needInGroup = needTags.any((tag) => group.any((keyword) => tag.contains(keyword)));
      
      if (donationInGroup && needInGroup) {
        return true;
      }
    }
    
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Donation Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmationDialog(context);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete Donation', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<SupabaseAppState>(
        builder: (context, appState, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Image
                Container(
                  width: double.infinity,
                  height: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey[100],
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildDonationImage(widget.donation.imageUrl),
                  ),
                ),
                const SizedBox(height: 20),

                // Item Details
                _buildDetailCard(
                  title: 'Item Information',
                  children: [
                    _buildDetailRow('Name', widget.donation.itemName),
                    _buildDetailRow('Description', widget.donation.description),
                    if (widget.donation.contextDescription != null && widget.donation.contextDescription!.isNotEmpty)
                      _buildDetailRow('Context Provided', widget.donation.contextDescription!, 
                        isContext: true),
                    _buildDetailRow('City', widget.donation.city),
                    _buildDetailRow('Status', _getStatusText(widget.donation.status)),
                    _buildDetailRow('Created', _formatDate(widget.donation.createdAt)),
                  ],
                ),
                const SizedBox(height: 16),

                // Tags
                if (widget.donation.tags.isNotEmpty) ...[
                  _buildDetailCard(
                    title: 'Tags',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: widget.donation.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Current Matches (if any)
                _buildCurrentMatchesCard(context, appState),
                const SizedBox(height: 16),

                // Actions
                if (widget.donation.status == DonationStatus.available)
                  _buildActionButtons(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isContext = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Row(
              children: [
                if (isContext) ...[
                  Icon(
                    Icons.psychology_outlined,
                    size: 14,
                    color: Colors.blue[600],
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: Text(
                    '$label:',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: isContext ? Colors.blue[600] : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: isContext ? const EdgeInsets.all(8) : EdgeInsets.zero,
              decoration: isContext ? BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ) : null,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: isContext ? FontStyle.italic : FontStyle.normal,
                  color: isContext ? Colors.blue[700] : null,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement edit functionality
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Edit functionality coming soon!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      _showCancelDialog(context);
                    },
                    icon: const Icon(Icons.cancel),
                    label: const Text('Cancel'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Donation'),
        content: const Text('Are you sure you want to cancel this donation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              // TODO: Implement cancel functionality
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Donation cancelled'),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  String _getStatusText(DonationStatus status) {
    switch (status) {
      case DonationStatus.available:
        return 'Available';
      case DonationStatus.pendingMatch:
        return 'Pending Match';
      case DonationStatus.matchFound:
        return 'Match Found';
      case DonationStatus.readyForPickup:
        return 'Ready for Pickup';
      case DonationStatus.donationCompleted:
        return 'Completed';
      case DonationStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildDonationImage(String imageUrl) {
    return UniversalImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }

  Widget _buildCurrentMatchesCard(BuildContext context, SupabaseAppState appState) {
    // Get matches for this donation
    final matches = appState.matches.where((match) => match.donationId == widget.donation.id).toList();
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.handshake,
                    color: Colors.green[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Current Matches',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ),
                if (matches.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${matches.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            
            if (matches.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    if (_isSearchingMatches) ...[
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Finding matches...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Analyzing compatibility with available needs',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ] else ...[
                      Icon(
                        Icons.search_off,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No matches found yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'We automatically searched for recipients who need this item',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _isSearchingMatches ? null : () {
                          _findMatchesForDonation();
                        },
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Search Again'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else ...[
              ...matches.take(3).map((match) => _buildMatchPreview(context, appState, match)),
              if (matches.length > 3) ...[
                const SizedBox(height: 12),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      _showAllMatches(context, matches);
                    },
                    icon: const Icon(Icons.visibility),
                    label: Text('View all ${matches.length} matches'),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchPreview(BuildContext context, SupabaseAppState appState, Match match) {
    try {
      final need = appState.needs.firstWhere(
        (n) => n.id == match.needId,
        orElse: () => throw StateError('Need not found'),
      );
      
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _getMatchScoreColor(match.matchScore).withOpacity(0.1),
              _getMatchScoreColor(match.matchScore).withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _getMatchScoreColor(match.matchScore).withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getMatchScoreColor(match.matchScore),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      '${(match.matchScore * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  need.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _buildStatusChip(match.status),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                need.city,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              const Spacer(),
              Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                _formatMatchDate(match.createdAt),
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Matched tags
          if (need.requiredTags.isNotEmpty) ...[
            Wrap(
              spacing: 4,
              children: need.requiredTags.take(3).map((tag) {
                final isMatched = widget.donation.tags.contains(tag);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isMatched ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isMatched ? Icons.check : Icons.schedule,
                        size: 8,
                        color: isMatched ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        tag,
                        style: TextStyle(
                          fontSize: 9,
                          color: isMatched ? Colors.green[700] : Colors.orange[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
    } catch (e) {
      // If need is not found, show a fallback widget
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.red.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.error, color: Colors.red, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Match data unavailable (Need ${match.needId} not found)',
                style: TextStyle(
                  color: Colors.red[700],
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildStatusChip(MatchStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case MatchStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        break;
      case MatchStatus.accepted:
        color = Colors.green;
        text = 'Accepted';
        break;
      case MatchStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        break;
      case MatchStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        break;
      case MatchStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _formatMatchDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return 'Just now';
    }
  }

  void _showAllMatches(BuildContext context, List<Match> matches) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'All Matches',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${matches.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: matches.length,
                  itemBuilder: (context, index) {
                    return Consumer<SupabaseAppState>(
                      builder: (context, appState, child) {
                        return _buildMatchPreview(context, appState, matches[index]);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Donation'),
          content: Text(
            'Are you sure you want to delete "${widget.donation.itemName}"? This action cannot be undone.',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteDonation(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _deleteDonation(BuildContext context) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Delete the donation
      await context.read<SupabaseAppState>().deleteDonation(widget.donation.id);

      // Close loading indicator
      Navigator.of(context).pop();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.donation.itemName} deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Go back to previous screen
      Navigator.of(context).pop();
    } catch (e) {
      // Close loading indicator
      Navigator.of(context).pop();

      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete donation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}