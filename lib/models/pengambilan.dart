class PengambilanModel {
  final String namaPelanggan;
  final String createdBy;
  final String statusBayar;
  final int totalHarga;
  final int uangDiterima;
  final int kembalian;
  final List<Map<String, dynamic>> layananList;

  PengambilanModel({
    required this.namaPelanggan,
    required this.createdBy,
    required this.statusBayar,
    required this.totalHarga,
    required this.uangDiterima,
    required this.kembalian,
    required this.layananList,
  });

  factory PengambilanModel.fromJson(
    Map<String, dynamic> master,
    List<dynamic> details,
  ) {
    return PengambilanModel(
      namaPelanggan: master['nama_pelanggan'] ?? '',
      createdBy: master['created_by'] ?? '',
      statusBayar: master['status_bayar'] ?? '',
      totalHarga: int.tryParse(master['total_harga'].toString()) ?? 0,
      uangDiterima: int.tryParse(master['uang_diterima'].toString()) ?? 0,
      kembalian: int.tryParse(master['kembalian'].toString()) ?? 0,
      layananList: List<Map<String, dynamic>>.from(details),
    );
  }
}
