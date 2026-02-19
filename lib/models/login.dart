class UserModel {
  final String nama;
  final String role;

  UserModel({required this.nama, required this.role});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(nama: json['nama'], role: json['role']);
  }
}
