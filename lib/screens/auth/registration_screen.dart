import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import '../../models/user.dart' as app_user;
import 'registration_success_screen.dart';
import '../admin/admin_login_screen.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();

  app_user.UserType _selectedUserType = app_user.UserType.donor;
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Show immediate feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
              SizedBox(width: 12),
              Text('Creating your account...'),
            ],
          ),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 2),
        ),
      );
    }

    try {
      if (kDebugMode) {
        print('Starting registration process...');
      }
      
      final appState = context.read<SupabaseAppState>();
      
      appState.registerAccount(
        _emailController.text.trim(),
        _nameController.text.trim(),
        _selectedUserType.name,
        _passwordController.text.trim(),
        _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        (error) {
          if (kDebugMode) {
            print('Registration error: $error');
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Registration failed: ${error.toString()}'),
                    ),
                  ],
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Retry',
                  textColor: Colors.white,
                  onPressed: () => _register(),
                ),
              ),
            );
          }
        },
        () {
          // Success callback
          if (kDebugMode) {
            print('Registration successful!');
          }
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
            
            ScaffoldMessenger.of(context).clearSnackBars();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.white),
                    SizedBox(width: 12),
                    Text('Account created successfully!'),
                  ],
                ),
                backgroundColor: Colors.green,
                duration: Duration(seconds: 2),
              ),
            );

            // Navigate to success screen first, then auto-login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => RegistrationSuccessScreen(
                  userEmail: _emailController.text.trim(),
                  userName: _nameController.text.trim(),
                  onContinue: () async {
                    // Auto-login after registration
                    if (kDebugMode) {
                      print('Attempting auto-login after registration...');
                    }
                    
                    // Wait longer for the user profile to be fully created
                    await Future.delayed(const Duration(seconds: 2));
                    
                    if (!mounted) return;
                    
                    final appState = context.read<SupabaseAppState>();
                    await appState.signInWithEmailAndPassword(
                      _emailController.text.trim(),
                      _passwordController.text.trim(),
                      (error) {
                        if (kDebugMode) {
                          print('Auto-login failed: $error');
                        }
                        if (mounted) {
                          // Show error message and go back to login
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Registration successful! Please log in manually.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          // Go back to login flow
                          appState.startLoginFlow();
                        }
                      },
                    );
                    
                    // AuthWrapper will handle navigation based on loginState
                    if (kDebugMode) {
                      if (appState.loginState == ApplicationLoginState.loggedIn) {
                        print('Auto-login successful - AuthWrapper will handle navigation');
                      } else {
                        print('Auto-login failed - showing login screen');
                      }
                    }
                  },
                ),
              ),
            );
          }
        },
      );

      if (kDebugMode) {
        print('Registration call completed');
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('Registration exception: $e');
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('An unexpected error occurred: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'admin') {
                _showAdminAccess(context);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'admin',
                child: Row(
                  children: [
                    Icon(Icons.admin_panel_settings, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Admin Access'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Join the Community',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Create an account to start donating or receiving help',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 40),

              // User Type
              DropdownButtonFormField<app_user.UserType>(
                value: _selectedUserType,
                decoration: InputDecoration(
                  labelText: 'I am a...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: app_user.UserType.values
                    .where((type) => type != app_user.UserType.admin) // Exclude admin from public registration
                    .map((type) {
                  String displayName;
                  switch (type) {
                    case app_user.UserType.donor:
                      displayName = 'Donor';
                      break;
                    case app_user.UserType.ngo:
                      displayName = 'NGO/Organization';
                      break;
                    case app_user.UserType.individual:
                      displayName = 'Individual in Need';
                      break;
                    case app_user.UserType.admin:
                      displayName = 'Admin'; // This won't show due to the where clause
                      break;
                  }
                  return DropdownMenuItem(
                    value: type,
                    child: Text(displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedUserType = value!;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your name' : null,
              ),
              const SizedBox(height: 20),

              // Email
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'Enter your email',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Password
              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Phone
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  hintText: 'Enter your phone number',
                  prefixIcon: const Icon(Icons.phone),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your phone number' : null,
              ),
              const SizedBox(height: 20),

              // City
              TextFormField(
                controller: _cityController,
                decoration: InputDecoration(
                  labelText: 'City',
                  hintText: 'Enter your city',
                  prefixIcon: const Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter your city' : null,
              ),
              const SizedBox(height: 40),

              // Register Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () {
                    print('Create Account button pressed!'); // Debug log
                    // Add haptic feedback
                    HapticFeedback.lightImpact();
                    _register();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isLoading 
                        ? Colors.grey[400] 
                        : const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _isLoading ? 0 : 2,
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Creating Account...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),

              // Login Button
              Center(
                child: TextButton(
                  onPressed: () {
                    context.read<SupabaseAppState>().cancelRegistration();
                  },
                  child: const Text(
                    'Already have an account? Sign In',
                    style: TextStyle(
                      color: Color(0xFF2E7D32),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminAccess(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(
                Icons.admin_panel_settings,
                color: Colors.red.shade600,
              ),
              const SizedBox(width: 8),
              const Text('Admin Access'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will take you to the admin panel for disaster response management. '
                'Only authorized personnel should access this area.',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminLoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              child: const Text('Admin Login'),
            ),
          ],
        );
      },
    );
  }
}
