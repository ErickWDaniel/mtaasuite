import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:sms_autofill/sms_autofill.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/services/translation_service.dart';
import 'package:mtaasuite/auth/auth_gui/forgot_password_gui.dart';
import 'package:mtaasuite/auth/auth_gui/register_user_gui.dart';
import 'package:mtaasuite/screens/auth_success_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final GlobalKey<FormState> _phoneFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _otpFormKey = GlobalKey<FormState>();
  
  bool _otpSent = false;
  String _completePhoneNumber = '';
  String _signature = '';

  // Resend timer state
  Timer? _resendTimer;
  int _resendCountdown = 0;
  bool get _canResendOTP => _resendCountdown == 0;

  // Define supported languages here
  final List<_LanguageOption> _languages = [
    _LanguageOption(
      code: 'en',
      label: 'English',
      countryCode: 'US', // For flag
    ),
    _LanguageOption(
      code: 'sw',
      label: 'Swahili',
      countryCode: 'TZ', // For flag
    ),
  ];

  String _currentLanguageCode = 'en'; // default

  // Flag to prevent setState during dispose
  bool _isDisposing = false;

  @override
  void initState() {
    super.initState();
    // Use app-level translation state and listen for changes instead of re-initializing
    _currentLanguageCode =
        TranslationService.instance.currentLocale?.languageCode ??
        _currentLanguageCode;
    TranslationService.instance.addListener(_onTranslationChanged);
    
    // Initialize SMS autofill
    _initSmsListener();
  }

  // Initialize SMS autofill listener
  void _initSmsListener() async {
    try {
      final signature = await SmsAutoFill().getAppSignature;
      setState(() {
        _signature = signature ?? '';
      });
    } catch (e) {
      print('Error getting app signature: $e');
    }
  }

  // Listen for SMS when OTP is sent
  void _listenForSms() {
    SmsAutoFill().listenForCode();
  }

  // Stop listening for SMS
  void _stopListeningForSms() {
    SmsAutoFill().unregisterListener();
  }

  // Start resend timer
  void _startResendTimer() {
    if (_isDisposing) return; // Prevent starting timer on disposed widget
    
    setState(() {
      _resendCountdown = 60; // 60 seconds countdown
    });
    
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        // Widget disposed during timer - clean up and exit
        timer.cancel();
        _resendTimer = null;
        return;
      }
      
      if (_isDisposing) {
        // Widget is being disposed, cancel the timer
        timer.cancel();
        _resendTimer = null;
        return;
      }
      
      setState(() {
        _resendCountdown--;
      });
      
      if (_resendCountdown <= 0) {
        timer.cancel();
        _resendTimer = null;
      }
    });
  }

  // Stop resend timer
  void _stopResendTimer() {
    print('=== _stopResendTimer DEBUG START ===');
    print('Widget mounted: $mounted');
    print('Is disposing: $_isDisposing');
    
    _resendTimer?.cancel();
    _resendTimer = null;
    
    if (!_isDisposing && mounted) {
      setState(() {
        _resendCountdown = 0;
      });
      print('setState called successfully - countdown reset to 0');
    } else {
      print('Skipping setState - disposing or not mounted');
    }
    
    print('=== _stopResendTimer DEBUG END ===');
  }

  void _onTranslationChanged() {
    if (!_isDisposing && mounted) setState(() {});
  }

  @override
  void dispose() {
    _isDisposing = true;
    TranslationService.instance.removeListener(_onTranslationChanged);
    _phoneController.dispose();
    _otpController.dispose();
    _stopListeningForSms();
    _stopResendTimer();
    super.dispose();
  }

  void _setLanguage(String language) async {
    await TranslationService.instance.changeLanguage(language);
    setState(() {
      _currentLanguageCode = language;
    });
  }

  String _getFlagEmoji(String countryCode) {
    switch (countryCode) {
      case 'US':
        return '🇺🇸';
      case 'TZ':
        return '🇹🇿';
      default:
        return '🏳️';
    }
  }

  Widget _buildLanguageMenu() {
    return Center(
      child: PopupMenuButton<String>(
        tooltip: tr('common.language_english'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.tealAccent),
          ),
          child: Text(
            _getFlagEmoji(
              _languages
                  .firstWhere(
                    (l) => l.code == _currentLanguageCode,
                    orElse: () => _languages[0],
                  )
                  .countryCode,
            ),
            style: const TextStyle(fontSize: 22),
          ),
        ),
        onSelected: (value) {
          _setLanguage(value);
        },
        itemBuilder: (context) => _languages.map((lang) {
          return PopupMenuItem<String>(
            value: lang.code,
            child: Row(
              children: [
                Text(
                  _getFlagEmoji(lang.countryCode),
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 8),
                Text(lang.label),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  void _sendOTP() async {
    if (!_phoneFormKey.currentState!.validate()) return;
    
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    authService.clearError();
    
    final success = await authService.sendLoginOTP(_completePhoneNumber);
    
    if (success) {
      setState(() {
        _otpSent = true;
      });
      _showSnack(tr('auth.login.otp_sent'), isError: false);
      // Start listening for SMS
      _listenForSms();
      // Start resend timer
      _startResendTimer();
    }
  }

  void _verifyOTP() async {
    if (!_otpFormKey.currentState!.validate()) return;
    
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    authService.clearError();
    
    final success = await authService.verifyOTP(_otpController.text.trim());
    
    if (success) {
      // Navigate to success screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AuthSuccessScreen(),
        ),
      );
    } else if (authService.errorMessage != null) {
      _showSnack(authService.errorMessage!);
    }
  }

  void _showSnack(String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetToPhoneInput() {
    setState(() {
      _otpSent = false;
      _otpController.clear();
    });
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    authService.clearError();
    _stopResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PhoneAuthService>(
        builder: (context, authService, child) {
          return Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Card(
                        color: Colors.grey[900],
                        elevation: 8,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/images/mtaasuitelogo.png',
                                height: 80,
                                width: 80,
                              ),
                              const SizedBox(height: 20),
                              Text(
                                tr('auth.login.title'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.tealAccent,
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Phone number input or OTP input
                              if (!_otpSent) 
                                _buildPhoneInputSection(authService)
                              else 
                                _buildOTPInputSection(authService),

                              const SizedBox(height: 20),
                              
                              // Error message display
                              if (authService.errorMessage != null)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.red[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.red[200]!),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red[700],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          authService.errorMessage!,
                                          style: TextStyle(color: Colors.red[700]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Action button
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.tealAccent,
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  onPressed: authService.isLoading 
                                    ? null 
                                    : (!_otpSent ? _sendOTP : _verifyOTP),
                                  child: authService.isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.black54,
                                        ),
                                      )
                                    : Text(
                                        !_otpSent
                                            ? tr('auth.login.send_otp')
                                            : tr('auth.login.verify_otp'),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                ),
                              ),

                              // Back to phone input (when OTP is shown)
                              if (_otpSent) ...[
                                const SizedBox(height: 12),
                                TextButton(
                                  onPressed: _resetToPhoneInput,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.arrow_back,
                                        color: Colors.tealAccent,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tr('auth.login.change_phone'),
                                        style: const TextStyle(color: Colors.tealAccent),
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordPage(),
                                    ),
                                  );
                                },
                                child: Text(
                                  tr('auth.login.forgot_password'),
                                  style: const TextStyle(color: Colors.tealAccent),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: Text(
                                      tr('auth.login.no_account'),
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Expanded(
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => const RegisterPage(),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        tr('auth.login.create_account'),
                                        style: const TextStyle(
                                          color: Colors.tealAccent,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLanguageMenu(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPhoneInputSection(PhoneAuthService authService) {
    return Form(
      key: _phoneFormKey,
      child: IntlPhoneField(
        controller: _phoneController,
        decoration: InputDecoration(
          labelText: tr('auth.login.phone_label'),
          labelStyle: const TextStyle(color: Colors.tealAccent),
          hintText: tr('auth.login.phone_hint'),
          hintStyle: const TextStyle(color: Colors.grey),
          prefixIcon: const Icon(Icons.phone, color: Colors.tealAccent),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.tealAccent, width: 2),
          ),
        ),
        initialCountryCode: 'TZ',
        style: const TextStyle(color: Colors.white),
        dropdownTextStyle: const TextStyle(color: Colors.white),
        onChanged: (phone) {
          _completePhoneNumber = phone.completeNumber;
        },
        validator: (phone) {
          if (phone == null || phone.number.isEmpty) {
            return tr('validation.required');
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOTPInputSection(PhoneAuthService authService) {
    return Form(
      key: _otpFormKey,
      child: Column(
        children: [
          Text(
            tr('auth.login.otp_sent_to'),
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            _completePhoneNumber,
            style: const TextStyle(
              color: Colors.tealAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          PinCodeTextField(
            appContext: context,
            controller: _otpController,
            length: 6,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            animationType: AnimationType.fade,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius: BorderRadius.circular(8),
              fieldHeight: 50,
              fieldWidth: 45,
              activeFillColor: Colors.grey[800],
              activeColor: Colors.tealAccent,
              inactiveColor: Colors.grey[600],
              selectedColor: Colors.tealAccent,
              selectedFillColor: Colors.grey[750],
              inactiveFillColor: Colors.grey[850],
            ),
            animationDuration: const Duration(milliseconds: 300),
            backgroundColor: Colors.transparent,
            enableActiveFill: true,
            textStyle: const TextStyle(color: Colors.white, fontSize: 16),
            autoFocus: true,
            enablePinAutofill: true,
            onChanged: (value) {
              // Auto-verify when 6 digits are entered
              if (value.length == 6) {
                _verifyOTP();
              }
            },
            onCompleted: (value) {
              // Auto-verify when completed
                _verifyOTP();
            },
            beforeTextPaste: (text) {
              // Allow pasting only numeric values
              return RegExp(r'^\d{6}$').hasMatch(text ?? '');
            },
            validator: (value) {
              if (value == null || value.length != 6) {
                return tr('auth.login.otp_invalid');
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: (authService.isLoading || !_canResendOTP) 
              ? null 
              : () => _sendOTP(),
            icon: Icon(
              _canResendOTP ? Icons.refresh : Icons.timer,
              color: _canResendOTP ? Colors.tealAccent : Colors.grey,
            ),
            label: Text(
              _canResendOTP 
                ? tr('auth.login.resend_otp')
                : 'Resend in ${_resendCountdown}s',
              style: TextStyle(
                color: _canResendOTP ? Colors.tealAccent : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Helper class for language options
class _LanguageOption {
  final String code; // e.g. "en"
  final String label; // e.g. "English"
  final String countryCode; // For flag icon

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.countryCode,
  });
}
