import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_coupon.dart';
import 'package:zoe_portal/domain/services/portal_coupon_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalCouponsState extends Equatable {
  const PortalCouponsState();

  @override
  List<Object?> get props => [];
}

class PortalCouponsInitial extends PortalCouponsState {
  const PortalCouponsInitial();
}

class PortalCouponsLoading extends PortalCouponsState {
  const PortalCouponsLoading();
}

class PortalCouponsLoaded extends PortalCouponsState {
  final List<PortalCoupon> coupons;

  const PortalCouponsLoaded(this.coupons);

  @override
  List<Object?> get props => [coupons];
}

class PortalCouponsError extends PortalCouponsState {
  final String message;

  const PortalCouponsError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalCouponsCubit extends Cubit<PortalCouponsState> {
  final PortalCouponService _couponService;

  PortalCouponsCubit({required PortalCouponService couponService})
      : _couponService = couponService,
        super(const PortalCouponsInitial());

  /// Carrega todos os cupons.
  Future<void> loadCoupons() async {
    emit(const PortalCouponsLoading());
    try {
      final coupons = await _couponService.getCoupons();
      emit(PortalCouponsLoaded(coupons));
    } catch (e) {
      emit(PortalCouponsError(e.toString()));
    }
  }

  /// Cria um novo cupom e recarrega a lista.
  Future<void> createCoupon(Map<String, dynamic> data) async {
    emit(const PortalCouponsLoading());
    try {
      await _couponService.createCoupon(data);
      await loadCoupons();
    } catch (e) {
      emit(PortalCouponsError(e.toString()));
    }
  }

  /// Remove um cupom e recarrega a lista.
  Future<void> deleteCoupon(String id) async {
    emit(const PortalCouponsLoading());
    try {
      await _couponService.deleteCoupon(id);
      await loadCoupons();
    } catch (e) {
      emit(PortalCouponsError(e.toString()));
    }
  }

  /// Ativa ou desativa um cupom e recarrega a lista.
  Future<void> toggleCoupon(String id, bool isActive) async {
    try {
      await _couponService.toggleCoupon(id, isActive);
      await loadCoupons();
    } catch (e) {
      emit(PortalCouponsError(e.toString()));
    }
  }
}
