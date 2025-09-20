import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supabase_app_state.dart';
import 'login_screen.dart';
import 'registration_screen.dart';
import 'user_type_selection_screen.dart';

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SupabaseAppState>(
      builder: (context, appState, _) {
        switch (appState.loginState) {
          case ApplicationLoginState.loggedOut:
            return const UserTypeSelectionScreen();
          case ApplicationLoginState.emailAddress:
          case ApplicationLoginState.password:
            return const LoginScreen();
          case ApplicationLoginState.register:
            return const RegistrationScreen();
          default:
            return const UserTypeSelectionScreen();
        }
      },
    );
  }
}
