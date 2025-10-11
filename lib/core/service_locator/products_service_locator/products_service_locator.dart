part of '../service_locator.dart';
class ProductsServiceLocator {
  static Future<void> execute({required GetIt getIt}) async {
    getIt.registerLazySingleton<ProductsDataSource>(()=> ProductsDataSourceImpl(getIt<GenericDataSource>()),);
    getIt.registerFactory<GetProductsBloc>(()=> GetProductsBloc(getIt<ProductsDataSource>(),));
    getIt.registerFactory<AddProductBloc>(()=> AddProductBloc(getIt<ProductsDataSource>(),));
    getIt.registerFactory<UpdateProductBloc>(()=> UpdateProductBloc(getIt<ProductsDataSource>()));
    getIt.registerFactory<DeleteProductBloc>(()=> DeleteProductBloc(getIt<ProductsDataSource>()));
  }
}