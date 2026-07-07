import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/app_enums.dart';
import '../../l10n/app_localizations.dart';
import '../../state/app_state.dart';

class OnboardingOverlay extends ConsumerStatefulWidget {
  const OnboardingOverlay({super.key});

  @override
  ConsumerState<OnboardingOverlay> createState() => _OnboardingOverlayState();
}

class _OnboardingOverlayState extends ConsumerState<OnboardingOverlay> {
  int _currentStepIndex = 0;
  bool _isVisible = true;

  List<_OnboardingStep> _getStepsForRole(UserRole role, AppLocalizations l10n) {
    // Base steps for staff/housekeeper
    final steps = [
      _OnboardingStep(
        title: l10n.t('onboardingStep1Title'),
        description: l10n.t('onboardingStep1Desc'),
      ),
      _OnboardingStep(
        title: l10n.t('onboardingStep2Title'),
        description: l10n.t('onboardingStep2Desc'),
      ),
      _OnboardingStep(
        title: l10n.t('onboardingStep3Title'),
        description: l10n.t('onboardingStep3Desc'),
      ),
      _OnboardingStep(
        title: l10n.t('onboardingStep4Title'),
        description: l10n.t('onboardingStep4Desc'),
      ),
    ];

    if (role == UserRole.hotelManager || role == UserRole.appManager || role == UserRole.appAdmin) {
      steps.addAll([
        _OnboardingStep(
          title: l10n.t('onboardingStep5Title'),
          description: l10n.t('onboardingStep5Desc'),
        ),
        _OnboardingStep(
          title: l10n.t('onboardingStep6Title'),
          description: l10n.t('onboardingStep6Desc'),
        ),
        _OnboardingStep(
          title: l10n.t('onboardingStep7Title'),
          description: l10n.t('onboardingStep7Desc'),
        ),
      ]);
    }

    if (role == UserRole.appManager || role == UserRole.appAdmin) {
       steps.addAll([
        _OnboardingStep(
          title: l10n.t('onboardingStep8Title'),
          description: l10n.t('onboardingStep8Desc'),
        ),
        _OnboardingStep(
          title: l10n.t('onboardingStep9Title'),
          description: l10n.t('onboardingStep9Desc'),
        ),
        _OnboardingStep(
          title: l10n.t('onboardingStep10Title'),
          description: l10n.t('onboardingStep10Desc'),
        ),
      ]);
    }

    return steps;
  }

  void _completeOnboarding() async {
    setState(() {
      _isVisible = false;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_completed_onboarding', true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final steps = _getStepsForRole(user.role, l10n);

    if (steps.isEmpty) return const SizedBox.shrink();
    if (_currentStepIndex >= steps.length) {
      _completeOnboarding();
      return const SizedBox.shrink();
    }

    final currentStep = steps[_currentStepIndex];
    final theme = Theme.of(context);

    return Material(
      color: Colors.black.withValues(alpha: 0.7),
      child: Stack(
        children: [
          // Semi-transparent overlay with spotlight effect (simulated with a simple centered box for now)
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currentStep.title,
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentStep.description,
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: Text(l10n.t('onboardingSkip')),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_currentStepIndex + 1} / ${steps.length}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(width: 16),
                          FilledButton(
                            onPressed: () {
                              if (_currentStepIndex < steps.length - 1) {
                                setState(() {
                                  _currentStepIndex++;
                                });
                              } else {
                                _completeOnboarding();
                              }
                            },
                            child: Text(
                              _currentStepIndex < steps.length - 1
                                  ? l10n.t('onboardingNext')
                                  : l10n.t('onboardingDone'),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingStep {
  final String title;
  final String description;

  const _OnboardingStep({required this.title, required this.description});
}
