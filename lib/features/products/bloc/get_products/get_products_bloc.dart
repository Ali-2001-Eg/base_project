part of '../../products.dart';
class GetProductsBloc extends PaginatedBloc<ProductsModel> {
  final ProductsDataSource _productsDataSource;
  GetProductsBloc(this._productsDataSource): super(fetchPage: (page,limit,query,params) => _productsDataSource.getProducts(PaginationParams(limit: limit, page: page),query: params?["query"]??""),cacheKeyBuilder: (query,_)=> "get_products");
}