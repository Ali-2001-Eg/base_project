part of "../../auth.dart";

abstract interface class LoginEvent extends Equatable {
  final String email;
  const LoginEvent(this.email);
  @override
  List<Object?> get props => [email];
}
