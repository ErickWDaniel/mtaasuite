import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:mtaasuite/services/translation_service.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/services/recaptcha_validation_service.dart';
import 'package:mtaasuite/auth_wrapper.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'dart:async';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();
      await dotenv.load(fileName: ".env");
       try {
          await Firebase.initializeApp(
            options: DefaultFirebaseOptions.currentPlatform,
          );
          print('Firebase initialized successfully');
          print('Firebase project ID: ${DefaultFirebaseOptions.currentPlatform.projectId}');
          
          // Validate reCAPTCHA Enterprise configuration before App Check activation
          print('=== RECAPTCHA ENTERPRISE VALIDATION START ===');
          RecaptchaValidationService.logConfiguration();
          final isValidKey = await RecaptchaValidationService.validateSiteKey();
          print('reCAPTCHA site key validation result: $isValidKey');
          
          if (!isValidKey) {
            print('WARNING: reCAPTCHA site key validation failed - App Check may not work properly');
          }
          print('=== RECAPTCHA ENTERPRISE VALIDATION END ===');
          
          // Configure Firebase App Check to fix "Firebase App Check token is invalid" errors
          print('=== FIREBASE APP CHECK CONFIGURATION START ===');
          try {
            await FirebaseAppCheck.instance.activate(
              // Use debug provider for development - Play Integrity requires published app
              androidProvider: AndroidProvider.debug,
              appleProvider: AppleProvider.debug,
              // Use the actual reCAPTCHA Enterprise site key for web
              webProvider: ReCaptchaV3Provider('6LeMlsErAAAAAJMZkGTtEvOvjoTFFzW4peW9E69m'),
            );
            print('Firebase App Check activated successfully with debug provider');
            
            // Get and print debug token for Firebase console registration
            try {
              final token = await FirebaseAppCheck.instance.getToken(false);
              print('Firebase App Check Debug Token: $token');
              print('Register this token in Firebase Console > App Check > Debug tokens');
            } catch (tokenError) {
              print('Failed to get App Check debug token: $tokenError');
            }
          } catch (appCheckError) {
            print('Firebase App Check activation FAILED: $appCheckError');
            // Continue execution - App Check issues shouldn't crash the app
          }
          print('=== FIREBASE APP CHECK CONFIGURATION END ===');
          
        } catch (e) {
         print('Firebase initialization failed: $e');
         rethrow;
       }
      // Initialize translation service with default language (English)
      await TranslationService.instance.initialize(const Locale('en'));
      runApp(const MyApp());
    },
    (error, stack) {
      //Todo: remove this print and log to a logging service

      print('Uncaught error: $error');
      print('Uncaught error: $stack');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    TranslationService.instance.addListener(_onTranslationChanged);
  }

  void _onTranslationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    TranslationService.instance.removeListener(_onTranslationChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PhoneAuthService>(
      create: (_) => PhoneAuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MtaaSuite',
        locale: TranslationService.instance.currentLocale,
        theme: ThemeData(
          textTheme: GoogleFonts.montserratTextTheme(),
          primaryTextTheme: GoogleFonts.montserratTextTheme(),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: GoogleFonts.montserrat(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}
