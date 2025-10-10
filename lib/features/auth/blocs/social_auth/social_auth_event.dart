part of "../../auth.dart";
abstract interface class SocialAuthEvent extends Equatable{
  final String email;
  const SocialAuthEvent(this.email);
  @override
  List<Object?> get props => [email];
}
