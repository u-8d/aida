import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/donation.dart';
import '../models/need.dart';

class GeminiService {
  static String get _apiKey => ApiConfig.geminiApiKey;
  static String get _baseUrl => ApiConfig.geminiBaseUrl;

  // New method for AI-powered donation-need matching
  static Future<List<MatchResult>> findMatches(Donation donation, List<Need> availableNeeds) async {
    if (availableNeeds.isEmpty) {
      return [];
    }

    try {
      // Validate API key
      if (!ApiConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please add your actual API key in lib/config/api_config.dart to use AI matching.');
      }

      // Build the enhanced matching prompt aligned with our sophisticated algorithm
      String prompt = '''You are an intelligent donation matching AI for a platform in India. Your task is to analyze a donation item and find the best matches from available needs using a sophisticated multi-factor scoring system.

**DONATION ITEM:**
Title: ${donation.itemName}
Description: ${donation.description}
${donation.contextDescription != null ? 'Additional Context: ${donation.contextDescription}\n' : ''}Tags: ${donation.tags.join(', ')}
Category: Based on tags and description
City: ${donation.city}
State: Based on city
Status: ${donation.status.toString().split('.').last}
Created: ${donation.createdAt}

**AVAILABLE NEEDS (${availableNeeds.length} total):**
${availableNeeds.asMap().entries.map((entry) {
  final index = entry.key;
  final need = entry.value;
  return '''
Need #${index + 1}:
- ID: ${need.id}
- Title: ${need.title}
- Description: ${need.description}
- Required Tags: ${need.requiredTags.join(', ')}
- City: ${need.city}
- State: Based on city
- Urgency: ${need.urgency.toString().split('.').last}
- Recipient: ${need.recipientName} (${need.recipientType})
- Quantity Needed: ${need.quantity}
- Created: ${need.createdAt}
''';
}).join('\n')}

**ADVANCED MATCHING CRITERIA:**
Use this sophisticated scoring system that matches our platform's algorithm:

1. **LOCATION SCORING (0-30 points)**:
   - Same city: 30 points
   - Same metropolitan area (Mumbai/Pune, Delhi/Gurgaon, Bangalore/Mysore, Chennai/Coimbatore): 25 points
   - Same state: 20 points
   - Different state: 10 points

2. **SEMANTIC CATEGORY MATCHING (0-25 points)**:
   - Clothing & Accessories: clothing, shirts, pants, shoes, accessories, winter-wear, formal-wear
   - Education & Learning: books, stationery, educational, school-supplies, learning-materials
   - Food & Nutrition: food, groceries, meals, nutrition, cooking, kitchen-items
   - Technology & Electronics: electronics, gadgets, computers, mobile, tech, digital
   - Health & Medical: medical, healthcare, medicines, hospital, health, hygiene
   - Home & Living: furniture, household, home-items, appliances, utensils, bedding
   - Sports & Recreation: sports, games, toys, recreation, fitness, outdoor
   - Other items: general, miscellaneous, tools, equipment

3. **URGENCY PRIORITIZATION (0-20 points)**:
   - Critical urgency: 20 points
   - High urgency: 15 points  
   - Medium urgency: 10 points
   - Low urgency: 5 points

4. **QUANTITY COMPATIBILITY (0-10 points)**:
   - Perfect quantity match: 10 points
   - Can fulfill partially (50%+): 7 points
   - Can fulfill some (25-50%): 5 points
   - Minimal fulfillment (<25%): 3 points

5. **RECIPIENT TYPE PREFERENCE (0-8 points)**:
   - NGO recipients: +8 for any match (NGOs can distribute efficiently)
   - Individual recipients: +8 for direct matches, +4 for partial matches

6. **FRESHNESS FACTOR (0-5 points)**:
   - Need posted within 7 days: 5 points
   - Need posted within 30 days: 3 points
   - Older needs: 1 point

7. **DESCRIPTION QUALITY BONUS (0-2 points)**:
   - Detailed descriptions with specific requirements: +2 points
   - Generic descriptions: +1 point

**CONFLICT DETECTION (-50 points)**:
Apply heavy penalty for incompatible categories:
- Technology items for food needs
- Adult clothing for children's specific needs
- Seasonal mismatches (winter items for summer needs)

**FINAL SCORING RANGES:**
- 90-100 points: Perfect match - Same city, exact category, high urgency
- 75-89 points: Excellent match - Good location, strong category match
- 60-74 points: Good match - Reasonable compatibility across factors
- 45-59 points: Fair match - Some compatibility, worth considering
- 30-44 points: Possible match - Limited compatibility
- Below 30 points: Poor match - exclude from results

**RETURN FORMAT:**
For each viable match (score ≥ 30), provide:

```json
{
  "matches": [
    {
      "needId": "need_1",
      "matchScore": 85,
      "confidence": "high",
      "detailedBreakdown": {
        "locationScore": 30,
        "semanticScore": 25,
        "urgencyScore": 15,
        "quantityScore": 7,
        "recipientScore": 8,
        "freshnessScore": 3,
        "qualityBonus": 2,
        "conflictPenalty": 0
      },
      "reasoning": "High-scoring match due to same city location, perfect category alignment, and high urgency need",
      "compatibilityFactors": [
        "Same city location (30 pts)",
        "Perfect category match (25 pts)", 
        "High urgency priority (15 pts)",
        "NGO recipient efficiency (8 pts)"
      ],
      "potentialConcerns": [
        "Any limitations or considerations"
      ]
    }
  ]
}
```

Focus on finding meaningful matches that would genuinely help fulfill the needs, with detailed scoring breakdown.
- Appropriate for adult recipients

Please analyze and return only viable matches (score ≥ 50%) in the JSON format above. Be thoughtful and realistic in your scoring.''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt}
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.3,
          'maxOutputTokens': 2048,
          'topP': 0.9,
          'topK': 30,
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No matching results returned from Gemini API');
        }

        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean the content to extract JSON
        String cleanContent = content.trim();
        
        // Remove any markdown formatting
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7);
        }
        if (cleanContent.startsWith('```')) {
          cleanContent = cleanContent.substring(3);
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.substring(0, cleanContent.length - 3);
        }
        
        cleanContent = cleanContent.trim();
        
        try {
          final matchData = jsonDecode(cleanContent);
          final matches = matchData['matches'] as List<dynamic>? ?? [];
          
          return matches.map((match) => MatchResult(
            needId: match['needId']?.toString() ?? '',
            matchScore: (match['matchScore'] as num?)?.toDouble() ?? 0.0,
            confidence: match['confidence']?.toString() ?? 'medium',
            reasoning: match['reasoning']?.toString() ?? 'AI analysis completed',
            compatibilityFactors: _parseStringList(match['compatibilityFactors']),
            potentialConcerns: _parseStringList(match['potentialConcerns']),
          )).toList();
          
        } catch (jsonError) {
          if (kDebugMode) {
            print('JSON parsing error in matching: $jsonError');
            print('Content received: $cleanContent');
          }
          throw Exception('Failed to parse AI matching response');
        }
      } else {
        if (kDebugMode) {
          print('Matching API Error - Status: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        throw Exception('Gemini API error during matching: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AI matching error: $e');
      }
      rethrow;
    }
  }

  static List<String> _parseStringList(dynamic list) {
    if (list == null) return [];
    
    if (list is List) {
      return list.map((item) => item.toString()).toList();
    } else if (list is String) {
      return [list];
    }
    
    return [];
  }

  static Future<ImageAnalysisResult> analyzeMultipleImages(List<File> imageFiles, {String? userDescription}) async {
    if (imageFiles.isEmpty) {
      throw Exception('No images provided for analysis');
    }
    
    // If only one image, use the single image method
    if (imageFiles.length == 1) {
      return analyzeImage(imageFiles.first, userDescription: userDescription);
    }
    
    try {
      // Validate API key
      if (!ApiConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please add your actual API key in lib/config/api_config.dart to use AI analysis.');
      }

      // Convert all images to base64
      List<Map<String, dynamic>> imageParts = [];
      
      for (int i = 0; i < imageFiles.length; i++) {
        final bytes = await imageFiles[i].readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Get MIME type based on file extension
        String mimeType = 'image/jpeg';
        final extension = imageFiles[i].path.toLowerCase().split('.').last;
        switch (extension) {
          case 'png':
            mimeType = 'image/png';
            break;
          case 'jpg':
          case 'jpeg':
            mimeType = 'image/jpeg';
            break;
          case 'webp':
            mimeType = 'image/webp';
            break;
          default:
            mimeType = 'image/jpeg';
        }
        
        imageParts.add({
          'inline_data': {
            'mime_type': mimeType,
            'data': base64Image
          }
        });
      }

      // Build enhanced prompt for multiple images
      String prompt = '''Analyze these ${imageFiles.length} images of the same donation item and provide comprehensive classification for a donation matching platform in India.

${userDescription != null ? '''
IMPORTANT USER-PROVIDED DETAILS: "$userDescription"
Please use this information along with all the images to enhance your analysis. The user has provided specific context that may help identify details not clearly visible in individual images.

''' : ''}MULTIPLE IMAGE ANALYSIS INSTRUCTIONS:
You have ${imageFiles.length} images showing different aspects of the same item. Please:

1. **Examine ALL images carefully** - Look for size tags, brand labels, specification stickers, condition details across all photos
2. **Combine information** from all images for the most complete analysis
3. **Prioritize visible text/labels** - If you see size tags, brand names, model numbers, or specifications in any image, include them
4. **Cross-reference details** - Use information from one image to enhance understanding of others

Special focus areas:
- **Size tags/labels** (shirt sizes, shoe sizes, dimensions on stickers)
- **Brand names and logos** (visible on items or tags)
- **Model numbers/specifications** (especially for electronics, books, etc.)
- **Condition indicators** (wear patterns, damage, newness across different angles)
- **Age/target indicators** (children's sizing, adult features, etc.)

Provide the following information:

1. **Item Title**: A short, concise title for the item (2-4 words max) suitable for donation listings - focus on the main item type and key attribute (e.g., "Men's Winter Jacket", "Children's Books", "Kitchen Utensils")
2. **Item Description**: A detailed description (2-3 sentences) providing comprehensive information about condition, features, brand, size, and other relevant details
3. **Classification Tags**: 8-10 specific tags including ANY visible sizes, brands, models, conditions found across images
4. **Category**: Main category (clothing, books, food, electronics, furniture, toys, household, medical, sports, stationery, etc.)
5. **Condition**: Overall condition assessment from all image angles ${userDescription != null ? '(consider both visual assessment and user description)' : ''}
6. **Size/Details**: Specific sizes or details found in ANY of the images ${userDescription != null ? '(prioritize user-provided information)' : ''}
7. **Target Audience**: Who this item would be suitable for (be specific about age ranges, user types)
8. **Seasonality**: If applicable (winter, summer, monsoon, all-season, not-applicable)
9. **Urgency Level**: How urgently this type of item is typically needed in India (low, medium, high, urgent)

${userDescription != null ? '''
ENHANCEMENT WITH USER DETAILS:
- Combine visible information from images with user description
- If user mentions sizes and you see confirmation in images, prioritize that
- If user mentions brands and you see labels, include in tags
- Use user context to interpret what you see in the images

''' : ''}EXAMPLES of what to look for:
- Clothing: Size tags (S/M/L/XL), brand labels, care instruction labels
- Electronics: Model stickers, specification labels, brand logos
- Books: Title pages, edition information, publisher details
- Toys: Age recommendations, brand names, safety labels

Return your response as valid JSON only, with these exact keys: title, description, tags, category, condition, size, targetAudience, seasonality, urgencyLevel

Example for multiple clothing images:
{
  "title": "Men's Winter Jacket",
  "description": "A high-quality men's winter jacket in size XL, featuring Allen Solly branding. The jacket is in excellent condition with original tags still attached, made from durable material suitable for cold weather protection.",
  "tags": ["XL jacket", "Allen Solly", "men's clothing", "winter wear", "excellent condition", "original tags", "cold weather", "outerwear", "branded"],
  "category": "Clothing",
  "condition": "Excellent",
  "size": "XL",
  "targetAudience": "Adult men",
  "seasonality": "Winter",
  "urgencyLevel": "High"
}''';

      // Build request with text + all images
      List<Map<String, dynamic>> parts = [
        {'text': prompt},
        ...imageParts
      ];

      final requestBody = {
        'contents': [
          {
            'parts': parts
          }
        ],
        'generationConfig': {
          'temperature': 0.2, // Balanced for accuracy with creativity for details
          'maxOutputTokens': 1024, // Sufficient for detailed responses
          'topP': 0.9, // Allow more diverse vocabulary for descriptions
          'topK': 30, // Good balance of speed and quality
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No analysis results returned from Gemini API');
        }

        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean the content to extract JSON
        String cleanContent = content.trim();
        
        // Remove any markdown formatting
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7);
        }
        if (cleanContent.startsWith('```')) {
          cleanContent = cleanContent.substring(3);
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.substring(0, cleanContent.length - 3);
        }
        
        cleanContent = cleanContent.trim();
        
        try {
          // Parse the JSON response from Gemini
          final analysisData = jsonDecode(cleanContent);
          
          return ImageAnalysisResult(
            title: analysisData['title']?.toString() ?? 'Donation Item',
            description: analysisData['description']?.toString() ?? 'Unable to analyze image content',
            tags: _parseTagsList(analysisData['tags']),
            category: analysisData['category']?.toString() ?? 'Other',
            condition: analysisData['condition']?.toString() ?? 'Unknown',
            size: analysisData['size']?.toString() ?? '',
            targetAudience: analysisData['targetAudience']?.toString() ?? 'All ages',
            seasonality: analysisData['seasonality']?.toString() ?? 'All-season',
            urgencyLevel: analysisData['urgencyLevel']?.toString() ?? 'Medium',
          );
        } catch (jsonError) {
          // Log error for debugging (only in debug mode)
          if (kDebugMode) {
            print('JSON parsing error: $jsonError');
            print('Content received: $cleanContent');
          }
          throw Exception('Failed to parse AI response. The AI returned invalid format.');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Invalid request: ${errorData['error']['message'] ?? 'Bad request'}');
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or has insufficient permissions');
      } else if (response.statusCode == 429) {
        throw Exception('API quota exceeded. Please try again later');
      } else {
        if (kDebugMode) {
          print('API Error - Status: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Multiple image analysis error: $e');
      }
      rethrow; // Don't fall back to mock data, let the UI handle the error
    }
  }

  static Future<ImageAnalysisResult> analyzeImage(File imageFile, {String? userDescription}) async {
    try {
      // Validate API key
      if (!ApiConfig.isGeminiConfigured) {
        throw Exception('Gemini API key not configured. Please add your actual API key in lib/config/api_config.dart to use AI analysis.');
      }

      // Convert image to base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // Get MIME type based on file extension
      String mimeType = 'image/jpeg';
      final extension = imageFile.path.toLowerCase().split('.').last;
      switch (extension) {
        case 'png':
          mimeType = 'image/png';
          break;
        case 'jpg':
        case 'jpeg':
          mimeType = 'image/jpeg';
          break;
        case 'webp':
          mimeType = 'image/webp';
          break;
        default:
          mimeType = 'image/jpeg';
      }

      // Build enhanced prompt with user description if provided
      String prompt = '''Analyze this donation item image and provide detailed classification for a donation matching platform in India.

${userDescription != null ? '''
IMPORTANT USER-PROVIDED DETAILS: "$userDescription"
Please use this information to enhance your analysis. The user has provided specific context about the item that may not be visible in the image (like size, age, condition details, intended use, etc.). Incorporate these details into your analysis and use them to make more accurate classifications.

''' : ''}Please carefully examine the image and provide accurate information about what you see. ${userDescription != null ? 'Combine visual analysis with the user-provided details above for the most accurate classification.' : 'Do not make assumptions about items that are not clearly visible.'}

Provide the following information:

1. **Item Title**: A short, concise title for the item (2-4 words max) suitable for donation listings - focus on the main item type and key attribute (e.g., "Men's Winter Jacket", "Children's Books", "Kitchen Utensils")
2. **Item Description**: A detailed description (2-3 sentences) providing comprehensive information about condition, features, brand, size, and other relevant details ${userDescription != null ? 'enhanced with user-provided details' : ''}
3. **Classification Tags**: 5-8 specific tags for matching (include size, brand, condition, age group, etc. from user details)
4. **Category**: Main category (clothing, books, food, electronics, furniture, toys, household, medical, sports, stationery, etc.)
5. **Condition**: Item condition ${userDescription != null ? '(consider both visual assessment and user description)' : '(based on visual assessment)'}
6. **Size/Details**: Specific size, dimensions, or details ${userDescription != null ? '(prioritize user-provided size information)' : '(from visual analysis)'}
7. **Target Audience**: Who this item would be suitable for (be specific about age ranges, user types)
8. **Seasonality**: If applicable (winter, summer, monsoon, all-season, not-applicable)
9. **Urgency Level**: How urgently this type of item is typically needed in India (low, medium, high, urgent)

${userDescription != null ? '''
ENHANCEMENT INSTRUCTIONS:
- If the user mentions specific sizes (XL, 32", size 9, etc.), include these in your tags and size field
- If the user mentions brand names, include them in tags if visible
- If the user mentions age groups (kids 8-10, toddlers, etc.), use this for target audience
- If the user mentions condition details (gently used, excellent condition, etc.), factor this into condition assessment
- If the user mentions specific uses (school books, winter wear, sports equipment), enhance your category and tags accordingly

''' : ''}Return your response as valid JSON only, with these exact keys: title, description, tags, category, condition, size, targetAudience, seasonality, urgencyLevel

Example with user details:
User says: "XL men's winter jacket, barely used, bought last year"
{
  "title": "Men's Winter Jacket",
  "description": "A men's winter jacket in XL size, appears to be in excellent condition with minimal wear as described by the donor. The item was recently purchased and shows very little use, making it ideal for donation.",
  "tags": ["XL jacket", "men's winter wear", "excellent condition", "winter clothing", "outerwear", "barely used"],
  "category": "Clothing",
  "condition": "Excellent",
  "size": "XL",
  "targetAudience": "Adult men",
  "seasonality": "Winter", 
  "urgencyLevel": "High"
}''';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {
                'text': prompt
              },
              {
                'inline_data': {
                  'mime_type': mimeType,
                  'data': base64Image
                }
              }
            ]
          }
        ],
        'generationConfig': {
          'temperature': 0.2, // Slightly higher for better variation
          'maxOutputTokens': 1024, // Reduced from 2048 to save quota
          'topP': 0.9,
          'topK': 20, // Reduced from 40
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE'
          }
        ]
      };

      final response = await http.post(
        Uri.parse('$_baseUrl?key=$_apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['candidates'] == null || data['candidates'].isEmpty) {
          throw Exception('No analysis results returned from Gemini API');
        }

        final content = data['candidates'][0]['content']['parts'][0]['text'];
        
        // Clean the content to extract JSON
        String cleanContent = content.trim();
        
        // Remove any markdown formatting
        if (cleanContent.startsWith('```json')) {
          cleanContent = cleanContent.substring(7);
        }
        if (cleanContent.startsWith('```')) {
          cleanContent = cleanContent.substring(3);
        }
        if (cleanContent.endsWith('```')) {
          cleanContent = cleanContent.substring(0, cleanContent.length - 3);
        }
        
        cleanContent = cleanContent.trim();
        
        try {
          // Parse the JSON response from Gemini
          final analysisData = jsonDecode(cleanContent);
          
          return ImageAnalysisResult(
            title: analysisData['title']?.toString() ?? 'Donation Item',
            description: analysisData['description']?.toString() ?? 'Unable to analyze image content',
            tags: _parseTagsList(analysisData['tags']),
            category: analysisData['category']?.toString() ?? 'Other',
            condition: analysisData['condition']?.toString() ?? 'Unknown',
            size: analysisData['size']?.toString() ?? '',
            targetAudience: analysisData['targetAudience']?.toString() ?? 'All ages',
            seasonality: analysisData['seasonality']?.toString() ?? 'All-season',
            urgencyLevel: analysisData['urgencyLevel']?.toString() ?? 'Medium',
          );
        } catch (jsonError) {
          // Log error for debugging (only in debug mode)
          if (kDebugMode) {
            print('JSON parsing error: $jsonError');
            print('Content received: $cleanContent');
          }
          throw Exception('Failed to parse AI response. The AI returned invalid format.');
        }
      } else if (response.statusCode == 400) {
        final errorData = jsonDecode(response.body);
        throw Exception('Invalid request: ${errorData['error']['message'] ?? 'Bad request'}');
      } else if (response.statusCode == 403) {
        throw Exception('API key is invalid or has insufficient permissions');
      } else if (response.statusCode == 429) {
        throw Exception('API quota exceeded. Please try again later');
      } else {
        if (kDebugMode) {
          print('API Error - Status: ${response.statusCode}');
          print('Response: ${response.body}');
        }
        throw Exception('Gemini API error: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Image analysis error: $e');
      }
      rethrow; // Don't fall back to mock data, let the UI handle the error
    }
  }

  static List<String> _parseTagsList(dynamic tags) {
    if (tags == null) return [];
    
    if (tags is List) {
      return tags.map((tag) => tag.toString()).toList();
    } else if (tags is String) {
      // Handle case where tags might be returned as a comma-separated string
      return tags.split(',').map((tag) => tag.trim()).where((tag) => tag.isNotEmpty).toList();
    }
    
    return [];
  }

}

class MatchResult {
  final String needId;
  final double matchScore;
  final String confidence;
  final String reasoning;
  final List<String> compatibilityFactors;
  final List<String> potentialConcerns;

  MatchResult({
    required this.needId,
    required this.matchScore,
    required this.confidence,
    required this.reasoning,
    required this.compatibilityFactors,
    required this.potentialConcerns,
  });
}

class ImageAnalysisResult {
  final String title;
  final String description;
  final List<String> tags;
  final String category;
  final String condition;
  final String size;
  final String targetAudience;
  final String seasonality;
  final String urgencyLevel;

  ImageAnalysisResult({
    required this.title,
    required this.description,
    required this.tags,
    required this.category,
    required this.condition,
    required this.size,
    required this.targetAudience,
    required this.seasonality,
    required this.urgencyLevel,
  });
}
