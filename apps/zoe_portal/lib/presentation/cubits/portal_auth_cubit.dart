import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:zoe_portal/domain/services/portal_auth_service.dart';

// ─── States ──────────────────────────────────────────────────────────

abstract class PortalAuthState extends Equatable {
  const PortalAuthState();

  @override
  List<Object?> get props => [];
}

class PortalAuthInitial extends PortalAuthState {
  const PortalAuthInitial();
}

class PortalAuthLoading extends PortalAuthState {
  const PortalAuthLoading();
}

class PortalAuthAuthenticated extends PortalAuthState {
  final Map<String, dynamic> user;
  final String role;
  final String storeId;

  const PortalAuthAuthenticated({
    required this.user,
    required this.role,
    required this.storeId,
  });

  @override
  List<Object?> get props => [user, role, storeId];
}

class PortalAuthUnauthenticated extends PortalAuthState {
  const PortalAuthUnauthenticated();
}

class PortalAuthError extends PortalAuthState {
  final String message;

  const PortalAuthError(this.message);

  @override
  List<Object?> get props => [message];
}

// ─── Cubit ───────────────────────────────────────────────────────────

class PortalAuthCubit extends Cubit<PortalAuthState> {
  final PortalAuthService _authService;

  PortalAuthCubit({required PortalAuthService authService})
      : _authService = authService,
        super(const PortalAuthInitial());

  /// Autentica o merchant com e-mail e senha.
  Future<void> login(String email, String password) async {
    emit(const PortalAuthLoading());
    try {
      final data = await _authService.login(email, password);
      emit(PortalAuthAuthenticated(
        user: data,
        role: data['role'] as String? ?? '',
        storeId: data['store_id'] as String? ?? '',
      ));
    } catch (e) {
      emit(PortalAuthError(e.toString()));
    }
  }

  /// Encerra a sessão.
  Future<void> logout() async {
    emit(const PortalAuthLoading());
    try {
      await _authService.logout();
      emit(const PortalAuthUnauthenticated());
    } catch (e) {
      emit(PortalAuthError(e.toString()));
    }
  }

  /// Verifica se já existe uma sessão ativa.
  Future<void> checkAuth() async {
    emit(const PortalAuthLoading());
    try {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        emit(PortalAuthAuthenticated(
          user: user,
          role: user['role'] as String? ?? '',
          storeId: user['store_id'] as String? ?? '',
        ));
      } else {
        emit(const PortalAuthUnauthenticated());
      }
    } catch (e) {
      emit(const PortalAuthUnauthenticated());
    }
  }
}
