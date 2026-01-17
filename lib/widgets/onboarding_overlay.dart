import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../core/theme.dart';

class OnboardingOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingOverlay({super.key, required this.onComplete});

  @override
  State<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends State<OnboardingOverlay> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  final List<OnboardingStep> _steps = [
    OnboardingStep(
      title: 'Upload Lab Reports',
      description: 'Simply upload your PDF or photo. Our AI instantly extracts and constructs your digital health profile.',
      icon: FontAwesomeIcons.fileArrowUp,
      color: Color(0xFF3B82F6), // Blue
    ),
    OnboardingStep(
      title: 'AI Health Insights',
      description: 'Ask deep questions about your health. LabSense understands your history and gives personalized, medical-grade answers.',
      icon: FontAwesomeIcons.userDoctor,
      color: Color(0xFF10B981), // Emerald
    ),
    OnboardingStep(
      title: 'Track & Optimize',
      description: 'Visualize trends over time and get science-backed recommendations to optimize your longevity and vitality.',
      icon: FontAwesomeIcons.chartLine,
      color: Color(0xFF8B5CF6), // Violet
    ),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubicEmphasized,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Backdrop Blur
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: Colors.black.withOpacity(0.6),
            ),
          ),
        ),
        
        // Main Content
        Center(
          child: Container(
            width: 480,
            height: 600,
            margin: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(32),
              child: Stack(
                children: [
                  // Background Pattern (Optional subtle decoration)
                  Positioned(
                    top: -100,
                    right: -100,
                    child: Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            _steps[_currentStep].color.withOpacity(0.1),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  Column(
                    children: [
                      // Top Bar: Skip Button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: widget.onComplete,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.secondary,
                              ),
                              child: const Text('Skip Tour'),
                            ),
                          ],
                        ),
                      ),

                      // Slider Content
                      Expanded(
                        child: PageView.builder(
                          controller: _pageController,
                          onPageChanged: (index) => setState(() => _currentStep = index),
                          itemCount: _steps.length,
                          itemBuilder: (context, index) {
                            final step = _steps[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon Container
                                  Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      color: step.color.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: FaIcon(
                                        step.icon,
                                        size: 48,
                                        color: step.color,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 48),
                                  
                                  // Text Content
                                  Text(
                                    step.title,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF111827),
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    step.description,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF6B7280),
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom Action Area
                      Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          children: [
                            // Page Indicators
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(_steps.length, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: index == _currentStep ? 24 : 8,
                                  height: 8,
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  decoration: BoxDecoration(
                                    color: index == _currentStep 
                                        ? _steps[_currentStep].color 
                                        : Colors.grey[300],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                );
                              }),
                            ),
                            const SizedBox(height: 32),
                            
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _next,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _steps[_currentStep].color,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  _currentStep == _steps.length - 1 ? 'Get Started' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OnboardingStep {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingStep({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
