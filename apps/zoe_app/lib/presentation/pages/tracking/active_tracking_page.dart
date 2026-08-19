import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../cubits/tracking/tracking_cubit.dart';
import '../../cubits/auth/auth_cubit.dart';

/// ActiveTrackingPage — rastreamento em tempo real do pedido.
///
/// Referência: ARCHITECTURE.md §2.3: Rastreamento em Tempo Real
class ActiveTrackingPage extends StatefulWidget {
  final String orderId;

  const ActiveTrackingPage({super.key, required this.orderId});

  @override
  State<ActiveTrackingPage> createState() => _ActiveTrackingPageState();
}

class _ActiveTrackingPageState extends State<ActiveTrackingPage> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    final token = authState is AuthAuthenticated ? authState.token : '';
    context.read<TrackingCubit>().startTracking(widget.orderId, token);
  }

  @override
  void dispose() {
    context.read<TrackingCubit>().stopTracking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('RASTREAMENTO', style: ZoeTypography.headlineSmall.copyWith(letterSpacing: 2)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
      ),
      body: BlocBuilder<TrackingCubit, TrackingState>(
        builder: (context, state) {
          if (state is TrackingConnecting) {
            return const Center(child: CircularProgressIndicator(color: ZoeColors.primary));
          }

          if (state is TrackingActive) {
            final tracking = state.tracking;
            return SingleChildScrollView(
              padding: EdgeInsets.all(ZoeSpacing.md),
              child: Column(
                children: [
                  // Map placeholder
                  Container(
                    width: double.infinity,
                    height: 250,
                    decoration: BoxDecoration(
                      color: ZoeColors.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        const Icon(Icons.map, size: 64, color: ZoeColors.textSecondary),
                        Positioned(
                          bottom: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
                            ),
                            child: Text(
                              '${tracking.currentLat?.toStringAsFixed(4) ?? '-'}, ${tracking.currentLng?.toStringAsFixed(4) ?? '-'}',
                              style: ZoeTypography.bodySmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ZoeSpacing.lg),

                  // Driver info
                  Container(
                    padding: EdgeInsets.all(ZoeSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: ZoeColors.primary.withValues(alpha: 0.1),
                          child: const Icon(Icons.delivery_dining, color: ZoeColors.primary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(tracking.driverName ?? 'Motorista', style: ZoeTypography.bodyLarge),
                              const SizedBox(height: 4),
                              Text(tracking.driverPhone ?? '', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.phone, color: ZoeColors.primary),
                          onPressed: () {
                            // Launch phone
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ZoeSpacing.md),

                  // Status timeline
                  Container(
                    padding: EdgeInsets.all(ZoeSpacing.md),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('STATUS', style: ZoeTypography.labelMedium.copyWith(letterSpacing: 1.2, color: ZoeColors.textSecondary)),
                        SizedBox(height: ZoeSpacing.sm),
                        _StatusStep(
                          label: 'Pedido confirmado',
                          isActive: true,
                          isCompleted: true,
                        ),
                        _StatusStep(
                          label: 'Preparando',
                          isActive: tracking.status == 'preparing' || tracking.status == 'picked_up' || tracking.status == 'in_transit' || tracking.status == 'delivered',
                          isCompleted: tracking.status != 'preparing',
                        ),
                        _StatusStep(
                          label: 'Saiu para entrega',
                          isActive: tracking.status == 'in_transit' || tracking.status == 'delivered',
                          isCompleted: tracking.status == 'delivered',
                        ),
                        _StatusStep(
                          label: 'Entregue',
                          isActive: tracking.status == 'delivered',
                          isCompleted: tracking.status == 'delivered',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: ZoeSpacing.md),

                  // ETA
                  if (tracking.estimatedArrival != null)
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(ZoeSpacing.md),
                      decoration: BoxDecoration(
                        color: ZoeColors.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ZoeColors.primary.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, color: ZoeColors.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Previsão de entrega', style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.textSecondary)),
                              Text(
                                _formatTime(tracking.estimatedArrival!),
                                style: ZoeTypography.headlineSmall.copyWith(color: ZoeColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          }

          if (state is TrackingError) {
            return Center(child: Text(state.message, style: ZoeTypography.bodyMedium.copyWith(color: Colors.red)));
          }

          return const Center(child: Text('Aguardando dados de rastreamento...'));
        },
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusStep extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isCompleted;
  final bool isLast;

  const _StatusStep({
    required this.label,
    required this.isActive,
    required this.isCompleted,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? ZoeColors.primary : ZoeColors.divider,
              ),
              child: isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
                color: isActive ? ZoeColors.primary : ZoeColors.divider,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            style: ZoeTypography.bodyMedium.copyWith(
              color: isActive ? ZoeColors.textPrimary : ZoeColors.textSecondary,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}
