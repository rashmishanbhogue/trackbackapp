// splashscreen.dart, route to onboarding to home or direct home based on user onboarding

import 'package:flutter/material.dart';
import 'package:trackbackapp/screens/onboarding_screen.dart';
import 'dart:async';
import '../theme.dart';
import '../widgets/navbar.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  SplashScreenState createState() => SplashScreenState();
}

class SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  // late Timer navigationTimer; // avoid potential memory leak

  // local to avoid gloabl lifecycle issues
  late final AnimationController controller;
  // fadein animation for logo
  late final Animation<double> opacity;
  // subtle scale up to avoid static feel
  late final Animation<double> scale;

  // flag for routing decision, palceholder for future persisted user state
  bool showOnboarding = true; // flag

  @override
  void initState() {
    super.initState();

    // initialise splash animation
    controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));

    opacity = CurvedAnimation(parent: controller, curve: Curves.easeInOut);

    scale = Tween<double>(begin: 0.96, end: 1.0)
        .animate(CurvedAnimation(parent: controller, curve: Curves.easeOut));

    // start animation immediately on launch
    controller.forward();

    // navigate after animation settles, mounted check to prevent context access after dispose
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              showOnboarding ? const OnboardingScreen() : const CustomNavBar(),
        ),
      );
    });
  }

  @override
  void dispose() {
    // clean up after animation controller to avoid leaks
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      // solid background
      backgroundColor: AppTheme.weekHighlightDark,
      body: Center(
        child: Hero(
          // shared hero tag for future animated transition
          tag: 'trackback-logo',
          child: Text(
            'trackback',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AppTheme.maintenanceDarkest,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}
