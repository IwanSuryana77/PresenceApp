import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:peresenceapp/screens/home/home_screen.dart';

const skyBlue = Color(0xFF53B6FF);

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage> {
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
  ];

  List<String> lampiran = [];

  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles();
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

      // ================= APP BAR =================
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(left: 6, top: 8, right: 6),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
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
              lampiran: lampiran,
              onUploadLampiran: pickFile,
              onDeleteLampiran: (i) => setState(() => lampiran.removeAt(i)),
              onSubmit: () {
                if (_formKey.currentState!.validate()) {
                  setState(() {
                    dummyRiwayat.insert(
                      0,
                      "${tglLemburC.text} • Shift: $shiftValue • ${kompensasiC.text}",
                    );
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Pengajuan berhasil")),
                  );
                }
              },
            ),

            const SizedBox(height: 28),

            GestureDetector(
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                  (_) => false,
                );
              },
              child: const Text(
                "Kembali ke Home",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: skyBlue,
                  fontSize: 20,
                ),
              ),
            ),

            const SizedBox(height: 12),

            ...dummyRiwayat.map(
              (s) => Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(Icons.history, color: skyBlue),
                  title: Text(s),
                  trailing:
                      const Icon(Icons.check_circle, color: Colors.green),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
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
  final List<String> lampiran;
  final VoidCallback onUploadLampiran;
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
    required this.lampiran,
    required this.onUploadLampiran,
    required this.onDeleteLampiran,
    required this.onSubmit,
  });

  @override 
   Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Form fields go here
        ],
      ),
    );
  }
}