import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:zoe_portal/domain/entities/portal_review.dart';
import 'package:zoe_portal/presentation/cubits/portal_reviews_cubit.dart';

/// Página de moderação de avaliações.
///
/// Exibe lista de avaliações com filtros por status de moderação
/// e ações de aprovar/rejeitar para avaliações pendentes.
class ReviewsPage extends StatefulWidget {
  const ReviewsPage({super.key});

  @override
  State<ReviewsPage> createState() => _ReviewsPageState();
}

class _ReviewsPageState extends State<ReviewsPage> {
  String _selectedFilter = 'all';

  static const _filters = <String, String>{
    'all': 'Todas',
    'pending': 'Pendentes',
    'approved': 'Aprovadas',
    'rejected': 'Rejeitadas',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortalReviewsCubit>().loadReviews();
    });
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    final cubit = context.read<PortalReviewsCubit>();
    if (filter == 'all') {
      cubit.loadReviews();
    } else {
      cubit.loadReviews(status: filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Text('Avaliações', style: theme.textTheme.headlineMedium),
          const SizedBox(height: 16),

          // ── Filter Chips ──
          Wrap(
            spacing: 8,
            children: _filters.entries.map((entry) {
              final selected = _selectedFilter == entry.key;
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: (_) => _onFilterChanged(entry.key),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // ── Content ──
          Expanded(
            child: BlocBuilder<PortalReviewsCubit, PortalReviewsState>(
              builder: (context, state) {
                if (state is PortalReviewsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is PortalReviewsError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                        const SizedBox(height: 12),
                        Text(state.message, style: TextStyle(color: colorScheme.error)),
                      ],
                    ),
                  );
                }

                if (state is PortalReviewsLoaded) {
                  final reviews = state.reviews;
                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.rate_review_outlined,
                              size: 64,
                              color: colorScheme.onSurface.withValues(alpha: 0.38)),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhuma avaliação encontrada',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: reviews.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _ReviewCard(
                        review: review,
                        dateFmt: dateFmt,
                        colorScheme: colorScheme,
                        theme: theme,
                        onApprove: review.status == 'pending'
                            ? () => context
                                .read<PortalReviewsCubit>()
                                .moderateReview(review.id, 'approved')
                            : null,
                        onReject: review.status == 'pending'
                            ? () => context
                                .read<PortalReviewsCubit>()
                                .moderateReview(review.id, 'rejected')
                            : null,
                      );
                    },
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Review Card Widget ──────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final PortalReview review;
  final DateFormat dateFmt;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback? onApprove;
  final VoidCallback? onReject;

  const _ReviewCard({
    required this.review,
    required this.dateFmt,
    required this.colorScheme,
    required this.theme,
    this.onApprove,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: Stars, product name, status badge
            Row(
              children: [
                // Star rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(5, (i) {
                    return Icon(
                      i < review.rating ? Icons.star : Icons.star_border,
                      size: 20,
                      color: i < review.rating
                          ? Colors.amber
                          : colorScheme.onSurface.withValues(alpha: 0.3),
                    );
                  }),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    review.productName,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StatusBadge(status: review.status, colorScheme: colorScheme),
              ],
            ),
            const SizedBox(height: 8),

            // Customer name and date
            Row(
              children: [
                Icon(Icons.person_outline,
                    size: 16,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  review.customerName,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(width: 16),
                Icon(Icons.calendar_today_outlined,
                    size: 14,
                    color: colorScheme.onSurface.withValues(alpha: 0.5)),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(review.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),

            // Comment
            if (review.comment != null && review.comment!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  review.comment!,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],

            // Action buttons for pending reviews
            if (onApprove != null || onReject != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onReject != null)
                    OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Rejeitar'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: colorScheme.error,
                        side: BorderSide(color: colorScheme.error),
                      ),
                    ),
                  if (onApprove != null && onReject != null)
                    const SizedBox(width: 12),
                  if (onApprove != null)
                    FilledButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Aprovar'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  final ColorScheme colorScheme;

  const _StatusBadge({required this.status, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final (label, bgColor, fgColor) = switch (status) {
      'pending' => ('Pendente', Colors.orange.withValues(alpha: 0.12), Colors.orange),
      'approved' => ('Aprovada', Colors.green.withValues(alpha: 0.12), Colors.green),
      'rejected' => ('Rejeitada', colorScheme.error.withValues(alpha: 0.12), colorScheme.error),
      _ => ('Desconhecido', colorScheme.surfaceContainerHighest, colorScheme.onSurface),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fgColor),
      ),
    );
  }
}
