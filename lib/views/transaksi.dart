import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../services/layanan.dart';
import '../models/layanan.dart';
import '../services/transaksi.dart';
import '../models/transaksi.dart';
import '../models/struk.dart';
import 'struk.dart';

void tampilkanAlert(BuildContext context, String pesan) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.clearSnackBars();
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        pesan,
        textAlign: TextAlign.center,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.black87,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      duration: const Duration(seconds: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}

class TransaksiPage extends StatefulWidget {
  const TransaksiPage({super.key});

  @override
  State<TransaksiPage> createState() => _TransaksiPageState();
}

class _TransaksiPageState extends State<TransaksiPage> {
  String formatRupiah(num number) {
    final format = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return format.format(number);
  }

  final NumberFormat _rupiahFormatter = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  final _namaController = TextEditingController();
  final _nomorController = TextEditingController();
  final _beratController = TextEditingController();
  final _uangDiterimaController = TextEditingController();
  final _catatanController = TextEditingController();

  String? _jenisLayananDipilih;
  String _createdBy = '';
  String? _layananSatuanDipilih;
  LayananModel? _layananTerpilih;

  List<LayananModel> _listLayanan = [];
  List<int> _durasiTersedia = [];
  int? _durasiDipilih;

  bool _isLoadingLayanan = false;
  String? _statusBayar;
  List<Map<String, dynamic>> _layananDipilih = [];

  bool get _bolehSimpan {
    final isLunas = _statusBayar == 'Lunas';
    final uangOk = !isLunas || (uangDiterima >= total.toInt());

    return _namaController.text.isNotEmpty &&
        _layananDipilih.isNotEmpty &&
        _statusBayar != null &&
        uangOk;
  }

  double get total {
    return _layananDipilih.fold(0, (sum, item) {
      final berat = double.tryParse(item['berat'].toString()) ?? 1;
      final harga = item['harga'] as int;
      return sum + (item['jenis'] == 'Kiloan' ? harga * berat : harga);
    });
  }

  int get kembalian {
    final selisih = uangDiterima - total.toInt();
    return selisih < 0 ? 0 : selisih;
  }

  int get uangDiterima {
    final digitsOnly = _uangDiterimaController.text.replaceAll(
      RegExp(r'[^0-9]'),
      '',
    );
    return int.tryParse(digitsOnly) ?? 0;
  }

  void _ambilLayanan(bool isKiloan) async {
    setState(() {
      _isLoadingLayanan = true;
      _layananTerpilih = null;
      _layananSatuanDipilih = null;
      _listLayanan = [];
      _durasiTersedia = [];
    });

    try {
      final status = isKiloan ? 'kiloan' : 'satuan';
      final data = await LayananService.getByStatus(status);

      setState(() {
        _listLayanan = data;
      });
    } catch (e) {
      _tampilkanError('Gagal mengambil data layanan');
    } finally {
      setState(() {
        _isLoadingLayanan = false;
      });
    }
  }

  void _loadDurasi(String namaLayanan) async {
    final durasiList = await LayananService.getDurasiDariNama(namaLayanan);

    setState(() {
      _durasiTersedia = durasiList;
      _durasiDipilih = null;
    });
  }

  String _normalisasiNomorPelanggan(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('0')) {
      return digits.substring(1);
    }

    if (digits.startsWith('62')) {
      return digits.substring(2);
    }

