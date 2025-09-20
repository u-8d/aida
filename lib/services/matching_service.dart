import '../models/donation.dart';
import '../models/need.dart';
import '../models/match.dart';

class MatchingService {
  static List<Match> findMatches(Donation donation, List<Need> needs) {
    // Null safety checks
    if (donation.id.isEmpty || needs.isEmpty) {
      return [];
    }
    
    List<Match> matches = [];
    
    try {
      for (var need in needs) {
        if (need.status == NeedStatus.fulfilled || need.status == NeedStatus.cancelled) {
          continue;
        }
        
        double score = _calculateMatchScore(donation, need);
        
        if (score > 0.3) { // Minimum threshold for matching
          matches.add(Match(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            donationId: donation.id,
            needId: need.id,
            donorId: donation.donorId,
            recipientId: need.recipientId,
            matchScore: score,
            status: MatchStatus.pending,
            createdAt: DateTime.now(),
          ));
        }
      }
      
      // Sort by match score (highest first)
      matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } catch (e) {
      print('Error in findMatches: $e');
      return [];
    }
    
    return matches;
  }

  static double _calculateMatchScore(Donation donation, Need need) {
    try {
      double score = 0.0;
      
      // Location matching (30% weight)
      if (donation.city.isNotEmpty && need.city.isNotEmpty && 
          donation.city.toLowerCase() == need.city.toLowerCase()) {
        score += 0.3;
      } else if (donation.city.isNotEmpty && need.city.isNotEmpty) {
        // Partial credit for nearby cities (mock implementation)
        score += 0.1;
      }
      
      // Tag matching (40% weight)
      double tagScore = _calculateTagSimilarity(donation.tags, need.requiredTags);
      score += tagScore * 0.4;
      
      // Urgency bonus (20% weight)
      switch (need.urgency) {
        case UrgencyLevel.urgent:
          score += 0.2;
          break;
        case UrgencyLevel.high:
          score += 0.15;
          break;
        case UrgencyLevel.medium:
          score += 0.1;
          break;
        case UrgencyLevel.low:
          score += 0.05;
          break;
      }
      
      // Quantity matching (10% weight)
      if (need.quantity == 1) {
        score += 0.1; // Single item donations match single item needs
      }
      
      return score.clamp(0.0, 1.0);
    } catch (e) {
      print('Error calculating match score: $e');
      return 0.0;
    }
  }

  static double _calculateTagSimilarity(List<String> donationTags, List<String> needTags) {
    try {
      if (donationTags.isEmpty || needTags.isEmpty) return 0.0;
      
      int matches = 0;
      for (String donationTag in donationTags) {
        if (donationTag.isEmpty) continue;
        
        for (String needTag in needTags) {
          if (needTag.isEmpty) continue;
          
          if (donationTag.toLowerCase().contains(needTag.toLowerCase()) ||
              needTag.toLowerCase().contains(donationTag.toLowerCase())) {
            matches++;
            break;
          }
        }
      }
      
      return matches / needTags.length;
    } catch (e) {
      print('Error calculating tag similarity: $e');
      return 0.0;
    }
  }
}
