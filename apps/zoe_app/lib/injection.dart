/// Service Locator (GetIt).
///
/// Referências:
/// - ARCHITECTURE.md §Estrutura de Pastas: injection.dart
/// - prompt.md §3.1: get_it
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/network/interceptors/auth_interceptor.dart';
import 'core/storage/secure_storage.dart';

// Domain services
import 'domain/services/auth_service.dart';
import 'domain/services/cart_service.dart';
import 'domain/services/order_service.dart';
import 'domain/services/product_service.dart';
import 'domain/services/store_service.dart';
import 'domain/services/wishlist_service.dart';
import 'domain/services/review_service.dart';
import 'domain/services/rma_service.dart';
import 'domain/services/notification_service.dart';
import 'domain/services/payment_service.dart';
import 'domain/services/tracking_service.dart';

// Data repositories
import 'data/repositories/auth_service_impl.dart';
import 'data/repositories/cart_service_impl.dart';
import 'data/repositories/order_service_impl.dart';
import 'data/repositories/product_service_impl.dart';
import 'data/repositories/store_service_impl.dart';
import 'data/repositories/wishlist_service_impl.dart';
import 'data/repositories/review_service_impl.dart';
import 'data/repositories/rma_service_impl.dart';
import 'data/repositories/notification_service_impl.dart';
import 'data/repositories/payment_service_impl.dart';
import 'data/repositories/tracking_service_impl.dart';

// Cubits
import 'presentation/cubits/auth/auth_cubit.dart';
import 'presentation/cubits/address/address_cubit.dart';
import 'presentation/cubits/cart/cart_cubit.dart';
import 'presentation/cubits/catalog/catalog_cubit.dart';
import 'presentation/cubits/checkout/checkout_cubit.dart';
import 'presentation/cubits/orders/orders_cubit.dart';
import 'presentation/cubits/wishlist/wishlist_cubit.dart';
import 'presentation/cubits/tracking/tracking_cubit.dart';
import 'presentation/cubits/notification/notification_cubit.dart';

final getIt = GetIt.instance;

/// Inicializa todas as dependências.
/// Chamado em main.dart antes de runApp.
Future<void> configureDependencies() async {
  // ── Plataforma ────────────────────────────────────────────
  getIt.registerLazySingleton<FlutterSecureStorage>(
    () => const FlutterSecureStorage(),
  );

  getIt.registerLazySingleton<SecureStorage>(
    () => SecureStorage(getIt<FlutterSecureStorage>()),
  );

  // ── Network ───────────────────────────────────────────────
  getIt.registerLazySingleton<Dio>(() {
    final apiClient = ApiClient.create(AuthInterceptor());
    return apiClient.dio;
  });

  // ── Services ──────────────────────────────────────────────
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(getIt<Dio>(), getIt<SecureStorage>()),
  );

  getIt.registerLazySingleton<CartService>(
    () => CartServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<OrderService>(
    () => OrderServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ProductService>(
    () => ProductServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<StoreService>(
    () => StoreServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<WishlistService>(
    () => WishlistServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<ReviewService>(
    () => ReviewServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<RmaService>(
    () => RmaServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<NotificationService>(
    () => NotificationServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<PaymentService>(
    () => PaymentServiceImpl(getIt<Dio>()),
  );

  getIt.registerLazySingleton<TrackingService>(
    () => TrackingServiceImpl(getIt<Dio>()),
  );

  // ── Cubits ────────────────────────────────────────────────
  getIt.registerFactory<AuthCubit>(
    () => AuthCubit(
      authService: getIt<AuthService>(),
      storage: getIt<SecureStorage>(),
    ),
  );

  getIt.registerFactory<AddressCubit>(
    () => AddressCubit(),
  );

  getIt.registerFactory<CartCubit>(
    () => CartCubit(),
  );

  getIt.registerFactory<CatalogCubit>(
    () => CatalogCubit(
      productService: getIt<ProductService>(),
      storeService: getIt<StoreService>(),
    ),
  );

  getIt.registerFactory<CheckoutCubit>(
    () => CheckoutCubit(orderService: getIt<OrderService>()),
  );

  getIt.registerFactory<OrdersCubit>(
    () => OrdersCubit(orderService: getIt<OrderService>()),
  );

  getIt.registerFactory<WishlistCubit>(
    () => WishlistCubit(),
  );

  getIt.registerFactory<TrackingCubit>(
    () => TrackingCubit(wsUrl: EnvConfig.wsUrl),
  );

  getIt.registerFactory<NotificationCubit>(
    () => NotificationCubit(),
  );
}
