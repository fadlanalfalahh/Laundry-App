import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login.dart';
import 'layanan.dart';
import 'transaksi.dart';
import 'transaksi_hari_ini.dart';
import 'pengambilan.dart';
import 'laporan_transaksi.dart';
import 'user.dart';

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

class DashboardPage extends StatelessWidget {
  final String nama;
  final String role;
  const DashboardPage({super.key, required this.nama, required this.role});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('is_logged_in');
    await prefs.remove('nama_user');
    await prefs.remove('role');
    await prefs.remove('username');

    tampilkanAlert(context, "Berhasil logout");

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  static List<String> _labelsForRole(String roleRaw) {
    final role = roleRaw.toLowerCase();
    const all = [
      'Tambah Transaksi',
      'Daftar Layanan',
      'Transaksi Hari Ini',
      'Pengambilan',
      'Laporan Transaksi',
      'User',
    ];
    const staffOnly = [
      'Tambah Transaksi',
      'Transaksi Hari Ini',
      'Pengambilan',
      'Daftar Layanan',
    ];

    if (role == 'admin' || role == 'superadmin') return all;
    if (role == 'kasir' || role == 'staff') return staffOnly;

    return staffOnly;
  }

  static IconData _iconFor(String label) {
    switch (label) {
      case 'Tambah Transaksi':
        return Icons.add_circle;
      case 'Daftar Layanan':
        return Icons.list_alt;
      case 'Transaksi Hari Ini':
        return Icons.receipt_long;
      case 'Pengambilan':
        return Icons.inventory_2;
      case 'Laporan Transaksi':
        return Icons.assignment_sharp;
      case 'User':
        return Icons.person;
      default:
        return Icons.apps;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 16),
            color: Colors.blue,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Halo, ${nama.split(' ').first} 👋",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Selamat datang di Aplikasi Laundry",
                      style: TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                  ],
                ),

                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Logout',
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Menu Grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: _labelsForRole(role)
                    .map(
                      (label) =>
                          _buildMenuCard(context, _iconFor(label), label),
                    )
                    .toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildMenuCard(
    BuildContext context,
    IconData icon,
    String label,
  ) {
    return GestureDetector(
      onTap: () {
        if (label == 'Tambah Transaksi') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransaksiPage()),
          );
        }
        if (label == 'Daftar Layanan') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DaftarCucianPage()),
          );
        }
        if (label == 'Transaksi Hari Ini') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TransaksiHariIniPage()),
          );
        }
        if (label == 'Pengambilan') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PengambilanPage()),
          );
        }
        if (label == 'Laporan Transaksi') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LaporanTransaksiPage()),
          );
        }
        if (label == 'User') {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UserPage()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 36, color: Colors.blue),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
