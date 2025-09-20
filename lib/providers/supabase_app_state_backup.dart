import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/supabase_user.dart';
import '../models/donation.dart';
import '../models/need.dart';
import '../models/match.dart';
import '../services/supabase_auth_service.dart';
import '../services/sample_data_service.dart';

enum ApplicationLoginState {
  loggedOut,
  emailAddress,
  register,
  password,
  loggedIn,
}

class SupabaseAppState extends ChangeNotifier {
  SupabaseAppState() {
    init();
  }

  ApplicationLoginState _loginState = ApplicationLoginState.loggedOut;
  ApplicationLoginState get loginState {
    if (kDebugMode) {
      print('Getting login state: $_loginState');
    }
    return _loginState;
  }

  String? _email;
  String? get email => _email;

  StreamSubscription<AuthState>? _authStateSubscription;
  SupabaseUser? _currentUser;
  SupabaseUser? get currentUser => _currentUser;

  // Donation and needs management
  List<Donation> _donations = [];
  List<Need> _needs = [];
  List<Match> _matches = [];
  
  List<Donation> get donations => _donations;
  List<Need> get needs => _needs;
  List<Match> get matches => _matches;

  void init() {
    // Test network connectivity first
    _testConnectivity();
    
    // Initialize sample data for demo purposes
    _loadSampleData();
    
    // Try to load real data from database (even for public access) - but don't block initialization
    _loadPublicDataInBackground();
    
    // Listen to auth state changes
    _authStateSubscription = SupabaseAuthService.authStateChanges.listen((data) {
      if (kDebugMode) {
        print('Auth state change event: ${data.event}');
        print('Session exists: ${data.session != null}');
        if (data.session?.user != null) {
          print('User in session: ${data.session!.user.id}');
        }
      }
      
      if (data.event == AuthChangeEvent.signedIn && data.session != null) {
        // User signed in
        _onUserSignedIn(data.session!.user);
      } else if (data.event == AuthChangeEvent.signedOut) {
        // User signed out
        _onUserSignedOut();
      } else if (data.event == AuthChangeEvent.tokenRefreshed && data.session != null) {
        // Token refreshed, user still signed in
        if (kDebugMode) {
          print('Token refreshed for user: ${data.session!.user.id}');
        }
        if (_currentUser == null) {
          // If we don't have user data loaded, reload it
          _onUserSignedIn(data.session!.user);
        }
      }
    });

    // Check initial auth state
    final currentAuthUser = SupabaseAuthService.currentUser;
    if (currentAuthUser != null) {
      if (kDebugMode) {
        print('Initial auth check: User already signed in: ${currentAuthUser.id}');
      }
      _onUserSignedIn(currentAuthUser);
    } else {
      if (kDebugMode) {
        print('Initial auth check: No user signed in');
      }
    }
  }

  void _testConnectivity() async {
    try {
      if (kDebugMode) {
        print('Testing connectivity to Supabase...');
      }
      
      // Simple connectivity test
      await Supabase.instance.client.from('users').select('count').limit(1);
      
      if (kDebugMode) {
        print('Connectivity test successful');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Connectivity test failed: $e');
        print('This may indicate network or configuration issues');
      }
    }
  }

  void _loadSampleData() {
    _donations = SampleDataService.getSampleDonations();
    _needs = SampleDataService.getSampleNeeds();
    _matches = SampleDataService.getSampleMatches();
  }

  // Public method to fetch data (for explore screen even when not logged in)
  Future<void> loadPublicData() async {
    try {
      if (kDebugMode) {
        print('Loading public data from database...');
      }
      await Future.wait([
        fetchAllDonations(),
        fetchAllNeeds(),
      ]);
      if (kDebugMode) {
        print('Successfully loaded public data from database');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching public data, keeping sample data: $e');
      }
      // Keep sample data if database fetch fails
    }
  }

  // Background method that doesn't block initialization
  void _loadPublicDataInBackground() {
    // Run in background without awaiting to not block initialization
    Future.microtask(() async {
      try {
        if (kDebugMode) {
          print('Loading public data in background...');
        }
        await loadPublicData();
      } catch (e) {
        if (kDebugMode) {
          print('Background data loading failed: $e');
        }
        // Silently fail - sample data is already loaded
      }
    });
  }

  Future<void> _onUserSignedIn(User user) async {
    if (kDebugMode) {
      print('User signed in: ${user.id}');
    }

    _email = user.email;
    
    try {
      // Fetch user profile with retries for newly created users
      _currentUser = await _fetchUserProfileWithRetry(user.id);
      
      if (_currentUser != null) {
        _loginState = ApplicationLoginState.loggedIn;
        if (kDebugMode) {
          print('User profile loaded: ${_currentUser!.name}');
          print('Setting login state to: $_loginState');
        }
      } else {
        if (kDebugMode) {
          print('Failed to load user profile after retries');
        }
        // If we can't load the profile, sign out
        await signOut();
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading user profile: $e');
      }
      await signOut();
      return;
    }
    
    // Fetch real data from database after successful login (in background)
    _loadDataAfterLogin();
    
    if (kDebugMode) {
      print('Calling notifyListeners() with state: $_loginState');
    }
    notifyListeners();
  }

