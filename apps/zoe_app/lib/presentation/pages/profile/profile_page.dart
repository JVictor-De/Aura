import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/zoe_colors.dart';
import '../../../core/theme/zoe_typography.dart';
import '../../../core/theme/zoe_spacing.dart';
import '../../cubits/auth/auth_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is AuthAuthenticated;
        final userName = isAuthenticated ? authState.user.name : 'Visitante';
        final userEmail = isAuthenticated ? authState.user.email : '';

        return Scaffold(
          backgroundColor: ZoeColors.background,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 200,
                pinned: true,
                backgroundColor: ZoeColors.secondary,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [ZoeColors.secondary, ZoeColors.charcoal],
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 16),
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: ZoeColors.primary, width: 2),
                              color: ZoeColors.charcoal,
                            ),
                            child: const Icon(Icons.person, size: 40, color: ZoeColors.primary),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            userName.isNotEmpty ? userName : 'Visitante',
                            style: ZoeTypography.headlineMedium.copyWith(color: ZoeColors.white),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isAuthenticated
                                ? userEmail
                                : 'Faça login para acessar recursos exclusivos',
                            style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Login CTA (only for unauthenticated) ─
              if (!isAuthenticated)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(ZoeSpacing.pagePadding),
                    child: GestureDetector(
                      onTap: () => context.push('/login?returnTo=/profile'),
                      child: Container(
                        padding: const EdgeInsets.all(ZoeSpacing.md),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [ZoeColors.primary, ZoeColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Experiência Completa', style: ZoeTypography.headlineSmall.copyWith(color: ZoeColors.white)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Crie sua conta e aproveite frete grátis na primeira compra',
                                    style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.white.withValues(alpha: 0.8)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: ZoeColors.white,
                                borderRadius: BorderRadius.circular(ZoeSpacing.radiusSm),
                              ),
                              child: Text('ENTRAR', style: ZoeTypography.labelMedium.copyWith(color: ZoeColors.primaryDark)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                ),

              // ─── Menu Sections ─────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: ZoeSpacing.pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('MINHA CONTA', [
                        _MenuItem(icon: Icons.receipt_long_outlined, label: 'Meus Pedidos', subtitle: 'Acompanhe suas entregas', onTap: () => context.go('/orders')),
                        _MenuItem(icon: Icons.favorite_border, label: 'Lista de Desejos', subtitle: 'Peças que você salvou', onTap: () => context.push('/wishlist')),
                        _MenuItem(icon: Icons.location_on_outlined, label: 'Endereços', subtitle: 'Gerencie seus endereços', onTap: () => context.push('/location')),
                        _MenuItem(icon: Icons.credit_card_outlined, label: 'Pagamento', subtitle: 'Cartões e Pix', onTap: () => context.push('/payment-methods')),
                      ]),
                      const SizedBox(height: ZoeSpacing.lg),
                      _buildSection('PREFERÊNCIAS', [
                        _MenuItem(icon: Icons.notifications_outlined, label: 'Notificações', subtitle: 'Configure seus alertas', onTap: () => context.push('/notifications')),
                        _MenuItem(icon: Icons.straighten, label: 'Meus Tamanhos', subtitle: 'Guia de medidas salvo', onTap: () {}),
                        _MenuItem(icon: Icons.palette_outlined, label: 'Preferências de Estilo', subtitle: 'Personalize seu feed', onTap: () {}),
                      ]),
                      const SizedBox(height: ZoeSpacing.lg),
                      _buildSection('SUPORTE', [
                        _MenuItem(icon: Icons.headset_mic_outlined, label: 'Central de Ajuda', subtitle: 'FAQ e atendimento', onTap: () {}),
                        _MenuItem(icon: Icons.assignment_return_outlined, label: 'Trocas e Devoluções', subtitle: 'Política RMA', onTap: () => context.push('/returns')),
                        _MenuItem(icon: Icons.info_outline, label: 'Sobre o Zoe', subtitle: 'Versão 1.0.0', onTap: () {}),
                      ]),
                      if (isAuthenticated) ...[
                        const SizedBox(height: ZoeSpacing.lg),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => context.read<AuthCubit>().logout(),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: ZoeColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd)),
                            ),
                            child: Text('SAIR DA CONTA', style: ZoeTypography.labelMedium.copyWith(color: ZoeColors.error, letterSpacing: 2)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<_MenuItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: ZoeTypography.labelMedium.copyWith(color: ZoeColors.mediumGray, letterSpacing: 2)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: ZoeColors.surface,
            borderRadius: BorderRadius.circular(ZoeSpacing.radiusMd),
            border: Border.all(color: ZoeColors.lightGray.withValues(alpha: 0.6)),
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (i > 0) Divider(height: 1, color: ZoeColors.lightGray.withValues(alpha: 0.5), indent: 56),
                  ListTile(
                    onTap: item.onTap,
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: ZoeColors.cream,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: ZoeColors.primary, size: 20),
                    ),
                    title: Text(item.label, style: ZoeTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                    subtitle: Text(item.subtitle, style: ZoeTypography.bodySmall.copyWith(color: ZoeColors.mediumGray, fontSize: 11)),
                    trailing: const Icon(Icons.chevron_right, color: ZoeColors.lightGray, size: 20),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback? onTap;
  const _MenuItem({required this.icon, required this.label, required this.subtitle, this.onTap});
}
