import 'package:equatable/equatable.dart';
import 'package:hive_flutter/hive_flutter.dart';
part 'products_model.g.dart';
@HiveType(typeId: 2)
class ProductsModel extends Equatable{
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;

  const ProductsModel({
    required this.id,
    required this.name,
  });

  factory ProductsModel.fromJson(Map<String, dynamic> json) =>
      ProductsModel(id: json['id']??0, name: json['name']??"");

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
  };

  @override
  List<Object?> get props => [id, name];

}