part of "../../auth.dart";

class RegisterBloc extends Bloc<RegisterEvent, BaseState<void>> {
  final RegisterDataSource _loginDataSource;
  RegisterBloc(this._loginDataSource) : super(const BaseState<void>()) {
    on<RegisterEvent>(_onForgetPassword);
  }
  FutureOr<void> _onForgetPassword(
      RegisterEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _loginDataSource.register(event.email);
    emit(result.fold(
      (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
      (data) => state.copyWith(status: Status.success),
    ));
  }
}
