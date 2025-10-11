part of "../products.dart";
abstract interface class ProductsDataSource{
  Future<Either<Failure,List<ProductsModel>>> getProducts(PaginationParams params,{String? query});
  Future<Either<Failure,void>> addProduct(AddProductParams params);
  Future<Either<Failure,void>> updateProduct(UpdateProductParams params);
  Future<Either<Failure,void>> deleteProduct(int id);
}
class ProductsDataSourceImpl implements ProductsDataSource{
  final GenericDataSource _genericDataSource;
  ProductsDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, List<ProductsModel>>> getProducts(PaginationParams params, {String? query}) {
   return _genericDataSource.fetchData<ProductsModel>(endpoint: Endpoints.product, fromJson: ProductsModel.fromJson,queryParameters: {
     'query': query,
   });
  }

  @override
  Future<Either<Failure, void>> addProduct(AddProductParams params) {
    return _genericDataSource.postData<void>(endpoint: Endpoints.product, data: params.toJson());
  }

  @override
  Future<Either<Failure, void>> deleteProduct(int id) {
    return _genericDataSource.deleteData<void>(endpoint: Endpoints.product,data: {'id':id});
  }

  @override
  Future<Either<Failure, void>> updateProduct(UpdateProductParams params) {
   return  _genericDataSource.updateData(endpoint: Endpoints.product,data: params.toJson());
  }
}