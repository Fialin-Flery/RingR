import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../services/zego_call_service.dart';
import '../auth/login_page.dart';
import '../home/home_page.dart';

class LaunchPage extends StatefulWidget {
  const LaunchPage({super.key});

  @override
  State<LaunchPage> createState() =>
      _LaunchPageState();
}

class _LaunchPageState
    extends State<LaunchPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeAnimation;

  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration:
      const Duration(milliseconds: 1400),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _scaleAnimation =
        Tween<double>(
          begin: 0.94,
          end: 1.0,
        ).animate(
          CurvedAnimation(
            parent: _controller,
            curve: Curves.easeOutCubic,
          ),
        );

    _controller.forward();

    Timer(
      const Duration(milliseconds: 2200),
      _checkSession,
    );
  }

  Future<void> _checkSession() async {
    if (!mounted) return;

    final user =
        FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        await ZegoCallService
            .instance
            .initializeForCurrentUser();
      } catch (e) {
        debugPrint(
          'ZEGOCLOUD initialization failed: $e',
        );
      }

      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
          const HomePage(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
          const LoginPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme =
    Theme.of(context);

    final colorScheme =
        theme.colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration:
        BoxDecoration(
          gradient:
          LinearGradient(
            begin:
            Alignment.topLeft,
            end:
            Alignment.bottomRight,
            colors: [
              colorScheme.surface,
              colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.45),
            ],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity:
            _fadeAnimation,
            child:
            ScaleTransition(
              scale:
              _scaleAnimation,
              child:
              Image.asset(
                'assets/images/ringr_logo.png',
                width: 220,
                fit:
                BoxFit.contain,
              ),
            ),
          ),
        ),
      ),
    );
  }
}