import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/laporan_transaksi.dart';
import '../config.dart';

class LaporanService {
  static const String baseUrl = AppConfig.transaksi;

  static Future<List<LaporanModel>> getLaporan({
    String? tglAwal,
    String? tglAkhir,
    String? query,
  }) async {
    final params = <String, String>{};
    if (tglAwal != null) params['tgl_awal'] = tglAwal;
    if (tglAkhir != null) params['tgl_akhir'] = tglAkhir;
    if (query != null && query.isNotEmpty) params['q'] = query;

    final url = Uri.parse(
      "$baseUrl/get_laporan.php",
    ).replace(queryParameters: params);

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['success'] == true) {
        final List list = data['data'];
        return list.map((e) => LaporanModel.fromJson(e)).toList();
      }
    }
    return [];
  }
}