    return digits;
  }

  Future<void> _pilihKontakPelanggan() async {
    try {
      final allowed = await FlutterContacts.requestPermission(readonly: true);
      if (!mounted) return;

      if (!allowed) {
        tampilkanAlert(context, 'Izin kontak ditolak');
        return;
      }

      final contact = await FlutterContacts.openExternalPick();
      if (!mounted || contact == null) return;

      final nomorRaw = contact.phones
          .map((phone) => phone.number.trim())
          .firstWhere((number) => number.isNotEmpty, orElse: () => '');

      if (nomorRaw.isEmpty) {
        tampilkanAlert(context, 'Kontak tidak memiliki nomor telepon');
        return;
      }

      final nomor = _normalisasiNomorPelanggan(nomorRaw);
      if (nomor.isEmpty) {
        tampilkanAlert(context, 'Nomor kontak tidak valid');
        return;
      }

      final namaKontak = contact.displayName.trim();
      if (namaKontak.isNotEmpty) {
        _namaController.text = namaKontak;
      }
      _nomorController.text = nomor;
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      tampilkanAlert(context, 'Gagal mengambil kontak');
    }
  }

  void _simpanTransaksi() async {
    final nama = _namaController.text.trim();
    final nomorLokal = _normalisasiNomorPelanggan(_nomorController.text);
    final nomor = nomorLokal.isEmpty ? '' : '+62$nomorLokal';

    if (nama.isEmpty ||
        _layananDipilih.isEmpty ||
        _statusBayar == null ||
        (_statusBayar == 'Lunas' && _uangDiterimaController.text.isEmpty)) {
      tampilkanAlert(context, 'Lengkapi semua data!');
      return;
    }

    if (_statusBayar == 'Lunas' && uangDiterima < total.toInt()) {
      tampilkanAlert(
        context,
        'Uang diterima kurang dari Grand Total. Transaksi ditolak.',
      );
      return;
    }

    final transaksi = TransaksiModel(
      namaPelanggan: nama,
      nomorPelanggan: nomor,
      jenisLayanan: '',
      beratLayanan: '',
      durasiLayanan: 0,
      statusBayar: _statusBayar!,
      uangDiterima: uangDiterima,
      kembalian: _statusBayar == 'Lunas' ? kembalian : 0,
      totalHarga: total.toInt(),
      createdBy: _createdBy,
      catatan: _catatanController.text,
      layananList: _layananDipilih,
    );

    try {
      final result = await TransaksiService.tambahTransaksi(transaksi.toJson());
      debugPrint('RESULT RAW: $result');
      result.forEach((k, v) => debugPrint(' - $k => ${v.runtimeType} : $v'));

      if (result['success'] == true) {
        final String idMasterStr = result['id_master']?.toString() ?? '';
        final String noTransaksiStr = result['no_transaksi']?.toString() ?? '';

        final transaksiDenganId = TransaksiModel(
          id: idMasterStr,
          namaPelanggan: transaksi.namaPelanggan,
          nomorPelanggan: transaksi.nomorPelanggan,
          jenisLayanan: transaksi.layananList.map((e) => e['jenis']).join(', '),
          beratLayanan: transaksi.beratLayanan,
          durasiLayanan: transaksi.durasiLayanan,
          statusBayar: transaksi.statusBayar,
          uangDiterima: transaksi.uangDiterima,
          kembalian: transaksi.kembalian,
          totalHarga: transaksi.totalHarga,
          createdBy: transaksi.createdBy,
          layananList: transaksi.layananList,
        );

        _namaController.clear();
        _nomorController.clear();
        _beratController.clear();
        _uangDiterimaController.clear();
        setState(() {
          _jenisLayananDipilih = null;
          _layananTerpilih = null;
          _layananSatuanDipilih = null;
          _statusBayar = null;
          _durasiDipilih = null;
          _durasiTersedia = [];
          _listLayanan = [];
        });

        if (!mounted) return;
        FocusScope.of(context).unfocus();

        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;

        debugPrint('NAV (root) -> Struk: $noTransaksiStr');
        final data = result['data'] ?? {};
        final master = data['master'] != null
            ? Map<String, dynamic>.from(data['master'])
            : <String, dynamic>{};
        final details = data['details'] != null
            ? List<Map<String, dynamic>>.from(data['details'])
            : <Map<String, dynamic>>[];

        await Navigator.of(context, rootNavigator: true).pushReplacement(
          MaterialPageRoute(
            builder: (_) => StrukPage(
              transaksi: StrukModel.fromTransaksi(master, details),
              noTransaksi: noTransaksiStr,
            ),
          ),
        );
        return;
      } else {
        _tampilkanError(result['message']);
      }
    } catch (e) {
      tampilkanAlert(context, 'Gagal menyimpan transaksi. Silahkan coba lagi.');
    }
  }

  void _tampilkanError(String pesan) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pop();
        });

        return AlertDialog(content: Text(pesan, textAlign: TextAlign.center));
      },
    );
  }

  void _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _createdBy = prefs.getString('nama_user') ?? '';
    });
  }

  String _toTitleCase(String input) {
    return input
        .split(RegExp(r'\s+'))
        .map(
          (w) => w.isEmpty
              ? ''
              : '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
        )
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
    _namaController.addListener(() {
      final text = _namaController.text;
      final formatted = _toTitleCase(text);
      if (text != formatted) {
        _namaController.value = _namaController.value.copyWith(
          text: formatted,
          selection: TextSelection.collapsed(offset: formatted.length),
        );
      }
    });
  }

  @override
  void dispose() {
    _namaController.dispose();
    _nomorController.dispose();
    _beratController.dispose();
    _uangDiterimaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      appBar: AppBar(
        backgroundColor: Colors.blue,
        centerTitle: true,
        title: const Text(
          'Tambah Transaksi',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTextField(_namaController, 'Nama Pelanggan'),
                const SizedBox(height: 12),
                _buildTextField(_nomorController, 'Nomor Pelanggan'),
                const SizedBox(height: 12),
                _buildJenisLayananDropdown(),
                const SizedBox(height: 12),
                if (_jenisLayananDipilih == 'Kiloan') ..._buildLayananKiloan(),
                if (_jenisLayananDipilih == 'Satuan') ..._buildLayananSatuan(),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if ((_jenisLayananDipilih == 'Kiloan' &&
                            _layananTerpilih != null &&
                            _beratController.text.isNotEmpty) ||
                        (_jenisLayananDipilih == 'Satuan' &&
                            _layananTerpilih != null &&
                            _durasiDipilih != null)) {
                      final layananBaru = {
                        'jenis': _jenisLayananDipilih,
                        'nama': _layananTerpilih?.nama ?? '',
                        'berat': _jenisLayananDipilih == 'Kiloan'
                            ? _beratController.text
                            : '1',
                        'durasi':
                            _durasiDipilih ?? (_layananTerpilih?.durasi ?? 0),
                        'harga': _layananTerpilih?.harga ?? 0,
                      };

                      setState(() {
                        _layananDipilih.add(layananBaru);
                        _layananTerpilih = null;
                        _layananSatuanDipilih = null;
                        _beratController.clear();
                        _durasiDipilih = null;
                        _jenisLayananDipilih = null;
                      });
                    } else {
                      tampilkanAlert(context, 'Lengkapi data layanan!');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Tambah Layanan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (_layananDipilih.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Daftar Layanan Dipilih:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      ..._layananDipilih.map(
                        (layanan) => Card(
                          child: ListTile(
                            title: Text(
                              '${layanan['jenis']} - ${layanan['nama']}',
                            ),
                            subtitle: Text(
                              layanan['jenis'] == 'Kiloan'
                                  ? 'Berat: ${layanan['berat']} kg | Durasi: ' +
                                        ((layanan['durasi'] ?? 0) >= 24
                                            ? '${(layanan['durasi'] / 24).round()} Hari'
                                            : '${layanan['durasi']} Jam')
                                  : 'Durasi: ' +
                                        ((layanan['durasi'] ?? 0) >= 24
                                            ? '${(layanan['durasi'] / 24).round()} Hari'
                                            : '${layanan['durasi']} Jam'),
                            ),
                            trailing: Text(
                              (() {
                                final bool isKiloan =
                                    layanan['jenis'] == 'Kiloan';
                                final int harga = (layanan['harga'] as int);
                                final double berat = (layanan['berat'] is num)
                                    ? (layanan['berat'] as num).toDouble()
                                    : double.tryParse(
                                            layanan['berat'].toString(),
                                          ) ??
                                          1.0;
                                final int lineTotal = isKiloan
                                    ? (harga * berat).round()
                                    : harga;
                                return formatRupiah(lineTotal);
                              })(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            leading: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  _layananDipilih.remove(layanan);
                                });
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 12),
                _buildStatusPembayaranDropdown(),
                if (_statusBayar == 'Lunas') ...[
                  const SizedBox(height: 12),
                  TextField(
                    controller: _uangDiterimaController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Uang Diterima',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                    onChanged: (value) {
                      final digitsOnly = value.replaceAll(
                        RegExp(r'[^0-9]'),
                        '',
                      );
                      final angka = int.tryParse(digitsOnly) ?? 0;
                      final formatted = NumberFormat.decimalPattern(
                        'id_ID',
                      ).format(angka);

                      setState(() {
                        _uangDiterimaController.value = TextEditingValue(
                          text: formatted,
                          selection: TextSelection.collapsed(
                            offset: formatted.length,
                          ),
                        );
                      });
                    },
                  ),
                ],
                const SizedBox(height: 12),
                TextField(
                  controller: _catatanController,
                  decoration: const InputDecoration(
                    labelText: 'Catatan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_statusBayar == 'Lunas') ...[
                      const SizedBox(height: 8),
                      Text(
                        'Bayar: ${formatRupiah(uangDiterima)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kembali: ${formatRupiah(kembalian < 0 ? 0 : kembalian)}',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Grand Total: ${formatRupiah(total)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _bolehSimpan ? _simpanTransaksi : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text(
                    'Simpan Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    final isNomor = label == 'Nomor Pelanggan';
    final isNama = label == 'Nama Pelanggan';

    return TextField(
      textCapitalization: isNama
          ? TextCapitalization.words
          : TextCapitalization.none,
      controller: controller,
      keyboardType: isNomor ? TextInputType.number : TextInputType.text,
      inputFormatters: isNomor ? [FilteringTextInputFormatter.digitsOnly] : [],
      onChanged: (_) {
        if (isNama) setState(() {});
      },
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixText: isNomor ? '+62 ' : null,
        suffixIcon: isNomor
            ? IconButton(
                onPressed: _pilihKontakPelanggan,
                tooltip: 'Pilih dari kontak HP',
                icon: const Icon(Icons.contacts_outlined),
              )
            : null,
      ),
    );
  }

  Widget _buildJenisLayananDropdown() {
    return DropdownButtonFormField<String>(
      value: _jenisLayananDipilih,
      decoration: const InputDecoration(
        labelText: 'Jenis Layanan',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih Jenis Layanan'),
      items: const [
        DropdownMenuItem(value: 'Kiloan', child: Text('Kiloan')),
        DropdownMenuItem(value: 'Satuan', child: Text('Satuan')),
      ],
      onChanged: (value) {
        setState(() {
          _jenisLayananDipilih = value;
          _layananTerpilih = null;
          _layananSatuanDipilih = null;
          _beratController.clear();
          _durasiDipilih = null;
          _durasiTersedia = [];
          _statusBayar = null;
          _uangDiterimaController.clear();
        });

        if (value == 'Kiloan') {
          _ambilLayanan(true);
        } else if (value == 'Satuan') {
          _ambilLayanan(false);
        }
      },
    );
  }

  List<Widget> _buildLayananKiloan() {
    return [
      _isLoadingLayanan
          ? const Center(child: CircularProgressIndicator())
          : DropdownButtonFormField<LayananModel>(
              value: _layananTerpilih,
              decoration: const InputDecoration(
                labelText: 'Layanan Kiloan',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Pilih Layanan Kiloan'),
              items: _listLayanan
                  .map(
                    (layanan) => DropdownMenuItem(
                      value: layanan,
                      child: Text(layanan.nama),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _layananTerpilih = value;
                });
              },
            ),

      const SizedBox(height: 12),

      if (_layananTerpilih != null)
        TextField(
          controller: _beratController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: const InputDecoration(
            labelText: 'Berat (kg)',
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => setState(() {}),
        ),
    ];
  }

  List<Widget> _buildLayananSatuan() {
    final namaList = _listLayanan.map((e) => e.nama).toSet().toList();

    return [
      DropdownButtonFormField<String>(
        value: namaList.contains(_layananSatuanDipilih)
            ? _layananSatuanDipilih
            : null,
        decoration: const InputDecoration(
          labelText: 'Layanan Satuan',
          border: OutlineInputBorder(),
        ),
        hint: const Text('Pilih Layanan Satuan'),
        items: namaList
            .map((nama) => DropdownMenuItem(value: nama, child: Text(nama)))
            .toList(),
        onChanged: (value) {
          setState(() => _layananSatuanDipilih = value);
          if (value != null) _loadDurasi(value);
        },
      ),
      const SizedBox(height: 12),

      if (_durasiTersedia.isNotEmpty)
        DropdownButtonFormField<int>(
          value: _durasiDipilih,
          decoration: const InputDecoration(
            labelText: 'Durasi Layanan',
            border: OutlineInputBorder(),
          ),
          hint: const Text('Pilih Durasi Layanan'),
          items: _durasiTersedia
              .map(
                (d) => DropdownMenuItem(
                  value: d,
                  child: Text(d >= 24 ? '${(d / 24).round()} Hari' : '$d Jam'),
                ),
              )
              .toList(),
          onChanged: (value) async {
            setState(() {
              _durasiDipilih = value;
            });

            if (_layananSatuanDipilih != null && value != null) {
              final harga = await LayananService.getHargaDariLayananDanDurasi(
                _layananSatuanDipilih!,
                value,
              );

              if (harga != null) {
                setState(() {
                  _layananTerpilih = LayananModel(
                    id: '',
                    nama: _layananSatuanDipilih!,
                    harga: harga,
                    durasi: value,
                    status: false,
                  );
                });
              }
            }
          },
        ),
    ];
  }

  Widget _buildStatusPembayaranDropdown() {
    return DropdownButtonFormField<String>(
      value: _statusBayar,
      decoration: const InputDecoration(
        labelText: 'Status Pembayaran',
        border: OutlineInputBorder(),
      ),
      hint: const Text('Pilih Status Pembayaran'),
      items: const [
        DropdownMenuItem(value: 'Lunas', child: Text('Lunas')),
        DropdownMenuItem(value: 'Belum Lunas', child: Text('Belum Lunas')),
      ],
      onChanged: (value) => setState(() => _statusBayar = value),
      validator: (value) =>
          value == null ? 'Status Pembayaran wajib dipilih' : null,
    );
  }
}
