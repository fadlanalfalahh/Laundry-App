import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'struk.dart';
import '../models/struk.dart';
import '../services/pengambilan.dart';

class PengambilanPage extends StatefulWidget {
  const PengambilanPage({super.key});

  @override
  State<PengambilanPage> createState() => _PengambilanPageState();
}

class _PengambilanPageState extends State<PengambilanPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _rupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final _dfDate = DateFormat('dd MMM yyyy', 'id_ID');
  final _dfDateTime = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  final _searchCtrl = TextEditingController();
  String _query = '';
  DateTime? _selectedDate;

  bool _loadingAction = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _load(String status) async {
    return PengambilanService.listPengambilan(
      status: status,
      date: _selectedDate,
      q: _query.isEmpty ? null : _query,
    );
  }

  int _toInt(dynamic v) => int.tryParse((v ?? '0').toString()) ?? 0;

  int _sisaPembayaran(Map<String, dynamic> it) {
    final total = _toInt(it['total_harga']);
    final uang = _toInt(it['uang_diterima']);
    final kembali = _toInt(it['kembalian']);
    final sisa = total - (uang - kembali);
    return sisa > 0 ? sisa : 0;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final init = _selectedDate ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      helpText: 'Pilih Tanggal Siap Diambil',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (d != null) {
      setState(() => _selectedDate = DateTime(d.year, d.month, d.day));
    }
  }

  Future<void> _confirmPickupLunas(int idMaster, String noTrans) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Pengambilan'),
        content: Text('Tandai transaksi $noTrans sebagai Diambil?'),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );
    if (yes != true) return;

    setState(() => _loadingAction = true);
    final res = await PengambilanService.pickup(idMaster: idMaster);
    setState(() => _loadingAction = false);

    if (res['success'] == true) {
      // === buka Struk ===
      final master = res['data']['master'];
      final details = res['data']['details'];

      final transaksi = StrukModel.fromPengambilan(master, details);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukPage(transaksi: transaksi, noTransaksi: noTrans),
        ),
      );
    } else {
      _toast(res['message'] ?? 'Gagal.');
    }
  }

  Future<void> _pelunasanDanPickup(Map<String, dynamic> it) async {
    final idMaster = _toInt(it['id_master']);
    final noTrans = (it['no_transaksi'] ?? '').toString();
    final sisa = _sisaPembayaran(it);

    final _uangDiterimaController = TextEditingController();

    final allow = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Pelunasan & Ambil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('No: $noTrans'),
            const SizedBox(height: 8),
            Text('Sisa: ${_rupiah.format(sisa)}'),
            const SizedBox(height: 12),
            TextField(
              controller: _uangDiterimaController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Uang Diterima',
                border: OutlineInputBorder(),
                prefix: Text('Rp '),
              ),
              onChanged: (value) {
                final digitsOnly = value.replaceAll(RegExp(r'[^0-9]'), '');

                if (digitsOnly.isEmpty) {
                  _uangDiterimaController.value = const TextEditingValue(
                    text: '',
                    selection: TextSelection.collapsed(offset: 0),
                  );
                  return;
                }

                final angka = int.tryParse(digitsOnly) ?? 0;
                final formatted = NumberFormat.decimalPattern(
                  'id_ID',
                ).format(angka);

                _uangDiterimaController.value = TextEditingValue(
                  text: formatted,
                  selection: TextSelection.collapsed(offset: formatted.length),
                );
              },
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _uangDiterimaController,
              builder: (context, value, _) {
                final uangDiterima =
                    int.tryParse(value.text.replaceAll('.', '')) ?? 0;
                final kembalian = uangDiterima - sisa;

                if (uangDiterima == 0) {
                  return const Text('Masukkan nominal pembayaran.');
                } else if (uangDiterima < sisa) {
                  return Text(
                    'Nominal kurang ${_rupiah.format(sisa - uangDiterima)}',
                    style: const TextStyle(color: Colors.red),
                  );
                } else {
                  return Text(
                    'Kembalian: ${_rupiah.format(kembalian)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            style: TextButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Prosess'),
          ),
        ],
      ),
    );
    if (allow != true) return;

    final uang =
        int.tryParse(_uangDiterimaController.text.replaceAll('.', '')) ?? 0;
    if (uang < sisa) {
      _toast('Nominal kurang dari sisa.');
      return;
    }

    setState(() => _loadingAction = true);
    final res = await PengambilanService.pickup(
      idMaster: idMaster,
      uangDiterima: uang,
    );
    setState(() => _loadingAction = false);

    final ok = res['success'] == true;

    if (ok) {
      final master = res['data']['master'];
      final details = res['data']['details'];

      final transaksi = StrukModel.fromPengambilan(master, details);

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StrukPage(transaksi: transaksi, noTransaksi: noTrans),
        ),
      );

      setState(() {});
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final dateLabel = _selectedDate == null
        ? 'Hari ini'
        : _dfDate.format(_selectedDate!);

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Colors.blue[50],
          appBar: AppBar(
            backgroundColor: Colors.blue,
            centerTitle: true,
            title: const Text(
              'Pengambilan',
              style: TextStyle(color: Colors.white),
            ),
            iconTheme: const IconThemeData(color: Colors.white),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Lunas'),
                Tab(text: 'Belum Lunas'),
              ],
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              indicatorColor: Colors.black38,
            ),
            actions: [
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: Text(
                  dateLabel,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              if (_selectedDate != null)
                IconButton(
                  tooltip: 'Reset ke hari ini',
                  onPressed: () => setState(() => _selectedDate = null),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
            ],
          ),
          body: Column(
            children: [
              // Search
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: 'Cari No. Transaksi / Nama Pelanggan...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                ),
              ),

              // Isi tab
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [_buildList('lunas'), _buildList('belum lunas')],
                ),
              ),
            ],
          ),
        ),

        if (_loadingAction)
          Container(
            color: Colors.black26,
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Widget _buildList(String status) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _load(status),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                Center(child: Text('Belum ada yang siap diambil.')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = items[i];

              final idMaster = _toInt(it['id_master']);
              final noTrans = (it['no_transaksi'] ?? '').toString();
              final nama = (it['nama_pelanggan'] ?? '').toString();
              final siapAt =
                  (it['siap_at'] ?? it['tgl_selesai'] ?? it['created_at'] ?? '')
                      .toString();

              String? subtitle;
              if (siapAt.isNotEmpty) {
                final dt = DateTime.tryParse(siapAt);
                if (dt != null) {
                  final now = DateTime.now();
                  final today = DateTime(now.year, now.month, now.day);
                  final besok = today.add(const Duration(days: 1));
                  final kemarin = today.subtract(const Duration(days: 1));
                  final tglDt = DateTime(dt.year, dt.month, dt.day);

                  if (tglDt == today) {
                    subtitle = 'Siap: Hari ini';
                  } else if (tglDt == besok) {
                    subtitle = 'Siap: Besok';
                  } else if (tglDt == kemarin) {
                    subtitle = 'Siap: Kemarin';
                  } else {
                    subtitle = 'Siap: ${_dfDate.format(dt)}';
                  }
                } else {
                  subtitle = 'Siap: $siapAt';
                }
              }

              final trailing = status == 'lunas'
                  ? IconButton(
                      onPressed: () => _confirmPickupLunas(idMaster, noTrans),
                      icon: const Icon(
                        Icons.shopping_bag,
                        color: Colors.blue,
                        size: 40,
                      ),
                      tooltip: 'Ambil',
                    )
                  : IconButton(
                      onPressed: () => _pelunasanDanPickup(it),
                      icon: const Icon(
                        Icons.payments,
                        color: Colors.green,
                        size: 40,
                      ),
                      tooltip: 'Lunasi & Ambil',
                    );

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No. ${i + 1}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        noTrans,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (status == 'belum lunas')
                        Text(
                          'Sisa: ${_rupiah.format(_sisaPembayaran(it))}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  trailing: trailing,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
