import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';

/// Onboarding Page — apresentação do app antes do login.
///
/// Referência: ARCHITECTURE.md §Diagrama de Fluxo: splash → onboarding → auth
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<_OnboardingStep> _steps = const [
    _OnboardingStep(
      icon: Icons.diamond_outlined,
      title: 'Moda de Luxo',
      subtitle: 'Descubra as melhores marcas premium com curadoria exclusiva.',
    ),
    _OnboardingStep(
      icon: Icons.location_on_outlined,
      title: 'Lojas Perto de Você',
      subtitle: 'Encontre boutiques de luxo próximas com entrega ultra-rápida.',
    ),
    _OnboardingStep(
      icon: Icons.local_shipping_outlined,
      title: 'Entrega em Tempo Real',
      subtitle: 'Acompanhe seu pedido do ateliê até a sua porta.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => context.go('/location'),
                child: Text('Pular', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
              ),
            ),

            // Pages
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _steps.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(step.icon, size: 80, color: ZoeColors.primary),
                        const SizedBox(height: 32),
                        Text(step.title, style: ZoeTypography.headlineLarge, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Text(step.subtitle, style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.textSecondary), textAlign: TextAlign.center),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Indicators
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i ? ZoeColors.primary : ZoeColors.divider,
                  ),
                );
              }),
            ),

            const SizedBox(height: 32),

            // CTA button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZoeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    if (_currentPage < _steps.length - 1) {
                      _controller.nextPage(duration: const Duration(milliseconds: 450), curve: Curves.easeInOutCubic);
                    } else {
                      context.go('/location');
                    }
                  },
                  child: Text(
                    _currentPage < _steps.length - 1 ? 'PRÓXIMO' : 'COMEÇAR',
                    style: ZoeTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.5),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _OnboardingStep {
  final IconData icon;
  final String title;
  final String subtitle;

  const _OnboardingStep({required this.icon, required this.title, required this.subtitle});
}
