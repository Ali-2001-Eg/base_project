part of "../../auth.dart";

class LogoutBloc extends Bloc<LogoutEvent, BaseState<void>> {
  final LogoutDataSource _loginDataSource;
  LogoutBloc(this._loginDataSource) : super(const BaseState<void>()) {
    on<LogoutEvent>(_onForgetPassword);
  }
  FutureOr<void> _onForgetPassword(
      LogoutEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _loginDataSource.logout(const NoParams());
    emit(result.fold(
      (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
      (data) => state.copyWith(status: Status.success),
    ));
  }
}
