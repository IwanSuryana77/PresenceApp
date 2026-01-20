import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:dotted_border/dotted_border.dart';

/// ================= CONFIG CLOUDINARY =================
/// GANTI DENGAN PUNYA KAMU
const String cloudinaryCloudName = "dv8zwl76d";
const String cloudinaryUploadPreset = "facesign_unsigned";

/// ================= TEMA =================
const primaryBlue = Color(0xFF242484);
const lightGrey = Color(0xFFEFEFF2);

/// =====================================================
/// ================= LIST PAGE ==========================
/// =====================================================
class ReimbursementListPage extends StatefulWidget {
  const ReimbursementListPage({super.key});

  @override
  State<ReimbursementListPage> createState() => _ReimbursementListPageState();
}

class _ReimbursementListPageState extends State<ReimbursementListPage> {
  DateTime selectedMonth = DateTime.now();

  Stream<List<ReimbursementRequest>> _stream() {
    return FirebaseFirestore.instance
        .collection('reimbursement_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ReimbursementRequest.fromMap(d.data(), d.id))
            .toList());
  }

  void _openForm() async {
    final res = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReimbursementFormPage()),
    );
    if (res == true) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reimbursement',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<ReimbursementRequest>>(
        stream: _stream(),
        builder: (c, s) {
          if (s.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (s.hasError) {
            return const Center(child: Text('Error Firestore'));
          }

          final data = (s.data ?? [])
              .where((e) =>
                  e.createdAt.month == selectedMonth.month &&
                  e.createdAt.year == selectedMonth.year)
              .toList();

          if (data.isEmpty) {
            return const Center(
              child: Text(
                'Tidak ada pengajuan',
                style: TextStyle(
                    color: primaryBlue,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            );
          }

          return ListView(
            children: data.map((e) {
              return ListTile(
                leading: const Icon(Icons.receipt_long, color: primaryBlue),
                title: Text(e.description),
                subtitle: Text(
                  DateFormat('dd MMM yyyy', 'id_ID').format(e.startDate),
                ),
                trailing: Text(
                  NumberFormat.currency(
                          locale: 'id_ID',
                          symbol: 'Rp ',
                          decimalDigits: 0)
                      .format(e.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _openForm,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueAccent,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Ajukan Reimbursement',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}

/// =====================================================
/// ================= FORM PAGE ==========================
/// =====================================================
class ReimbursementFormPage extends StatefulWidget {
  const ReimbursementFormPage({super.key});

  @override
  State<ReimbursementFormPage> createState() => _ReimbursementFormPageState();
}

class _ReimbursementFormPageState extends State<ReimbursementFormPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descCtrl = TextEditingController();

  DateTime _date = DateTime.now();
  bool _loading = false;

  final List<PlatformFile> _files = [];
  final List<_BenefitItem> _items = [];

  int get _total => _items.fold(0, (s, e) => s + e.amount);

  /// ================= PICK FILE =================
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
    );

    if (result != null) {
      setState(() {
        _files.addAll(result.files.where((f) => f.bytes != null));
      });
    }
  }

  /// ================= UPLOAD CLOUDINARY =================
  Future<List<String>> _uploadFiles() async {
    List<String> urls = [];

    for (final file in _files) {
      final uri = Uri.parse(
          "https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload");

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        urls.add(json.decode(body)['secure_url']);
      } else {
        throw Exception('Upload gagal');
      }
    }

    return urls;
  }

  /// ================= SUBMIT =================
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan item benefit')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final urls = await _uploadFiles();

      await FirebaseFirestore.instance
          .collection('reimbursement_requests')
          .add({
        'employeeId': user?.uid ?? 'anon',
        'employeeName': user?.displayName ?? 'User',
        'description': _descCtrl.text.trim(),
        'startDate': _date,
        'amount': _total.toDouble(),
        'attachmentUrls': urls,
        'createdAt': DateTime.now(),
      });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _loading = false);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Pengajuan Reimbursement',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _descCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              decoration: const InputDecoration(
                labelText: 'Deskripsi',
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            /// FILE
            Wrap(
              spacing: 8,
              children: [
                ..._files.map((f) => Chip(label: Text(f.name))),
                GestureDetector(
                  onTap: _pickFiles,
                  child: DottedBorder(
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      child:
                          const Icon(Icons.add, color: primaryBlue, size: 28),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// ITEM
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _items.add(_BenefitItem('Contoh Item', 50000));
                });
              },
              child: const Text('Tambah Item Contoh'),
            ),

            const SizedBox(height: 16),
            Text(
              'Total: Rp $_total',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: primaryBlue),
            ),

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Kirim',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ================= MODEL =================
class ReimbursementRequest {
  final String id;
  final String description;
  final DateTime startDate;
  final double amount;
  final DateTime createdAt;

  ReimbursementRequest({
    required this.id,
    required this.description,
    required this.startDate,
    required this.amount,
    required this.createdAt,
  });

  factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
    return ReimbursementRequest(
      id: id,
      description: map['description'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

class _BenefitItem {
  final String name;
  final int amount;

  _BenefitItem(this.name, this.amount);
}
