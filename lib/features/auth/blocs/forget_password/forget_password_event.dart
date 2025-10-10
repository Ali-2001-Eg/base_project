part of "../../auth.dart";
abstract interface class ForgetPasswordEvent extends Equatable{
  final String email;
  const ForgetPasswordEvent(this.email);

  @override
  List<Object?> get props => [email];

}