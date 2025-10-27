part of "../../auth.dart";

class ForgetPasswordBloc extends Bloc<ForgetPasswordEvent, BaseState<void>> {
  final ForgetPasswordDataSource _forgetPasswordDataSource;
  ForgetPasswordBloc(this._forgetPasswordDataSource)
      : super(const BaseState<void>()) {
    on<ForgetPasswordEvent>(_onForgetPassword);
  }
  FutureOr<void> _onForgetPassword(
      ForgetPasswordEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _forgetPasswordDataSource.forgetPassword(event.email);
    emit(result.fold(
      (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
      (data) => state.copyWith(status: Status.success),
    ));
  }
}
