import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class TransaksiService {
  static const String baseUrl = AppConfig.transaksi;

  static Future<List<Map<String, dynamic>>> getTransaksiHariIni({
    String? status,
  }) async {
    final String? normalized = status?.trim().toLowerCase();
    final uri = Uri.parse(
      '$baseUrl/list_today.php${normalized != null ? '?status=${Uri.encodeQueryComponent(normalized)}' : ''}',
    );

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) return [];

      final decoded = json.decode(res.body);
      if (decoded is Map &&
          decoded['success'] == true &&
          decoded['data'] is List) {
        return List<Map<String, dynamic>>.from(decoded['data']);
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> cancelTransaksi(
    int idMaster,
    String role,
  ) async {
    final uri = Uri.parse('$baseUrl/cancel.php');
    try {
      final res = await http
          .post(uri, body: {'id_master': idMaster.toString(), 'role': role})
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        return {"success": false, "message": "Gagal koneksi ke server"};
      }
      return json.decode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
