import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SlipGajiPage extends StatefulWidget {
  const SlipGajiPage({super.key});

  @override
  State<SlipGajiPage> createState() => _SlipGajiPageState();
}

class _SlipGajiPageState extends State<SlipGajiPage> {
  final Color biruTua = const Color(0xFF0044FF);
  final Color hijau = const Color(0xFF18BB47);
  final Color tileBg = const Color(0xFFE5F1FC);

  // Generate otomatis 6 bulan terakhir
  late final List<Map<String, dynamic>> slipList;
  int? expandedIndex;

  @override
  void initState() {
    super.initState();
    slipList = List.generate(6, (i) {
      final date =
          DateTime(DateTime.now().year, DateTime.now().month - i, 1);
      return {
        "bulan": DateFormat('MMMM yyyy', 'id_ID').format(date),
        "status": i == 4 ? 'Diproses' : 'Terbayar',
        "nominal": (i < 2) ? 5800000 : 5500000,
        "detail": {
          "Gaji Pokok": 5000000,
          "Tunjangan Transportasi": 200000,
          "Tunjangan Makan": 300000,
          "Tunjangan Kesehatan": 100000,
          "Tunjangan Lain-lain": 50000,
          "Potongan BPJS": -50000,
          "Potongan Pajak": -50000,
        }
      };
    });
    expandedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 65,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: biruTua, size: 28),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Slip Gaji",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined, color: Color(0xFFB0B5C2)),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.help_outline, color: Color(0xFFB0B5C2)),
            onPressed: () {},
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1.3, color: tileBg),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(13, 8, 13, 12),
        itemCount: slipList.length,
        itemBuilder: (context, i) {
          final slip = slipList[i];
          final expanded = expandedIndex == i;
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Colors.white,
                  elevation: expanded ? 3 : 0,
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    decoration: BoxDecoration(
                      color: tileBg,
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: expanded ? biruTua : tileBg,
                        width: expanded ? 2.2 : 1.1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 13),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Row bulan, status, tombol lihat
                        Row(
                          children: [
                            const Icon(Icons.calendar_month_outlined, color: Color(0xFF0250A5), size: 22),
                            const SizedBox(width: 7),
                            Text(
                              slip["bulan"],
                              style: const TextStyle(
                                color: Color(0xFF181D27),
                                fontWeight: FontWeight.w600,
                                fontSize: 16.8,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              decoration: BoxDecoration(
                                color: slip["status"] == "Terbayar" ? hijau : Colors.amber,
                                borderRadius: BorderRadius.circular(19),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 5),
                              child: Text(
                                slip["status"],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.2,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() => expandedIndex = expanded ? null : i);
                              },
                              icon: const Icon(Icons.visibility, size: 17),
                              label: const Text("Lihat", style: TextStyle(fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: biruTua,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 1),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(9),
                                ),
                                minimumSize: const Size(0,34),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Text("Gaji Bersih", style: TextStyle(fontSize: 14.1, color: Colors.black54, fontWeight: FontWeight.w500)),
                            const SizedBox(width: 9),
                            Text(
                              NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                                  .format(slip["nominal"] ?? 0),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 17,
                                color: Color(0xFF181D27),
                              ),
                            ),
                          ],
                        ),
                        // DETAIL INLINE
                        if (expanded)
                          Padding(
                            padding: const EdgeInsets.only(top: 13),
                            child: _GajiDetailBox(
                              bulanTahun: slip["bulan"],
                              detail: slip["detail"] as Map<String, int>,
                              gajiBersih: slip["nominal"],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---- Widget Detail Slip Modern (sama seperti sebelumnya) ----
class _GajiDetailBox extends StatelessWidget {
  final String bulanTahun;
  final Map<String, int> detail;
  final int gajiBersih;

  const _GajiDetailBox({
    required this.bulanTahun,
    required this.detail,
    required this.gajiBersih,
  });

  @override
  Widget build(BuildContext context) {
    const biruTua = Color(0xFF0044FF);
    const judul = TextStyle(
      fontWeight: FontWeight.w700,
      color: biruTua,
      fontSize: 16.8,
    );
    const isi = TextStyle(
      color: Color(0xFF181D27),
      fontWeight: FontWeight.w400,
      fontSize: 14.7,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFF),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: biruTua.withOpacity(.13)),
        boxShadow: [
          BoxShadow(
            color: biruTua.withOpacity(0.07),
            blurRadius: 5,
            offset: Offset(0, 3.2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text("Ringkasan Slip Gaji", style: judul),
              const Spacer(),
              Text(
                bulanTahun,
                style: const TextStyle(color: biruTua, fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 20, color: biruTua),
          const Text("Rincian Pendapatan", style: isi),
          const SizedBox(height: 3),
          ...detail.entries.map((e) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 1.6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        e.key,
                        style: isi.copyWith(
                          color: (e.value < 0)
                              ? Colors.red
                              : isi.color,
                          fontWeight: (e.key.startsWith('Potongan')) ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(
                        locale: 'id_ID',
                        symbol: e.value < 0 ? "- Rp " : "Rp ",
                        decimalDigits: 0,
                      ).format(e.value.abs()),
                      style: isi.copyWith(
                        color: (e.value < 0) ? Colors.red : isi.color,
                        fontWeight: (e.key.startsWith('Potongan')) ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 5),
          const Divider(),
          Row(
            children: [
              Expanded(
                child: Text(
                  "Total Gaji Bersih:",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: biruTua,
                    fontSize: 16.2,
                  ),
                ),
              ),
              Text(
                NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
                    .format(gajiBersih),
                style: const TextStyle(
                  color: biruTua,
                  fontWeight: FontWeight.bold,
                  fontSize: 17.1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// import 'package:flutter/material.dart';

// class SlipGajiPage extends StatelessWidget {
//   const SlipGajiPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     // Warna utama dan pendukung
//     // const biruLangit = Color(0xFF339CFF);
//     const biruTua = Color.fromARGB(255, 0, 68, 255);
//     const hijau = Color.fromARGB(255, 149, 255, 0);
//     const tileBg = Color.fromARGB(255, 229, 241, 252);

//     final data = [
//       {"bulan": "Desember 2025"},
//       {"bulan": "November 2025"},
//       {"bulan": "Oktober 2025"},
//       {"bulan": "September 2025"},
//       {"bulan": "Agustus 2025"},
//     ];

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_rounded, color: biruTua, size: 30),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           "Slip Gaji",
//           style: TextStyle(
//             color: Color.fromARGB(255, 0, 0, 0),
//             fontWeight: FontWeight.bold,
//             fontSize: 28,
//           ),
//         ),
//         centerTitle: true,
//         toolbarHeight: 70,
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1.5),
//           child: Container(color: biruTua, height: 1.5),
//         ),
//       ),
//       body: ListView.builder(
//         padding: const EdgeInsets.fromLTRB(15, 18, 15, 16),
//         itemCount: data.length,
//         itemBuilder: (context, i) => Container(
//           margin: const EdgeInsets.only(bottom: 18),
//           padding: const EdgeInsets.all(15),
//           decoration: BoxDecoration(
//             color: tileBg,
//             borderRadius: BorderRadius.circular(14),
//             boxShadow: [
//               BoxShadow(
//                 color: biruTua.withValues(alpha: 0.03),
//                 blurRadius: 3,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               // Row tanggal dan chip status
//               Row(
//                 children: [
//                   const Icon(
//                     Icons.calendar_month_rounded,
//                     color: biruTua,
//                     size: 25,
//                   ),
//                   const SizedBox(width: 7),
//                   Text(
//                     data[i]["bulan"]!,
//                     style: const TextStyle(
//                       color: Color.fromARGB(255, 0, 0, 0),
//                       fontWeight: FontWeight.bold,
//                       fontSize: 19,
//                     ),
//                   ),
//                   const Spacer(),
//                   Container(
//                     padding: const EdgeInsets.symmetric(
//                       vertical: 5,
//                       horizontal: 18,
//                     ),
//                     decoration: BoxDecoration(
//                       color: hijau,
//                       borderRadius: BorderRadius.circular(18),
//                     ),
//                     child: const Text(
//                       "Terbayar",
//                       style: TextStyle(
//                         color: Colors.white,
//                         fontWeight: FontWeight.bold,
//                         letterSpacing: 0.3,
//                         fontSize: 14.2,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 5),
//               Container(
//                 height: 2,
//                 margin: const EdgeInsets.only(bottom: 8, top: 6),
//                 color: biruTua,
//               ),
//               const Text(
//                 "Gaji Bersih",
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 0, 0, 0),
//                   fontSize: 15.7,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 2),
//               const Text(
//                 "Rp.8.500.000",
//                 style: TextStyle(
//                   color: Color.fromARGB(255, 0, 0, 0),
//                   fontWeight: FontWeight.bold,
//                   fontSize: 22.5,
//                   letterSpacing: 1,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Row(
//                 children: [
//                   const Spacer(),
//                   ElevatedButton.icon(
//                     onPressed: () {
//                       // TODO: buka detail slip gaji
//                     },
//                     icon: const Icon(Icons.visibility_rounded, size: 18),
//                     label: const Text(
//                       "Lihat",
//                       style: TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 15,
//                       ),
//                     ),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: biruTua,
//                       foregroundColor: Colors.white,
//                       padding: const EdgeInsets.symmetric(
//                         horizontal: 21,
//                         vertical: 8,
//                       ),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       elevation: 0,
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
