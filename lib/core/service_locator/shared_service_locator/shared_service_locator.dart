part of '../service_locator.dart';


class SharedServiceLocator {

  static Future<void> execute({required GetIt getIt}) async {
    final token = HiveServiceImpl.instance.getAccessToken();

    loggerWarn("token in sl $token");
    loggerWarn("Accept Language in sl ${navigatorKey.currentContext?.isArabic}");
    getIt.registerLazySingleton<Dio>(
          () {
        return Dio(
          BaseOptions(
            baseUrl: Endpoints.baseUrl,
            connectTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'Accept-Language':
              navigatorKey.currentContext?.isArabic??true ? 'ar' : 'en',
              'Authorization': 'Bearer $token',
            },
          ),
        )..interceptors.addAll([
          if (kDebugMode)
            PrettyDioLogger(
              requestHeader: true,
              requestBody: true,
              responseBody: true,
              responseHeader: false,
              error: true,
              compact: true,
              enabled: true,
              request: true,
              maxWidth: 90,
            ),
        ]);
      },
    );
    getIt.registerLazySingleton<ApiConsumer>(() => BaseApiConsumer(dio: getIt<Dio>()));
    getIt.registerLazySingleton<GenericDataSource>(() => GenericDataSource( getIt<ApiConsumer>()));
    getIt.registerLazySingleton<SyncManager>(() => SyncManager());
    getIt.registerLazySingleton<ConnectivityService>(() => ConnectivityService.instance);

    // getIt.registerLazySingleton<SyncBloc>(() => SyncBloc(syncManager: getIt<SyncManager>(), connectivityService: getIt<ConnectivityService>()));
  }
}