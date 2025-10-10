part of "../../auth.dart";
class VerifyOTPBloc extends Bloc<VerifyOtpEvent, BaseState<void>> {
  final VerifyOTPDataSource _verifyDataSource;
  VerifyOTPBloc(this._verifyDataSource)
      : super(const BaseState<void>()) {
    on<VerifyOtpEvent>(_onVerify);
  }
  FutureOr<void> _onVerify(
      VerifyOtpEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _verifyDataSource.verify(event.email);
    emit(result.fold(
          (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
          (data) => state.copyWith(status: Status.success, data: data),
    ));
  }
}