import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class LoginController {
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.login),
        body: {'username': username, 'password': password},
      );

      final data = json.decode(response.body);
      return data;
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
