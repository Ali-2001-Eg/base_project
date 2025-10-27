part of "../../auth.dart";

class ResetPasswordBloc extends Bloc<ResetPasswordEvent, BaseState<void>> {
  final ResetPasswordDataSource _loginDataSource;
  ResetPasswordBloc(this._loginDataSource) : super(const BaseState<void>()) {
    on<ResetPasswordEvent>(_onResetPasswordEvent);
  }
  FutureOr<void> _onResetPasswordEvent(
      ResetPasswordEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _loginDataSource.resetPassword(event.email);
    emit(result.fold(
      (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
      (data) => state.copyWith(status: Status.success),
    ));
  }
}
