import 'package:flutter/material.dart';

// Sky blue color
const skyBlue = Color(0xFF53B6FF);

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburModernPageState();
}

class _LemburModernPageState extends State<LemburPage> {
  final _formKey = GlobalKey<FormState>();

  final tglLemburC = TextEditingController();
  String? shiftValue;
  final sebelumDurasiC = TextEditingController();
  final sebelumIstirahatC = TextEditingController();
  final sesudahDurasiC = TextEditingController();
  final sesudahIstirahatC = TextEditingController();
  final kompensasiC = TextEditingController();
  final alasanC = TextEditingController();

  List<String> dummyRiwayat = [
    "2024-06-12 • Shift: Siang • Kompensasi: Uang makan",
    "2024-06-18 • Shift: Malam • Kompensasi: Transport",
    "2024-06-19 • Shift: Pagi • Kompensasi: Uang lembur",
  ];

  // Placeholder untuk file lampiran
  List<String> lampiran = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 6, top: 8, right: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.arrow_back_rounded, color: skyBlue, size: 28),
                ),
                const Expanded(
                  child: Center(
                    child: Text(
                      "Pengajuan Lembur",
                      style: TextStyle(
                        color: skyBlue,
                        fontWeight: FontWeight.w700,
                        fontSize: 24,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 54), // supaya judul tetap center
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LemburForm(
                formKey: _formKey,
                tglLemburC: tglLemburC,
                shiftValue: shiftValue,
                shiftOnChanged: (v) => setState(() => shiftValue = v),
                sebelumDurasiC: sebelumDurasiC,
                sebelumIstirahatC: sebelumIstirahatC,
                sesudahDurasiC: sesudahDurasiC,
                sesudahIstirahatC: sesudahIstirahatC,
                kompensasiC: kompensasiC,
                alasanC: alasanC,
                onUploadLampiran: () {
                  // Tambahkan fungsi file picker di sini
                  setState(() {
                    lampiran.add('lampiran_${lampiran.length + 1}.pdf');
                  });
                },
                lampiran: lampiran,
                onDeleteLampiran: (i) {
                  setState(() {
                    lampiran.removeAt(i);
                  });
                },
                onSubmit: () {
                  if (_formKey.currentState!.validate()) {
                    setState(() {
                      dummyRiwayat.insert(
                        0,
                        "${tglLemburC.text} • Shift: $shiftValue • Kompensasi: ${kompensasiC.text}",
                      );
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pengajuan berhasil disubmit! (dummy, belum ke DB)"),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              const Text(
                "Riwayat Pengajuan",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: skyBlue,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 10),
              ...dummyRiwayat.map((s) => Card(
                elevation: 1.5,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                margin: const EdgeInsets.symmetric(vertical: 5),
                child: ListTile(
                  leading: Icon(Icons.history_edu, color: skyBlue),
                  title: Text(
                    s,
                    style: const TextStyle(fontSize: 15, color: Color(0xFF323A4B)),
                  ),
                  trailing: Icon(Icons.check_circle_rounded, color: Colors.green[400]),
                ),
              )),
              const SizedBox(height: 22),
              // SPACE untuk koneksi ke database firebase
              // TODO: Implementasi pengiriman data & pengambilan riwayat dari Firebase
            ],
          ),
        ),
      ),
    );
  }
}

