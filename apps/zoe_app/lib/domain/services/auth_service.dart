/// Contrato do AuthService (Facade pattern).
///
/// Referências:
/// - ARCHITECTURE.md §Pragmatic Clean Architecture: Service/Facade
/// - prompt.md §Princípio 2: YAGNI — serviço único ao invés de UseCases
import '../entities/user.dart';
import '../repositories/result.dart';

abstract class AuthService {
  Future<Result<AuthTokens>> login(String email, String password);
  Future<Result<AuthTokens>> register(String email, String password, String fullName);
  Future<Result<AuthTokens>> refreshToken(String refreshToken);
  Future<Result<UserProfile>> getProfile();
  Future<void> logout();
}

class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final String userId;

  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['access_token'] as String,
        refreshToken: json['refresh_token'] as String,
        userId: json['user_id'] as String? ?? '',
      );
}
