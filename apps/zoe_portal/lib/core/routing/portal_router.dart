/// Auth guard para rotas do Portal.
///
/// Referências:
/// - ARCHITECTURE.md §RBAC: merchant/admin guard
/// - prompt.md §3.2: Dashboard (Flutter Web)
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/dashboard/dashboard_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/inventory/inventory_page.dart';
import '../../presentation/pages/products/products_page.dart';
import '../../presentation/pages/returns/returns_page.dart';
import '../../presentation/pages/coupons/coupons_page.dart';
import '../../presentation/pages/reviews/reviews_page.dart';
import '../../presentation/pages/settings/store_settings_page.dart';
import '../../presentation/pages/reports/reports_page.dart';

final GoRouter portalRouter = GoRouter(
  initialLocation: '/login',
  redirect: _authGuard,
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const PortalLoginPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => DashboardPage(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          name: 'dashboard',
          builder: (context, state) => const Center(
            child: Text('Dashboard KPIs'),
          ),
        ),
        GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersPage(),
        ),
        GoRoute(
          path: '/inventory',
          name: 'inventory',
          builder: (context, state) => const InventoryPage(),
        ),
        GoRoute(
          path: '/products',
          name: 'products',
          builder: (context, state) => const ProductsPage(),
        ),
        GoRoute(
          path: '/returns',
          name: 'returns',
          builder: (context, state) => const ReturnsPage(),
        ),
        GoRoute(
          path: '/coupons',
          name: 'coupons',
          builder: (context, state) => const CouponsPage(),
        ),
        GoRoute(
          path: '/reviews',
          name: 'reviews',
          builder: (context, state) => const ReviewsPage(),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const StoreSettingsPage(),
        ),
        GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsPage(),
        ),
      ],
    ),
  ],
);

/// Auth guard: redireciona para /login se não autenticado.
Future<String?> _authGuard(
  BuildContext context,
  GoRouterState state,
) async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('access_token');
  final isLoggedIn = token != null && token.isNotEmpty;
  final isLoginRoute = state.matchedLocation == '/login';

  if (!isLoggedIn && !isLoginRoute) return '/login';
  if (isLoggedIn && isLoginRoute) return '/dashboard';

  return null;
}
