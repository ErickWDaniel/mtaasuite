import 'package:flutter/material.dart';
import 'package:mtaasuite/auth/auth_core/forgot_password.dart';
import 'package:mtaasuite/services/translation_service.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final ForgotPasswordCore _core = ForgotPasswordCore();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _otpCtrl = TextEditingController();

  bool _otpSent = false;
  bool _loading = false;

  String _normalizePhone(String phone) {
    final p = phone.trim();
    if (p.startsWith('+')) return p;
    if (p.startsWith('0')) return '+255${p.substring(1)}';
    if (p.startsWith('255')) return '+$p';
    return p;
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _sendOTP() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) {
      _showSnack(tr('auth.forgot.enter_phone'));
      return;
    }
    setState(() => _loading = true);
    await _core.sendOTP(
      _normalizePhone(phone),
      () {
        setState(() {
          _otpSent = true;
          _loading = false;
        });
        _showSnack(tr('auth.forgot.otp_sent'));
      },
      (error) {
        setState(() => _loading = false);
        _showSnack(error);
      },
    );
  }

  Future<void> _verifyOTP() async {
    final code = _otpCtrl.text.trim();
    if (code.isEmpty) {
      _showSnack(tr('auth.forgot.enter_otp'));
      return;
    }
    setState(() => _loading = true);
    await _core.verifyOTP(code, context, (error) {
      setState(() => _loading = false);
      _showSnack(error);
    });
    if (!mounted) return;
    setState(() => _loading = false);
    _showSnack(tr('auth.forgot.success'));
    // Pop back so AuthWrapper rebuilds and routes to the dashboard
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(tr('auth.forgot.title')),
        backgroundColor: Colors.tealAccent,
        foregroundColor: Colors.black,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
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
                  Icon(Icons.lock_reset, size: 80, color: Colors.tealAccent),
                  const SizedBox(height: 20),
                  Text(
                    tr('auth.forgot.subtitle'),
                    style: const TextStyle(fontSize: 18, color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  if (!_otpSent)
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: tr('auth.forgot.phone_label'),
                        hintText: tr('auth.forgot.phone_hint'),
                        labelStyle: const TextStyle(color: Colors.tealAccent),
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.phone,
                          color: Colors.tealAccent,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.tealAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    )
                  else
                    TextField(
                      controller: _otpCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: tr('auth.forgot.otp_label'),
                        hintText: tr('auth.forgot.otp_hint'),
                        labelStyle: const TextStyle(color: Colors.tealAccent),
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(
                          Icons.sms,
                          color: Colors.tealAccent,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.tealAccent,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.tealAccent,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _loading
                      ? const CircularProgressIndicator(
                          color: Colors.tealAccent,
                        )
                      : ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.tealAccent,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 40,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: !_otpSent ? _sendOTP : _verifyOTP,
                          child: Text(
                            !_otpSent
                                ? tr('auth.forgot.send_otp')
                                : tr('auth.forgot.verify_otp'),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
