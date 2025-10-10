part of "../../auth.dart";
abstract interface class VerifyOtpEvent extends Equatable{
  final String email;
  const VerifyOtpEvent(this.email);
  @override
  List<Object?> get props => [email];
}
