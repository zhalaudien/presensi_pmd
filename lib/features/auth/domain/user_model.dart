import 'cabang_model.dart';

class UserModel {
  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? role;
  final int? cabangId;
  final CabangModel? cabang;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.role,
    this.cabangId,
    this.cabang,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    CabangModel? cabangObj;
    if (json['cabang'] is Map<String, dynamic>) {
      cabangObj = CabangModel.fromJson(json['cabang'] as Map<String, dynamic>);
    }

    return UserModel(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      name: (json['name'] ?? json['nama'] ?? 'Petugas Cabang').toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      role: json['role']?.toString() ?? 'admin_cabang',
      cabangId: json['cabang_id'] is int
          ? json['cabang_id']
          : int.tryParse(json['cabang_id']?.toString() ?? ''),
      cabang: cabangObj,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'username': username,
      'email': email,
      'role': role,
      'cabang_id': cabangId,
      'cabang': cabang?.toJson(),
    };
  }
}
