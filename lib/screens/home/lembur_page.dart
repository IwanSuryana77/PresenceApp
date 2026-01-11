import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart'; // Penting untuk format tanggal

// ===== COLORS =====
const primaryBlue = Color(0xFF2196F3);
const lightBg = Color(0xFFF6F7FB);
const borderGrey = Color(0xFFE1E4EF);

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});
  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage> {
  final _formKey = GlobalKey<FormState>();
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
    if (picked != null) setState(() => tanggalLembur = picked);
  }

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => loading = true);

    List<String> uploadedFiles = [];
    for (final file in attachments) {
      final ref = FirebaseStorage.instance.ref().child(
        'lembur/${DateTime.now().millisecondsSinceEpoch}_${file.name}',
      );
      await ref.putData(file.bytes!);
      final url = await ref.getDownloadURL();
      uploadedFiles.add(url);
    }

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

    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pengajuan lembur berhasil dikirim!')),
    );
    Navigator.pop(context);
  }

  InputDecoration modernInput({
    String? label,
    IconData? icon,
    bool isRequired = false,
    String? helper,
  }) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        prefixIcon: icon != null ? Icon(icon, color: primaryBlue, size: 22) : null,
        helperText: helper,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGrey, width: 1.3),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderGrey, width: 1.3),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 17),
        isDense: true,
      );

  Widget _modernCard({required Widget child}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 17),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: borderGrey, width: 1.4),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(.02),
              offset: const Offset(0, 2),
              blurRadius: 3,
            )
          ],
        ),
        child: child,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBg,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            children: [
              // Header
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () => Navigator.pop(context),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(Icons.arrow_back, color: Colors.black, size: 25),
                    ),
                  ),
                  const SizedBox(width: 13),
                  const Text(
                    "Pengajuan Lembur",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 21,
                      color: Colors.black,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 11),

              /// ============= JADWAL LEMBUR CARD =============
              _modernCard(
                child: Padding(
                  padding: const EdgeInsets.only(top: 17, bottom: 3, left: 17, right: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Jadwal lembur",
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.2, color: Colors.black)),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Tanggal lembur
                          Expanded(
                            child: GestureDetector(
                              onTap: _pickDate,
                              child: AbsorbPointer(
                                child: TextFormField(
                                  readOnly: true,
                                  decoration: modernInput(
                                      label: "Tanggal lembur",
                                      icon: Icons.calendar_today,
                                      isRequired: true),
                                  validator: (_) =>
                                      tanggalLembur == null ? "Wajib diisi" : null,
                                  controller: TextEditingController(
                                    text: tanggalLembur != null
                                        ? DateFormat('dd MMMM yyyy', 'id_ID').format(tanggalLembur!)
                                        : "",
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          // Shift
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: shift.isEmpty ? null : shift,
                              items: ['Pagi', 'Siang', 'Malam']
                                  .map((e) => DropdownMenuItem(
                                        value: e,
                                        child: Text(e, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
                                      ))
                                  .toList(),
                              onChanged: (v) => setState(() => shift = v ?? ''),
                              decoration: modernInput(label: "Shift", icon: Icons.access_time),
                              validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                              style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w500),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              /// ============= LEMBUR SEBELUM SHIFT CARD =============
              _modernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Lembur sebelum shift", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: modernInput(label: "Durasi lembur", icon: Icons.access_time_rounded),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (v) => setState(() => sebelumLembur = v),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        decoration: modernInput(label: "Durasi istirahat lembur", icon: Icons.self_improvement, helper: "opsional"),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (v) => setState(() => sebelumIstirahat = v),
                      ),
                    ],
                  ),
                ),
              ),

              /// ============= LEMBUR SETELAH SHIFT CARD =============
              _modernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Lembur setelah shift", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 8),
                      TextFormField(
                        decoration: modernInput(label: "Durasi lembur", icon: Icons.access_time_rounded),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (v) => setState(() => sesudahLembur = v),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        decoration: modernInput(label: "Durasi istirahat lembur", icon: Icons.self_improvement, helper: "opsional"),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (v) => setState(() => sesudahIstirahat = v),
                      ),
                    ],
                  ),
                ),
              ),

              /// ============= INFO TAMBAHAN CARD =============
              _modernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Informasi tambahan", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 7),
                      TextFormField(
                        decoration: modernInput(label: "Kompensasi", icon: Icons.monetization_on_rounded, isRequired: true),
                        style: const TextStyle(fontSize: 15),
                        validator: (v) => (v == null || v.isEmpty) ? "Wajib diisi" : null,
                        onChanged: (v) => setState(() => kompensasi = v),
                      ),
                      const SizedBox(height: 13),
                      TextFormField(
                        decoration: modernInput(label: "Alasan", icon: Icons.sticky_note_2_outlined),
                        style: const TextStyle(fontSize: 15),
                        onChanged: (v) => setState(() => alasan = v),
                      ),
                    ],
                  ),
                ),
              ),

              /// ============= LAMPIRAN CARD =============
              _modernCard(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 17),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Lampiran", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          InkWell(
                            onTap: _pickFiles,
                            borderRadius: BorderRadius.circular(11),
                            child: Container(
                              width: 57,
                              height: 57,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(13),
                                border: Border.all(
                                  color: primaryBlue,
                                  style: BorderStyle.solid,
                                  width: 1.7,
                                ),
                                color: Colors.white,
                              ),
                              child: const Center(
                                child: Icon(Icons.add, color: primaryBlue, size: 30),
                              ),
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
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
                                    children: attachments
                                        .map((a) => Chip(
                                              label: Text(a.name, style: const TextStyle(fontSize: 12, color: Colors.black)),
                                              backgroundColor: Colors.white,
                                              deleteIcon: const Icon(Icons.close, size: 18, color: Colors.red),
                                              onDeleted: () => setState(() => attachments.remove(a)),
                                            ))
                                        .toList(),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // Kirim Button
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                    padding: const EdgeInsets.symmetric(vertical: 17),
                  ),
                  onPressed: loading ? null : _submit,
                  child: loading
                      ? const SizedBox(
                          height: 25,
                          width: 25,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          "Kirim",
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
              const SizedBox(height: 15),
            ],
          ),
        ),
      ),
    );
  }
}