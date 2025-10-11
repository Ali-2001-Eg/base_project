part of 'local_storage.dart';


abstract interface class IPaginatedCache<T> {
  const IPaginatedCache();

  Future<void> cachePage(List<T> items, {required String cacheKey});

  Future<List<T>> getCachedPage({required String cacheKey});

  Future<void> clearCachedPage({required String cacheKey});
}

class ProductsPaginatedCache extends IPaginatedCache<ProductsModel>{
  final HiveServiceImpl hiveService;
  const ProductsPaginatedCache(this.hiveService);
  @override
  Future<void> cachePage(List<ProductsModel> items, {required String cacheKey}) async {
    hiveService._cachePage(items, cacheKey: 'products$cacheKey');
  }

  @override
  Future<void> clearCachedPage({required String cacheKey}) {
    return hiveService._clearCachedPage(cacheKey: 'products$cacheKey');

  }

  @override
  Future<List<ProductsModel>> getCachedPage({required String cacheKey}) {
    return hiveService._getCachedPage(cacheKey: 'products$cacheKey');
  }

}