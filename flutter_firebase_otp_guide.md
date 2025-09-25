# Complete Flutter Firebase OTP Implementation Guide

## 1. Project Setup

### Add Firebase to your Flutter project

#### Install Firebase CLI
```bash
npm install -g firebase-tools
dart pub global activate flutterfire_cli
```

#### Configure Firebase
```bash
firebase login
flutterfire configure
```

### Add Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  
  # UI & State Management
  provider: ^6.1.1
  pin_code_fields: ^8.0.1
  
  # Optional utilities
  intl_phone_field: ^3.2.0
  fluttertoast: ^8.2.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
```

## 2. Firebase Configuration

### Android Configuration (android/app/build.gradle)
```gradle
android {
    compileSdkVersion 34

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 34
        multiDexEnabled true
    }
}

dependencies {
    implementation 'androidx.multidex:multidex:2.0.1'
}
```

### iOS Configuration (ios/Runner/Info.plist)
```xml
<!-- Add before closing </dict> -->
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLName</key>
        <string>REVERSED_CLIENT_ID</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>YOUR_REVERSED_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 3. Main App Setup (main.dart)

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/phone_auth_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        title: 'Flutter OTP Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: PhoneAuthScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
```

## 4. Auth Service (services/auth_service.dart)

```dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isLoading = false;
  String? _verificationId;
  String? _errorMessage;
  User? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  User? get user => _user;
  bool get isAuthenticated => _user != null;

  AuthService() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _errorMessage = error;
    notifyListeners();
  }

  Future<bool> sendOTP(String phoneNumber) async {
    try {
      _setLoading(true);
      _setError(null);

      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification (Android only)
          await _signInWithCredential(credential);
        },
        verificationFailed: (FirebaseAuthException e) {
          _setError(_getErrorMessage(e.code));
          _setLoading(false);
        },
        codeSent: (String verificationId, int? resendToken) {
          _verificationId = verificationId;
          _setLoading(false);
        },
        timeout: Duration(seconds: 60),
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );

      return true;
    } catch (e) {
      _setError('Failed to send OTP: ${e.toString()}');
      _setLoading(false);
      return false;
    }
  }

  Future<bool> verifyOTP(String otp) async {
    try {
      _setLoading(true);
      _setError(null);

      if (_verificationId == null) {
        _setError('Verification ID is null. Please resend OTP.');
        _setLoading(false);
        return false;
      }

      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );

      await _signInWithCredential(credential);
      return true;
    } catch (e) {
      _setError('Invalid OTP. Please try again.');
      _setLoading(false);
      return false;
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      UserCredential userCredential = await _auth.signInWithCredential(credential);
      _user = userCredential.user;
      _setLoading(false);
    } on FirebaseAuthException catch (e) {
      _setError(_getErrorMessage(e.code));
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _user = null;
    _verificationId = null;
    _setError(null);
    notifyListeners();
  }

  Future<bool> resendOTP(String phoneNumber) async {
    return await sendOTP(phoneNumber);
  }

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
      default:
        return 'An error occurred. Please try again.';
    }
  }
}
```

## 5. Phone Auth Screen (screens/phone_auth_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';
import 'otp_verification_screen.dart';
import 'home_screen.dart';

class PhoneAuthScreen extends StatefulWidget {
  @override
  _PhoneAuthScreenState createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String _completePhoneNumber = '';

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Navigate to home if already authenticated
        if (authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => HomeScreen()),
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Phone Authentication'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.phone_android,
                    size: 80,
                    color: Colors.blue[600],
                  ),
                  SizedBox(height: 32),
                  Text(
                    'Enter your phone number',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'We will send you a verification code',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),
                  IntlPhoneField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    initialCountryCode: 'IN',
                    onChanged: (phone) {
                      _completePhoneNumber = phone.completeNumber;
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 24),
                  if (authService.errorMessage != null)
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[200]!),
                      ),
                      child: Text(
                        authService.errorMessage!,
                        style: TextStyle(color: Colors.red[700]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton(
                    onPressed: authService.isLoading ? null : _sendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: authService.isLoading
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Text('Sending OTP...'),
                            ],
                          )
                        : Text(
                            'Send OTP',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _sendOTP() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      bool success = await authService.sendOTP(_completePhoneNumber);
      
      if (success && !authService.isLoading) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => OTPVerificationScreen(
              phoneNumber: _completePhoneNumber,
            ),
          ),
        );
      }
    }
  }
}
```

