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

  // palceholder dummies
  final List<OnboardingPageData> pages = const [
    OnboardingPageData(
        title: 'Track what you did,',
        subtitle: 'not what you failed to do.',
        imageAsset: 'assets/images/onboarding1.png'),
    OnboardingPageData(
        title: 'Get it out of your head,',
        subtitle: 'without turning it into a task.',
        imageAsset: 'assets/images/onboarding2.png'),
    OnboardingPageData(
        title: 'Notice patterns,',
        subtitle: 'no judgement, just insight.',
        imageAsset: 'assets/images/onboarding3.png'),
  ];

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
          child: Column(
        children: [
          // hero shared with splash
          AnimatedPadding(
            padding: EdgeInsets.only(
              top: moveUp ? 16 : MediaQuery.of(context).size.height * 0.35,
            ),
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
          Expanded(
            child: AnimatedOpacity(
              opacity: showContent ? 1 : 0,
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeIn,
              child: Column(
                children: [
                  // swipable pages
                  Expanded(
                    child: PageView.builder(
                        controller: controller,
                        itemCount: pages.length,
                        onPageChanged: (index) {
                          setState(() => currentPage = index);
                        },
                        itemBuilder: (_, index) {
                          final page = pages[index];

                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        MediaQuery.of(context).size.height *
                                            0.55,
                                  ),
                                  child: AspectRatio(
                                    aspectRatio: 9 / 16, // phone screen ratio
                                    child: Container(
                                      decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          border: Border.all(
                                              color: theme.dividerColor,
                                              width: 1),
                                          boxShadow: const [
                                            BoxShadow(
                                                color: Colors.black12,
                                                blurRadius: 12,
                                                offset: Offset(0, 6))
                                          ]),
                                      child: Image.asset(
                                        page.imageAsset,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Text(
                                page.title,
                                style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.greyDark),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                page.subtitle,
                                style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w400,
                                    color: AppTheme.greyDark),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          );
                        }),
                  ),

                  // arrow navigation
                  SizedBox(
                    height: 156,
                    child: Padding(
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
                                  icon: InkWell(
                                      child: Container(
                                          width: 48,
                                          height: 48,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: currentPage == 0
                                                ? AppTheme.idleDarkest
                                                : theme.colorScheme.primary,
                                          ),
                                          child: Icon(
                                            Icons.arrow_back,
                                            color: currentPage == 0
                                                ? AppTheme.iconDisabledDark
                                                : Colors.white,
                                          ))),
                                ),
                                IconButton(
                                  onPressed: goNext,
                                  icon: InkWell(
                                    child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: theme.colorScheme.primary),
                                        child: const Icon(
                                          Icons.arrow_forward,
                                          color: Colors.white,
                                        )),
                                  ),
                                ),
                              ],
                            ),
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

class OnboardingPageData {
  final String title;
  final String subtitle;
  final String imageAsset; // placeholder for screenshots

  const OnboardingPageData({
    required this.title,
    required this.subtitle,
    required this.imageAsset,
  });
}
