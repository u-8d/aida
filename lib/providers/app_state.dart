import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/donation.dart';
import '../models/need.dart';
import '../models/match.dart';
import '../models/chat_conversation.dart';
import '../models/chat_message.dart';
import '../services/sample_data_service.dart';
import '../services/user_storage_service.dart';
import '../services/data_storage_service.dart';
import '../services/ai_chat_service.dart';

class AppState extends ChangeNotifier {
  User? _currentUser;
  List<Donation> _donations = [];
  List<Need> _needs = [];
  List<Match> _matches = [];
  List<ChatConversation> _chatConversations = [];
  bool _isLoading = false;
  
  // Callback for showing notifications
  Function(String, String)? _showNotificationCallback;

  // Getters
  User? get currentUser => _currentUser;
  List<Donation> get donations => _donations;
  List<Need> get needs => _needs;
  List<Match> get matches => _matches;
  List<ChatConversation> get chatConversations => _chatConversations;
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _currentUser != null;
  
  // Set notification callback
  void setNotificationCallback(Function(String, String) callback) {
    _showNotificationCallback = callback;
    if (kDebugMode) {
      print('Notification callback set');
    }
  }

  // Initialize with sample data
  Future<void> initializeApp() async {
    _isLoading = true;
    notifyListeners();

    // Try to load saved user from storage
    await _loadSavedUser();

    // Load persisted donations and needs
    await _loadPersistedData();
    
    _isLoading = false;
    notifyListeners();
  }