// === Form Widget Modern ===
class _LemburForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController tglLemburC;
  final String? shiftValue;
  final ValueChanged<String?> shiftOnChanged;
  final TextEditingController sebelumDurasiC;
  final TextEditingController sebelumIstirahatC;
  final TextEditingController sesudahDurasiC;
  final TextEditingController sesudahIstirahatC;
  final TextEditingController kompensasiC;
  final TextEditingController alasanC;
  final VoidCallback onUploadLampiran;
  final List<String> lampiran;
  final ValueChanged<int> onDeleteLampiran;
  final VoidCallback onSubmit;

  const _LemburForm({
    required this.formKey,
    required this.tglLemburC,
    required this.shiftValue,
    required this.shiftOnChanged,
    required this.sebelumDurasiC,
    required this.sebelumIstirahatC,
    required this.sesudahDurasiC,
    required this.sesudahIstirahatC,
    required this.kompensasiC,
    required this.alasanC,
    required this.onUploadLampiran,
    required this.lampiran,
    required this.onDeleteLampiran,
    required this.onSubmit,
  });

  Widget _formSectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 9),
    child: Text(
      text,
      style: const TextStyle(
        color: skyBlue,
        fontWeight: FontWeight.w600,
        fontSize: 17,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18.0);

    return Form(
      key: formKey,
      child: Column(
        children: [
          _formSectionTitle("Jadwal lembur"),
          Material(
            elevation: 1,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              child: Column(
                children: [
                  TextFormField(
                    controller: tglLemburC,
                    decoration: InputDecoration(
                      labelText: 'Tanggal lembur *',
                      prefixIcon: const Icon(Icons.date_range, color: skyBlue,),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Tanggal wajib diisi" : null,
                    readOnly: true,
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                        initialDate: DateTime.now(),
                      );
                      if (picked != null) {
                        tglLemburC.text = "${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}";
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: "Shift *",
                      border: const OutlineInputBorder(),
                    ),
                    value: shiftValue,
                    items: [
                      "Pagi",
                      "Siang",
                      "Malam",
                    ].map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(e),
                    )).toList(),
                    onChanged: shiftOnChanged,
                    validator: (v) => v == null ? "Shift wajib dipilih" : null,
                  ),
                ],
              ),
            ),
          ),

          _formSectionTitle("Lembur sebelum shift"),
          Material(
            elevation: 1,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              child: Column(
                children: [
                  TextFormField(
                    controller: sebelumDurasiC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Durasi lembur",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sebelumIstirahatC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Durasi istirahat lembur",
                      border: OutlineInputBorder(),
                      helperText: "opsional",
                    ),
                  ),
                ],
              ),
            ),
          ),

          _formSectionTitle("Lembur setelah shift"),
          Material(
            elevation: 1,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              child: Column(
                children: [
                  TextFormField(
                    controller: sesudahDurasiC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Durasi lembur",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: sesudahIstirahatC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Durasi istirahat lembur",
                      border: OutlineInputBorder(),
                      helperText: "opsional",
                    ),
                  ),
                ],
              ),
            ),
          ),

          _formSectionTitle("Informasi tambahan"),
          Material(
            elevation: 1,
            borderRadius: borderRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              child: Column(
                children: [
                  TextFormField(
                    controller: kompensasiC,
                    decoration: const InputDecoration(
                      labelText: "Kompensasi *",
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => v!.isEmpty ? "Kompensasi wajib diisi" : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: alasanC,
                    decoration: const InputDecoration(
                      labelText: "Alasan",
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Lampiran",
                      style: TextStyle(color: Colors.blueGrey[600], fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: onUploadLampiran,
                        child: DottedUploadBox(),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Wrap(
                          spacing: 5,
                          children: lampiran.map((f) {
                            final i = lampiran.indexOf(f);
                            return Chip(
                              label: Text(f, style: const TextStyle(fontSize: 12)),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => onDeleteLampiran(i),
                              backgroundColor: skyBlue.withOpacity(0.15),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.only(top: 4),
                    child: Text(
                      "Maksimal 5 file. Format: PDF, JPG, PNG, XLSX, DOCX, DLL. Maks 10MB",
                      style: TextStyle(fontSize: 11),
                    ),
                  )
                ],
              ),
            ),
          ),

          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: skyBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text(
                "Kirim",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==== Tombol Upload Lampiran Kotak Putus-putus ====
class DottedUploadBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66, height: 66,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: skyBlue, width: 1.7, style: BorderStyle.solid),
        // Simulasikan border dashed/putus
      ),
      child: Center(
        child: Icon(Icons.add, size: 34, color: skyBlue),
      ),
    );
  }
}