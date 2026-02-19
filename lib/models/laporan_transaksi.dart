class LaporanDetail {
  final String namaLayanan;

  LaporanDetail({required this.namaLayanan});

  factory LaporanDetail.fromJson(Map<String, dynamic> json) {
    return LaporanDetail(namaLayanan: json['nama_layanan'] ?? '');
  }
}

class LaporanModel {
  final String noTransaksi;
  final String namaPelanggan;
  final String nomorPelanggan;
  final int totalHarga;
  final String statusBayar;
  final String createdBy;
  final String jenisLayanan;
  final String createdAt;
  final List<LaporanDetail> detail;

  LaporanModel({
    required this.noTransaksi,
    required this.namaPelanggan,
    required this.nomorPelanggan,
    required this.totalHarga,
    required this.statusBayar,
    required this.createdBy,
    required this.jenisLayanan,
    required this.createdAt,
    required this.detail,
  });

  factory LaporanModel.fromJson(Map<String, dynamic> json) {
    return LaporanModel(
      noTransaksi: json['no_transaksi'],
      namaPelanggan: json['nama_pelanggan'],
      nomorPelanggan: json['nomor_pelanggan'],
      totalHarga: int.tryParse(json['total_harga'].toString()) ?? 0,
      statusBayar: json['status_bayar'],
      createdBy: json['created_by'],
      jenisLayanan: json['jenis_layanan'],
      createdAt: json['created_at'] ?? '', // <-- mapping baru
      detail: (json['detail'] as List<dynamic>)
          .map((e) => LaporanDetail.fromJson(e))
          .toList(),
    );
  }
}
