/// GoRouter configuration com transições luxury e ShellRoute.
///
/// Referências:
/// - ARCHITECTURE.md §Diagrama de Fluxo: splash → onboarding → auth → home
/// - TECHNICAL_AUDIT.md §2.1: Curves.easeInOutCubic, duração 450ms
/// - prompt.md §3.1: go_router
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/pages/splash/splash_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/location/location_onboarding_page.dart';
import '../../presentation/pages/login/login_page.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/search/search_page.dart';
import '../../presentation/pages/cart/cart_page.dart';
import '../../presentation/pages/orders/orders_page.dart';
import '../../presentation/pages/profile/profile_page.dart';
import '../../presentation/pages/product/product_detail_page.dart';
import '../../presentation/pages/store/store_detail_page.dart';
import '../../presentation/pages/checkout/checkout_page.dart';
import '../../presentation/pages/order_success/order_success_page.dart';
import '../../presentation/pages/tracking/active_tracking_page.dart';
import '../../presentation/pages/wishlist/wishlist_page.dart';
import '../../presentation/pages/notifications/notifications_page.dart';
import '../../presentation/pages/payment_methods/payment_methods_page.dart';
import '../../presentation/pages/returns/returns_page.dart';
import '../../presentation/pages/shell/main_shell.dart';
import '../../presentation/cubits/auth/auth_cubit.dart';
import '../../presentation/cubits/address/address_cubit.dart';
import '../auth/auth_guard.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// GoRouter com transição luxury padrão + auth guard.
final GoRouter appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  redirect: (context, state) {
    final authState = context.read<AuthCubit>().state;
    final addressState = context.read<AddressCubit>().state;
    final path = state.uri.path;

    // Public routes — no guard
    const publicPaths = ['/', '/onboarding', '/login', '/register'];
    if (publicPaths.contains(path)) return null;

    // Location onboarding — accessible without address
    if (path == '/location') return null;

    // If no address set, redirect to location onboarding (except public + location paths)
    if (addressState is! AddressSelected && path != '/location') {
      return '/location';
    }

    // Protected routes — exigem login (lazy auth)
    if (AuthGuard.isProtected(path) && authState is! AuthAuthenticated) {
      return '/login?returnTo=${Uri.encodeComponent(path)}';
    }

    return null;
  },
  routes: [
    // ─── Splash ──────────────────────────────────────
    GoRoute(
      path: '/',
      name: 'splash',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const SplashPage()),
    ),

    // ─── Onboarding ──────────────────────────────────
    GoRoute(
      path: '/onboarding',
      name: 'onboarding',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const OnboardingPage()),
    ),

    // ─── Location Onboarding ─────────────────────────
    GoRoute(
      path: '/location',
      name: 'location',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const LocationOnboardingPage()),
    ),

    // ─── Login ───────────────────────────────────────
    GoRoute(
      path: '/login',
      name: 'login',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) {
        final returnTo = state.uri.queryParameters['returnTo'];
        return _luxuryPage(state, LoginPage(returnTo: returnTo));
      },
    ),

    // ─── Main Shell (Bottom Navigation) ──────────────
    StatefulShellRoute.indexedStack(
      pageBuilder: (context, state, navigationShell) => _luxuryPage(
        state,
        MainShell(navigationShell: navigationShell, child: navigationShell),
      ),
      branches: [
        // Tab 0: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              pageBuilder: (context, state) => _luxuryPage(state, const HomePage()),
            ),
          ],
        ),
        // Tab 1: Search / Catalog
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              pageBuilder: (context, state) => _luxuryPage(state, const SearchPage()),
            ),
          ],
        ),
        // Tab 2: Cart
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/cart',
              name: 'cart',
              pageBuilder: (context, state) => _luxuryPage(state, const CartPage()),
            ),
          ],
        ),
        // Tab 3: Orders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/orders',
              name: 'orders',
              pageBuilder: (context, state) => _luxuryPage(state, const OrdersPage()),
            ),
          ],
        ),
        // Tab 4: Profile
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/profile',
              name: 'profile',
              pageBuilder: (context, state) => _luxuryPage(state, const ProfilePage()),
            ),
          ],
        ),
      ],
    ),

    // ─── Fullscreen Routes ───────────────────────────
    GoRoute(
      path: '/product/:id',
      name: 'productDetails',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(
        state,
        ProductDetailPage(productId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/store/:id',
      name: 'storeDetails',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(
        state,
        StoreDetailPage(storeId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/checkout',
      name: 'checkout',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const CheckoutPage()),
    ),
    GoRoute(
      path: '/order-success/:id',
      name: 'orderSuccess',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(
        state,
        OrderSuccessPage(orderId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/tracking/:id',
      name: 'tracking',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(
        state,
        ActiveTrackingPage(orderId: state.pathParameters['id'] ?? ''),
      ),
    ),
    GoRoute(
      path: '/wishlist',
      name: 'wishlist',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const WishlistPage()),
    ),
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const NotificationsPage()),
    ),
    GoRoute(
      path: '/payment-methods',
      name: 'paymentMethods',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const PaymentMethodsPage()),
    ),
    GoRoute(
      path: '/returns',
      name: 'returns',
      parentNavigatorKey: _rootNavigatorKey,
      pageBuilder: (context, state) => _luxuryPage(state, const ReturnsPage()),
    ),
  ],
);

/// Transição luxury: fade + slide sutil com easeInOutCubic (TECHNICAL_AUDIT §2.1)
CustomTransitionPage<void> _luxuryPage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 450),
    reverseTransitionDuration: const Duration(milliseconds: 450),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeInOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}
