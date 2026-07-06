import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeIn)),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    _controller.forward();
    _startNavigationSequence();
  }

  void _startNavigationSequence() async {
    // Wait for at least 3 seconds of "wow" factor
    await Future.delayed(const Duration(seconds: 3));
    
    if (!mounted) return;
    
    // Check if auth is initialized
    final authService = Provider.of<AuthService>(context, listen: false);
    
    if (authService.isInitialized) {
      _navigateAway();
    } else {
      // If not initialized, wait for it
      debugPrint('⏳ Splash: Waiting for AuthService to initialize...');
      
      // We can use a listener or just a periodic check for simplicity
      // since isInitialized only changes once.
      _waitForInitialization();
    }
  }

  void _waitForInitialization() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    while (!authService.isInitialized) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;
    }
    _navigateAway();
  }

  void _navigateAway() {
    if (mounted) {
      debugPrint('🚀 Splash: Navigating to initial route...');
      // The router's redirect logic will handle where we actually go
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Background subtle gradient or decorative elements could go here
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          ),
                          child: ClipOval(
                            child: ColorFiltered(
                              colorFilter: ColorFilter.mode(
                                Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.transparent,
                                BlendMode.srcATop,
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: AppTheme.primary.withOpacity(0.1),
                                    child: const Icon(Icons.rocket_launch, size: 80, color: AppTheme.primary),
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'BIDAYA',
                          style: GoogleFonts.manrope(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'More than theory. Real experience.',
                          style: GoogleFonts.manrope(
                            fontSize: 16,
                            color: AppTheme.getAdaptiveTextSecondary(context),
                            letterSpacing: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary.withOpacity(0.3)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