  // Load persisted donations and needs from storage
  Future<void> _loadPersistedData() async {
    try {
      // Load stored donations and needs
      final storedDonations = await DataStorageService.loadDonations();
      final storedNeeds = await DataStorageService.loadNeeds();
      
      // If no stored data, load sample data
      if (storedDonations.isEmpty && storedNeeds.isEmpty) {
        _needs = SampleDataService.getSampleNeeds();
        _donations = SampleDataService.getSampleDonations();
        _matches = SampleDataService.getSampleMatches();
        
        // Save sample data for persistence
        await DataStorageService.saveDonations(_donations);
        await DataStorageService.saveNeeds(_needs);
      } else {
        // Use stored data
        _donations = storedDonations;
        _needs = storedNeeds;
        
        // If only one type is missing, add sample data for that type
        if (storedDonations.isEmpty) {
          _donations = SampleDataService.getSampleDonations();
          await DataStorageService.saveDonations(_donations);
        }
        if (storedNeeds.isEmpty) {
          _needs = SampleDataService.getSampleNeeds();
          await DataStorageService.saveNeeds(_needs);
        }
      }
      
      // Always load matches (for demo purposes)
      _matches = SampleDataService.getSampleMatches();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading persisted data: $e');
      }
      // Fallback to sample data
      _needs = SampleDataService.getSampleNeeds();
      _donations = SampleDataService.getSampleDonations();
      _matches = SampleDataService.getSampleMatches();
    }
  }

  // Load saved user from persistent storage
  Future<void> _loadSavedUser() async {
    try {
      final savedUser = await UserStorageService.loadUser();
      if (savedUser != null) {
        _currentUser = savedUser;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading saved user: $e');
      }
    }
  }

  // User authentication
  Future<void> login(User user) async {
    _currentUser = user;
    
    // Save user to persistent storage
    await UserStorageService.saveUser(user);
    
    notifyListeners();
  }

  Future<void> logout() async {
    _currentUser = null;
    
    // Clear user from persistent storage
    await UserStorageService.clearUser();
    
    notifyListeners();
  }

  // Donation management
  void addDonation(Donation donation) {
    _donations.add(donation);
    notifyListeners();
    // Persist the changes
    _saveDonationsAsync();
    
    if (kDebugMode) {
      print('Donation added: ${donation.itemName}, scheduling AI conversation in 5 seconds');
    }
    
    // Schedule AI conversation after 5 seconds for testing (change to 30 for production)
    Timer(const Duration(seconds: 5), () {
      _scheduleAiConversation(donation);
    });
  }
  
  void _scheduleAiConversation(Donation donation) async {
    try {
      if (kDebugMode) {
        print('Creating AI conversation for donation: ${donation.itemName}');
      }
      
      await createAiConversationForDonation(donation);
      
      if (kDebugMode) {
        print('AI conversation created successfully');
      }
      
      // Show notification if callback is set
      if (_showNotificationCallback != null) {
        if (kDebugMode) {
          print('Showing notification');
        }
        _showNotificationCallback!(
          'Someone is interested in your donation!', 
          'Tap to chat about "${donation.itemName}"'
        );
      } else {
        if (kDebugMode) {
          print('No notification callback set');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error creating AI conversation: $e');
      }
    }
  }

  void updateDonation(String donationId, Donation updatedDonation) {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index != -1) {
      _donations[index] = updatedDonation;
      notifyListeners();
      // Persist the changes
      _saveDonationsAsync();
    }
  }

  List<Donation> getDonationsByUser(String userId) {
    return _donations.where((d) => d.donorId == userId).toList();
  }

  // Need management
  void addNeed(Need need) {
    _needs.add(need);
    notifyListeners();
    // Persist the changes
    _saveNeedsAsync();
  }

  void updateNeed(String needId, Need updatedNeed) {
    final index = _needs.indexWhere((n) => n.id == needId);
    if (index != -1) {
      _needs[index] = updatedNeed;
      notifyListeners();
      // Persist the changes
      _saveNeedsAsync();
    }
  }

  // Async save methods (fire and forget)
  void _saveDonationsAsync() {
    DataStorageService.saveDonations(_donations).catchError((e) {
      if (kDebugMode) {
        print('Error saving donations: $e');
      }
      return false;
    });
  }

  void _saveNeedsAsync() {
    DataStorageService.saveNeeds(_needs).catchError((e) {
      if (kDebugMode) {
        print('Error saving needs: $e');
      }
      return false;
    });
  }

  List<Need> getNeedsByUser(String userId) {
    return _needs.where((n) => n.recipientId == userId).toList();
  }

  // Match management
  void addMatch(Match match) {
    _matches.add(match);
    notifyListeners();
  }

  void updateMatch(String matchId, Match updatedMatch) {
    final index = _matches.indexWhere((m) => m.id == matchId);
    if (index != -1) {
      _matches[index] = updatedMatch;
      notifyListeners();
    }
  }

  List<Match> getMatchesForUser(String userId) {
    return _matches.where((m) => m.donorId == userId || m.recipientId == userId).toList();
  }

  // Get available needs for matching
  List<Need> getAvailableNeeds() {
    return _needs.where((n) => n.status == NeedStatus.unmet || n.status == NeedStatus.partialMatch).toList();
  }

  // Get available donations for matching
  List<Donation> getAvailableDonations() {
    return _donations.where((d) => d.status == DonationStatus.pendingMatch).toList();
  }

  // Chat management
  void addChatConversation(ChatConversation conversation) {
    _chatConversations.add(conversation);
    notifyListeners();
  }

  List<ChatConversation> getChatConversationsForUser(String userId) {
    return _chatConversations.where((c) => c.donorId == userId || c.receiverId == userId).toList();
  }

  ChatConversation? getChatConversationById(String conversationId) {
    try {
      return _chatConversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }

  void addMessageToConversation(String conversationId, ChatMessage message) {
    final index = _chatConversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _chatConversations[index];
      final updatedMessages = [...conversation.messages, message];
      _chatConversations[index] = conversation.copyWith(
        messages: updatedMessages,
        lastMessageAt: message.timestamp,
      );
      notifyListeners();
    }
  }

  // Create AI conversation after donation
  Future<void> createAiConversationForDonation(Donation donation) async {
    if (_currentUser == null) return;

    // Generate AI receiver
    final aiReceiverName = AiChatService.getRandomAiReceiverName();
    final aiReceiverId = 'ai_${DateTime.now().millisecondsSinceEpoch}';

    // Create conversation
    final conversation = ChatConversation(
      id: 'chat_${DateTime.now().millisecondsSinceEpoch}',
      donationId: donation.id,
      donorId: _currentUser!.id,
      donorName: _currentUser!.name,
      receiverId: aiReceiverId,
      receiverName: aiReceiverName,
      receiverType: 'ai',
      donationTitle: donation.itemName,
      messages: [],
      createdAt: DateTime.now(),
    );

    // Add conversation
    addChatConversation(conversation);

    // Generate initial AI message
    try {
      final initialMessage = await AiChatService.generateInitialMessage(donation, aiReceiverName);
      
      final aiMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: conversation.id,
        senderId: aiReceiverId,
        senderName: aiReceiverName,
        message: initialMessage,
        timestamp: DateTime.now(),
        type: MessageType.text,
      );

      addMessageToConversation(conversation.id, aiMessage);
    } catch (e) {
      if (kDebugMode) {
        print('Error creating initial AI message: $e');
      }
    }
  }
}