## 6. OTP Verification Screen (screens/otp_verification_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'dart:async';
import '../services/auth_service.dart';
import 'home_screen.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String phoneNumber;

  OTPVerificationScreen({required this.phoneNumber});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  String _otpCode = '';
  Timer? _timer;
  int _resendTime = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    _canResend = false;
    _resendTime = 60;
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_resendTime > 0) {
          _resendTime--;
        } else {
          _canResend = true;
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Navigate to home if authenticated
        if (authService.isAuthenticated) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => HomeScreen()),
              (route) => false,
            );
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Verify Phone'),
            backgroundColor: Colors.blue[600],
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 32),
                Icon(
                  Icons.message,
                  size: 80,
                  color: Colors.blue[600],
                ),
                SizedBox(height: 32),
                Text(
                  'Verification Code',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'We have sent a verification code to',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  widget.phoneNumber,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue[600],
                  ),
                ),
                SizedBox(height: 32),
                PinCodeTextField(
                  appContext: context,
                  length: 6,
                  keyboardType: TextInputType.number,
                  animationType: AnimationType.fade,
                  pinTheme: PinTheme(
                    shape: PinCodeFieldShape.box,
                    borderRadius: BorderRadius.circular(12),
                    fieldHeight: 50,
                    fieldWidth: 45,
                    activeFillColor: Colors.blue[50],
                    activeColor: Colors.blue[600],
                    inactiveColor: Colors.grey[300],
                    selectedColor: Colors.blue[600],
                  ),
                  animationDuration: Duration(milliseconds: 300),
                  backgroundColor: Colors.transparent,
                  enableActiveFill: true,
                  onChanged: (value) {
                    setState(() {
                      _otpCode = value;
                    });
                  },
                  onCompleted: (value) {
                    _verifyOTP();
                  },
                ),
                SizedBox(height: 24),
                if (authService.errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Text(
                      authService.errorMessage!,
                      style: TextStyle(color: Colors.red[700]),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ElevatedButton(
                  onPressed: authService.isLoading || _otpCode.length != 6
                      ? null
                      : _verifyOTP,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: authService.isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Verifying...'),
                          ],
                        )
                      : Text(
                          'Verify OTP',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
                SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Didn't receive the code? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    GestureDetector(
                      onTap: _canResend ? _resendOTP : null,
                      child: Text(
                        _canResend 
                            ? 'Resend OTP' 
                            : 'Resend OTP (${_resendTime}s)',
                        style: TextStyle(
                          color: _canResend ? Colors.blue[600] : Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _verifyOTP() async {
    if (_otpCode.length == 6) {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.verifyOTP(_otpCode);
    }
  }

  void _resendOTP() async {
    if (_canResend) {
      final authService = Provider.of<AuthService>(context, listen: false);
      bool success = await authService.resendOTP(widget.phoneNumber);
      
      if (success) {
        _startResendTimer();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('OTP resent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }
}
```

## 7. Home Screen (screens/home_screen.dart)

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'phone_auth_screen.dart';

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Home'),
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            actions: [
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: () => _signOut(context, authService),
              ),
            ],
          ),
          body: Center(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 100,
                    color: Colors.green[600],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Phone Verified Successfully!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green[700],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Phone Number:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    authService.user?.phoneNumber ?? 'Unknown',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[600],
                    ),
                  ),
                  SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () => _signOut(context, authService),
                    icon: Icon(Icons.logout),
                    label: Text('Sign Out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[600],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _signOut(BuildContext context, AuthService authService) async {
    await authService.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => PhoneAuthScreen()),
      (route) => false,
    );
  }
}
```

## 8. Firebase Console Configuration

### Enable Phone Authentication:
1. Go to Firebase Console → Authentication
2. Click "Sign-in method" tab
3. Enable "Phone" provider
4. Add test phone numbers for development:
   - `+1 650-555-3434` (code: `123456`)
   - `+1 650-555-3435` (code: `654321`)

### Add SHA fingerprints (Android):
```bash
# Debug key
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android

# Release key (for production)
keytool -list -v -keystore /path/to/your/keystore.jks -alias your-alias
```

## 9. Platform-specific Configuration

### Android - Enable MultiDex (android/app/src/main/java/.../MainActivity.java)
```java
import androidx.multidex.MultiDex;
import io.flutter.embedding.android.FlutterMultiDexApplication;

public class MainApplication extends FlutterMultiDexApplication {
    @Override
    public void onCreate() {
        super.onCreate();
        MultiDex.install(this);
    }
}
```

## 10. Testing & Deployment

### Test Phone Numbers:
```dart
// Use these in development
Map<String, String> testNumbers = {
  '+1 650-555-3434': '123456',
  '+1 650-555-3435': '654321',
  '+91 9876543210': '123456', // Add your own
};
```

### Production Checklist:
- [ ] Remove test phone numbers
- [ ] Enable App Check
- [ ] Set up reCAPTCHA (web)
- [ ] Configure rate limiting
- [ ] Test on real devices
- [ ] Monitor authentication metrics
- [ ] Set up proper error logging

## 11. Common Issues & Solutions

### Issue: OTP not received
**Solution:** Check phone number format, Firebase quotas, and test with test numbers first

### Issue: Auto-verification not working
**Solution:** Ensure proper SHA fingerprints are added and Google Play Services is updated

### Issue: iOS build errors
**Solution:** Run `cd ios && pod install` and ensure iOS deployment target is 11.0+

This implementation provides a complete, production-ready Flutter OTP system with modern UI, proper state management, and comprehensive error handling.