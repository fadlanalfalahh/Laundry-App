import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/layanan.dart';
import '../services/layanan.dart';

void tampilkanAlert(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
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

class DaftarCucianPage extends StatefulWidget {
  const DaftarCucianPage({super.key});

  @override
  State<DaftarCucianPage> createState() => _DaftarCucianPageState();
}

class _DaftarCucianPageState extends State<DaftarCucianPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LayananModel> _paket = [];
  List<LayananModel> _satuan = [];
  int? _selectedPaketIndex;
  int? _selectedSatuanIndex;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedPaketIndex = null;
          _selectedSatuanIndex = null;
        });
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final allData = await LayananService.getAll();
      setState(() {
        _paket = allData.where((item) => item.status == true).toList();
        _satuan = allData.where((item) => item.status == false).toList();
      });
    } catch (e) {
      print('Gagal memuat data: $e');
    }
  }

  void _tambahData(bool isPaket) {
    final controllerNama = TextEditingController();
    controllerNama.addListener(() {
      final text = controllerNama.text;
      final kapital = text
          .split(' ')
          .map(
            (e) => e.isEmpty
                ? ''
                : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
          )
          .join(' ');

      if (text != kapital) {
        controllerNama.value = controllerNama.value.copyWith(
          text: kapital,
          selection: TextSelection.collapsed(offset: kapital.length),
        );
      }
    });
    final controllerHarga = TextEditingController();
    String? selectedDurasi;
    final durasiOptions = List.generate(
      7,
      (i) => {'label': '${i + 1} Hari', 'value': 24 * (i + 1)},
    )..insert(0, {'label': '12 Jam', 'value': 12});

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    controllerHarga.addListener(() {
      final text = controllerHarga.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final number = int.parse(text);
        final newText = formatter.format(number);
        controllerHarga.value = controllerHarga.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Tambah ${isPaket ? 'Cucian Kiloan' : 'Cucian Satuan'}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerNama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Layanan'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedDurasi,
                decoration: const InputDecoration(labelText: 'Durasi Layanan'),
                items: durasiOptions.map((durasi) {
                  return DropdownMenuItem<String>(
                    value: durasi['value'].toString(),
                    child: Text(durasi['label'].toString()),
                  );
                }).toList(),
                onChanged: (val) => selectedDurasi = val,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controllerHarga,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPaket ? 'Harga per-Kg' : 'Harga Satuan',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String kapitalisasiKata(String input) {
                  return input
                      .split(' ')
                      .map((word) {
                        if (word.isEmpty) return '';
                        return word[0].toUpperCase() +
                            word.substring(1).toLowerCase();
                      })
                      .join(' ');
                }

                final nama = kapitalisasiKata(controllerNama.text.trim());
                final harga =
                    int.tryParse(
                      controllerHarga.text.replaceAll('.', '').trim(),
                    ) ??
                    0;
                final durasi = int.tryParse(selectedDurasi ?? '') ?? 24;

                if (nama.isEmpty || harga <= 0) {
                  tampilkanAlert(context, "Nama dan harga wajib diisi.");
                  return;
                }

                final layanan = LayananModel(
                  id: '',
                  nama: nama,
                  harga: harga,
                  durasi: durasi,
                  status: isPaket,
                );

                final result = await LayananService.tambah(layanan);
                if (result['success'] == true) {
                  await _loadData();
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  tampilkanAlert(context, "Layanan berhasil ditambahkan.");
                } else {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 100));
                  tampilkanAlert(context, result['message']);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _editData(LayananModel item, bool isPaket) {
    final controllerNama = TextEditingController(text: item.nama);
    controllerNama.addListener(() {
      final text = controllerNama.text;
      final kapital = text
          .split(' ')
          .map(
            (e) => e.isEmpty
                ? ''
                : '${e[0].toUpperCase()}${e.substring(1).toLowerCase()}',
          )
          .join(' ');

      if (text != kapital) {
        controllerNama.value = controllerNama.value.copyWith(
          text: kapital,
          selection: TextSelection.collapsed(offset: kapital.length),
        );
      }
    });
    final controllerHarga = TextEditingController(
      text: NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      ).format(item.harga),
    );
    String selectedDurasi = item.durasi.toString();

    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: '',
      decimalDigits: 0,
    );
    controllerHarga.addListener(() {
      final text = controllerHarga.text.replaceAll(RegExp(r'[^0-9]'), '');
      if (text.isNotEmpty) {
        final number = int.parse(text);
        final newText = formatter.format(number);
        controllerHarga.value = controllerHarga.value.copyWith(
          text: newText,
          selection: TextSelection.collapsed(offset: newText.length),
        );
      }
    });

    final durasiOptions = List.generate(
      7,
      (i) => {'label': '${i + 1} Hari', 'value': 24 * (i + 1)},
    )..insert(0, {'label': '12 Jam', 'value': 12});

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Layanan'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controllerNama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Layanan'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: selectedDurasi,
                decoration: const InputDecoration(labelText: 'Durasi Layanan'),
                items: durasiOptions.map((durasi) {
                  return DropdownMenuItem<String>(
                    value: durasi['value'].toString(),
                    child: Text(durasi['label'].toString()),
                  );
                }).toList(),
                onChanged: (val) => selectedDurasi = val!,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controllerHarga,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: isPaket ? 'Harga per-Kg' : 'Harga Satuan',
                  prefixText: 'Rp ',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                String kapitalisasiKata(String input) {
                  return input
                      .split(' ')
                      .map((word) {
                        if (word.isEmpty) return '';
                        return word[0].toUpperCase() +
                            word.substring(1).toLowerCase();
                      })
                      .join(' ');
                }

                final nama = kapitalisasiKata(controllerNama.text.trim());
                final harga =
                    int.tryParse(
                      controllerHarga.text.replaceAll('.', '').trim(),
                    ) ??
                    0;
                final durasi = int.tryParse(selectedDurasi) ?? 24;

                if (nama.isEmpty || harga <= 0) return;

                final updated = item.copyWith(
                  nama: nama,
                  harga: harga,
                  durasi: durasi,
                );

                final result = await LayananService.update(updated);
                if (result['success'] == true) {
                  await _loadData();
                  setState(() {
                    isPaket
                        ? _selectedPaketIndex = null
                        : _selectedSatuanIndex = null;
                  });
                  Navigator.pop(context);
                  tampilkanAlert(context, "Layanan berhasil diperbarui.");
                } else {
                  Navigator.pop(context);
                  tampilkanAlert(context, result['message']);
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _hapusData(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Yakin ingin menghapus layanan ini?'),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Ya', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await LayananService.delete(id);
      await _loadData();
      setState(() {
        _selectedPaketIndex = null;
        _selectedSatuanIndex = null;
      });
      tampilkanAlert(context, "Layanan berhasil dihapus.");
    }
  }

  String _formatDurasiText(int durasiJam) {
    final hari = durasiJam ~/ 24;
    final jam = durasiJam % 24;

    String teks = '';
    if (hari > 0) teks += '$hari Hari';
    if (jam > 0) teks += '${teks.isNotEmpty ? ' ' : ''}$jam Jam';
    if (teks.isEmpty) teks = '0 Jam';
    return teks;
  }

  String _formatRupiahInt(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  Widget _buildSatuanGrouped(List<LayananModel> data) {
    if (data.isEmpty) return const Center(child: Text('Belum ada data.'));

    final Map<int, List<LayananModel>> groups = {};
    for (final item in data) {
      groups.putIfAbsent(item.durasi, () => []).add(item);
    }

    final sortedKeys = groups.keys.toList()..sort();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sortedKeys.length,
      itemBuilder: (context, idx) {
        final durasi = sortedKeys[idx];
        final items = groups[durasi]!;
        final titleText = 'Durasi: ${_formatDurasiText(durasi)}';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 1.5,
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              collapsedShape: const RoundedRectangleBorder(
                side: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              title: Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              children: items.map((item) {
                final hargaText = _formatRupiahInt(item.harga);
                return ListTile(
                  title: Text(item.nama),
                  subtitle: Text('Harga: Rp $hargaText'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Edit',
                        icon: const Icon(Icons.edit, color: Colors.orange),
                        onPressed: () => _editData(item, false),
                      ),
                      IconButton(
                        tooltip: 'Hapus',
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _hapusData(item.id),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildList(List<LayananModel> data, bool isPaket) {
    final selectedIndex = isPaket ? _selectedPaketIndex : _selectedSatuanIndex;

    if (data.isEmpty) return const Center(child: Text('Belum ada data.'));

    return ListView.builder(
      itemCount: data.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = data[index];
        final hari = item.durasi ~/ 24;
        final jam = item.durasi % 24;

        String durasiText = '';
        if (hari > 0) durasiText += '$hari Hari';
        if (jam > 0)
          durasiText += '${durasiText.isNotEmpty ? ' ' : ''}$jam Jam';
        if (durasiText.isEmpty) durasiText = '0 Jam';

        final hargaText = item.harga.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]}.',
        );

        return GestureDetector(
          onTap: () {
            setState(() {
              if (isPaket) {
                _selectedPaketIndex = _selectedPaketIndex == index
                    ? null
                    : index;
              } else {
                _selectedSatuanIndex = _selectedSatuanIndex == index
                    ? null
                    : index;
              }
            });
          },
          child: Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              title: Text(item.nama),
              subtitle: Text('Durasi: $durasiText'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${isPaket ? "Harga per-kg " : ""}Rp $hargaText',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (selectedIndex == index) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.orange),
                      onPressed: () => _editData(item, isPaket),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _hapusData(item.id),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        dividerTheme: const DividerThemeData(thickness: 0, space: 0),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'Daftar Layanan',
            style: TextStyle(color: Colors.white),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          backgroundColor: Colors.blue,
          centerTitle: true,
          bottom: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Cucian Kiloan'),
              Tab(text: 'Cucian Satuan'),
            ],
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.black38,
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildList(_paket, true), _buildSatuanGrouped(_satuan)],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _tambahData(_tabController.index == 0),
          backgroundColor: Colors.blue,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text('Tambah', style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
