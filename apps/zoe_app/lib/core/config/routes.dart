/// Configuração de rotas com transições luxury.
///
/// Referências:
/// - ARCHITECTURE.md §Diagrama de Fluxo: splash → onboarding → auth → home
/// - TECHNICAL_AUDIT.md §2.1: Curves.easeInOutCubic, duração 450ms
import 'package:flutter/material.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String storeDetails = '/store';
  static const String productDetails = '/product';
  static const String cart = '/cart';
  static const String checkout = '/checkout';
  static const String orderSuccess = '/order-success';
  static const String orderTracking = '/order-tracking';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      // Duração luxury: 450ms (TECHNICAL_AUDIT §2.1)
      transitionDuration: const Duration(milliseconds: 450),
      reverseTransitionDuration: const Duration(milliseconds: 450),
      pageBuilder: (context, animation, secondaryAnimation) {
        switch (settings.name) {
          case splash:
            return const Scaffold(body: Center(child: Text('ZOE')));
          case home:
            return const Scaffold(body: Center(child: Text('Home')));
          default:
            return const Scaffold(body: Center(child: Text('404')));
        }
      },
      // Curva principal: easeInOutCubic (TECHNICAL_AUDIT §2.1)
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeInOutCubic,
        );
        return FadeTransition(
          opacity: curvedAnimation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.02),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: child,
          ),
        );
      },
    );
  }
}
