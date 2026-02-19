import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/layanan.dart';
import '../config.dart';

class LayananService {
  static const String baseUrl = AppConfig.daftarLayanan;

  static Future<List<LayananModel>> getAll() async {
    final response = await http.get(Uri.parse('$baseUrl/view.php'));

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => LayananModel.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data layanan');
    }
  }

  static Future<List<LayananModel>> getByStatus(String status) async {
    final response = await http.get(
      Uri.parse('$baseUrl/view.php?status=$status'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => LayananModel.fromJson(json)).toList();
    } else {
      throw Exception('Gagal memuat data layanan dengan status $status');
    }
  }

  static Future<Map<String, dynamic>> tambah(LayananModel layanan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/add.php'),
      body: layanan.toJson(),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> update(LayananModel layanan) async {
    final response = await http.post(
      Uri.parse('$baseUrl/update.php'),
      body: layanan.toJson(),
    );
    return json.decode(response.body);
  }

  static Future<Map<String, dynamic>> delete(String id) async {
    final response = await http.post(
      Uri.parse('$baseUrl/delete.php'),
      body: {'id': id},
    );
    return json.decode(response.body);
  }

  static Future<int?> getHargaDariLayananDanDurasi(
    String nama,
    int durasi,
  ) async {
    final url = Uri.parse(
      '$baseUrl/get_harga_dari_durasi.php?nama=$nama&durasi=$durasi',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      if (jsonBody['success']) {
        return int.tryParse(jsonBody['harga'].toString());
      }
    }

    return null;
  }

  static Future<List<int>> getDurasiDariNama(String nama) async {
    final url = Uri.parse('$baseUrl/get_durasi_dari_layanan.php?nama=$nama');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final jsonBody = json.decode(response.body);
      if (jsonBody['success'] == true) {
        return List<int>.from(jsonBody['durasi']);
      }
    }
    return [];
  }
}
