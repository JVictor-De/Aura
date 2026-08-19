import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/orders/orders_cubit.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<OrdersCubit>().loadOrders();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ZoeColors.background,
      appBar: AppBar(
        title: Text('MEUS PEDIDOS', style: ZoeTypography.labelLarge.copyWith(letterSpacing: 3)),
        backgroundColor: ZoeColors.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return _LoginRequiredView();
          }
          return BlocBuilder<OrdersCubit, OrdersState>(
        builder: (context, state) {
          if (state is OrdersLoading || state is OrdersInitial) {
            return const Center(child: CircularProgressIndicator(color: ZoeColors.primary));
          }
          if (state is OrdersError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: ZoeColors.error),
                  const SizedBox(height: 16),
                  Text(state.message, style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.error)),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: () => context.read<OrdersCubit>().loadOrders(),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          if (state is OrdersLoaded) {
            return RefreshIndicator(
              onRefresh: () => context.read<OrdersCubit>().loadOrders(),
              color: ZoeColors.primary,
              child: ListView.separated(
                padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
                itemCount: state.orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) {
                  final order = state.orders[i];
                  return GestureDetector(
                    onTap: () => context.push('/tracking/${order.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(ZoeSpacing.md),
                      decoration: BoxDecoration(
                        color: ZoeColors.surface,
                        borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
                        border: Border.all(color: ZoeColors.lightGray.withValues(alpha: 0.6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Pedido #${order.id.substring(0, 8).toUpperCase()}',
                                style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                              _StatusBadge(status: order.status),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${order.shipments.fold<int>(0, (sum, s) => sum + s.items.length)} itens • R\$ ${order.total.toStringAsFixed(2)}',
                            style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(order.createdAt),
                            style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: Duration(milliseconds: 60 * i)).fadeIn(duration: 300.ms);
                },
              ),
            );
          }
          // OrdersEmpty
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(ZoeSpacing.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: ZoeColors.cream,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_outlined, size: 48, color: ZoeColors.primaryLight),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Nenhum pedido ainda',
                    style: ZoeTypography.headlineMedium.copyWith(color: ZoeColors.charcoal),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Seus pedidos aparecerão aqui\nassim que você fizer sua primeira compra',
                    style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    String label;
    switch (status) {
      case 'pending':
        bgColor = ZoeColors.warning.withValues(alpha: 0.1);
        textColor = ZoeColors.warning;
        label = 'Pendente';
        break;
      case 'confirmed':
        bgColor = ZoeColors.info.withValues(alpha: 0.1);
        textColor = ZoeColors.info;
        label = 'Confirmado';
        break;
      case 'preparing':
        bgColor = ZoeColors.primary.withValues(alpha: 0.1);
        textColor = ZoeColors.primary;
        label = 'Preparando';
        break;
      case 'in_transit':
        bgColor = ZoeColors.accent.withValues(alpha: 0.1);
        textColor = ZoeColors.accent;
        label = 'Em trânsito';
        break;
      case 'delivered':
        bgColor = ZoeColors.success.withValues(alpha: 0.1);
        textColor = ZoeColors.success;
        label = 'Entregue';
        break;
      case 'cancelled':
        bgColor = ZoeColors.error.withValues(alpha: 0.1);
        textColor = ZoeColors.error;
        label = 'Cancelado';
        break;
      default:
        bgColor = ZoeColors.lightGray;
        textColor = ZoeColors.darkGray;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(ZoeSpacing.radiusFull),
      ),
      child: Text(label, style: ZoeTypography.labelSmall.copyWith(color: textColor, fontSize: 11)),
    );
  }
}

class _LoginRequiredView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ZoeSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                color: ZoeColors.cream,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline, size: 48, color: ZoeColors.primaryLight),
            ),
            const SizedBox(height: 24),
            Text(
              'Entre para ver seus pedidos',
              style: ZoeTypography.headlineMedium.copyWith(color: ZoeColors.charcoal),
            ),
            const SizedBox(height: 8),
            Text(
              'Faça login para acompanhar\nseus pedidos e entregas',
              style: ZoeTypography.bodyMedium.copyWith(color: ZoeColors.mediumGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 220,
              height: 52,
              child: ElevatedButton(
                onPressed: () => context.push('/login?returnTo=/orders'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ZoeColors.secondary,
                  foregroundColor: ZoeColors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(ZoeSpacing.radiusLg),
                  ),
                ),
                child: Text(
                  'ENTRAR',
                  style: ZoeTypography.labelLarge.copyWith(color: ZoeColors.white, letterSpacing: 2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
