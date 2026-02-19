import 'dart:convert';

class TransaksiModel {
  final String? id;
  final String namaPelanggan;
  final String nomorPelanggan;
  final String jenisLayanan;
  final String beratLayanan;
  final int durasiLayanan;
  final String statusBayar;
  final int uangDiterima;
  final int kembalian;
  final int totalHarga;
  final String createdBy;
  final String? catatan;
  final List<Map<String, dynamic>> layananList;

  TransaksiModel({
    this.id,
    required this.namaPelanggan,
    required this.nomorPelanggan,
    required this.jenisLayanan,
    required this.beratLayanan,
    required this.durasiLayanan,
    required this.statusBayar,
    required this.uangDiterima,
    required this.kembalian,
    required this.totalHarga,
    required this.createdBy,
    this.catatan,
    this.layananList = const [],
  });

  Map<String, dynamic> toJson() {
    final data = {
      'nama_pelanggan': namaPelanggan,
      'nomor_pelanggan': nomorPelanggan,
      'status_bayar': statusBayar.toLowerCase(),
      'uang_diterima': uangDiterima.toString(),
      'kembalian': kembalian.toString(),
      'total_harga': totalHarga.toString(),
      'created_by': createdBy,
      'catatan': catatan ?? '',
      'layanan_list': jsonEncode(layananList),
    };

    if (id != null && id!.isNotEmpty) {
      data['id'] = id!;
    }

    return data;
  }
}
