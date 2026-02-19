import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/struk.dart';
import '../views/struk.dart';
import '../services/struk.dart';
import '../services/transaksi_hari_ini.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

class TransaksiHariIniPage extends StatefulWidget {
  const TransaksiHariIniPage({super.key});

  @override
  State<TransaksiHariIniPage> createState() => _TransaksiHariIniPageState();
}

class _TransaksiHariIniPageState extends State<TransaksiHariIniPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formatRupiah = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String _role = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRole();
  }

  Future<void> _loadRole() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _role = prefs.getString('role') ?? '';
    });
  }

  Future<List<Map<String, dynamic>>> _loadData(String? status) async {
    return await TransaksiService.getTransaksiHariIni(status: status);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabController.dispose();
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
          'Transaksi Hari Ini',
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
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (val) =>
                  setState(() => _query = val.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Cari No.Transaksi atau Nama Pelanggan...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _query = '');
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                isDense: true,
              ),
            ),
          ),

          // Daftar per tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildList(statusFilter: 'lunas'),
                _buildList(statusFilter: 'belum lunas'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoLeading(int no) {
    return SizedBox(
      width: 44,
      child: Center(
        child: Text(
          'No. $no',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildList({required String statusFilter}) {
    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loadData(statusFilter),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data ?? [];
          final q = _query;
          final filtered = (q.isEmpty)
              ? items
              : items.where((it) {
                  final noTrans = (it['no_transaksi'] ?? '')
                      .toString()
                      .toLowerCase();
                  final nama = (it['nama_pelanggan'] ?? '')
                      .toString()
                      .toLowerCase();
                  return noTrans.contains(q) || nama.contains(q);
                }).toList();

          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                Center(child: Text('Belum ada transaksi.')),
              ],
            );
          }

          if (filtered.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 40),
                Center(child: Text('Tidak ada data yang cocok.')),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final it = filtered[i];

              final noTrans = (it['no_transaksi'] ?? '').toString();
              final nama = (it['nama_pelanggan'] ?? '').toString();
              final total =
                  int.tryParse((it['total_harga'] ?? '0').toString()) ?? 0;
              final uang =
                  int.tryParse((it['uang_diterima'] ?? '0').toString()) ?? 0;
              final kembali =
                  int.tryParse((it['kembalian'] ?? '0').toString()) ?? 0;

              final int sisa = (total - (uang - kembali)) > 0
                  ? (total - (uang - kembali))
                  : 0;

              if (statusFilter.toLowerCase() == 'lunas') {
                // Lunas
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    subtitle: Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final idMaster =
                                int.tryParse(it['id_master'].toString()) ?? 0;

                            final res = await StrukService.getStruk(idMaster);
                            if (res['success'] == true) {
                              final master = res['data']['master'];
                              final details = res['data']['details'];

                              final transaksi = StrukModel.fromPengambilan(
                                master,
                                details,
                              );

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StrukPage(
                                    transaksi: transaksi,
                                    noTransaksi: it['no_transaksi'].toString(),
                                  ),
                                ),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Gagal mengambil struk',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                            size: 40,
                          ),
                          tooltip: 'Lihat Struk',
                        ),
                        if (_role == 'admin')
                          IconButton(
                            onPressed: () async {
                              final idMaster =
                                  int.tryParse(it['id_master'].toString()) ?? 0;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Konfirmasi"),
                                  content: const Text(
                                    "Apakah Anda yakin ingin membatalkan transaksi ini?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Tidak"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Ya"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final res =
                                    await TransaksiService.cancelTransaksi(
                                      idMaster,
                                      _role,
                                    );
                                if (res['success'] == true) {
                                  if (!mounted) return;
                                  tampilkanAlert(
                                    context,
                                    "Transaksi berhasil dibatalkan.",
                                  );
                                  setState(() {});
                                } else {
                                  tampilkanAlert(
                                    context,
                                    res['message'] ??
                                        "Gagal membatalkan transaksi.",
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 40,
                            ),
                            tooltip: 'Batalkan Transaksi',
                          ),
                      ],
                    ),
                  ),
                );
              } else {
                // Belum Lunas
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
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
                            fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 2),
                        Text(
                          'Sisa: ${_formatRupiah.format(sisa)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () async {
                            final idMaster =
                                int.tryParse(it['id_master'].toString()) ?? 0;

                            final res = await StrukService.getStruk(idMaster);
                            if (res['success'] == true) {
                              final master = res['data']['master'];
                              final details = res['data']['details'];

                              final transaksi = StrukModel.fromPengambilan(
                                master,
                                details,
                              );

                              if (!mounted) return;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StrukPage(
                                    transaksi: transaksi,
                                    noTransaksi: it['no_transaksi'].toString(),
                                  ),
                                ),
                              );
                            } else {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    res['message'] ?? 'Gagal mengambil struk',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(
                            Icons.visibility,
                            color: Colors.blue,
                            size: 40,
                          ),
                          tooltip: 'Lihat Struk',
                        ),

                        if (_role == 'admin')
                          IconButton(
                            onPressed: () async {
                              final idMaster =
                                  int.tryParse(it['id_master'].toString()) ?? 0;

                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Konfirmasi"),
                                  content: const Text(
                                    "Apakah Anda yakin ingin membatalkan transaksi ini?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      style: TextButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Tidak"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                      ),
                                      child: const Text("Ya"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                final res =
                                    await TransaksiService.cancelTransaksi(
                                      idMaster,
                                      _role,
                                    );
                                if (res['success'] == true) {
                                  if (!mounted) return;
                                  tampilkanAlert(
                                    context,
                                    "Transaksi berhasil dibatalkan.",
                                  );
                                  setState(() {});
                                } else {
                                  tampilkanAlert(
                                    context,
                                    res['message'] ??
                                        "Gagal membatalkan transaksi.",
                                  );
                                }
                              }
                            },
                            icon: const Icon(
                              Icons.cancel,
                              color: Colors.red,
                              size: 40,
                            ),
                            tooltip: 'Batalkan Transaksi',
                          ),
                      ],
                    ),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
