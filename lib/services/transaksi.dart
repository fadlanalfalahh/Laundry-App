import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class TransaksiService {
  static const String baseUrl = AppConfig.transaksi;

  static Future<Map<String, dynamic>> tambahTransaksi(
    Map<String, dynamic> data,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add.php'),
      headers: {"Content-Type": "application/x-www-form-urlencoded"},
      body: data,
    );

    return json.decode(response.body);
  }
}
