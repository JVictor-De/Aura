/// AuthCubit — gerenciamento de estado de autenticação.
///
/// Referência: ARCHITECTURE.md §3.3: Gestão de Estado
import 'package:hydrated_bloc/hydrated_bloc.dart';

import '../../../domain/entities/user.dart';
import '../../../domain/services/auth_service.dart';
import '../../../core/storage/secure_storage.dart';

part 'auth_state.dart';

class AuthCubit extends HydratedCubit<AuthState> {
  final AuthService _authService;
  final SecureStorage _storage;

  AuthCubit({
    required AuthService authService,
    required SecureStorage storage,
  })  : _authService = authService,
        _storage = storage,
        super(const AuthInitial());

  Future<void> login(String email, String password) async {
    emit(const AuthLoading());
    final result = await _authService.login(email, password);
    result.fold(
      onSuccess: (tokens) async {
        await _storage.setAccessToken(tokens.accessToken);
        await _storage.setRefreshToken(tokens.refreshToken);
        final profileResult = await _authService.getProfile();
        profileResult.fold(
          onSuccess: (profile) {
            emit(AuthAuthenticated(user: profile, token: tokens.accessToken));
          },
          onFailure: (failure) {
            emit(AuthAuthenticated(
              user: UserProfile(id: tokens.userId, email: email, fullName: email),
              token: tokens.accessToken,
            ));
          },
        );
      },
      onFailure: (failure) {
        emit(AuthError(message: failure.message));
      },
    );
  }

  Future<void> register(String email, String password, String fullName) async {
    emit(const AuthLoading());
    final result = await _authService.register(email, password, fullName);
    result.fold(
      onSuccess: (tokens) async {
        await _storage.setAccessToken(tokens.accessToken);
        await _storage.setRefreshToken(tokens.refreshToken);
        emit(AuthAuthenticated(
          user: UserProfile(id: tokens.userId, email: email, fullName: fullName),
          token: tokens.accessToken,
        ));
      },
      onFailure: (failure) {
        emit(AuthError(message: failure.message));
      },
    );
  }

  Future<void> checkAuth() async {
    final token = await _storage.getAccessToken();
    if (token == null) {
      emit(const AuthUnauthenticated());
      return;
    }
    final result = await _authService.getProfile();
    result.fold(
      onSuccess: (profile) {
        emit(AuthAuthenticated(user: profile, token: token));
      },
      onFailure: (_) {
        emit(const AuthUnauthenticated());
      },
    );
  }

  Future<void> logout() async {
    await _authService.logout();
    await _storage.clearAll();
    emit(const AuthUnauthenticated());
  }

  bool get isAuthenticated => state is AuthAuthenticated;

  @override
  AuthState? fromJson(Map<String, dynamic> json) {
    try {
      final isAuth = json['is_authenticated'] as bool? ?? false;
      if (!isAuth) return const AuthUnauthenticated();
      return AuthAuthenticated(
        user: UserProfile(
          id: json['user_id'] as String? ?? '',
          email: json['email'] as String? ?? '',
          fullName: json['name'] as String? ?? '',
          phone: json['phone'] as String?,
          avatarUrl: json['avatar_url'] as String?,
        ),
        token: json['token'] as String? ?? '',
      );
    } catch (_) {
      return const AuthUnauthenticated();
    }
  }

  @override
  Map<String, dynamic>? toJson(AuthState state) {
    if (state is AuthAuthenticated) {
      return {
        'is_authenticated': true,
        'user_id': state.user.id,
        'email': state.user.email,
        'name': state.user.name,
        'phone': state.user.phone,
        'avatar_url': state.user.avatarUrl,
        'token': state.token,
      };
    }
    return {'is_authenticated': false};
  }
}
