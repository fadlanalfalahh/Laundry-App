import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/user.dart';

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

class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  List<UserModel> _users = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final data = await UserService.getAll();
    if (!mounted) return;
    setState(() {
      _users = data;
      _loading = false;
    });
  }

  void _tambahUser() {
    _showFormDialog();
  }

  void _editUser(UserModel user) {
    _showFormDialog(user: user);
  }

  void _showFormDialog({UserModel? user}) {
    final controllerNama = TextEditingController(text: user?.namaUser ?? '');
    final controllerUsername = TextEditingController(
      text: user?.username ?? '',
    );
    final controllerPassword = TextEditingController();
    String role = user?.role ?? 'kasir';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(user == null ? "Tambah User" : "Edit User"),
          content: SizedBox(
            width: MediaQuery.of(dialogContext).size.width * 0.85,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controllerNama,
                  decoration: const InputDecoration(labelText: "Nama User"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: role,
                  decoration: const InputDecoration(labelText: "Role"),
                  items: const [
                    DropdownMenuItem(value: "admin", child: Text("Admin")),
                    DropdownMenuItem(value: "kasir", child: Text("Kasir")),
                  ],
                  onChanged: (val) => role = val!,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controllerUsername,
                  decoration: const InputDecoration(labelText: "Username"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controllerPassword,
                  decoration: const InputDecoration(
                    labelText: "Password (hanya isi jika mau ganti)",
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final nama = controllerNama.text.trim();
                final uname = controllerUsername.text.trim();
                final pass = controllerPassword.text.trim();

                if (nama.isEmpty || uname.isEmpty) {
                  tampilkanAlert(context, "Nama dan username wajib diisi");
                  return;
                }

                Map<String, dynamic> result;
                if (user == null) {
                  result = await UserService.create(nama, role, uname, pass);
                } else {
                  result = await UserService.update(
                    user.id,
                    nama,
                    role,
                    uname,
                    pass,
                  );
                }

                if (!mounted || !dialogContext.mounted) return;
                Navigator.pop(dialogContext);
                if (result['success'] == true) {
                  await _loadData();
                  if (!mounted) return;
                  tampilkanAlert(context, result['message']);
                } else {
                  tampilkanAlert(context, result['message'] ?? "Gagal");
                }
              },
              child: const Text("Simpan"),
            ),
          ],
        );
      },
    );
  }

  void _hapusUser(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: const Text("Yakin ingin menghapus user ini?"),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Ya, Hapus"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final result = await UserService.delete(id);
      if (result['success'] == true) {
        await _loadData();
        if (!mounted) return;
        tampilkanAlert(context, result['message']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar User', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
          ? const Center(child: Text("Belum ada user"))
          : ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, i) {
                final user = _users[i];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: ListTile(
                    title: Text(user.namaUser),
                    subtitle: Text("${user.username} • ${user.role}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.orange),
                          onPressed: () => _editUser(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _hapusUser(user.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _tambahUser,
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }
}
