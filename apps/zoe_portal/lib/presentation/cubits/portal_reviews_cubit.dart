import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_review.dart';
import 'package:zoe_portal/domain/services/portal_review_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalReviewsState extends Equatable {
  const PortalReviewsState();

  @override
  List<Object?> get props => [];
}

class PortalReviewsInitial extends PortalReviewsState {
  const PortalReviewsInitial();
}

class PortalReviewsLoading extends PortalReviewsState {
  const PortalReviewsLoading();
}

class PortalReviewsLoaded extends PortalReviewsState {
  final List<PortalReview> reviews;

  const PortalReviewsLoaded(this.reviews);

  @override
  List<Object?> get props => [reviews];
}

class PortalReviewsError extends PortalReviewsState {
  final String message;

  const PortalReviewsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalReviewsCubit extends Cubit<PortalReviewsState> {
  final PortalReviewService _reviewService;

  PortalReviewsCubit({required PortalReviewService reviewService})
      : _reviewService = reviewService,
        super(const PortalReviewsInitial());

  /// Carrega avaliações com filtro opcional por [status].
  Future<void> loadReviews({String? status}) async {
    emit(const PortalReviewsLoading());
    try {
      final reviews = await _reviewService.getReviews(status: status);
      emit(PortalReviewsLoaded(reviews));
    } catch (e) {
      emit(PortalReviewsError(e.toString()));
    }
  }

  /// Modera uma avaliação (approved/rejected) e recarrega a lista.
  Future<void> moderateReview(String id, String status) async {
    try {
      await _reviewService.moderateReview(id, status);
      await loadReviews();
    } catch (e) {
      emit(PortalReviewsError(e.toString()));
    }
  }
}
