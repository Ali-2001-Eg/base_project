part of "../../auth/auth.dart";
abstract interface class ResetPasswordDataSource{
  Future<Either<Failure,void>> resetPassword(String email);
}

class ResetPasswordDataSourceImpl implements ResetPasswordDataSource{
  final GenericDataSource _genericDataSource;
  const ResetPasswordDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> resetPassword(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  }
}

