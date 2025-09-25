import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/auth/auth_gui/login_gui.dart';
import 'package:mtaasuite/dashboards/citizen/citizenlandpage.dart';
import 'package:mtaasuite/dashboards/ward/wardlandpage.dart';
import 'package:mtaasuite/services/translation_service.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<PhoneAuthService>(
      builder: (context, authService, child) {
        // Show loading screen while checking authentication state
        if (authService.isLoading) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App logo
                  Image.asset(
                    'assets/images/mtaasuitelogo.png',
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('app.loading'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // If not authenticated, show login page
        if (!authService.isAuthenticated) {
          return const LoginPage();
        }

        // User is authenticated, check if user profile is loaded
        if (authService.userProfile == null) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/mtaasuitelogo.png',
                    height: 80,
                    width: 80,
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: Colors.tealAccent,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    tr('auth.loading_profile'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Navigate to appropriate dashboard based on user type
        final userType = authService.userProfile!.type;
        if (userType == 'ward') {
          return const WardDashboard();
        } else {
          return const CitizenDashboard();
        }
      },
    );
  }
}