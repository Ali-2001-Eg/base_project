part of '../../products.dart';
class AddProductEvent extends Equatable{
  final String name;
  final String code;
  const AddProductEvent({required this.name,required this.code});
  @override
  List<Object?> get props => [name,code];
}