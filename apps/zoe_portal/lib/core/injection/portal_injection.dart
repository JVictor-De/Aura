/// Service Locator do Portal (GetIt).
///
/// Referências:
/// - ARCHITECTURE.md §Dependency Injection: get_it pattern
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../network/portal_api_client.dart';

// Domain services
import '../../domain/services/portal_auth_service.dart';
import '../../domain/services/portal_order_service.dart';
import '../../domain/services/portal_inventory_service.dart';
import '../../domain/services/portal_coupon_service.dart';
import '../../domain/services/portal_review_service.dart';
import '../../domain/services/portal_rma_service.dart';
import '../../domain/services/portal_settings_service.dart';
import '../../domain/services/portal_report_service.dart';

// Data implementations
import '../../data/services/portal_auth_service_impl.dart';
import '../../data/services/portal_order_service_impl.dart';
import '../../data/services/portal_inventory_service_impl.dart';
import '../../data/services/portal_coupon_service_impl.dart';
import '../../data/services/portal_review_service_impl.dart';
import '../../data/services/portal_rma_service_impl.dart';
import '../../data/services/portal_settings_service_impl.dart';
import '../../data/services/portal_report_service_impl.dart';

// Cubits
import '../../presentation/cubits/portal_auth_cubit.dart';
import '../../presentation/cubits/portal_orders_cubit.dart';
import '../../presentation/cubits/portal_inventory_cubit.dart';
import '../../presentation/cubits/portal_coupons_cubit.dart';
import '../../presentation/cubits/portal_reviews_cubit.dart';
import '../../presentation/cubits/portal_rma_cubit.dart';
import '../../presentation/cubits/portal_settings_cubit.dart';

final portalGetIt = GetIt.instance;

Future<void> configurePortalDependencies() async {
  final prefs = await SharedPreferences.getInstance();
  portalGetIt.registerSingleton<SharedPreferences>(prefs);

  portalGetIt.registerLazySingleton<Dio>(() => PortalApiClient.createDio());

  // ── Services ──────────────────────────────────────────────
  portalGetIt.registerLazySingleton<PortalAuthService>(
    () => PortalAuthServiceImpl(
      dio: portalGetIt<Dio>(),
      prefs: portalGetIt<SharedPreferences>(),
    ),
  );
  portalGetIt.registerLazySingleton<PortalOrderService>(
    () => PortalOrderServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalInventoryService>(
    () => PortalInventoryServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalCouponService>(
    () => PortalCouponServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalReviewService>(
    () => PortalReviewServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalRmaService>(
    () => PortalRmaServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalSettingsService>(
    () => PortalSettingsServiceImpl(dio: portalGetIt<Dio>()),
  );
  portalGetIt.registerLazySingleton<PortalReportService>(
    () => PortalReportServiceImpl(dio: portalGetIt<Dio>()),
  );

  // ── Cubits ────────────────────────────────────────────────
  portalGetIt.registerFactory<PortalAuthCubit>(
    () => PortalAuthCubit(authService: portalGetIt<PortalAuthService>()),
  );
  portalGetIt.registerFactory<PortalOrdersCubit>(
    () => PortalOrdersCubit(orderService: portalGetIt<PortalOrderService>()),
  );
  portalGetIt.registerFactory<PortalInventoryCubit>(
    () => PortalInventoryCubit(inventoryService: portalGetIt<PortalInventoryService>()),
  );
  portalGetIt.registerFactory<PortalCouponsCubit>(
    () => PortalCouponsCubit(couponService: portalGetIt<PortalCouponService>()),
  );
  portalGetIt.registerFactory<PortalReviewsCubit>(
    () => PortalReviewsCubit(reviewService: portalGetIt<PortalReviewService>()),
  );
  portalGetIt.registerFactory<PortalRmaCubit>(
    () => PortalRmaCubit(rmaService: portalGetIt<PortalRmaService>()),
  );

  portalGetIt.registerFactory<PortalSettingsCubit>(
    () => PortalSettingsCubit(settingsService: portalGetIt<PortalSettingsService>()),
  );
}
