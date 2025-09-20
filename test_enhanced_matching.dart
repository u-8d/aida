import 'lib/models/donation.dart';
import 'lib/models/need.dart';
import 'lib/services/sample_data_service.dart';

void main() async {
  print('Testing Enhanced Matching Algorithm...\n');
  
  // Get enhanced sample data
  final sampleNeeds = SampleDataService.getSampleNeeds();
  final sampleDonations = SampleDataService.getSampleDonations();
  
  print('📊 Sample Data Overview:');
  print('Needs: ${sampleNeeds.length}');
  print('Donations: ${sampleDonations.length}\n');
  
  // Test matching with a few example donations
  final testDonations = sampleDonations.take(3).toList();
  
  for (int i = 0; i < testDonations.length; i++) {
    final donation = testDonations[i];
    print('🎁 Testing Donation ${i + 1}: ${donation.itemName}');
    print('   Location: ${donation.city}');
    print('   Tags: ${donation.tags.join(', ')}');
    print('   Description: ${donation.description.substring(0, 100)}...\n');
    
    // Calculate matches using our algorithm logic
    List<Map<String, dynamic>> matches = [];
    
    for (final need in sampleNeeds) {
      final score = _calculateMatchScore(donation, need);
      if (score >= 30) { // Our threshold for viable matches
        matches.add({
          'need': need,
          'score': score,
          'breakdown': _getScoreBreakdown(donation, need),
        });
      }
    }
    
    // Sort by score
    matches.sort((a, b) => (b['score'] as double).compareTo(a['score'] as double));
    
    if (matches.isEmpty) {
      print('   ❌ No viable matches found (score < 30)\n');
    } else {
      print('   ✅ Found ${matches.length} viable matches:');
      for (int j = 0; j < matches.length && j < 3; j++) {
        final match = matches[j];
        final need = match['need'] as Need;
        final score = match['score'] as double;
        final breakdown = match['breakdown'] as Map<String, double>;
        
        print('   ${j + 1}. ${need.title} (Score: ${score.toStringAsFixed(1)})');
        print('      Location: ${need.city} | Urgency: ${need.urgency.toString().split('.').last}');
        print('      Breakdown: Location(${breakdown['location']?.toStringAsFixed(0)}), Semantic(${breakdown['semantic']?.toStringAsFixed(0)}), Urgency(${breakdown['urgency']?.toStringAsFixed(0)})');
      }
      print('');
    }
  }
  
  print('✅ Enhanced matching algorithm test completed!');
}

double _calculateMatchScore(Donation donation, Need need) {
  double score = 0.0;
  
  // 1. Location scoring (0-30 points)
  score += _calculateLocationScore(donation.city, need.city);
  
  // 2. Semantic category matching (0-25 points)
  score += _calculateSemanticScore(donation.tags, need.requiredTags);
  
  // 3. Urgency prioritization (0-20 points)
  switch (need.urgency) {
    case UrgencyLevel.urgent:
      score += 20;
      break;
    case UrgencyLevel.high:
      score += 15;
      break;
    case UrgencyLevel.medium:
      score += 10;
      break;
    case UrgencyLevel.low:
      score += 5;
      break;
  }
  
  // 4. Quantity compatibility (0-10 points)
  score += 7; // Assume good compatibility for testing
  
  // 5. Recipient type preference (0-8 points)
  if (need.recipientType == 'NGO') {
    score += 8;
  } else {
    score += 6;
  }
  
  // 6. Freshness factor (0-5 points)
  score += 3; // Assume recent for testing
  
  // 7. Description quality bonus (0-2 points)
  if (need.description.length > 50) {
    score += 2;
  } else {
    score += 1;
  }
  
  // Check for conflicts and apply penalties
  if (_hasConflict(donation.tags, need.requiredTags)) {
    score -= 50;
  }
  
  return score.clamp(0, 100);
}

Map<String, double> _getScoreBreakdown(Donation donation, Need need) {
  return {
    'location': _calculateLocationScore(donation.city, need.city),
    'semantic': _calculateSemanticScore(donation.tags, need.requiredTags),
    'urgency': need.urgency == UrgencyLevel.urgent ? 20 : 
               need.urgency == UrgencyLevel.high ? 15 :
               need.urgency == UrgencyLevel.medium ? 10 : 5,
  };
}

double _calculateLocationScore(String donationCity, String needCity) {
  if (donationCity.toLowerCase() == needCity.toLowerCase()) {
    return 30;
  }
  
  // Metro area groups
  final metroGroups = [
    ['mumbai', 'pune', 'thane', 'navi mumbai'],
    ['delhi', 'gurgaon', 'noida', 'faridabad'],
    ['bangalore', 'mysore', 'mangalore'],
    ['chennai', 'coimbatore', 'madurai'],
  ];
  
  final donationLower = donationCity.toLowerCase();
  final needLower = needCity.toLowerCase();
  
  for (final group in metroGroups) {
    if (group.contains(donationLower) && group.contains(needLower)) {
      return 25;
    }
  }
  
  return 20; // Assume same state for testing
}

double _calculateSemanticScore(List<String> donationTags, List<String> needTags) {
  final categoryGroups = {
    'clothing': ['clothing', 'shirts', 'pants', 'shoes', 'accessories', 'winter-wear', 'formal-wear', 'traditional'],
    'education': ['books', 'stationery', 'educational', 'school-supplies', 'learning-materials', 'notebooks'],
    'food': ['food', 'groceries', 'meals', 'nutrition', 'cooking', 'kitchen-items', 'utensils'],
    'technology': ['electronics', 'gadgets', 'computers', 'mobile', 'tech', 'digital'],
    'health': ['medical', 'healthcare', 'medicines', 'hospital', 'health', 'hygiene'],
    'home': ['furniture', 'household', 'home-items', 'appliances', 'utensils', 'bedding'],
    'sports': ['sports', 'games', 'toys', 'recreation', 'fitness', 'outdoor'],
  };
  
  // Find categories for both donation and need
  String? donationCategory;
  String? needCategory;
  
  for (final entry in categoryGroups.entries) {
    if (donationTags.any((tag) => entry.value.contains(tag.toLowerCase()))) {
      donationCategory = entry.key;
      break;
    }
  }
  
  for (final entry in categoryGroups.entries) {
    if (needTags.any((tag) => entry.value.contains(tag.toLowerCase()))) {
      needCategory = entry.key;
      break;
    }
  }
  
  if (donationCategory == needCategory) {
    return 25;
  } else if (donationCategory != null && needCategory != null) {
    return 10; // Related but different categories
  }
  
  return 5; // No clear category match
}

bool _hasConflict(List<String> donationTags, List<String> needTags) {
  // Simple conflict detection
  final techTags = ['electronics', 'gadgets', 'computers'];
  final foodTags = ['food', 'groceries', 'meals'];
  
  final hasTechDonation = donationTags.any((tag) => techTags.contains(tag.toLowerCase()));
  final hasFoodNeed = needTags.any((tag) => foodTags.contains(tag.toLowerCase()));
  
  return hasTechDonation && hasFoodNeed;
}
