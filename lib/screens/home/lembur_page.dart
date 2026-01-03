import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// ===== COLORS =====
const primaryBlue = Color(0xFF1F2A7A);
const softGrey = Color(0xFFF1F1F1);

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers/variables
  DateTime? tanggalLembur;
  String shift = '';
  String sebelumLembur = '';
  String sebelumIstirahat = '';
  String sesudahLembur = '';
  String sesudahIstirahat = '';
  String kompensasi = '';
  String alasan = '';
  List<PlatformFile> attachments = [];
  bool loading = false;

  // PICK DATE
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: tanggalLembur ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => tanggalLembur = picked);
    }
  }

  // PICK FILES
  Future<void> _pickFiles() async {
    if (attachments.length >= 5) return;
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: ['pdf', 'jpg', 'png', 'xlsx', 'docx'],
      type: FileType.custom,
      withData: true,
    );
    if (result != null) {
      setState(() {
        final filesToAdd = result.files.take(5 - attachments.length).toList();
        attachments.addAll(filesToAdd);
      });
    }
  }

  // UPLOAD TO FIREBASE
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    // 1. Upload files to Firebase Storage
    List<String> uploadedFiles = [];
    for (final file in attachments) {
      final ref = FirebaseStorage.instance.ref().child(
        'lembur/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();
      uploadedFiles.add(url);
    }

    // 2. Save form data to Firestore
    await FirebaseFirestore.instance.collection('lembur').add({
      'tanggal_lembur': tanggalLembur?.toIso8601String(),
      'shift': shift,
      'sebelum_lembur': sebelumLembur,
      'sebelum_istirahat': sebelumIstirahat,
      'sesudah_lembur': sesudahLembur,
      'sesudah_istirahat': sesudahIstirahat,
      'kompensasi': kompensasi,
      'alasan': alasan,
      'lampiran_urls': uploadedFiles,
      'created_at': FieldValue.serverTimestamp(),
    });

    setState(() {
      loading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan lembur berhasil dikirim!')),
    );
    Navigator.pop(context); // Balik ke home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () => Navigator.pop(context),
                      child: CircleAvatar(
                        backgroundColor: const Color.fromARGB(
                          255,
                          255,
                          255,
                          255,
                        ).withOpacity(0.1),
                        child: Icon(Icons.arrow_back, color: primaryBlue),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Pengajuan Lembur",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // From
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      sectionTitle("Jadwal lembur"),
                      // Tanggal lembur
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: GestureDetector(
                          onTap: _pickDate,
                          child: AbsorbPointer(
                            child: TextFormField(
                              decoration: InputDecoration(
                                labelText: "Tanggal lembur *",
                                suffixIcon: const Icon(Icons.calendar_today),
                                border: const UnderlineInputBorder(),
                              ),
                              validator: (_) =>
                                  tanggalLembur == null ? "Wajib diisi" : null,
                              controller: TextEditingController(
                                text: tanggalLembur == null
                                    ? ""
                                    : "${tanggalLembur!.day.toString().padLeft(2, '0')}-${tanggalLembur!.month.toString().padLeft(2, '0')}-${tanggalLembur!.year}",
                              ),
                              readOnly: true,
                            ),
                          ),
                        ),
                      ),
                      // Shift
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DropdownButtonFormField<String>(
                          value: shift.isEmpty ? null : shift,
                          items: ['Pagi', 'Siang', 'Malam']
                              .map(
                                (e) =>
                                    DropdownMenuItem(value: e, child: Text(e)),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => shift = v ?? ''),
                          decoration: const InputDecoration(
                            labelText: "Shift *",
                            suffixIcon: Icon(Icons.keyboard_arrow_down),
                            border: UnderlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Wajib diisi" : null,
                        ),
                      ),

                      sectionTitle("Lembur sebelum shift"),
                      greyCard([
                        inputField(
                          "Durasi lembur",
                          (v) => setState(() => sebelumLembur = v),
                        ),
                        inputField(
                          "Durasi istirahat lembur",
                          (v) => setState(() => sebelumIstirahat = v),
                          helper: "opsional",
                        ),
                      ]),

                      sectionTitle("Lembur setelah shift"),
                      greyCard([
                        inputField(
                          "Durasi lembur",
                          (v) => setState(() => sesudahLembur = v),
                        ),
                        inputField(
                          "Durasi istirahat lembur",
                          (v) => setState(() => sesudahIstirahat = v),
                          helper: "opsional",
                        ),
                      ]),

                      sectionTitle("Informasi tambahan"),
                      greyCard([
                        inputField(
                          "Kompensasi *",
                          (v) => setState(() => kompensasi = v),
                          isRequired: true,
                        ),
                        inputField("Alasan", (v) => setState(() => alasan = v)),
                        const SizedBox(height: 10),
                        const Text(
                          "Lampiran",
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            InkWell(onTap: _pickFiles, child: uploadBox()),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Anda dapat mengunggah maksimal 5 file\nPDF, JPG, PNG, XLSX, DOCX (maks 10MB)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  if (attachments.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    ...attachments.map(
                                      (a) => Text(
                                        a.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ]),

                      const SizedBox(height: 30),

                      //button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          onPressed: loading ? null : _submit,
                          child: loading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  "Kirim",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===== WIDGET KECIL =====
  static Widget sectionTitle(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
    ),
  );

  static Widget inputField(
    String label,
    void Function(String) onChanged, {
    String? helper,
    bool isRequired = false,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        helperText: helper,
        border: const UnderlineInputBorder(),
      ),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? "Wajib diisi" : null
          : null,
      onChanged: onChanged,
    ),
  );

  static Widget greyCard(List<Widget> children) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: softGrey,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(children: children),
  );

  static Widget uploadBox() => Container(
    width: 64,
    height: 64,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: primaryBlue,
        width: 1.5,
        style: BorderStyle.solid,
      ),
    ),
    child: const Icon(Icons.add, color: primaryBlue, size: 32),
  );
}
