/// Contrato do serviço de autenticação do Portal.
///
/// Gerencia login, logout e recuperação do perfil do merchant autenticado.
abstract class PortalAuthService {
  /// Autentica o merchant com e-mail e senha.
  ///
  /// Retorna um mapa contendo `access_token`, `refresh_token`, `user_id`
  /// e `role`.
  Future<Map<String, dynamic>> login(String email, String password);

  /// Encerra a sessão atual, removendo tokens persistidos.
  Future<void> logout();

  /// Retorna o perfil do merchant autenticado ou `null` se não houver
  /// sessão ativa.
  Future<Map<String, dynamic>?> getCurrentUser();
}
