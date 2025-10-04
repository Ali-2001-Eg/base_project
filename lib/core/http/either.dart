abstract interface class Either<L, R> {
  Either();

  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn);
}

class Left<L, R> extends Either<L, R> {
  final L value;

  Left(this.value);

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return leftFn(value);
  }
}

class Right<L, R> extends Either<L, R> {
  final R value;

  Right(this.value);

  @override
  T fold<T>(T Function(L left) leftFn, T Function(R right) rightFn) {
    return rightFn(value);
  }
}