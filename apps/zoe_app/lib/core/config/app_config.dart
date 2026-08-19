/// Configuração de ambiente e endpoints.
///
/// Referência: ARCHITECTURE.md §core/config/
class EnvConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/api/v1',
  );

  static const String wsUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000/api/v1/ws',
  );
}

class ApiEndpoints {
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register/customer';
  static const String registerCustomer = '/auth/register/customer';
  static const String refreshToken = '/auth/refresh';
  static const String me = '/auth/me';

  // Users / Profile
  static const String users = '/users';
  static const String profile = '/users/me';
  static const String addresses = '/users/me/addresses';

  // Stores
  static const String stores = '/stores';

  // Products
  static const String products = '/products';

  // Cart
  static const String cart = '/cart';

  // Orders
  static const String orders = '/orders';

  // Payments
  static const String payments = '/payments';

  // Coupons
  static const String coupons = '/coupons';

  // Reviews
  static const String reviews = '/reviews';

  // Wishlists
  static const String wishlists = '/wishlists';

  // RMA
  static const String rma = '/rma';

  // Notifications
  static const String notifications = '/notifications';

  // Inventory (Dashboard)
  static const String inventory = '/inventory';
}
