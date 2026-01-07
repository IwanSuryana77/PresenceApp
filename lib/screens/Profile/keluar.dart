import 'package:flutter/material.dart';

class KeluarPage extends StatefulWidget {
  const KeluarPage({super.key});

  @override
  State<KeluarPage> createState() => _KeluarPageState();
}

class _KeluarPageState extends State<KeluarPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Keluar Akun"),
        backgroundColor: Colors.blueAccent,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon Perhatian
            const Icon(
              Icons.warning,
              size: 100,
              color: Colors.orange,
            ),
            const SizedBox(height: 20),

            // Pesan Konfirmasi
            const Text(
              "Apakah Anda yakin ingin keluar?",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            Text(
              "Anda akan keluar dari akun ini dan perlu login kembali untuk mengakses aplikasi",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Pilihan Keluar
            Column(
              children: [
                // Keluar Akun
                _buildLogoutOption(
                  icon: Icons.logout,
                  title: "Keluar Akun",
                  subtitle: "Hanya logout dari aplikasi ini",
                  onTap: () {
                    _showLogoutConfirmation(context, type: "logout");
                  },
                ),
                const SizedBox(height: 16),

                // Keluar dari Semua Perangkat
                _buildLogoutOption(
                  icon: Icons.devices,
                  title: "Keluar dari Semua Perangkat",
                  subtitle: "Logout dari semua perangkat yang terhubung",
                  onTap: () {
                    _showLogoutConfirmation(context, type: "all_devices");
                  },
                ),
                const SizedBox(height: 16),

                // Hapus Akun
                _buildLogoutOption(
                  icon: Icons.delete_forever,
                  title: "Hapus Akun Permanen",
                  subtitle: "Hapus semua data akun Anda",
                  isDanger: true,
                  onTap: () {
                    _showDeleteAccountConfirmation(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 40),

            // Tombol Batal
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: const Text(
                  "Batal",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDanger ? Colors.red.shade100 : Colors.grey.shade200,
          width: 1,
        ),
      ),
      color: isDanger ? Colors.red.shade50 : Colors.white,
      child: ListTile(
        leading: Icon(
          icon,
          color: isDanger ? Colors.red : Colors.blueAccent,
          size: 28,
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDanger ? Colors.red : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: isDanger ? Colors.red.shade600 : Colors.grey.shade600,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context, {required String type}) {
    String message = type == "logout"
        ? "Anda akan keluar dari akun ini. Login kembali untuk mengakses aplikasi."
        : "Anda akan keluar dari semua perangkat yang terhubung ke akun ini. Anda perlu login ulang di setiap perangkat.";

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          type == "logout" ? "Keluar Akun" : "Keluar dari Semua Perangkat",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              type == "logout" ? Icons.logout : Icons.devices,
              size: 50,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performLogout(context, type: type);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: type == "logout" ? Colors.blueAccent : Colors.orange,
            ),
            child: Text(type == "logout" ? "Keluar" : "Keluar Semua"),
          ),
        ],
      ),
    );
  }

  void _performLogout(BuildContext context, {required String type}) {
    // Simulasi proses logout
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          type == "logout"
              ? "Berhasil logout dari akun"
              : "Berhasil logout dari semua perangkat",
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Delay sebelum kembali ke login
    Future.delayed(const Duration(seconds: 2), () {
      // Navigasi ke halaman login
      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
    });
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Hapus Akun Permanen"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.warning_amber,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "PERINGATAN!",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              "Tindakan ini akan menghapus semua data akun Anda secara permanen, termasuk:",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• Riwayat absensi"),
                  const Text("• Data gaji dan tunjangan"),
                  const Text("• Pengajuan izin dan lembur"),
                  const Text("• Semua informasi pribadi"),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              decoration: const InputDecoration(
                labelText: "Ketik 'DELETE' untuk konfirmasi",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showFinalDeleteConfirmation(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Hapus Akun"),
          ),
        ],
      ),
    );
  }

  void _showFinalDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi Terakhir"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              "Apakah Anda benar-benar yakin?",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              "Tindakan ini TIDAK DAPAT DIBATALKAN! Semua data akan dihapus selamanya.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Tidak, Batal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performAccountDeletion(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Ya, Hapus Permanen"),
          ),
        ],
      ),
    );
  }

  void _performAccountDeletion(BuildContext context) {
    // Simulasi proses penghapusan akun
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Permintaan penghapusan akun telah dikirim"),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );

    // Delay sebelum kembali ke register
    Future.delayed(const Duration(seconds: 3), () {
      // Navigasi ke halaman register/login
      Navigator.pushNamedAndRemoveUntil(context, '/register', (route) => false);
    });
  }
}