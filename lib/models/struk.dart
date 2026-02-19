class StrukModel {
  final String namaPelanggan;
  final String createdBy;
  final String statusBayar;
  final int totalHarga;
  final int uangDiterima;
  final int kembalian;
  final String? catatan;
  final List<Map<String, dynamic>> layananList;

  StrukModel({
    required this.namaPelanggan,
    required this.createdBy,
    required this.statusBayar,
    required this.totalHarga,
    required this.uangDiterima,
    required this.kembalian,
    this.catatan,
    required this.layananList,
  });

  factory StrukModel.fromTransaksi(
    Map<String, dynamic> master,
    dynamic details,
  ) {
    return StrukModel(
      namaPelanggan: master['nama_pelanggan'] ?? '',
      createdBy: master['created_by'] ?? '',
      statusBayar: master['status_bayar'] ?? '',
      totalHarga: int.tryParse(master['total_harga']?.toString() ?? '0') ?? 0,
      uangDiterima:
          int.tryParse(master['uang_diterima']?.toString() ?? '0') ?? 0,
      kembalian: int.tryParse(master['kembalian']?.toString() ?? '0') ?? 0,
      catatan: master['catatan'],
      layananList: (details is List)
          ? details
                .where((e) => e != null && e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : [],
    );
  }

  factory StrukModel.fromPengambilan(
    Map<String, dynamic> master,
    List<dynamic>? details,
  ) {
    return StrukModel(
      namaPelanggan: master['nama_pelanggan'] ?? '',
      createdBy: master['created_by'] ?? '',
      statusBayar: master['status_bayar'] ?? '',
      totalHarga: int.tryParse(master['total_harga'].toString()) ?? 0,
      uangDiterima: int.tryParse(master['uang_diterima'].toString()) ?? 0,
      kembalian: int.tryParse(master['kembalian'].toString()) ?? 0,
      catatan: master['catatan'],
      layananList: (details != null)
          ? details
                .where((e) => e is Map)
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList()
          : [],
    );
  }
}
