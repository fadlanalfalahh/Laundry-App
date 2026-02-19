import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../config.dart';

class UserService {
  static const String baseUrl = AppConfig.users;

  static Future<List<UserModel>> getAll() async {
    final url = Uri.parse("$baseUrl/read.php");
    final res = await http.get(url);

    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['success'] == true) {
        return (data['data'] as List)
            .map((e) => UserModel.fromJson(e))
            .toList();
      }
    }
    return [];
  }

  static Future<Map<String, dynamic>> create(
    String nama,
    String role,
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/create.php");
    final res = await http.post(
      url,
      body: {
        "nama_user": nama,
        "role": role,
        "username": username,
        "password": password,
      },
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> update(
    String id,
    String nama,
    String role,
    String username,
    String password,
  ) async {
    final url = Uri.parse("$baseUrl/update.php");
    final res = await http.post(
      url,
      body: {
        "id": id,
        "nama_user": nama,
        "role": role,
        "username": username,
        "password": password,
      },
    );
    return json.decode(res.body);
  }

  static Future<Map<String, dynamic>> delete(String id) async {
    final url = Uri.parse("$baseUrl/delete.php");
    final res = await http.post(url, body: {"id": id});
    return json.decode(res.body);
  }
}
