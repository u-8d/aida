import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/match.dart';
import '../../models/donation.dart';
import '../../widgets/universal_image.dart';

class MatchesFeedScreen extends StatefulWidget {
  const MatchesFeedScreen({super.key});

  @override
  State<MatchesFeedScreen> createState() => _MatchesFeedScreenState();
}

class _MatchesFeedScreenState extends State<MatchesFeedScreen> {
  String _selectedFilter = 'All';
  String _sortBy = 'Score';
  bool _showFilters = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Matches'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(_showFilters ? Icons.filter_list_off : Icons.filter_list),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
            tooltip: 'Toggle Filters',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort Options',
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'Score', child: Text('By Match Score')),
              const PopupMenuItem(value: 'Date', child: Text('By Date')),
              const PopupMenuItem(value: 'Status', child: Text('By Status')),
            ],
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final currentUser = appState.currentUser;
          if (currentUser == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.login, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Please log in to view matches', 
                    style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          final userMatches = _getFilteredAndSortedMatches(appState, currentUser.id);
          final allDonations = appState.donations;

          return Column(
            children: [
              // Enhanced Header with Statistics
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Theme.of(context).colorScheme.primary,
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                    ],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCard('Total', userMatches.length.toString(), Icons.favorite),
                            _buildStatCard('Pending', _getMatchCountByStatus(userMatches, MatchStatus.pending).toString(), Icons.schedule),
                            _buildStatCard('Accepted', _getMatchCountByStatus(userMatches, MatchStatus.accepted).toString(), Icons.check_circle),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Donations matching your needs',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Filters Bar
              if (_showFilters) _buildFiltersBar(),

              // Matches List
              Expanded(
                child: userMatches.isEmpty
                    ? _buildEmptyState(context)
                    : RefreshIndicator(
                        onRefresh: () async {
                          // Simulate refresh
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: userMatches.length,
                          itemBuilder: (context, index) {
                            final match = userMatches[index];
                            final donation = allDonations.firstWhere(
                              (d) => d.id == match.donationId,
                              orElse: () => Donation(
                                id: '',
                                donorId: '',
                                itemName: 'Unknown Item',
                                description: 'Description not available',
                                tags: [],
                                imageUrl: '',
                                city: '',
                                status: DonationStatus.pendingMatch,
                                createdAt: DateTime.now(),
                              ),
                            );
                            return _buildEnhancedMatchCard(context, match, donation, index);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All'),
            _buildFilterChip('Pending'),
            _buildFilterChip('Accepted'),
            _buildFilterChip('High Score'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _selectedFilter = selected ? label : 'All';
          });
        },
        backgroundColor: Colors.white,
        selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  List<Match> _getFilteredAndSortedMatches(AppState appState, String userId) {
    var matches = appState.getMatchesForUser(userId);
    
    // Apply filters
    switch (_selectedFilter) {
      case 'Pending':
        matches = matches.where((m) => m.status == MatchStatus.pending).toList();
        break;
      case 'Accepted':
        matches = matches.where((m) => m.status == MatchStatus.accepted).toList();
        break;
      case 'High Score':
        matches = matches.where((m) => m.matchScore >= 0.7).toList();
        break;
    }
    
    // Apply sorting
    switch (_sortBy) {
      case 'Score':
        matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
        break;
      case 'Date':
        matches.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'Status':
        matches.sort((a, b) => a.status.index.compareTo(b.status.index));
        break;
    }
    
    return matches;
  }

  int _getMatchCountByStatus(List<Match> matches, MatchStatus status) {
    return matches.where((m) => m.status == status).length;
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No matches yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We\'re looking for donations that match your needs',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
              ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Post More Needs'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedMatchCard(BuildContext context, Match match, Donation donation, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 8,
        shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: () => _showEnhancedMatchDetails(context, match, donation),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.grey[50]!,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with match score and status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    gradient: LinearGradient(
                      colors: [
                        _getMatchScoreColor(match.matchScore).withOpacity(0.1),
                        _getMatchScoreColor(match.matchScore).withOpacity(0.05),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getMatchScoreColor(match.matchScore),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _getMatchScoreColor(match.matchScore).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${(match.matchScore * 100).toInt()}%',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getMatchScoreText(match.matchScore),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getMatchScoreColor(match.matchScore),
                        ),
                      ),
                      const Spacer(),
                      _buildEnhancedStatusChip(match.status),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Item Image and Details
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Enhanced Image Container
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
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
                              child: _buildDonationImage(donation.imageUrl),
                            ),
                          ),
                          const SizedBox(width: 16),
                          
                          // Item Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  donation.itemName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                
                                // Location with enhanced styling
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.blue[700],
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        donation.city,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.blue[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Time indicator
                                Row(
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 14,
                                      color: Colors.grey[600],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _formatDate(match.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Matched Parts Section
                      Consumer<AppState>(
                        builder: (context, appState, child) {
                          final need = appState.needs.firstWhere(
                            (n) => n.id == match.needId,
                            orElse: () => throw Exception('Need not found'),
                          );
                          
                          final matchedTags = donation.tags
                              .where((tag) => need.requiredTags.contains(tag))
                              .toList();
                          final missingTags = need.requiredTags
                              .where((tag) => !donation.tags.contains(tag))
                              .toList();
                          
                          return Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.green.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.green[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Match Details for "${need.title}"',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ],
                                ),
                                if (matchedTags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Matched Requirements:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.green[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: matchedTags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.check,
                                              size: 10,
                                              color: Colors.green[700],
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.green[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                                if (missingTags.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Text(
                                    'Still Needed:',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange[600],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    runSpacing: 4,
                                    children: missingTags.map((tag) {
                                      return Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.orange.withOpacity(0.3),
                                            width: 0.5,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.schedule,
                                              size: 10,
                                              color: Colors.orange[700],
                                            ),
                                            const SizedBox(width: 2),
                                            Text(
                                              tag,
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w500,
                                                color: Colors.orange[700],
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
                        },
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tags
                      if (donation.tags.isNotEmpty)
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: donation.tags.take(4).map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => _showChatDialog(context, match),
                              icon: const Icon(Icons.chat_bubble_outline, size: 18),
                              label: const Text('Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                elevation: 2,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: match.status == MatchStatus.pending
                                ? ElevatedButton.icon(
                                    onPressed: () => _showAcceptDialog(context, match),
                                    icon: const Icon(Icons.check, size: 18),
                                    label: const Text('Accept'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      elevation: 2,
                                    ),
                                  )
                                : OutlinedButton.icon(
                                    onPressed: null,
                                    icon: Icon(_getStatusIcon(match.status), size: 18),
                                    label: Text(_getMatchStatusText(match.status)),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showMoreOptionsDialog(context, match, donation),
                            icon: const Icon(Icons.more_vert),
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.grey[100],
                              foregroundColor: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getMatchScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  String _getMatchScoreText(double score) {
    if (score >= 0.8) return 'Excellent Match';
    if (score >= 0.6) return 'Good Match';
    return 'Fair Match';
  }

  Widget _buildEnhancedStatusChip(MatchStatus status) {
    Color color;
    String text;
    IconData icon;
    
    switch (status) {
      case MatchStatus.pending:
        color = Colors.orange;
        text = 'Pending';
        icon = Icons.schedule;
        break;
      case MatchStatus.accepted:
        color = Colors.green;
        text = 'Accepted';
        icon = Icons.check_circle;
        break;
      case MatchStatus.rejected:
        color = Colors.red;
        text = 'Rejected';
        icon = Icons.cancel;
        break;
      case MatchStatus.completed:
        color = Colors.blue;
        text = 'Completed';
        icon = Icons.done_all;
        break;
      case MatchStatus.cancelled:
        color = Colors.grey;
        text = 'Cancelled';
        icon = Icons.cancel_outlined;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(MatchStatus status) {
    switch (status) {
      case MatchStatus.accepted:
        return Icons.check_circle;
      case MatchStatus.rejected:
        return Icons.cancel;
      case MatchStatus.completed:
        return Icons.done_all;
      case MatchStatus.cancelled:
        return Icons.cancel_outlined;
      default:
        return Icons.schedule;
    }
  }

  void _showEnhancedMatchDetails(BuildContext context, Match match, Donation donation) {
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
          child: SingleChildScrollView(
            controller: scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              donation.itemName,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          _buildEnhancedStatusChip(match.status),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Match Score
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              _getMatchScoreColor(match.matchScore).withOpacity(0.1),
                              _getMatchScoreColor(match.matchScore).withOpacity(0.05),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _getMatchScoreColor(match.matchScore).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.star,
                              color: _getMatchScoreColor(match.matchScore),
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${(match.matchScore * 100).toInt()}% Match',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: _getMatchScoreColor(match.matchScore),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '• ${_getMatchScoreText(match.matchScore)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: _getMatchScoreColor(match.matchScore),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Image
                      Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _buildDonationImage(donation.imageUrl),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Description
                      const Text(
                        'Description',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        donation.description,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      
                      // Location and Time
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on, color: Colors.blue[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    donation.city,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.schedule, color: Colors.orange[700], size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    _formatDate(match.createdAt),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.orange[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Tags
                      if (donation.tags.isNotEmpty) ...[
                        const Text(
                          'Tags',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: donation.tags.map((tag) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                    Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                tag,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                _showChatDialog(context, match);
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: const Text('Start Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (match.status == MatchStatus.pending)
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.pop(context);
                                  _showAcceptDialog(context, match);
                                },
                                icon: const Icon(Icons.check),
                                label: const Text('Accept'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMoreOptionsDialog(BuildContext context, Match match, Donation donation) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                _showEnhancedMatchDetails(context, match, donation);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share Match'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share functionality coming soon!')),
                );
              },
            ),
            if (match.status == MatchStatus.pending)
              ListTile(
                leading: const Icon(Icons.close, color: Colors.red),
                title: const Text('Decline Match'),
                onTap: () {
                  Navigator.pop(context);
                  _showDeclineDialog(context, match);
                },
              ),
            ListTile(
              leading: const Icon(Icons.report_outlined, color: Colors.orange),
              title: const Text('Report Issue'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report functionality coming soon!')),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeclineDialog(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Match'),
        content: const Text('Are you sure you want to decline this match? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Match declined successfully.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }

  void _showChatDialog(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.chat_bubble_outline, color: Colors.blue),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Start Conversation'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connect with the donor to discuss pickup details, timing, and any questions about the item.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.amber[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Real-time chat will be implemented with Firebase',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Chat request sent to donor!'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );
            },
            icon: const Icon(Icons.send),
            label: const Text('Send Message'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  void _showAcceptDialog(BuildContext context, Match match) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.check_circle, color: Colors.green),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Accept Match'),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'By accepting this match, you\'re confirming your interest in this donation. The donor will be notified and you can proceed to coordinate pickup.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.green[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Next Steps:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text('• Chat with the donor'),
                  const Text('• Arrange pickup details'),
                  const Text('• Coordinate timing'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.celebration, color: Colors.white),
                      SizedBox(width: 8),
                      Text('Match accepted! You can now chat with the donor.'),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  duration: const Duration(seconds: 4),
                ),
              );
            },
            icon: const Icon(Icons.check),
            label: const Text('Accept Match'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  String _getMatchStatusText(MatchStatus status) {
    switch (status) {
      case MatchStatus.pending:
        return 'Pending';
      case MatchStatus.accepted:
        return 'Accepted';
      case MatchStatus.rejected:
        return 'Rejected';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  String _formatDate(DateTime date) {
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

  Widget _buildDonationImage(String imageUrl) {
    return UniversalImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
