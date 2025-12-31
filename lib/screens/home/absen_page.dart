import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:peresenceapp/face_Kamera/clock_in_page.dart';


// Ganti ini dengan the real Place/Location & Photo kalau sudah terisi actual
class AbsenLog {
  final DateTime waktu;
  final String type; // "Clock In" / "Clock Out"
  final String lokasi;
  final String foto;
  AbsenLog({required this.waktu, required this.type, this.lokasi = "-", this.foto = ""});
}

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  State<AbsenPage> createState() => _AbsenPageState();
}

class _AbsenPageState extends State<AbsenPage> {
  late Timer _timer;
  DateTime _now = DateTime.now();

  List<AbsenLog> aktivitasHariIni = [];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _now = DateTime.now();
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Simulasi navigasi & absen:
  void _doAbsen(String jenis) async {
    // TODO: Setelah real, pindah ke halaman selfie/location/foto
    // Simulasi data absen dikirim dari page lain:
    // Setelah selesai proses absen di halaman berikutnya, tambah data di bawah
    final fakeLokasi = "Jl. Contoh, Bandung";
    final fakeFoto = ""; // Could be File.path or network photo url
    setState(() {
      aktivitasHariIni.add(
        AbsenLog(
          waktu: DateTime.now(),
          type: jenis,
          lokasi: fakeLokasi,
          foto: fakeFoto,
        ),
      );
    });
   // Untuk navigasi Clock In
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ClockInOutPage(absenType: 'Clock In'),
  ),
);

// Untuk navigasi Clock Out
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => const ClockInOutPage(absenType: 'Clock Out'),
  ),

);
  }

  @override
  Widget build(BuildContext context) {
    const navy = Color(0xFF1B1E6D);
    const biruMuda = Color(0xFFE8F1FF);
    const cardBg = Color(0xFFF2F3F8);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: navy, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        elevation: 0,
        title: const Text(
          "Absen",
          style: TextStyle(
            color: navy,
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 65,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Jam real time
            Center(
              child: Column(
                children: [
                  const SizedBox(height:6),
                  Text(
                    DateFormat.Hm().format(_now),
                    style: const TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 48,
                      letterSpacing: 2,
                    ),
                  ),
                  Text(
                    DateFormat('EEE, dd MMM yyyy').format(_now),
                    style: const TextStyle(
                      color: navy,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
              ),
            ),
            // Jadwal dan Button
            Container(
              padding: const EdgeInsets.symmetric(vertical: 23, horizontal: 14),
              margin: const EdgeInsets.only(bottom: 22),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    "jadwal: ${DateFormat('dd MMM yyyy').format(_now)}",
                    style: const TextStyle(
                      color: navy,
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    "DayOn",
                    style: TextStyle(
                      color: navy,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _doAbsen('Clock In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text("Clock In"),
                        ),
                      ),
                      const SizedBox(width: 22),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _doAbsen('Clock Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: navy,
                            foregroundColor: Colors.white,
                            textStyle: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                          ),
                          child: const Text("Clock Out"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 5),
            const Text(
              "Daftar Absensi",
              style: TextStyle(
                color: navy,
                fontWeight: FontWeight.bold,
                fontSize: 21,
              ),
            ),
            const SizedBox(height: 5),

            // Aktifitas Hari Ini
            aktivitasHariIni.isEmpty
                ? Padding(
                    padding: const EdgeInsets.only(top: 23),
                    child: Column(
                      children: const [
                        Text(
                          "tidak ada log aktivitas hari ini",
                          style: TextStyle(
                            color: navy,
                            fontWeight: FontWeight.w600,
                            fontSize: 15.5,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          "Aktivasi Clock In/Out anda akan tampil disini",
                          style: TextStyle(
                            color: navy,
                            fontSize: 12.6,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: aktivitasHariIni.length,
                    itemBuilder: (context, i) {
                      final log = aktivitasHariIni[aktivitasHariIni.length -1- i]; // Show newest at top
                      return Card(
                        color: biruMuda,
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${log.type} - ${DateFormat.Hm().format(log.waktu)}",
                                style: const TextStyle(
                                  color: navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "Lokasi: ${log.lokasi}",
                                style: const TextStyle(
                                  color: navy,
                                  fontSize: 13,
                                ),
                              ),
                              if (log.foto.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 5),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(7),
                                    child: Image.network(
                                      log.foto, // untuk network, atau FileImage kalau file lokal
                                      width: 85, height: 85, fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }
}