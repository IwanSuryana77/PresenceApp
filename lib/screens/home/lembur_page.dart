import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:peresenceapp/screens/home/home_screen.dart';

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

  List<String> lampiran = [];

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      setState(() {
        lampiran.add(result.files.single.name);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),

      // ================= APPBAR =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 6, top: 8, right: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    // ⬅️ LANGSUNG KEMBALI KE HOME (UI TIDAK DIUBAH)
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: skyBlue,
                    size: 28,
                  ),
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
                const SizedBox(width: 54),
              ],
            ),
          ),
        ),
      ),

      // ================= BODY =================
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
                onUploadLampiran: pickFile,
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
                        content: Text(
                          "Pengajuan berhasil disubmit! (dummy, belum ke DB)",
                        ),
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

              ...dummyRiwayat.map(
                (s) => Card(
                  elevation: 1.5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  child: ListTile(
                    leading: const Icon(Icons.history_edu, color: skyBlue),
                    title: Text(
                      s,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF323A4B),
                      ),
                    ),
                    trailing: Icon(
                      Icons.check_circle_rounded,
                      color: Colors.green[400],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 22),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== FORM WIDGET ==================
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tanggal Lembur
          TextFormField(
            controller: tglLemburC,
            decoration: const InputDecoration(
              labelText: 'Tanggal Lembur',
              prefixIcon: Icon(Icons.date_range),
              border: OutlineInputBorder(),
            ),
            readOnly: true,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2023),
                lastDate: DateTime(2100),
                initialDate: DateTime.now(),
              );
              if (picked != null) {
                tglLemburC.text =
                    "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
              }
            },
            validator: (v) =>
                v == null || v.isEmpty ? 'Tanggal wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          // Shift
          DropdownButtonFormField<String>(
            value: shiftValue,
            decoration: const InputDecoration(
              labelText: 'Shift',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'Pagi', child: Text('Pagi')),
              DropdownMenuItem(value: 'Siang', child: Text('Siang')),
              DropdownMenuItem(value: 'Malam', child: Text('Malam')),
            ],
            onChanged: shiftOnChanged,
            validator: (v) =>
                v == null || v.isEmpty ? 'Shift wajib dipilih' : null,
          ),
          const SizedBox(height: 12),
          // Sebelum Durasi
          TextFormField(
            controller: sebelumDurasiC,
            decoration: const InputDecoration(
              labelText: 'Durasi Lembur Sebelum Shift',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Sebelum Istirahat
          TextFormField(
            controller: sebelumIstirahatC,
            decoration: const InputDecoration(
              labelText: 'Durasi Istirahat Sebelum Shift',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Sesudah Durasi
          TextFormField(
            controller: sesudahDurasiC,
            decoration: const InputDecoration(
              labelText: 'Durasi Lembur Sesudah Shift',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Sesudah Istirahat
          TextFormField(
            controller: sesudahIstirahatC,
            decoration: const InputDecoration(
              labelText: 'Durasi Istirahat Sesudah Shift',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          // Kompensasi
          TextFormField(
            controller: kompensasiC,
            decoration: const InputDecoration(
              labelText: 'Kompensasi',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.isEmpty ? 'Kompensasi wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          // Alasan
          TextFormField(
            controller: alasanC,
            decoration: const InputDecoration(
              labelText: 'Alasan',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          // Lampiran
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: onUploadLampiran,
                icon: const Icon(Icons.attach_file),
                label: const Text('Tambahkan Lampiran'),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  children: lampiran
                      .asMap()
                      .entries
                      .map(
                        (entry) => Chip(
                          label: Text(entry.value),
                          onDeleted: () => onDeleteLampiran(entry.key),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Submit
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubmit,
              child: const Text('Kirim'),
            ),
          ),
        ],
      ),
    );
  }
}
