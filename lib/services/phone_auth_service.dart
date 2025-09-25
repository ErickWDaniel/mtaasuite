import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';
import 'package:mtaasuite/services/auth_storage.dart';
import 'package:mtaasuite/services/test_phone_numbers.dart';
import 'package:mtaasuite/services/security_service.dart';
import 'dart:developer' as developer;

class PhoneAuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref().child('users');

  // State variables
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;
  User? _currentUser;
  UserModel? _userProfile;

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get currentUser => _currentUser;
  UserModel? get userProfile => _userProfile;
  bool get isAuthenticated => _currentUser != null;

  PhoneAuthService() {
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((User? user) {
      _currentUser = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  // Set loading state
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  // Set error message
  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Normalize phone number to E.164 format for Tanzania
  String _normalizePhoneNumber(String phone) {
    // Remove all non-digits
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    
    // Handle Tanzania phone numbers
    if (digits.length == 9 && digits.startsWith('0')) {
      // 0XXXXXXXXX -> +255XXXXXXXXX
      return '+255${digits.substring(1)}';
    } else if (digits.length == 8) {
      // XXXXXXXX -> +255XXXXXXXX
      return '+255$digits';
    } else if (digits.length == 12 && digits.startsWith('255')) {
      // 255XXXXXXXXX -> +255XXXXXXXXX
      return '+$digits';
    } else if (digits.startsWith('255')) {
      // Already in correct format
      return '+$digits';
    }
    
    // Return as-is if already starts with +
    return phone.startsWith('+') ? phone : '+$phone';
  }

  // Validate phone number
  bool _isValidPhoneNumber(String phone) {
    final normalized = _normalizePhoneNumber(phone);
    // Tanzania phone numbers: +255 followed by 6, 7, or 9
    final regex = RegExp(r'^\+255[679]\d{8}$');
    return regex.hasMatch(normalized);
  }

  // Send OTP for login (existing user)
  Future<bool> sendLoginOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      // Sanitize and validate input
      final sanitizedPhone = SecurityService.sanitizeAndValidatePhone(phoneNumber);
      if (sanitizedPhone == null) {
        _setError('Invalid phone number format. Please enter a valid number.');
        _setLoading(false);
        return false;
      }

      final normalizedPhone = _normalizePhoneNumber(sanitizedPhone);
      
      if (!_isValidPhoneNumber(normalizedPhone)) {
        _setError('Invalid phone number format. Please use Tanzania format.');
        _setLoading(false);
        return false;
      }

      // Check rate limiting
      if (!await SecurityService.canRequestOTP(normalizedPhone)) {
        final cooldown = await SecurityService.getOTPCooldown(normalizedPhone);
        final minutes = (cooldown.inMinutes + 1);
        _setError('Too many OTP requests. Please try again in $minutes minutes.');
        _setLoading(false);
        return false;
      }

      // Check login rate limiting
      if (!await SecurityService.canAttemptLogin(normalizedPhone)) {
        _setError('Too many login attempts. Please try again later.');
        _setLoading(false);
        return false;
      }

      // Check if it's a test number in development mode
      if (TestPhoneNumbers.testNumbersEnabled && TestPhoneNumbers.isTestNumber(normalizedPhone)) {
        developer.log('Using test phone number: $normalizedPhone', name: 'PhoneAuthService');
        
        // Simulate OTP sending for test numbers
        _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 1500));
        
        _setLoading(false);
        return true;
      }

      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          developer.log('Auto verification completed', name: 'PhoneAuthService');
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          developer.log('Verification failed: ${e.message}', name: 'PhoneAuthService');
          _setError(_getErrorMessage(e.code));
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          developer.log('OTP code sent successfully', name: 'PhoneAuthService');
          _verificationId = verificationId;
          _setLoading(false);
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return true;
    } catch (e) {
      developer.log('Send OTP error: $e', name: 'PhoneAuthService');
      _setError('Failed to send OTP. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  // Send OTP for registration (new user)
  Future<bool> sendRegistrationOTP(String phoneNumber, UserModel userData) async {
    try {
      print('=== PhoneAuthService.sendRegistrationOTP DEBUG START ===');
      print('Input phoneNumber: "$phoneNumber"');
      print('Input userData:');
      print('  UID: ${userData.uid}');
      print('  Type: ${userData.type}');
      print('  Phone: ${userData.phone}');
      print('  Name: ${userData.name}');
      print('  Gender: ${userData.gender}');
      print('  DOB: ${userData.dob}');
      print('  Address: ${userData.address}');
      print('  Region: ${userData.region}');
      print('  District: ${userData.district}');
      print('  Ward: ${userData.ward}');
      print('  Street: ${userData.street}');
      print('  House Number: ${userData.houseNumber}');
      print('  Check Number: ${userData.checkNumber}');
      
      _setLoading(true);
      _setError(null);

      // Sanitize and validate input
      final sanitizedPhone = SecurityService.sanitizeAndValidatePhone(phoneNumber);
      print('Sanitized phone: "$sanitizedPhone"');
      
      if (sanitizedPhone == null) {
        print('Phone sanitization FAILED - setting error');
        _setError('Invalid phone number format. Please enter a valid number.');
        _setLoading(false);
        return false;
      }

      final normalizedPhone = _normalizePhoneNumber(sanitizedPhone);
      print('Normalized phone: "$normalizedPhone"');
      
      if (!_isValidPhoneNumber(normalizedPhone)) {
        print('Phone validation FAILED - setting error');
        _setError('Invalid phone number format. Please use Tanzania format.');
        _setLoading(false);
        return false;
      }

      // Sanitize user data
      final sanitizedUserData = UserModel(
        uid: userData.uid,
        type: userData.type,
        phone: normalizedPhone,
        name: SecurityService.sanitizeName(userData.name),
        gender: userData.gender,
        dob: userData.dob,
        address: SecurityService.sanitizeName(userData.address),
        region: userData.region,
        district: userData.district,
        ward: userData.ward,
        street: SecurityService.sanitizeName(userData.street),
        houseNumber: SecurityService.sanitizeName(userData.houseNumber),
        checkNumber: userData.checkNumber,
        profilePicUrl: userData.profilePicUrl,
        createdAt: userData.createdAt,
      );

      print('Sanitized user data:');
      print('  Phone: ${sanitizedUserData.phone}');
      print('  Name: ${sanitizedUserData.name}');
      print('  Address: ${sanitizedUserData.address}');
      print('  Street: ${sanitizedUserData.street}');
      print('  House Number: ${sanitizedUserData.houseNumber}');

      // Check rate limiting
      print('Checking rate limiting for phone: $normalizedPhone');
      if (!await SecurityService.canRequestOTP(normalizedPhone)) {
        final cooldown = await SecurityService.getOTPCooldown(normalizedPhone);
        final minutes = (cooldown.inMinutes + 1);
        print('Rate limiting FAILED - cooldown: ${cooldown.inMinutes} minutes');
        _setError('Too many OTP requests. Please try again in $minutes minutes.');
        _setLoading(false);
        return false;
      }
      print('Rate limiting passed');

      // Store user data temporarily for registration after OTP verification
      print('Storing user data temporarily for registration...');
      await AuthStorage.saveUserData('pending_registration', sanitizedUserData.toJson());
      print('User data stored successfully');

      // Check if it's a test number in development mode
      if (TestPhoneNumbers.testNumbersEnabled && TestPhoneNumbers.isTestNumber(normalizedPhone)) {
        print('Using test phone number for registration: $normalizedPhone');
        developer.log('Using test phone number for registration: $normalizedPhone', name: 'PhoneAuthService');
        
        // Simulate OTP sending for test numbers
        _verificationId = 'test_verification_id_${DateTime.now().millisecondsSinceEpoch}';
        print('Generated test verification ID: $_verificationId');
        
        // Simulate network delay
        await Future.delayed(const Duration(milliseconds: 1500));
        
        _setLoading(false);
        print('Test OTP flow completed successfully');
        print('=== PhoneAuthService.sendRegistrationOTP DEBUG END ===');
        return true;
      }

      print('Initiating Firebase phone verification for: $normalizedPhone');
      await _auth.verifyPhoneNumber(
        phoneNumber: normalizedPhone,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification - complete registration
          print('Auto-verification completed for registration');
          developer.log('Auto verification completed for registration', name: 'PhoneAuthService');
          await _signInWithCredential(credential);
          await _completeRegistration(sanitizedUserData);
        },
        verificationFailed: (FirebaseAuthException e) {
          print('Registration verification FAILED: ${e.message}');
          print('Error code: ${e.code}');
          developer.log('Registration verification failed: ${e.message}', name: 'PhoneAuthService');
          _setError(_getErrorMessage(e.code));
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          print('Registration OTP code sent successfully, verificationId: $verificationId');
          developer.log('Registration OTP code sent successfully', name: 'PhoneAuthService');
          _verificationId = verificationId;
          _setLoading(false);
        },
        timeout: const Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verificationId) {
          print('Code auto-retrieval timeout, verificationId: $verificationId');
          _verificationId = verificationId;
        },
      );

      print('Firebase phone verification initiated successfully');
      print('=== PhoneAuthService.sendRegistrationOTP DEBUG END ===');
      return true;
    } catch (e) {
      print('Send registration OTP EXCEPTION: $e');
      developer.log('Send registration OTP error: $e', name: 'PhoneAuthService');
      _setError('Failed to send OTP. Please try again.');
      _setLoading(false);
      print('=== PhoneAuthService.sendRegistrationOTP DEBUG END ===');
      return false;
    }
  }

  // Verify OTP code
  Future<bool> verifyOTP(String otpCode) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_verificationId == null) {
        _setError('Verification ID not found. Please request OTP again.');
        _setLoading(false);
        return false;
      }

      // Sanitize and validate OTP
      final sanitizedOTP = SecurityService.sanitizeOTP(otpCode);
      if (!SecurityService.isValidOTP(sanitizedOTP)) {
        _setError('Please enter a valid 6-digit OTP code.');
        _setLoading(false);
        return false;
      }

      // Handle test phone numbers in development mode
      if (TestPhoneNumbers.testNumbersEnabled && _verificationId!.startsWith('test_verification_id_')) {
        developer.log('Verifying test OTP code: $sanitizedOTP', name: 'PhoneAuthService');
        
        // Check if there's pending registration data
        final pendingUserData = await AuthStorage.getUserData('pending_registration');
        if (pendingUserData != null) {
          final userData = UserModel.fromJson(pendingUserData);
          final normalizedPhone = _normalizePhoneNumber(userData.phone);
          
          // Validate test OTP
          if (TestPhoneNumbers.validateTestOTP(normalizedPhone, sanitizedOTP)) {
            // Simulate successful authentication for test numbers
            developer.log('Test OTP verified successfully', name: 'PhoneAuthService');
            
            // Complete registration for test user
            await _completeTestRegistration(userData);
            await AuthStorage.clearUserData('pending_registration');
            
            _setLoading(false);
            return true;
          } else {
            _setError('Invalid test OTP code. Use the correct test OTP for this number.');
            _setLoading(false);
            return false;
          }
        } else {
          // Login with test number - simulate successful login
          if (TestPhoneNumbers.isTestNumber(_verificationId!)) {
            developer.log('Test login OTP verified successfully', name: 'PhoneAuthService');
            _setLoading(false);
            return true;
          }
        }
      }

      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: sanitizedOTP,
      );

      await _signInWithCredential(credential);
      
      // Check if this is a registration flow
      final pendingUserData = await AuthStorage.getUserData('pending_registration');
      if (pendingUserData != null) {
        final userData = UserModel.fromJson(pendingUserData);
        await _completeRegistration(userData);
        await AuthStorage.clearUserData('pending_registration');
      }

      return true;
    } catch (e) {
      developer.log('OTP verification error: $e', name: 'PhoneAuthService');
      _setError('Invalid OTP code. Please check and try again.');
      _setLoading(false);
      return false;
    }
  }

  // Sign in with credential
  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential = await _auth.signInWithCredential(credential);
      _currentUser = userCredential.user;
      _setLoading(false);
      developer.log('Successfully signed in: ${_currentUser?.uid}', name: 'PhoneAuthService');
    } catch (e) {
      developer.log('Sign in with credential error: $e', name: 'PhoneAuthService');
      _setError('Authentication failed. Please try again.');
      _setLoading(false);
    }
  }

  // Complete registration by saving user data
  Future<void> _completeRegistration(UserModel userData) async {
    try {
      if (_currentUser == null) return;

      // Update user data with actual Firebase UID
      final registeredUser = UserModel(
        uid: _currentUser!.uid,
        type: userData.type,
        phone: userData.phone,
        name: userData.name,
        gender: userData.gender,
        dob: userData.dob,
        address: userData.address,
        region: userData.region,
        district: userData.district,
        ward: userData.ward,
        street: userData.street,
        houseNumber: userData.houseNumber,
        checkNumber: userData.checkNumber,
        profilePicUrl: userData.profilePicUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Save to Firebase Realtime Database
      await _dbRef.child(_currentUser!.uid).set(registeredUser.toJson());
      
      // Save locally
      await AuthStorage.saveUser(registeredUser);
      
      _userProfile = registeredUser;
      developer.log('Registration completed successfully', name: 'PhoneAuthService');
    } catch (e) {
      developer.log('Complete registration error: $e', name: 'PhoneAuthService');
      throw Exception('Failed to complete registration: $e');
    }
  }

  // Complete test registration for development (bypasses Firebase Auth)
  Future<void> _completeTestRegistration(UserModel userData) async {
    try {
      // Create a mock user ID for test registration
      final testUserId = 'test_user_${DateTime.now().millisecondsSinceEpoch}';
      
      // Update user data with test UID
      final registeredUser = UserModel(
        uid: testUserId,
        type: userData.type,
        phone: userData.phone,
        name: userData.name,
        gender: userData.gender,
        dob: userData.dob,
        address: userData.address,
        region: userData.region,
        district: userData.district,
        ward: userData.ward,
        street: userData.street,
        houseNumber: userData.houseNumber,
        checkNumber: userData.checkNumber,
        profilePicUrl: userData.profilePicUrl,
        createdAt: DateTime.now().millisecondsSinceEpoch,
      );

      // Save locally for test user (skip Firebase for test)
      await AuthStorage.saveUser(registeredUser);
      
      _userProfile = registeredUser;
      
      // Mock current user for test
      // Note: In real testing, you might want to set up Firebase test environment
      
      developer.log('Test registration completed successfully for: ${userData.phone}', name: 'PhoneAuthService');
    } catch (e) {
      developer.log('Complete test registration error: $e', name: 'PhoneAuthService');
      throw Exception('Failed to complete test registration: $e');
    }
  }

  // Load user profile from database
  Future<void> _loadUserProfile(String uid) async {
    try {
      // Try to load from local storage first
      final localUser = await AuthStorage.loadUser();
      if (localUser != null && localUser.uid == uid) {
        _userProfile = localUser;
        notifyListeners();
        return;
      }

      // Load from Firebase if not in local storage
      final snapshot = await _dbRef.child(uid).get();
      if (snapshot.exists) {
        final userData = Map<String, dynamic>.from(snapshot.value as Map);
        _userProfile = UserModel.fromJson(userData);
        // Save locally for future use
        await AuthStorage.saveUser(_userProfile!);
      }
    } catch (e) {
      developer.log('Load user profile error: $e', name: 'PhoneAuthService');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await AuthStorage.clearUser();
      _currentUser = null;
      _userProfile = null;
      _verificationId = null;
      _setError(null);
      notifyListeners();
      developer.log('Successfully signed out', name: 'PhoneAuthService');
    } catch (e) {
      developer.log('Sign out error: $e', name: 'PhoneAuthService');
      _setError('Failed to sign out. Please try again.');
    }
  }

  // Resend OTP
  Future<bool> resendOTP(String phoneNumber, {UserModel? userData}) async {
    if (userData != null) {
      return await sendRegistrationOTP(phoneNumber, userData);
    } else {
      return await sendLoginOTP(phoneNumber);
    }
  }

  // Get user-friendly error message
  String _getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'invalid-phone-number':
        return 'The phone number is invalid.';
      case 'too-many-requests':
        return 'Too many requests. Please try again later.';
      case 'invalid-verification-code':
        return 'The verification code is invalid.';
      case 'invalid-verification-id':
        return 'The verification ID is invalid.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Please try again later.';
      case 'session-expired':
        return 'Session expired. Please request a new OTP.';
      case 'missing-client-identifier':
        return 'App configuration error. Please contact support.';
      case 'recaptcha-verification-failed':
        return 'Security verification failed. Please try again.';
      case 'missing-recaptcha-token':
        return 'Security verification required. Please try again.';
      case 'invalid-recaptcha-token':
        return 'Security verification failed. Please try again.';
      case 'recaptcha-action-mismatch':
        return 'Security verification error. Please try again.';
      case 'app-not-authorized':
        return 'App not authorized for this operation.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'web-context-cancelled':
        return 'Operation cancelled. Please try again.';
      case 'web-context-already-presented':
        return 'Another operation is in progress. Please wait.';
      case 'web-storage-unsupported':
        return 'Browser storage not supported.';
      default:
        return 'An error occurred (code: $errorCode). Please try again.';
    }
  }
}