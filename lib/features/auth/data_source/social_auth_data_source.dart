part of "../../auth/auth.dart";
abstract interface class SocialAuthDataSource{
  Future<Either<Failure,void>> login(String email);
}

class SocialAuthDataSourceImpl implements SocialAuthDataSource{
  final GenericDataSource _genericDataSource;
  const SocialAuthDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> login(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  }
}