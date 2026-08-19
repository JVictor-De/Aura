import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../cubits/address/address_cubit.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (!mounted) return;
      final addressState = context.read<AddressCubit>().state;

      // Login não é mais obrigatório na entrada.
      // Redireciona direto para home (se já tem endereço) ou onboarding.
      if (addressState is AddressSelected) {
        context.go('/home');
      } else {
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.secondary,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: ZoeColors.primary,
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Center(
                child: Text(
                  'Z',
                  style: TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontSize: 52,
                    fontWeight: FontWeight.w700,
                    color: ZoeColors.white,
                    height: 1,
                  ),
                ),
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.5, 0.5),
                  end: const Offset(1.0, 1.0),
                  duration: 800.ms,
                  curve: Curves.easeOutBack,
                )
                .fadeIn(duration: 600.ms),
            const SizedBox(height: 24),
            // Brand name
            Text(
              'ZOE',
              style: ZoeTypography.displayLarge.copyWith(
                color: ZoeColors.primary,
                letterSpacing: 12,
                fontSize: 42,
              ),
            )
                .animate(delay: 400.ms)
                .fadeIn(duration: 600.ms)
                .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),
            const SizedBox(height: 8),
            Text(
              'LUXURY FASHION DELIVERY',
              style: ZoeTypography.labelMedium.copyWith(
                color: ZoeColors.primary.withValues(alpha: 0.6),
                letterSpacing: 4,
                fontSize: 11,
              ),
            )
                .animate(delay: 700.ms)
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 48),
            // Loading indicator
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: ZoeColors.primary.withValues(alpha: 0.5),
              ),
            ).animate(delay: 1000.ms).fadeIn(duration: 400.ms),
          ],
        ),
      ),
    );
  }
}
