import 'package:flutter/material.dart';

class SlipGajiPage extends StatelessWidget {
  const SlipGajiPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Warna utama dan pendukung
    // const biruLangit = Color(0xFF339CFF);
    const biruTua = Color.fromARGB(255, 0, 68, 255);
    const hijau = Color.fromARGB(255, 149, 255, 0);
    const tileBg = Color.fromARGB(255, 229, 241, 252);

    final data = [
      {"bulan": "Desember 2025"},
      {"bulan": "November 2025"},
      {"bulan": "Oktober 2025"},
      {"bulan": "September 2025"},
      {"bulan": "Agustus 2025"},
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: biruTua, size: 30),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Slip Gaji",
          style: TextStyle(
            color: Color.fromARGB(255, 0, 0, 0),
            fontWeight: FontWeight.bold,
            fontSize: 28,
          ),
        ),
        centerTitle: true,
        toolbarHeight: 70,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: biruTua, height: 1.5),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
        itemCount: data.length,
        itemBuilder: (context, i) => Container(
          margin: const EdgeInsets.only(bottom: 18),
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: tileBg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: biruTua.withValues(alpha: 0.03),
                blurRadius: 3,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row tanggal dan chip status
              Row(
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: biruTua,
                    size: 25,
                  ),
                  const SizedBox(width: 7),
                  Text(
                    data[i]["bulan"]!,
                    style: const TextStyle(
                      color: Color.fromARGB(255, 0, 0, 0),
                      fontWeight: FontWeight.bold,
                      fontSize: 19,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 5,
                      horizontal: 18,
                    ),
                    decoration: BoxDecoration(
                      color: hijau,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      "Terbayar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                        fontSize: 14.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 8, top: 6),
                color: biruTua,
              ),
              const Text(
                "Gaji Bersih",
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontSize: 15.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                "Rp.8.500.000",
                style: TextStyle(
                  color: Color.fromARGB(255, 0, 0, 0),
                  fontWeight: FontWeight.bold,
                  fontSize: 22.5,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: buka detail slip gaji
                    },
                    icon: const Icon(Icons.visibility_rounded, size: 18),
                    label: const Text(
                      "Lihat",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: biruTua,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 21,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
