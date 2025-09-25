import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mtaasuite/auth/auth_gui/controllers/registration_controller.dart';
import 'package:mtaasuite/auth/auth_gui/widgets/personal_info_form.dart';
import 'package:mtaasuite/auth/auth_gui/widgets/location_info_form.dart';
import 'package:mtaasuite/auth/auth_gui/widgets/verification_page.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/services/translation_service.dart';
import 'package:mtaasuite/screens/auth_success_screen.dart';
import 'package:mtaasuite/auth/model/user_mode.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  late RegistrationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = RegistrationController(
      sendRegistrationOTP: _sendRegistrationOTP,
      verifyOTP: _verifyOTP,
    );
    TranslationService.instance.addListener(_onTranslationChanged);
  }

  @override
  void dispose() {
    TranslationService.instance.removeListener(_onTranslationChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onTranslationChanged() {
    setState(() {});
  }

  Future<bool> _sendRegistrationOTP(String phone, UserModel user) async {
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    authService.clearError();
    return await authService.sendRegistrationOTP(phone, user);
  }

  Future<bool> _verifyOTP(String otp) async {
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    authService.clearError();
    return await authService.verifyOTP(otp);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<RegistrationController>(
      create: (_) => _controller,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(tr('auth.register.title')),
          elevation: 0,
          backgroundColor: Colors.grey[900],
          foregroundColor: Colors.tealAccent,
        ),
        body: Consumer2<RegistrationController, PhoneAuthService>(
          builder: (context, controller, authService, child) {
            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.grey[900]!.withOpacity(0.8), Colors.black],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Progress Indicator
                    LinearProgressIndicator(
                      value: (controller.currentPage + 1) / 3,
                      backgroundColor: Colors.grey[700],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Colors.tealAccent,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Step indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: index <= controller.currentPage
                                ? Colors.tealAccent
                                : Colors.grey[600],
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

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

                    // PageView
                    Expanded(
                      child: PageView(
                        controller: controller.pageController,
                        onPageChanged: controller.onPageChanged,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          KeepAliveForm(child: PersonalInfoForm(controller: controller)),
                          KeepAliveForm(child: LocationInfoForm(controller: controller)),
                          KeepAliveForm(child: VerificationPage(controller: controller)),
                        ],
                      ),
                    ),

                    // Navigation Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (controller.currentPage > 0)
                            ElevatedButton.icon(
                              onPressed: authService.isLoading
                                  ? null
                                  : controller.previousPage,
                              icon: const Icon(Icons.arrow_back),
                              label: Text(tr('app.previous')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[700],
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          ElevatedButton.icon(
                            onPressed: authService.isLoading
                                ? null
                                : (controller.currentPage < 2
                                    ? controller.nextPage
                                    : controller.sendOTP),
                            icon: authService.isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black54,
                                    ),
                                  )
                                : Icon(
                                    controller.currentPage < 2
                                        ? Icons.arrow_forward
                                        : Icons.send,
                                  ),
                            label: Text(
                              controller.currentPage < 2
                                  ? tr('app.next')
                                  : tr('auth.register.send_otp'),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.tealAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
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
}

class KeepAliveForm extends StatefulWidget {
  final Widget child;
  const KeepAliveForm({super.key, required this.child});

  @override
  State<KeepAliveForm> createState() => _KeepAliveFormState();
}

class _KeepAliveFormState extends State<KeepAliveForm>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
