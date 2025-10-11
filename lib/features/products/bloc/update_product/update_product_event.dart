part of '../../products.dart';
class UpdateProductEvent extends Equatable{
  final int id;
  final String? name;
  final String? code;
  const UpdateProductEvent({required this.id,this.name,this.code});
  @override
  List<Object?> get props => [id,name,code];
}