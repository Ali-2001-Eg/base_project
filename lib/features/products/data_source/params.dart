part of '../products.dart';
class AddProductParams extends Equatable{
  final String name;
  final String code;
  const AddProductParams({required this.name,required this.code});
  @override
  List<Object?> get props => [name,code];
  Map<String, dynamic> toJson() => {
    'name': name,
    'code': code,
  };
}

class UpdateProductParams extends Equatable{
  final int id;
  final String? name;
  final String? code;
  const UpdateProductParams({required this.id,this.name,this.code});
  @override
  List<Object?> get props => [id,name,code];
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
  };
}