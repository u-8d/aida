import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state.dart';
import '../../models/need.dart';
import '../../models/match.dart';

class NeedDetailsScreen extends StatelessWidget {
  final Need need;

  const NeedDetailsScreen({
    super.key,
    required this.need,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Need Details'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Consumer<AppState>(
        builder: (context, appState, child) {
          final matches = appState.getMatchesForUser(need.recipientId)
              .where((m) => m.needId == need.id)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Need Header
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                need.title,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                            _buildStatusChip(need.status),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          need.description,
                          style: const TextStyle(
                            fontSize: 16,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Urgency and Quantity
                        Row(
                          children: [
                            _buildUrgencyChip(need.urgency),
                            const SizedBox(width: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                'Quantity: ${need.quantity}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Need Information
                _buildDetailCard(
                  title: 'Need Information',
                  children: [
                    _buildDetailRow('Recipient', need.recipientName),
                    _buildDetailRow('Type', need.recipientType.toUpperCase()),
                    _buildDetailRow('City', need.city),
                    _buildDetailRow('Posted', _formatDate(need.createdAt)),
                    if (need.fulfilledAt != null)
                      _buildDetailRow('Fulfilled', _formatDate(need.fulfilledAt!)),
                  ],
                ),
                const SizedBox(height: 16),

                // Required Tags
                if (need.requiredTags.isNotEmpty) ...[
                  _buildDetailCard(
                    title: 'Required Tags',
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: need.requiredTags.map((tag) {
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

                // Matches Found
                if (matches.isNotEmpty) ...[
                  _buildDetailCard(
                    title: 'Matches Found (${matches.length})',
                    children: [
                      ...matches.map((match) => _buildMatchCard(context, match)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Actions
                if (need.status == NeedStatus.unmet || need.status == NeedStatus.partialMatch)
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
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

  Widget _buildMatchCard(BuildContext context, Match match) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.favorite,
                color: Colors.green[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Match Score: ${(match.matchScore * 100).toInt()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Donor: ${match.donorId}', // In real app, get donor name
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${_getMatchStatusText(match.status)}',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement chat functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Chat functionality coming soon!'),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Chat with Donor'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    // TODO: Implement accept/reject functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Accept/Reject functionality coming soon!'),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green[700],
                    side: BorderSide(color: Colors.green[700]!),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: const Text('Accept'),
                ),
              ),
            ],
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
        title: const Text('Cancel Need'),
        content: const Text('Are you sure you want to cancel this need?'),
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
                  content: Text('Need cancelled'),
                ),
              );
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(NeedStatus status) {
    Color color;
    String text;
    
    switch (status) {
      case NeedStatus.unmet:
        color = Colors.orange;
        text = 'Unmet';
        break;
      case NeedStatus.partialMatch:
        color = Colors.blue;
        text = 'Partial Match';
        break;
      case NeedStatus.fulfilled:
        color = Colors.green;
        text = 'Fulfilled';
        break;
      case NeedStatus.cancelled:
        color = Colors.red;
        text = 'Cancelled';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(UrgencyLevel urgency) {
    Color color;
    String text;
    
    switch (urgency) {
      case UrgencyLevel.low:
        color = Colors.green;
        text = 'Low Priority';
        break;
      case UrgencyLevel.medium:
        color = Colors.orange;
        text = 'Medium Priority';
        break;
      case UrgencyLevel.high:
        color = Colors.red;
        text = 'High Priority';
        break;
      case UrgencyLevel.urgent:
        color = Colors.purple;
        text = 'Urgent';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
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
    return '${date.day}/${date.month}/${date.year} at ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
