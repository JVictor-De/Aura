import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/entities/portal_rma.dart';
import 'package:zoe_portal/domain/services/portal_rma_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalRmaState extends Equatable {
  const PortalRmaState();

  @override
  List<Object?> get props => [];
}

class PortalRmaInitial extends PortalRmaState {
  const PortalRmaInitial();
}

class PortalRmaLoading extends PortalRmaState {
  const PortalRmaLoading();
}

class PortalRmaLoaded extends PortalRmaState {
  final List<PortalRma> rmas;

  const PortalRmaLoaded(this.rmas);

  @override
  List<Object?> get props => [rmas];
}

class PortalRmaError extends PortalRmaState {
  final String message;

  const PortalRmaError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalRmaCubit extends Cubit<PortalRmaState> {
  final PortalRmaService _rmaService;

  PortalRmaCubit({required PortalRmaService rmaService})
      : _rmaService = rmaService,
        super(const PortalRmaInitial());

  /// Carrega solicitações de RMA com filtro opcional por [status].
  Future<void> loadRmas({String? status}) async {
    emit(const PortalRmaLoading());
    try {
      final rmas = await _rmaService.getRmaRequests(status: status);
      emit(PortalRmaLoaded(rmas));
    } catch (e) {
      emit(PortalRmaError(e.toString()));
    }
  }

  /// Atualiza o status de uma solicitação de RMA e recarrega a lista.
  Future<void> updateRmaStatus(String id, String status) async {
    try {
      await _rmaService.updateRmaStatus(id, status);
      await loadRmas();
    } catch (e) {
      emit(PortalRmaError(e.toString()));
    }
  }
}
