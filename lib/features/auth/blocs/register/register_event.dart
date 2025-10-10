part of "../../auth.dart";
abstract interface class RegisterEvent extends Equatable{
  final String email;
  const RegisterEvent(this.email);

  @override
  List<Object?> get props => [email];


}