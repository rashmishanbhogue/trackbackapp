// onboarding_screen.dart, onboarding for the firsttime user - placeholder for now

import 'package:flutter/material.dart';
import '../widgets/navbar.dart';
import '../theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => OnboardingScreenState();
}

class OnboardingScreenState extends State<OnboardingScreen> {
  // controls horizontal onbaording pages
  final PageController controller = PageController();
  // track current page index for nav + state
  int currentPage = 0;

  // drive logo lift animation after splash hero transition
  bool moveUp = false;
  // delay content rendering until logo settles
  bool showContent = false;

  @override
  void initState() {
    super.initState();
    // allow hero transition from splash to finish first
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() => moveUp = true);
      }
    });

    // show content after hero finishes moving up, by fading in
    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() => showContent = true);
    });
  }

  // palceholder dummies
  final List<String> pages = [
    'Capture your thoughts.',
    'Reflect on your patterns.',
    'Understand yourself better.'
  ];

  void goNext() {
    if (currentPage < pages.length - 1) {
      controller.nextPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void goBack() {
    if (currentPage > 0) {
      controller.previousPage(
          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  void completeOnboarding() {
    // placeholder completion, should persist onboarding completion + auth state
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CustomNavBar()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = currentPage == pages.length - 1;

    return Scaffold(
      body: SafeArea(
          child: Stack(
        children: [
          // hero shared with splash
          AnimatedAlign(
            alignment: moveUp ? const Alignment(0, -0.8) : Alignment.center,
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOut,
            child: const Hero(
              tag: 'trackback-logo',
              child: Text(
                'trackback',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.weekHighlightDark,
                ),
              ),
            ),
          ),

          // onboarding content
          Positioned.fill(
            child: AnimatedOpacity(
              opacity: showContent ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeIn,
              child: Column(
                children: [
                  const SizedBox(height: 96), // space for logo animation

                  // swipable pages
                  Expanded(
                    child: PageView.builder(
                      controller: controller,
                      itemCount: pages.length,
                      onPageChanged: (index) {
                        setState(() => currentPage = index);
                      },
                      itemBuilder: (_, index) {
                        return Center(
                          child: Text(
                            pages[index],
                            style: theme.textTheme.headlineSmall,
                            textAlign: TextAlign.center,
                          ),
                        );
                      },
                    ),
                  ),

                  // arrow navigation
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 24),
                    child: isLastPage
                        ? Column(
                            children: [
                              // placeholder auth actions - dummies for now
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: completeOnboarding,
                                  child: const Text('Sign in with Google'),
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: completeOnboarding,
                                  child: const Text('Sign in with Apple'),
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                onPressed: currentPage == 0 ? null : goBack,
                                icon: const Icon(Icons.arrow_back),
                              ),
                              IconButton(
                                onPressed: goNext,
                                icon: const Icon(Icons.arrow_forward),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      )),
    );
  }
}
