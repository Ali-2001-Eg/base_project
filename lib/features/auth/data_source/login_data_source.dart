part of "../../auth/auth.dart";
abstract interface class LoginDataSource{
  Future<Either<Failure,void>> login(String email);
}

class LoginDataSourceImpl implements LoginDataSource{
  final GenericDataSource _genericDataSource;
  const LoginDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> login(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  }
}
