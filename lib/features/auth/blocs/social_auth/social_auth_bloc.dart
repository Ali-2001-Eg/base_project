part of "../../auth.dart";
class SocialAuthBloc extends Bloc<SocialAuthEvent, BaseState<void>> {
  final SocialAuthDataSource _socialAuthDataSource;
  SocialAuthBloc(this._socialAuthDataSource)
      : super(const BaseState<void>()) {
    on<SocialAuthEvent>(_onSocialAuth);
  }
  FutureOr<void> _onSocialAuth(
      SocialAuthEvent event, Emitter<BaseState<void>> emit) async {
    emit(state.copyWith(status: Status.loading));
    final result = await _socialAuthDataSource.login(event.email);
    emit(result.fold(
          (failure) => state.copyWith(
          status: Status.failure,
          errorMessage: failure.message,
          failure: failure),
          (data) => state.copyWith(status: Status.success, data: data),
    ));
  }
}
