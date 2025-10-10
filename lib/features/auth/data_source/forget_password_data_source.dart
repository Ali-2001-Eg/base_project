part of "../../auth/auth.dart";
abstract interface class ForgetPasswordDataSource{
  Future<Either<Failure,void>> forgetPassword(String email);
}

class ForgetPasswordDataSourceImpl implements ForgetPasswordDataSource{
  final GenericDataSource _genericDataSource;
  const ForgetPasswordDataSourceImpl(this._genericDataSource);

  @override
  Future<Either<Failure, void>> forgetPassword(String email) {
    return _genericDataSource.postData(endpoint: Endpoints.forgetPassword,data: {"email":email});
  }
}
