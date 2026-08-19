/// App root do Dashboard do Lojista com GoRouter.
///
/// Referências:
/// - ARCHITECTURE.md §Fluxo do Lojista: Login → Dashboard → Pedidos/Inventário
/// - prompt.md §3: aplicação focada nos lojistas e administradores
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/injection/portal_injection.dart';
import 'core/theme/portal_theme.dart';
import 'core/routing/portal_router.dart';
import 'presentation/cubits/portal_auth_cubit.dart';
import 'presentation/cubits/portal_orders_cubit.dart';
import 'presentation/cubits/portal_inventory_cubit.dart';
import 'presentation/cubits/portal_coupons_cubit.dart';
import 'presentation/cubits/portal_reviews_cubit.dart';
import 'presentation/cubits/portal_rma_cubit.dart';
import 'presentation/cubits/portal_settings_cubit.dart';

class ZoePortalApp extends StatelessWidget {
  const ZoePortalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => portalGetIt<PortalAuthCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalOrdersCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalInventoryCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalCouponsCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalReviewsCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalRmaCubit>()),
        BlocProvider(create: (_) => portalGetIt<PortalSettingsCubit>()),
      ],
      child: MaterialApp.router(
        title: 'Zoe Portal',
        debugShowCheckedModeBanner: false,
        theme: PortalTheme.light(),
        routerConfig: portalRouter,
      ),
    );
  }
}
