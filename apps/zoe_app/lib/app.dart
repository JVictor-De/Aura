/// App root widget com ThemeData luxury e GoRouter.
///
/// Referências:
/// - ARCHITECTURE.md §Design System: ZoeColors, ZoeTypography, ZoeSpacing
/// - TECHNICAL_AUDIT.md §2.1: Curves.easeInOutCubic nas transições principais
/// - prompt.md §3.1: go_router, flutter_bloc
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/zoe_theme.dart';
import 'core/config/app_router.dart';
import 'injection.dart';

import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/address/address_cubit.dart';
import 'presentation/cubits/cart/cart_cubit.dart';
import 'presentation/cubits/catalog/catalog_cubit.dart';
import 'presentation/cubits/checkout/checkout_cubit.dart';
import 'presentation/cubits/orders/orders_cubit.dart';
import 'presentation/cubits/wishlist/wishlist_cubit.dart';
import 'presentation/cubits/tracking/tracking_cubit.dart';
import 'presentation/cubits/notification/notification_cubit.dart';

class ZoeApp extends StatelessWidget {
  const ZoeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<AuthCubit>()..checkAuth()),
        BlocProvider(create: (_) => getIt<AddressCubit>()),
        BlocProvider(create: (_) => getIt<CartCubit>()),
        BlocProvider(create: (_) => getIt<CatalogCubit>()),
        BlocProvider(create: (_) => getIt<CheckoutCubit>()),
        BlocProvider(create: (_) => getIt<OrdersCubit>()),
        BlocProvider(create: (_) => getIt<WishlistCubit>()),
        BlocProvider(create: (_) => getIt<TrackingCubit>()),
        BlocProvider(create: (_) => getIt<NotificationCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Zoe',
        debugShowCheckedModeBanner: false,
        theme: ZoeTheme.light(),
        routerConfig: appRouter,
      ),
    );
  }
}
