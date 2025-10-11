part of '../../products.dart';
class DeleteProductEvent extends Equatable{
  final int id;
  const DeleteProductEvent({required this.id});
  @override
  List<Object?> get props => [id];

}