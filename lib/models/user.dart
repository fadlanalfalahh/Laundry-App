class UserModel {
  final String id;
  final String namaUser;
  final String role;
  final String username;

  UserModel({
    required this.id,
    required this.namaUser,
    required this.role,
    required this.username,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'].toString(),
      namaUser: json['nama_user'],
      role: json['role'],
      username: json['username'],
    );
  }
}
