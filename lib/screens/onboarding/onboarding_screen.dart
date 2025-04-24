import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskswap/screens/auth/auth_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  bool _isLastPage = false;
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to TaskSwap',
      description: 'Manage your tasks, challenge friends, and build productive habits together.',
      image: 'assets/images/onboarding_1.png',
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Track Your Progress',
      description: 'Create tasks, set deadlines, and watch your productivity soar.',
      image: 'assets/images/onboarding_2.png',
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Challenge Friends',
      description: 'Make productivity fun by challenging friends to complete tasks.',
      image: 'assets/images/onboarding_3.png',
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Earn Aura Points',
      description: 'Complete tasks and challenges to earn points and climb the leaderboard.',
      image: 'assets/images/onboarding_4.png',
      color: Colors.purple,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Page view for onboarding pages
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _isLastPage = index == _pages.length - 1;
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Bottom navigation buttons
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Skip button (hidden on last page)
                  _isLastPage
                      ? const SizedBox(width: 80)
                      : TextButton(
                          onPressed: () {
                            _pageController.jumpToPage(_pages.length - 1);
                          },
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: _pages[_currentPage].color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                  // Page indicator
                  Center(
                    child: SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotHeight: 10,
                        dotWidth: 10,
                        activeDotColor: _pages[_currentPage].color,
                        dotColor: Colors.grey.shade300,
                      ),
                    ),
                  ),

                  // Next/Get Started button
                  _isLastPage
                      ? ElevatedButton(
                          onPressed: () {
                            _markOnboardingComplete();
                            _showAuthOptions(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _pages[_currentPage].color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'Get Started',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        )
                      : IconButton(
                          onPressed: () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _pages[_currentPage].color,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color.withAlpha(26), // opacity 0.1
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Image
          Expanded(
            flex: 3,
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Image.asset(
                page.image,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      color: page.color.withAlpha(51), // opacity 0.2
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      _getIconForPage(page.title),
                      size: 100,
                      color: page.color,
                    ),
                  );
                },
              ),
            ),
          ),

          // Text content
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    page.title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: page.color,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey.shade700,
                          height: 1.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForPage(String title) {
    if (title.contains('Welcome')) return Icons.task_alt;
    if (title.contains('Track')) return Icons.trending_up;
    if (title.contains('Challenge')) return Icons.people;
    if (title.contains('Earn')) return Icons.auto_awesome;
    return Icons.star;
  }

  void _showAuthOptions(BuildContext context) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
  });
}
