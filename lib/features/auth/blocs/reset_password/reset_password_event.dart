part of "../../auth.dart";
abstract interface class ResetPasswordEvent extends Equatable{
  final String email;
  const ResetPasswordEvent(this.email);
  @override
  List<Object?> get props => [email];
}
