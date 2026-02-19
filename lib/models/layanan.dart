class LayananModel {
  final String id;
  final String nama;
  final int harga;
  final int durasi;
  final bool status;

  LayananModel({
    required this.id,
    required this.nama,
    required this.harga,
    required this.durasi,
    required this.status,
  });

  factory LayananModel.fromJson(Map<String, dynamic> json) {
    return LayananModel(
      id: json['id'].toString(),
      nama: json['nama_layanan'],
      harga: json['harga'] is int ? json['harga'] : int.parse(json['harga']),
      durasi: json['durasi_jam'] is int
          ? json['durasi_jam']
          : int.parse(json['durasi_jam']),
      status: json['status'].toString().toLowerCase() == "kiloan",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nama_layanan': nama,
      'harga': harga.toString(),
      'durasi_jam': durasi.toString(),
      'status': status ? 'kiloan' : 'satuan',
    };
  }

  LayananModel copyWith({
    String? id,
    String? nama,
    int? harga,
    int? durasi,
    bool? status,
  }) {
    return LayananModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      harga: harga ?? this.harga,
      durasi: durasi ?? this.durasi,
      status: status ?? this.status,
    );
  }
}
