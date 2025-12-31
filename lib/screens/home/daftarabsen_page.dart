import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; 

class DaftarAbsenPage extends StatelessWidget {
  final List<DateTime> absensi;

  /// Contoh: kirim data absensi saat buat page
  const DaftarAbsenPage({
    super.key,
    required this.absensi,
  });

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1B1E6D);
    const surface = Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: navy),
        title: const Text(
          'Daftar Absen',
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white,
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Riwayat Absen Hari Ini",
                style: TextStyle(
                  color: navy,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: absensi.isEmpty
                    ? const Center(
                        child: Text(
                          "Belum ada data absen hari ini.",
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w500,
                            fontSize: 14.5,
                          ),
                        ),
                      )
                    : ListView.separated(
                        itemCount: absensi.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 18, color: Color(0xFFE5E7F1)),
                        itemBuilder: (context, i) {
                          final tgl = absensi[i];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: navy.withValues(alpha: 0.13),
                              child: const Icon(Icons.login, color: navy),
                            ),
                            title: const Text(
                              "Absen Masuk",
                              style: TextStyle(
                                  color: navy, fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              DateFormat('dd MMM yyyy • HH:mm:ss').format(tgl),
                              style: TextStyle(
                                color: navy.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}