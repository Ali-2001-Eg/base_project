part of '../service_locator.dart';
class HiveServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    getIt.registerLazySingleton<HiveServiceImpl>(() => HiveServiceImpl.instance);
    getIt.registerLazySingleton<IUserCache>(() => getIt<HiveServiceImpl>());
    getIt.registerLazySingleton<ITokenCache>(() => getIt<HiveServiceImpl>());
    getIt.registerLazySingleton<IPaginatedCache<ProductsModel>>(() => ProductsPaginatedCache(getIt<HiveServiceImpl>()));
  }
}