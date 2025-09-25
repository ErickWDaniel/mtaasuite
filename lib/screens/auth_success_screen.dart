import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:animate_do/animate_do.dart';
import 'package:mtaasuite/services/phone_auth_service.dart';
import 'package:mtaasuite/services/translation_service.dart';
import 'package:mtaasuite/dashboards/citizen/citizenlandpage.dart';
import 'package:mtaasuite/dashboards/ward/wardlandpage.dart';

class AuthSuccessScreen extends StatefulWidget {
  const AuthSuccessScreen({super.key});

  @override
  State<AuthSuccessScreen> createState() => _AuthSuccessScreenState();
}

class _AuthSuccessScreenState extends State<AuthSuccessScreen>
    with TickerProviderStateMixin {
  late ConfettiController _confettiController;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize confetti controller
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    
    // Initialize animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Scale animation for the success icon
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    // Fade animation for text
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animations and confetti
    _startSuccessSequence();
  }

  void _startSuccessSequence() async {
    // Start confetti
    _confettiController.play();
    
    // Start scale animation
    _animationController.forward();
    
    // Wait for animations to complete, then navigate
    await Future.delayed(const Duration(seconds: 4));
    
    if (mounted) {
      _navigateToDashboard();
    }
  }

  void _navigateToDashboard() {
    final authService = Provider.of<PhoneAuthService>(context, listen: false);
    final userType = authService.userProfile?.type ?? 'citizen';

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) {
          if (userType == 'ward') {
            return const WardDashboard();
          } else {
            return const CitizenDashboard();
          }
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(1.0, 0.0);
          const end = Offset.zero;
          const curve = Curves.ease;

          var tween = Tween(begin: begin, end: end).chain(
            CurveTween(curve: curve),
          );

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<PhoneAuthService>(
        builder: (context, authService, child) {
          final user = authService.userProfile;
          final userName = user?.name ?? 'User';
          final userType = user?.type ?? 'citizen';
          
          return Stack(
            alignment: Alignment.center,
            children: [
              // Gradient background
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.tealAccent.withOpacity(0.1),
                      Colors.black,
                      Colors.tealAccent.withOpacity(0.1),
                    ],
                  ),
                ),
              ),
              
              // Confetti
              Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confettiController,
                  blastDirection: 3.14 / 2, // downward
                  particleDrag: 0.05,
                  emissionFrequency: 0.03,
                  numberOfParticles: 30,
                  gravity: 0.1,
                  shouldLoop: false,
                  colors: const [
                    Colors.tealAccent,
                    Colors.cyanAccent,
                    Colors.greenAccent,
                    Colors.blueAccent,
                  ],
                ),
              ),
              
              // Main content
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Success icon with animation
                  AnimatedBuilder(
                    animation: _scaleAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _scaleAnimation.value,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.tealAccent,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.tealAccent.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check_circle,
                            size: 80,
                            color: Colors.black,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Success message with fade animation
                  FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 500),
                          child: Text(
                            tr('auth.success.title'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.tealAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 700),
                          child: Text(
                            '${tr('auth.success.welcome')} $userName!',
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        FadeInUp(
                          duration: const Duration(milliseconds: 800),
                          delay: const Duration(milliseconds: 900),
                          child: Text(
                            userType == 'ward' 
                              ? tr('auth.success.ward_message')
                              : tr('auth.success.citizen_message'),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 60),
                  
                  // Loading indicator with text
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 1100),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                          color: Colors.tealAccent,
                          strokeWidth: 3,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          tr('auth.success.preparing_dashboard'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Skip button (bottom right)
              Positioned(
                bottom: 40,
                right: 20,
                child: FadeInUp(
                  duration: const Duration(milliseconds: 800),
                  delay: const Duration(milliseconds: 1300),
                  child: TextButton.icon(
                    onPressed: _navigateToDashboard,
                    icon: const Icon(
                      Icons.skip_next,
                      color: Colors.tealAccent,
                    ),
                    label: Text(
                      tr('auth.success.skip'),
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}