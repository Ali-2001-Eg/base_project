import 'package:equatable/equatable.dart';
import 'package:hive_flutter/adapters.dart';
part 'user_model.g.dart';
@HiveType(typeId: 0)
class UserModel extends Equatable{
  @HiveField(0)
  final int id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String email;
  @HiveField(3)
  final String phone;
  //
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,});
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
    };
  }
  UserModel copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }
  @override
  List<Object?> get props => [id, name, email, phone];
}

