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
const darkGrey = Color(0xFF8E8E93);
const lightBlue = Color(0xFFE8F4FD);

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
        .map(
          (snap) => snap.docs
              .map((d) => ReimbursementRequest.fromMap(d.data(), d.id))
              .toList(),
        );
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Reimbursement',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Saldo Saya Section
          Container(
            padding: const EdgeInsets.all(20),
            color: lightBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Saldo Saya',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tidak ada kebijakan yang dibuat\nKebijakan reimburse akan muncul jika Anda telah membuatnya.',
                  style: TextStyle(color: darkGrey, fontSize: 14),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: lightGrey),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reimbursement Status',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(height: 1, color: lightGrey),
                      const SizedBox(height: 16),
                      // You can add status items here if needed
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Month Selector
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: lightGrey)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: primaryBlue),
              ],
            ),
          ),

          // Reimbursement List
          Expanded(
            child: StreamBuilder<List<ReimbursementRequest>>(
              stream: _stream(),
              builder: (c, s) {
                if (s.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.hasError) {
                  return const Center(child: Text('Error Firestore'));
                }

                final data = (s.data ?? [])
                    .where(
                      (e) =>
                          e.createdAt.month == selectedMonth.month &&
                          e.createdAt.year == selectedMonth.year,
                    )
                    .toList();

                if (data.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 60, color: lightGrey),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada pengajuan',
                          style: TextStyle(color: darkGrey, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: data.length,
                  itemBuilder: (context, index) {
                    final item = data[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: lightGrey),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: lightBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              color: primaryBlue,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.description,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMM yyyy',
                                    'id_ID',
                                  ).format(item.startDate),
                                  style: const TextStyle(
                                    color: darkGrey,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp',
                              decimalDigits: 0,
                            ).format(item.amount),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openForm,
        backgroundColor: primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white, size: 28),
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
  final TextEditingController _policyCtrl = TextEditingController();

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
      allowedExtensions: [
        'pdf',
        'jpg',
        'png',
        'xlsx',
        'docx',
        'doc',
        'txt',
        'ppt',
      ],
    );

    if (result != null) {
      setState(() {
        _files.addAll(
          result.files.where(
            (f) => f.bytes != null && f.size <= 10 * 1024 * 1024,
          ),
        );
      });
    }
  }

  /// ================= UPLOAD CLOUDINARY =================
  Future<List<String>> _uploadFiles() async {
    List<String> urls = [];

    for (final file in _files) {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload",
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        );

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Tambahkan item benefit')));
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
            'policy': _policyCtrl.text.trim(),
            'startDate': _date,
            'amount': _total.toDouble(),
            'attachmentUrls': urls,
            'createdAt': DateTime.now(),
          });

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }

    setState(() => _loading = false);
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan Reimbursement',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Kebijakan reimbursement
            const Text(
              'Kebijakan reimbursement *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _policyCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              decoration: InputDecoration(
                hintText: 'Masukkan kebijakan reimbursement',
                filled: true,
                fillColor: lightGrey.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Tanggal transaksi
            const Text(
              'Tanggal transaksi *',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() => _date = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: lightGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                      style: const TextStyle(fontSize: 16),
                    ),
                    const Icon(Icons.calendar_today, color: darkGrey),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),
            const Divider(height: 1, color: lightGrey),
            const SizedBox(height: 20),

            // Lampiran Section
            const Text(
              'Lampiran',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 12),

            // Deskripsi
            const Text(
              'Deskripsi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _descCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Masukkan deskripsi',
                filled: true,
                fillColor: lightGrey.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 16),

            // File upload area
            DottedBorder(
              child: GestureDetector(
                onTap: _pickFiles,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: lightBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload, size: 40, color: primaryBlue),
                      SizedBox(height: 12),
                      Text(
                        'Unggah File',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Maksimal 5 file\nFormat: PDF, JPG, PNG, XLSX, DOCX, DOC, TXT, PPT\nMaksimum 10MB',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: darkGrey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // List uploaded files
            if (_files.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _files.map((file) {
                  return Chip(
                    label: Text(file.name),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () {
                      setState(() => _files.remove(file));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 30),
            const Divider(height: 1, color: lightGrey),
            const SizedBox(height: 20),

            // Item benefit section
            const Text(
              'Item benefit',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Rincian benefit yang akan diajukan',
              style: TextStyle(color: darkGrey, fontSize: 14),
            ),

            const SizedBox(height: 16),

            // Add item button
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _items.add(_BenefitItem('Item ${_items.length + 1}', 0));
                });
              },
              icon: const Icon(Icons.add, color: primaryBlue),
              label: const Text(
                'Tambahkan Item',
                style: TextStyle(color: primaryBlue),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: primaryBlue),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            // List of items
            if (_items.isNotEmpty) ...[
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _items.length,
                itemBuilder: (context, index) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: lightGrey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: lightGrey),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _items[index].name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Rp ${NumberFormat('#,###').format(_items[index].amount)}',
                                style: const TextStyle(color: darkGrey),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() => _items.removeAt(index));
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],

            const SizedBox(height: 20),

            // Total amount
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Jumlah pengajuan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                  Text(
                    'Rp ${NumberFormat('#,###').format(_total)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Submit button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _loading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Kirim',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
  final String policy;
  final DateTime startDate;
  final double amount;
  final DateTime createdAt;

  ReimbursementRequest({
    required this.id,
    required this.description,
    required this.policy,
    required this.startDate,
    required this.amount,
    required this.createdAt,
  });

  factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
    return ReimbursementRequest(
      id: id,
      description: map['description'] ?? '',
      policy: map['policy'] ?? '',
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

// import 'dart:convert';

// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;
// import 'package:dotted_border/dotted_border.dart';

// /// ================= CONFIG CLOUDINARY =================
// /// GANTI DENGAN PUNYA KAMU
// const String cloudinaryCloudName = "dv8zwl76d";
// const String cloudinaryUploadPreset = "facesign_unsigned";

// /// ================= TEMA =================
// const primaryBlue = Color(0xFF242484);
// const lightGrey = Color(0xFFEFEFF2);

// /// =====================================================
// /// ================= LIST PAGE ==========================
// /// =====================================================
// class ReimbursementListPage extends StatefulWidget {
//   const ReimbursementListPage({super.key});

//   @override
//   State<ReimbursementListPage> createState() => _ReimbursementListPageState();
// }

// class _ReimbursementListPageState extends State<ReimbursementListPage> {
//   DateTime selectedMonth = DateTime.now();

//   Stream<List<ReimbursementRequest>> _stream() {
//     return FirebaseFirestore.instance
//         .collection('reimbursement_requests')
//         .orderBy('createdAt', descending: true)
//         .snapshots()
//         .map((snap) => snap.docs
//             .map((d) => ReimbursementRequest.fromMap(d.data(), d.id))
//             .toList());
//   }

//   void _openForm() async {
//     final res = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const ReimbursementFormPage()),
//     );
//     if (res == true) setState(() {});
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightGrey,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Reimbursement',
//           style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: StreamBuilder<List<ReimbursementRequest>>(
//         stream: _stream(),
//         builder: (c, s) {
//           if (s.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (s.hasError) {
//             return const Center(child: Text('Error Firestore'));
//           }

//           final data = (s.data ?? [])
//               .where((e) =>
//                   e.createdAt.month == selectedMonth.month &&
//                   e.createdAt.year == selectedMonth.year)
//               .toList();

//           if (data.isEmpty) {
//             return const Center(
//               child: Text(
//                 'Tidak ada pengajuan',
//                 style: TextStyle(
//                     color: primaryBlue,
//                     fontSize: 18,
//                     fontWeight: FontWeight.bold),
//               ),
//             );
//           }

//           return ListView(
//             children: data.map((e) {
//               return ListTile(
//                 leading: const Icon(Icons.receipt_long, color: primaryBlue),
//                 title: Text(e.description),
//                 subtitle: Text(
//                   DateFormat('dd MMM yyyy', 'id_ID').format(e.startDate),
//                 ),
//                 trailing: Text(
//                   NumberFormat.currency(
//                           locale: 'id_ID',
//                           symbol: 'Rp ',
//                           decimalDigits: 0)
//                       .format(e.amount),
//                   style: const TextStyle(fontWeight: FontWeight.bold),
//                 ),
//               );
//             }).toList(),
//           );
//         },
//       ),
//       bottomNavigationBar: Padding(
//         padding: const EdgeInsets.all(16),
//         child: ElevatedButton(
//           onPressed: _openForm,
//           style: ElevatedButton.styleFrom(
//             backgroundColor: Colors.blueAccent,
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             shape:
//                 RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//           ),
//           child: const Text(
//             'Ajukan Reimbursement',
//             style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//           ),
//         ),
//       ),
//     );
//   }
// }

// /// =====================================================
// /// ================= FORM PAGE ==========================
// /// =====================================================
// class ReimbursementFormPage extends StatefulWidget {
//   const ReimbursementFormPage({super.key});

//   @override
//   State<ReimbursementFormPage> createState() => _ReimbursementFormPageState();
// }

// class _ReimbursementFormPageState extends State<ReimbursementFormPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _descCtrl = TextEditingController();

//   DateTime _date = DateTime.now();
//   bool _loading = false;

//   final List<PlatformFile> _files = [];
//   final List<_BenefitItem> _items = [];

//   int get _total => _items.fold(0, (s, e) => s + e.amount);

//   /// ================= PICK FILE =================
//   Future<void> _pickFiles() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       withData: true,
//     );

//     if (result != null) {
//       setState(() {
//         _files.addAll(result.files.where((f) => f.bytes != null));
//       });
//     }
//   }

//   /// ================= UPLOAD CLOUDINARY =================
//   Future<List<String>> _uploadFiles() async {
//     List<String> urls = [];

//     for (final file in _files) {
//       final uri = Uri.parse(
//           "https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload");

//       final request = http.MultipartRequest('POST', uri)
//         ..fields['upload_preset'] = cloudinaryUploadPreset
//         ..files.add(http.MultipartFile.fromBytes(
//           'file',
//           file.bytes!,
//           filename: file.name,
//         ));

//       final response = await request.send();
//       final body = await response.stream.bytesToString();

//       if (response.statusCode == 200) {
//         urls.add(json.decode(body)['secure_url']);
//       } else {
//         throw Exception('Upload gagal');
//       }
//     }

//     return urls;
//   }

//   /// ================= SUBMIT =================
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_items.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Tambahkan item benefit')),
//       );
//       return;
//     }

//     setState(() => _loading = true);

//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       final urls = await _uploadFiles();

//       await FirebaseFirestore.instance
//           .collection('reimbursement_requests')
//           .add({
//         'employeeId': user?.uid ?? 'anon',
//         'employeeName': user?.displayName ?? 'User',
//         'description': _descCtrl.text.trim(),
//         'startDate': _date,
//         'amount': _total.toDouble(),
//         'attachmentUrls': urls,
//         'createdAt': DateTime.now(),
//       });

//       if (!mounted) return;
//       Navigator.pop(context, true);
//     } catch (e) {
//       ScaffoldMessenger.of(context)
//           .showSnackBar(SnackBar(content: Text('Error: $e')));
//     }

//     setState(() => _loading = false);
//   }

//   /// ================= UI =================
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightGrey,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           'Pengajuan Reimbursement',
//           style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold),
//         ),
//         centerTitle: true,
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.all(16),
//           children: [
//             TextFormField(
//               controller: _descCtrl,
//               validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
//               decoration: const InputDecoration(
//                 labelText: 'Deskripsi',
//                 filled: true,
//                 fillColor: Colors.white,
//               ),
//             ),
//             const SizedBox(height: 16),

//             /// FILE
//             Wrap(
//               spacing: 8,
//               children: [
//                 ..._files.map((f) => Chip(label: Text(f.name))),
//                 GestureDetector(
//                   onTap: _pickFiles,
//                   child: DottedBorder(
//                     child: Container(
//                       width: 50,
//                       height: 50,
//                       alignment: Alignment.center,
//                       child:
//                           const Icon(Icons.add, color: primaryBlue, size: 28),
//                     ),
//                   ),
//                 ),
//               ],
//             ),

//             const SizedBox(height: 16),

//             /// ITEM
//             ElevatedButton(
//               onPressed: () {
//                 setState(() {
//                   _items.add(_BenefitItem('Contoh Item', 50000));
//                 });
//               },
//               child: const Text('Tambah Item Contoh'),
//             ),

//             const SizedBox(height: 16),
//             Text(
//               'Total: Rp $_total',
//               style: const TextStyle(
//                   fontWeight: FontWeight.bold, color: primaryBlue),
//             ),

//             const SizedBox(height: 24),
//             ElevatedButton(
//               onPressed: _loading ? null : _submit,
//               style: ElevatedButton.styleFrom(
//                 backgroundColor: Colors.blueAccent,
//                 padding: const EdgeInsets.symmetric(vertical: 16),
//               ),
//               child: _loading
//                   ? const CircularProgressIndicator(color: Colors.white)
//                   : const Text(
//                       'Kirim',
//                       style:
//                           TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
//                     ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// /// ================= MODEL =================
// class ReimbursementRequest {
//   final String id;
//   final String description;
//   final DateTime startDate;
//   final double amount;
//   final DateTime createdAt;

//   ReimbursementRequest({
//     required this.id,
//     required this.description,
//     required this.startDate,
//     required this.amount,
//     required this.createdAt,
//   });

//   factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
//     return ReimbursementRequest(
//       id: id,
//       description: map['description'] ?? '',
//       startDate: (map['startDate'] as Timestamp).toDate(),
//       amount: (map['amount'] as num).toDouble(),
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//     );
//   }
// }

// class _BenefitItem {
//   final String name;
//   final int amount;

//   _BenefitItem(this.name, this.amount);
// }
