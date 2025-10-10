part of "../../auth/auth.dart";
abstract interface class RegisterDataSource{
  Future<Either<Failure,void>> register(String email);
}

class RegisterDataSourceImpl implements RegisterDataSource{
  final GenericDataSource _genericDataSource;
  const RegisterDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> register(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  }
}