  // Background method to load data after login without blocking the UI
  void _loadDataAfterLogin() {
    Future.microtask(() async {
      try {
        if (kDebugMode) {
          print('Fetching real data from database after login...');
        }
        await Future.wait([
          fetchAllDonations(),
          fetchAllNeeds(),
        ]);
        if (kDebugMode) {
          print('Successfully loaded real data from database after login');
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching real data after login, keeping sample data: $e');
        }
        // Keep sample data if database fetch fails
      }
    });
  }

  // Helper method to fetch user profile with retries (for newly created users)
  Future<SupabaseUser?> _fetchUserProfileWithRetry(String userId, {int maxRetries = 3}) async {
    for (int i = 0; i < maxRetries; i++) {
      try {
        final profile = await SupabaseAuthService.getUserProfile(userId);
        if (profile != null) {
          return profile;
        }
        
        // If profile not found, wait a bit before retrying
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Attempt ${i + 1} to fetch user profile failed: $e');
        }
        
        if (i < maxRetries - 1) {
          await Future.delayed(Duration(milliseconds: 500 * (i + 1)));
        }
      }
    }
    return null;
  }

  void _onUserSignedOut() {
    if (kDebugMode) {
      print('User signed out');
    }
    
    _loginState = ApplicationLoginState.loggedOut;
    _email = null;
    _currentUser = null;
    notifyListeners();
  }

  void verifyEmail(
    String email,
    void Function(Exception e) errorCallback,
  ) async {
    try {
      // Simple email validation
      if (!email.contains('@')) {
        throw Exception('Invalid email format');
      }
      
      _email = email;
      _loginState = ApplicationLoginState.password;
      notifyListeners();
    } catch (e) {
      errorCallback(Exception(e.toString()));
    }
  }

  Future<void> signInWithEmailAndPassword(
    String email,
    String password,
    void Function(Exception e) errorCallback,
  ) async {
    try {
      if (kDebugMode) {
        print('Starting sign in for: $email');
      }
      
      final error = await SupabaseAuthService.signIn(
        email: email,
        password: password,
      );
      
      if (error != null) {
        if (kDebugMode) {
          print('Sign in failed with error: $error');
        }
        errorCallback(Exception(error));
      } else {
        if (kDebugMode) {
          print('Sign in successful, updating state for user: ${SupabaseAuthService.currentUser?.id}');
        }
        // Don't manually update state here - let the auth listener handle it
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception during sign in: $e');
      }
      errorCallback(Exception(e.toString()));
    }
  }

  void registerAccount(
    String email,
    String name,
    String userType,
    String password,
    String? city,
    String? phone,
    void Function(String message) errorCallback,
    void Function() successCallback,
  ) async {
    try {
      if (kDebugMode) {
        print('Starting account registration for: $email');
      }
      
      final error = await SupabaseAuthService.signUp(
        email: email,
        password: password,
        name: name,
        userType: userType,
        city: city,
        phone: phone,
      );
      
      if (error != null) {
        if (kDebugMode) {
          print('Registration failed: $error');
        }
        errorCallback(error);
      } else {
        if (kDebugMode) {
          print('Registration successful');
        }
        // Update login state for registration flow
        _loginState = ApplicationLoginState.emailAddress;
        notifyListeners();
        successCallback();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exception during registration: $e');
      }
      errorCallback(e.toString());
    }
  }

  Future<void> signOut() async {
    await SupabaseAuthService.signOut();
  }

  void startLoginFlow() {
    _loginState = ApplicationLoginState.emailAddress;
    notifyListeners();
  }

  // Donation management methods
  Future<Donation> addDonation(Donation donation) async {
    try {
      if (kDebugMode) {
        print('Adding donation to Supabase: ${donation.itemName}');
      }

      // Convert Donation object to a map using the proper toJson method
      final Map<String, dynamic> donationJson = donation.toJson();
      
      // Remove fields that shouldn't be sent to database for creation
      donationJson.remove('id'); // Let Supabase generate the ID
      donationJson.remove('matched_at');
      donationJson.remove('matched_recipient_id');
      donationJson.remove('matched_recipient_name');

      if (kDebugMode) {
        print('Data to insert: $donationJson');
        print('Status in JSON: ${donationJson['status']}');
      }

      final response = await Supabase.instance.client
          .from('donations')
          .insert(donationJson)
          .select()
          .single();

      if (kDebugMode) {
        print('Supabase response: $response');
      }

      // Convert the response back to a Donation object
      final responseData = Map<String, dynamic>.from(response);
      
      if (kDebugMode) {
        print('Raw response data: $responseData');
        print('Status from database: ${responseData['status']}');
        print('Status type: ${responseData['status'].runtimeType}');
      }
      
      Donation newDonation;
      try {
        newDonation = Donation.fromJson(responseData);
      } catch (e) {
        if (kDebugMode) {
          print('Error in fromJson: $e');
          print('Attempting manual status conversion...');
        }
        
        // Fallback: manually handle the status conversion
        if (responseData['status'] is String) {
          final statusString = responseData['status'] as String;
          
          // Map the string to the enum
          DonationStatus? status;
          switch (statusString) {
            case 'available':
              status = DonationStatus.available;
              break;
            case 'pendingMatch':
              status = DonationStatus.pendingMatch;
              break;
            case 'matchFound':
              status = DonationStatus.matchFound;
              break;
            case 'readyForPickup':
              status = DonationStatus.readyForPickup;
              break;
            case 'donationCompleted':
              status = DonationStatus.donationCompleted;
              break;
            case 'cancelled':
              status = DonationStatus.cancelled;
              break;
            default:
              status = DonationStatus.available;
          }
          
          newDonation = Donation(
            id: responseData['id'] as String,
            donorId: responseData['donor_id'] as String,
            itemName: responseData['item_name'] as String,
            description: responseData['description'] as String,
            category: responseData['category'] as String,
            condition: responseData['condition'] as String,
            imageUrl: responseData['image_url'] as String? ?? '',
            tags: List<String>.from(responseData['tags'] ?? []),
            city: responseData['city'] as String,
            status: status!,
            createdAt: DateTime.parse(responseData['created_at'] as String),
            matchedAt: responseData['matched_at'] != null 
                ? DateTime.parse(responseData['matched_at'] as String)
                : null,
            matchedRecipientId: responseData['matched_recipient_id'] as String?,
            matchedRecipientName: responseData['matched_recipient_name'] as String?,
          );
        } else {
          rethrow;
        }
      }

      _donations.add(newDonation);
      notifyListeners();
      
      if (kDebugMode) {
        print('Donation added successfully: ${newDonation.id}');
      }
      return newDonation;
    } catch (error) {
      if (kDebugMode) {
        print('Error adding donation to Supabase: $error');
        print('Error type: ${error.runtimeType}');
      }
      // Re-throw the error to be caught by the UI
      rethrow;
    }
  }

  Future<void> updateDonation(String donationId, Donation updatedDonation) async {
    final index = _donations.indexWhere((d) => d.id == donationId);
    if (index != -1) {
      _donations[index] = updatedDonation;
      notifyListeners();
    }
  }

  List<Donation> getDonationsByUser(String userId) {
    return _donations.where((d) => d.donorId == userId).toList();
  }

  // Fetch all donations from database
  Future<void> fetchAllDonations() async {
    try {
      if (kDebugMode) {
        print('Fetching all donations from database...');
      }

      final response = await Supabase.instance.client
          .from('donations')
          .select()
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('Fetched ${response.length} donations from database');
      }

      final List<Donation> validDonations = [];
      for (final data in response) {
        try {
          final donation = Donation.fromJson(data);
          validDonations.add(donation);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing donation: $e, data: $data');
          }
          // Skip invalid donations
        }
      }

      _donations = validDonations;
      notifyListeners();
      
      if (kDebugMode) {
        print('Successfully loaded ${_donations.length} donations');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching donations: $error');
      }
      // Keep existing sample data on error
    }
  }

  // Fetch all needs from database
  Future<void> fetchAllNeeds() async {
    try {
      if (kDebugMode) {
        print('Fetching all needs from database...');
      }

      final response = await Supabase.instance.client
          .from('needs')
          .select()
          .order('created_at', ascending: false);

      if (kDebugMode) {
        print('Fetched ${response.length} needs from database');
      }

      final List<Need> validNeeds = [];
      for (final data in response) {
        try {
          final need = Need.fromJson(data);
          validNeeds.add(need);
        } catch (e) {
          if (kDebugMode) {
            print('Error parsing need: $e, data: $data');
          }
          // Skip invalid needs
        }
      }

      _needs = validNeeds;
      notifyListeners();
      
      if (kDebugMode) {
        print('Successfully loaded ${_needs.length} needs');
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching needs: $error');
      }
      // Keep existing sample data on error
    }
  }

  // Need management methods
  void addNeed(Need need) {
    _needs.add(need);
    notifyListeners();
  }

  void updateNeed(String needId, Need updatedNeed) {
    final index = _needs.indexWhere((n) => n.id == needId);
    if (index != -1) {
      _needs[index] = updatedNeed;
      notifyListeners();
    }
  }

  List<Need> getNeedsByUser(String userId) {
    return _needs.where((n) => n.recipientId == userId).toList();
  }

  // Match management methods
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

  List<Match> getMatchesByUser(String userId) {
    return _matches.where((m) => m.donorId == userId || m.recipientId == userId).toList();
  }

  List<Need> getAvailableNeeds() {
    return _needs.where((n) => n.status == NeedStatus.unmet || n.status == NeedStatus.partialMatch).toList();
  }

  List<Donation> getAvailableDonations() {
    return _donations.where((d) => d.status == DonationStatus.pendingMatch).toList();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
