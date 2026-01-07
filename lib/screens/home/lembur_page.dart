import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

// ===== COLORS =====
const primaryBlue = Color(0xFF2196F3);   // Bright blue
const boxWhite = Colors.white;

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
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: primaryBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
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
      backgroundColor: Colors.grey[100],
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
                        backgroundColor: const Color.fromARGB(255, 249, 252, 255).withOpacity(0.09),
                        child: Icon(Icons.arrow_back, color: const Color.fromARGB(255, 0, 0, 0), size: 26),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      "Pengajuan Lembur",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // FORM
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
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
                                labelStyle: TextStyle(color: Colors.black),
                                suffixIcon: Icon(Icons.calendar_today, color: primaryBlue),
                                filled: true,
                                fillColor: boxWhite,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              ),
                              validator: (_) =>
                                  tanggalLembur == null ? "Wajib diisi" : null,
                              controller: TextEditingController(
                                text: tanggalLembur == null
                                    ? ""
                                    : "${tanggalLembur!.day.toString().padLeft(2, '0')}-${tanggalLembur!.month.toString().padLeft(2, '0')}-${tanggalLembur!.year}",
                              ),
                              readOnly: true,
                              style: TextStyle(color: Colors.black),
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
                                    DropdownMenuItem(value: e, child: Text(e, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black))),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => shift = v ?? ''),
                          decoration: InputDecoration(
                            labelText: "Shift *",
                            labelStyle: TextStyle(color: Colors.black),
                            suffixIcon: Icon(Icons.keyboard_arrow_down, color: const Color.fromARGB(255, 255, 255, 255)),
                            filled: true,
                            fillColor: boxWhite,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? "Wajib diisi" : null,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),

                      sectionTitle("Lembur sebelum shift"),
                      whiteCard([
                        inputField(
                          "Durasi lembur",
                          (v) => setState(() => sebelumLembur = v),
                          icon: Icons.timelapse,
                        ),
                        inputField(
                          "Durasi istirahat lembur",
                          (v) => setState(() => sebelumIstirahat = v),
                          helper: "opsional",
                          icon: Icons.self_improvement_rounded,
                        ),
                      ]),

                      sectionTitle("Lembur setelah shift"),
                      whiteCard([
                        inputField(
                          "Durasi lembur",
                          (v) => setState(() => sesudahLembur = v),
                          icon: Icons.timelapse,
                        ),
                        inputField(
                          "Durasi istirahat lembur",
                          (v) => setState(() => sesudahIstirahat = v),
                          helper: "opsional",
                          icon: Icons.self_improvement_rounded,
                        ),
                      ]),

                      sectionTitle("Informasi tambahan"),
                      whiteCard([
                        inputField(
                          "Kompensasi ",
                          (v) => setState(() => kompensasi = v),
                          isRequired: true,
                          icon: Icons.monetization_on_rounded,
                        ),
                        inputField("Alasan", (v) => setState(() => alasan = v), icon: Icons.sticky_note_2_outlined),
                        const SizedBox(height: 12),
                        const Text(
                          "Lampiran",
                          style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
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
                                    "Upload maksimal 5 file:\nPDF, JPG, PNG, XLSX, DOCX (max 10MB)",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.black54,
                                    ),
                                  ),
                                  if (attachments.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      children: attachments.map(
                                        (a) => Chip(
                                          label: Text(a.name, style: TextStyle(fontSize: 12, color: Colors.black)),
                                          backgroundColor: boxWhite,
                                          deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                                          onDeleted: () {
                                            setState(() => attachments.remove(a));
                                          },
                                        ),
                                      ).toList(),
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
                            backgroundColor: const Color.fromARGB(255, 0, 46, 250),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
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
                      const SizedBox(height: 24),
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
    padding: const EdgeInsets.only(top: 28, bottom: 12),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Colors.black,
      ),
    ),
  );

  static Widget inputField(
    String label,
    void Function(String) onChanged, {
    String? helper,
    bool isRequired = false,
    IconData? icon,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.black),
        prefixIcon: icon != null ? Icon(icon, color: primaryBlue) : null,
        helperText: helper,
        filled: true,
        fillColor: boxWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(11),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      style: TextStyle(fontSize: 16, color: Colors.black),
      validator: isRequired
          ? (v) => v == null || v.isEmpty ? "Wajib diisi" : null
          : null,
      onChanged: onChanged,
    ),
  );

  static Widget whiteCard(List<Widget> children) => Container(
    margin: EdgeInsets.only(bottom: 2),
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color.fromARGB(255, 238, 238, 238),
      borderRadius: BorderRadius.circular(17),
      boxShadow: [
        BoxShadow(color: Colors.blue.withOpacity(0.03), blurRadius: 5, offset: Offset(0,2))
      ],
    ),
    child: Column(children: children),
  );

  static Widget uploadBox() => Container(
    width: 60,
    height: 60,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: primaryBlue,
        width: 1.5,
        style: BorderStyle.solid,
      ),
      color: boxWhite,
      boxShadow: [
        BoxShadow(
          color: primaryBlue.withOpacity(0.07),
          blurRadius: 3,
          offset: Offset(1, 2))
      ],
    ),
    child: const Icon(Icons.add, color: primaryBlue, size: 30),
  );
}