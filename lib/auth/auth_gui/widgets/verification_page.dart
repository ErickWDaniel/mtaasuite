import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:provider/provider.dart';
import 'package:mtaasuite/auth/auth_gui/controllers/registration_controller.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/services/translation_service.dart';
import 'package:mtaasuite/screens/auth_success_screen.dart';

class VerificationPage extends StatefulWidget {
  final RegistrationController controller;

  const VerificationPage({super.key, required this.controller});

  @override
  State<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends State<VerificationPage> {
  final TextEditingController _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PhoneAuthService>(
      builder: (context, authService, child) {
        return SingleChildScrollView(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.tealAccent.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('auth.register.verification'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.tealAccent,
                  ),
                ),
                const SizedBox(height: 16),

                if (widget.controller.otpSent) ...[
                  Text(
                    tr('auth.register.otp_sent_to'),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text(
                      widget.controller.completePhoneNumber,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // OTP Input
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
                        _verifyOTP(context, authService, value);
                      }
                    },
                    onCompleted: (value) {
                      // Auto-verify when completed
                      _verifyOTP(context, authService, value);
                    },
                    beforeTextPaste: (text) {
                      // Allow pasting only numeric values
                      return RegExp(r'^\d{6}$').hasMatch(text ?? '');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Resend OTP
                  Center(
                    child: TextButton.icon(
                      onPressed: (authService.isLoading || !widget.controller.canResendOTP)
                          ? null
                          : () => widget.controller.sendOTP(),
                      icon: Icon(
                        widget.controller.canResendOTP ? Icons.refresh : Icons.timer,
                        color: widget.controller.canResendOTP ? Colors.tealAccent : Colors.grey,
                      ),
                      label: Text(
                        widget.controller.canResendOTP
                            ? tr('auth.register.resend_otp')
                            : 'Resend in ${widget.controller.resendCountdown}s',
                        style: TextStyle(
                          color: widget.controller.canResendOTP ? Colors.tealAccent : Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  const Center(
                    child: Icon(Icons.send, size: 64, color: Colors.tealAccent),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      tr('auth.register.ready_to_send_otp'),
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  if (widget.controller.completePhoneNumber.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        widget.controller.completePhoneNumber,
                        style: const TextStyle(
                          color: Colors.tealAccent,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _verifyOTP(BuildContext context, PhoneAuthService authService, String otpCode) async {
    if (otpCode.trim().length != 6) {
      _showSnack(context, 'Please enter a valid 6-digit OTP code');
      return;
    }

    authService.clearError();

    // Use controller's callback
    if (widget.controller.verifyOTP != null) {
      final success = await widget.controller.verifyOTP!(otpCode.trim());
      if (success) {
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const AuthSuccessScreen()),
        );
      } else if (authService.errorMessage != null) {
        _showSnack(context, authService.errorMessage!);
      }
    }
  }

  void _showSnack(BuildContext context, String message, {bool isError = true}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}