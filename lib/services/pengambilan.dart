import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class PengambilanService {
  static const String baseUrl = AppConfig.transaksi;

  static Future<List<Map<String, dynamic>>> listPengambilan({
    String? status,
    DateTime? date,
    String? q,
  }) async {
    final normalized = status?.trim().toLowerCase();
    final String? day = date != null
        ? '${date.year.toString().padLeft(4, '0')}-'
              '${date.month.toString().padLeft(2, '0')}-'
              '${date.day.toString().padLeft(2, '0')}'
        : null;

    final params = <String, String>{};
    if (normalized != null && normalized.isNotEmpty) {
      params['status'] = normalized;
    }
    if (day != null) params['date'] = day;
    if (q != null && q.trim().isNotEmpty) params['q'] = q.trim();

    final uri = Uri.parse(
      '$baseUrl/list_pengambilan_today.php',
    ).replace(queryParameters: params.isEmpty ? null : params);

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

  static Future<Map<String, dynamic>> pickup({
    required int idMaster,
    int? uangDiterima,
  }) async {
    final uri = Uri.parse('$baseUrl/pickup.php');

    try {
      final res = await http
          .post(
            uri,
            headers: const {
              "Content-Type": "application/x-www-form-urlencoded",
            },
            body: {
              'id_master': idMaster.toString(),
              if (uangDiterima != null)
                'uang_diterima': uangDiterima.toString(),
            },
          )
          .timeout(const Duration(seconds: 20));

      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) return decoded;
      return {'success': false, 'message': 'Respon tidak valid'};
    } catch (_) {
      return {'success': false, 'message': 'Tidak dapat menghubungi server'};
    }
  }
}
