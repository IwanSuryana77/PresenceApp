import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

class LemburPage extends StatefulWidget {
  const LemburPage({super.key});

  @override
  State<LemburPage> createState() => _LemburPageState();
}

class _LemburPageState extends State<LemburPage> {
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  DateTime? tanggalLembur;
  String shift = '';
  String sebelumLembur = '';
  String sebelumIstirahat = '';
  String sesudahLembur = '';
  String sesudahIstirahat = '';
  String kompensasi = '';
  String alasan = '';

  List<PlatformFile> attachments = [];

  // ================= CLOUDINARY =================
  static const String cloudName = 'dv8zwl76d'; // GANTI JIKA BEDA
  static const String uploadPreset = 'facesign_unsigned';

  Future<String> uploadToCloudinary(PlatformFile file) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$cloudName/raw/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );

    final response = await request.send();

    if (response.statusCode == 200) {
      final resStr = await response.stream.bytesToString();
      final data = json.decode(resStr);
      return data['secure_url'];
    } else {
      throw Exception('Upload Cloudinary gagal');
    }
  }

  // ================= PICK FILE =================
  Future<void> pickFiles() async {
    if (attachments.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maksimal 5 file')),
      );
      return;
    }

    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        attachments.addAll(
          result.files.take(5 - attachments.length),
        );
      });
    }
  }

  // ================= SUBMIT =================
  Future<void> submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => loading = true);

    try {
      List<String> uploadedUrls = [];

      for (final file in attachments) {
        final url = await uploadToCloudinary(file);
        uploadedUrls.add(url);
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
        'lampiran_urls': uploadedUrls,
        'created_at': FieldValue.serverTimestamp(),
      });

      setState(() => loading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pengajuan lembur berhasil')),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Gagal: $e')),
      );
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan Lembur')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // TANGGAL
              ListTile(
                title: Text(
                  tanggalLembur == null
                      ? 'Pilih Tanggal Lembur'
                      : tanggalLembur!.toLocal().toString().split(' ')[0],
                ),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => tanggalLembur = picked);
                  }
                },
              ),

              textField('Shift', (v) => shift = v),
              textField('Sebelum Lembur', (v) => sebelumLembur = v),
              textField('Sebelum Istirahat', (v) => sebelumIstirahat = v),
              textField('Sesudah Lembur', (v) => sesudahLembur = v),
              textField('Sesudah Istirahat', (v) => sesudahIstirahat = v),
              textField('Kompensasi', (v) => kompensasi = v),
              textField('Alasan', (v) => alasan = v, maxLines: 3),

              const SizedBox(height: 16),

              // ATTACHMENTS
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Lampiran (${attachments.length}/5)',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),

              Wrap(
                spacing: 8,
                children: attachments
                    .map(
                      (f) => Chip(
                        label: Text(
                          f.name,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onDeleted: () {
                          setState(() => attachments.remove(f));
                        },
                      ),
                    )
                    .toList(),
              ),

              const SizedBox(height: 8),

              ElevatedButton.icon(
                onPressed: pickFiles,
                icon: const Icon(Icons.attach_file),
                label: const Text('Tambah Lampiran'),
              ),

              const SizedBox(height: 24),

              loading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: submit,
                        child: const Text('KIRIM'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget textField(
    String label,
    Function(String) onChanged, {
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: TextFormField(
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
        onChanged: onChanged,
      ),
    );
  }
}
