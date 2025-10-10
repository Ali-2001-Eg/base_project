part of '../service_locator.dart';

class AuthServiceLocator{
  static Future<void> execute({required GetIt getIt})async {
    //data sources
    getIt.registerLazySingleton<RegisterDataSource>(()=> RegisterDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<LoginDataSource>(()=> LoginDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<ForgetPasswordDataSource>(()=> ForgetPasswordDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<LogoutDataSource>(()=> LogoutDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<ResetPasswordDataSource>(()=> ResetPasswordDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<SocialAuthDataSource>(()=> SocialAuthDataSourceImpl(getIt<GenericDataSource>()));
    getIt.registerLazySingleton<VerifyOTPDataSource>(()=> VerifyOTPDataSourceImpl(getIt<GenericDataSource>()));
    //blocs
    getIt.registerFactory<RegisterBloc>(()=> RegisterBloc(getIt<RegisterDataSource>()));
    getIt.registerFactory<LoginBloc>(()=> LoginBloc(getIt<LoginDataSource>()));
    getIt.registerFactory<ForgetPasswordBloc>(()=> ForgetPasswordBloc(getIt<ForgetPasswordDataSource>()));
    getIt.registerFactory<LogoutBloc>(()=> LogoutBloc(getIt<LogoutDataSource>()));
    getIt.registerFactory<ResetPasswordBloc>(()=> ResetPasswordBloc(getIt<ResetPasswordDataSource>()));
    getIt.registerFactory<SocialAuthBloc>(()=> SocialAuthBloc(getIt<SocialAuthDataSource>()));
    getIt.registerFactory<VerifyOTPBloc>(()=> VerifyOTPBloc(getIt<VerifyOTPDataSource>()));

  }
}