/// AuthGuard — verificação lazy de autenticação.
///
/// Redireciona para /login?returnTo=<rota> quando o usuário tenta
/// executar uma ação que requer autenticação (favoritar, checkout, pedidos…).
///
/// Uso em widgets:
///   if (!AuthGuard.requireAuth(context)) return;
///   // … ação autenticada
///
/// Uso no GoRouter redirect:
///   if (AuthGuard.isProtected(path) && !isAuthenticated) return '/login?returnTo=$path';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../presentation/cubits/auth/auth_cubit.dart';

class AuthGuard {
  AuthGuard._();

  /// Rotas que exigem login (o redirect do GoRouter redireciona antes de renderizar).
  static const _protectedPaths = <String>{
    '/checkout',
    '/orders',
    '/wishlist',
    '/payment-methods',
    '/returns',
    '/notifications',
  };

  /// Verifica se o path é protegido.
  static bool isProtected(String path) => _protectedPaths.contains(path);

  /// Retorna `true` se o usuário está autenticado.
  /// Se não estiver, navega para `/login?returnTo=…` e retorna `false`.
  ///
  /// ```dart
  /// onPressed: () {
  ///   if (!AuthGuard.requireAuth(context)) return;
  ///   // ação protegida
  /// }
  /// ```
  static bool requireAuth(BuildContext context, {String? returnTo}) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) return true;

    final currentPath = returnTo ?? GoRouterState.of(context).uri.toString();
    context.push('/login?returnTo=${Uri.encodeComponent(currentPath)}');
    return false;
  }

  /// Variante assíncrona: exibe bottom sheet de login e espera resultado.
  /// Retorna `true` se o usuário se autenticou durante a exibição.
  static Future<bool> requireAuthAsync(BuildContext context, {String? returnTo}) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) return true;

    final currentPath = returnTo ?? GoRouterState.of(context).uri.toString();
    context.push('/login?returnTo=${Uri.encodeComponent(currentPath)}');
    return false;
  }
}
