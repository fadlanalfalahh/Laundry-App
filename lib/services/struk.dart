import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class StrukService {
  static const String baseUrl = AppConfig.transaksi;

  static Future<Map<String, dynamic>> getStruk(int idMaster) async {
    final uri = Uri.parse('$baseUrl/get_struk.php?id_master=$idMaster');

    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) {
        return {"success": false, "message": "Gagal koneksi ke server"};
      }
      return json.decode(res.body);
    } catch (e) {
      return {"success": false, "message": e.toString()};
    }
  }
}
