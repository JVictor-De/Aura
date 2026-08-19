import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../cubits/address/address_cubit.dart';

/// LocationOnboardingPage — GPS mandatory antes de acessar home.
///
/// Referência: ARCHITECTURE.md §2.1: Geolocalização-First (Multi-Endereços)
class LocationOnboardingPage extends StatefulWidget {
  const LocationOnboardingPage({super.key});

  @override
  State<LocationOnboardingPage> createState() => _LocationOnboardingPageState();
}

class _LocationOnboardingPageState extends State<LocationOnboardingPage> {
  bool _loading = false;
  String? _error;

  Future<void> _useCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // For web, use browser geolocation API
      // For now, set a default location (São Paulo center) and proceed
      // In production: use geolocator package
      context.read<AddressCubit>().setCoordinates(
        -23.5505,
        -46.6333,
        'Minha localização',
      );

      if (mounted) {
        context.go('/home');
      }
    } catch (e) {
      setState(() {
        _error = 'Não foi possível obter sua localização. Tente novamente.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: ZoeColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, size: 56, color: ZoeColors.primary),
              ),
              const SizedBox(height: 32),

              Text(
                'Onde você está?',
                style: ZoeTypography.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Precisamos da sua localização para\nmostrar lojas e produtos perto de você.',
                style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 40),

              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(_error!, style: ZoeTypography.bodySmall.copyWith(color: Colors.red)),
                ),
                const SizedBox(height: 16),
              ],

              // Use GPS button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ZoeColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _loading ? null : _useCurrentLocation,
                  icon: _loading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.my_location),
                  label: Text(
                    _loading ? 'LOCALIZANDO...' : 'USAR MINHA LOCALIZAÇÃO',
                    style: ZoeTypography.labelLarge.copyWith(color: Colors.white, letterSpacing: 1.2),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Manual address
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ZoeColors.primary,
                    side: const BorderSide(color: ZoeColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // Default location for testing
                    context.read<AddressCubit>().setCoordinates(-23.5505, -46.6333, 'Endereço manual');
                    context.go('/home');
                  },
                  icon: const Icon(Icons.edit_location_outlined),
                  label: Text(
                    'INSERIR ENDEREÇO',
                    style: ZoeTypography.labelLarge.copyWith(letterSpacing: 1.2),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
