part of "../../auth/auth.dart";
abstract interface class VerifyOTPDataSource{
  Future<Either<Failure,void>> verify(String email);
  Future<Either<Failure,void>> resend(String email);
}

class VerifyOTPDataSourceImpl implements VerifyOTPDataSource{
  final GenericDataSource _genericDataSource;
  const VerifyOTPDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> verify(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  } @override
  Future<Either<Failure, void>> resend(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.login,data: {"email":email});
  }
}