import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/user_service.dart';
import '../home/home_page.dart';
import '../registration/registration_page.dart';
import '../../services/zego_call_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final UserService _userService = UserService.instance;

  late AnimationController _animationController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // AuthService methods are STATIC.
      final result = await AuthService.signInWithGoogle();

      if (!mounted || result == null) return;
      if (result != null) await ZegoCallService.instance.initializeForCurrentUser();

      final user = result.user;

      if (user == null) {
        throw Exception(
          'Unable to retrieve Google account.',
        );
      }

      final profileExists =
      await _userService.userProfileExists(user.uid);

      if (!mounted) return;

      if (profileExists) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const HomePage(),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const ProfilePage(),
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'Google sign-in failed: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Google sign-in failed. Please try again.',
          ),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ---------------- LOGO ----------------
                    Image.asset(
                      'assets/images/ringr_logo_cropped.png',
                      width: 190,
                      fit: BoxFit.contain,
                    ),

                    const SizedBox(height: 48),

                    // ---------------- TITLE ----------------
                    Text(
                      'Welcome to Ringr',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                      ),
                    ),

                    const SizedBox(height: 10),

                    Text(
                      'Connect. Call. Stay close.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 42),

                    // ---------------- GOOGLE BUTTON ----------------
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton(
                        onPressed:
                        _isLoading
                            ? null
                            : _signInWithGoogle,
                        style: OutlinedButton.styleFrom(
                          backgroundColor:
                          colorScheme.surface,
                          foregroundColor:
                          colorScheme.onSurface,
                          side: BorderSide(
                            color:
                            colorScheme.outlineVariant,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child:
                        _isLoading
                            ? SizedBox(
                          width: 22,
                          height: 22,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2.2,
                            color:
                            colorScheme.primary,
                          ),
                        )
                            : Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children: [
                            Image.asset(
                              'assets/images/google.png',
                              width: 22,
                              height: 22,
                            ),

                            const SizedBox(
                              width: 14,
                            ),

                            Text(
                              'Continue with Google',
                              style:
                              theme
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ---------------- FOOTER ----------------
                    Text(
                      'Your calls, all in one place.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color:
                        colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}