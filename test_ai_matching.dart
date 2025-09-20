import 'package:aida2/models/donation.dart';
import 'package:aida2/models/need.dart';
import 'package:aida2/services/gemini_service.dart';

Future<void> main() async {
  print('Testing AI-powered matching system...\n');
  
  // Sample donation
  final donation = Donation(
    id: 'test_donation_1',
    donorId: 'test_donor_1',
    itemName: 'Rice bags - 10kg premium basmati rice',
    description: 'High quality basmati rice, perfect for families. Freshly packed and ready for distribution.',
    tags: ['food', 'rice', 'grains', 'family-size'],
    imageUrl: 'https://example.com/rice.jpg',
    city: 'Mumbai',
    status: DonationStatus.available,
    createdAt: DateTime.now(),
  );

  // Sample needs
  final needs = [
    Need(
      id: 'need_1',
      recipientId: 'recipient_1',
      recipientName: 'Hope Shelter',
      recipientType: 'ngo',
      title: 'Food for homeless shelter',
      description: 'Our shelter needs food supplies to feed 50 homeless individuals daily. Any non-perishable food items would be greatly appreciated.',
      requiredTags: ['food', 'grains', 'nutrition'],
      city: 'Mumbai',
      urgency: UrgencyLevel.high,
      status: NeedStatus.unmet,
      createdAt: DateTime.now(),
      quantity: 10,
    ),
    Need(
      id: 'need_2',
      recipientId: 'recipient_2',
      recipientName: 'Bright Future School',
      recipientType: 'ngo',
      title: 'Educational materials for children',
      description: 'School needs books, stationery, and educational supplies for underprivileged children aged 6-14.',
      requiredTags: ['education', 'books', 'stationery'],
      city: 'Mumbai',
      urgency: UrgencyLevel.medium,
      status: NeedStatus.unmet,
      createdAt: DateTime.now(),
      quantity: 5,
    ),
    Need(
      id: 'need_3',
      recipientId: 'recipient_3',
      recipientName: 'Community Kitchen Mumbai',
      recipientType: 'ngo',
      title: 'Rice and grains for community kitchen',
      description: 'Community kitchen serving daily meals to 200+ families needs rice, wheat, and other grains urgently.',
      requiredTags: ['food', 'rice', 'grains', 'bulk'],
      city: 'Mumbai',
      urgency: UrgencyLevel.high,
      status: NeedStatus.unmet,
      createdAt: DateTime.now(),
      quantity: 20,
    ),
  ];

  try {
    print('🤖 Sending donation and needs to Gemini AI for intelligent matching...');
    print('Donation: ${donation.itemName}');
    print('Description: ${donation.description}');
    print('Tags: ${donation.tags.join(', ')}');
    print('');
    
    print('Available needs:');
    for (int i = 0; i < needs.length; i++) {
      print('${i + 1}. ${needs[i].title} (${needs[i].recipientName})');
      print('   ${needs[i].description}');
      print('   Tags: ${needs[i].requiredTags.join(', ')}');
    }
    print('');

    final matches = await GeminiService.findMatches(donation, needs);
    
    print('✅ AI Analysis Complete!');
    print('Found ${matches.length} matches:\n');
    
    for (int i = 0; i < matches.length; i++) {
      final match = matches[i];
      final need = needs.firstWhere((n) => n.id == match.needId);
      
      print('🎯 Match ${i + 1}: ${need.title}');
      print('   Score: ${match.matchScore}%');
      print('   Confidence: ${match.confidence}');
      print('   Reasoning: ${match.reasoning}');
      print('   Compatibility Factors: ${match.compatibilityFactors.join(', ')}');
      if (match.potentialConcerns.isNotEmpty) {
        print('   ⚠️  Potential Concerns: ${match.potentialConcerns.join(', ')}');
      }
      print('');
    }
    
    if (matches.isEmpty) {
      print('❌ No suitable matches found by AI');
    }
    
  } catch (e) {
    print('❌ Error testing AI matching: $e');
    print('This might be due to missing API key or network issues.');
  }
}
