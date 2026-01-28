import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// Warna utama MODERN (update biru!)
const primaryBlue = Color(0xFF3F7DF4);
const lightGrey = Color(0xFFF7F8FA); // lebih soft
const darkGrey = Color(0xFF8E8E93);
const lightBlue = Color(0xFFEAF2FE);

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
  String name;
  int amount;
  String? notes;
  _BenefitItem(this.name, this.amount, {this.notes});
}

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

  void _showMonthPicker() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(top: 8),
          child: SizedBox(
            height: 340,
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text('Pilih Bulan',
                    style: TextStyle(
                        fontSize: 17, color: primaryBlue, fontWeight: FontWeight.bold)),
                Expanded(
                  child: ListView.builder(
                    itemCount: 24,
                    itemBuilder: (_, i) {
                      DateTime m = DateTime(
                          DateTime.now().year,
                          DateTime.now().month - i,
                          1);
                      return ListTile(
                        onTap: () => Navigator.pop(context, m),
                        title: Text(
                          DateFormat('MMMM yyyy', 'id_ID').format(m),
                          style: TextStyle(
                              color: selectedMonth.year == m.year &&
                                      selectedMonth.month == m.month
                                  ? primaryBlue
                                  : Colors.black87,
                              fontWeight: selectedMonth.year == m.year &&
                                      selectedMonth.month == m.month
                                  ? FontWeight.bold
                                  : FontWeight.normal),
                        ),
                        trailing: selectedMonth.year == m.year &&
                                selectedMonth.month == m.month
                            ? Icon(Icons.check_rounded, color: primaryBlue)
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked != null) setState(() => selectedMonth = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: lightGrey,
        centerTitle: true,
        title: Text(
          "Reimbursement",
          style: TextStyle(
            color: primaryBlue,
            fontWeight: FontWeight.bold,
            fontSize: 19,
            letterSpacing: 0.4,
          ),
        ),
      ),
      body: Column(children: [
        // Saldo Saya
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 8),
          child: Card(
            margin: EdgeInsets.zero,
            elevation: 2.5,
            color: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                          backgroundColor: Color(0xFFEDF5FE),
                          radius: 24,
                          child: Icon(Icons.account_balance_wallet_rounded,
                              size: 31, color: primaryBlue)),
                      SizedBox(width: 11),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Saldo Saya",
                                style: TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15),
                              ),
                              SizedBox(height: 1),
                              Text(
                                "Tidak ada kebijakan yang dibuat",
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 13.6),
                              ),
                              Text(
                                "Kebijakan reimburse akan muncul jika Anda telah membuatnya.",
                                style: TextStyle(
                                    color: darkGrey.withOpacity(.77),
                                    fontSize: 12.4,
                                    height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                  SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryBlue,
                        side: BorderSide(color: primaryBlue, width: 1),
                        shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(8)),
                        minimumSize: Size(70, 38),
                      ),
                      child: Text("Reimbursement Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Pilih bulan
        Container(
          margin: EdgeInsets.only(top: 11, bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 19, vertical: 8),
          decoration: BoxDecoration(
              color: Colors.white,
              border: Border.symmetric(
                  horizontal: BorderSide(color: lightGrey))),
          child: Row(
            children: [
              Icon(Icons.calendar_today_rounded,
                  color: primaryBlue, size: 20),
              SizedBox(width: 8),
              GestureDetector(
                onTap: _showMonthPicker,
                child: Row(
                  children: [
                    Text(
                      DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                      style: TextStyle(
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue),
                    ),
                    Icon(Icons.arrow_drop_down, color: primaryBlue),
                  ],
                ),
              ),
              Spacer(),
              Icon(Icons.filter_list_rounded, color: lightBlue, size: 26)
            ],
          ),
        ),
        // List
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
                    child: Padding(
                  padding: const EdgeInsets.all(31.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long,
                          size: 75, color: lightBlue),
                      const SizedBox(height: 18),
                      const Text(
                        'Tidak ada pengajuan',
                        style: TextStyle(color: darkGrey, fontSize: 16),
                      ),
                    ],
                  ),
                ));
              }

              return ListView.separated(
                separatorBuilder: (_, __) => SizedBox(height: 5),
                padding: EdgeInsets.all(13),
                itemCount: data.length,
                itemBuilder: (context, index) {
                  final item = data[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    margin: EdgeInsets.symmetric(vertical: 3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    child: ListTile(
                      minLeadingWidth: 0,
                      leading: Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: lightBlue,
                            borderRadius: BorderRadius.circular(13)),
                        child: Icon(Icons.receipt_long,
                            color: primaryBlue, size: 23),
                      ),
                      title: Text(item.description,
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 15)),
                      subtitle: Text(
                        DateFormat('dd MMM yyyy', 'id_ID')
                            .format(item.startDate),
                        style:
                            TextStyle(color: darkGrey, fontSize: 12.4),
                      ),
                      trailing: Text(
                        NumberFormat.currency(
                                locale: 'id_ID',
                                symbol: 'Rp',
                                decimalDigits: 0)
                            .format(item.amount),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            fontSize: 15),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ]),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReimbursementFormPage()),
          );
          if (res == true) setState(() {});
        },
        backgroundColor: primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(Icons.add, color: Colors.white, size: 26),
        label: Text("Ajukan", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        'pdf', 'jpg', 'png', 'xlsx', 'docx', 'doc', 'txt', 'ppt',
      ],
      type: FileType.custom,
    );

    if (result != null) {
      setState(() {
        final x = result.files.where(
          (f) => f.bytes != null && f.size <= 10 * 1024 * 1024,
        );
        if (_files.length + x.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Maksimal 5 file')));
        } else {
          _files.addAll(x);
        }
      });
    }
  }

  /// ================= UPLOAD CLOUDINARY =================
  Future<List<String>> _uploadFiles() async {
    List<String> urls = [];
    for (final file in _files) {
      final uri =
          Uri.parse("https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload");

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = "facesign_unsigned"
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
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambahkan item benefit')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      final urls = await _uploadFiles();
      await FirebaseFirestore.instance.collection('reimbursement_requests').add({
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  Future<void> _showAddItem() async {
    var _nCtrl = TextEditingController();
    var _nomCtrl = TextEditingController();
    var _notesCtrl = TextEditingController();
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        constraints: BoxConstraints(maxHeight: 330),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) {
          return Padding(
            padding:
                EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 21, 18, 10),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 45,
                      height: 4,
                      margin: EdgeInsets.only(bottom: 13),
                      decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    Text("Tambah Item",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: primaryBlue)),
                    SizedBox(height: 10),
                    TextField(
                      controller: _nCtrl,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        hintText: "Nama item (misal: Makan siang)",
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: lightBlue)),
                      ),
                    ),
                    SizedBox(height: 11),
                    TextField(
                      controller: _nomCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                        hintText: "Nominal",
                        prefixText: "Rp ",
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: lightBlue)),
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      controller: _notesCtrl,
                      minLines: 1,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: "Catatan singkat (opsional)",
                        filled: true,
                        fillColor: lightGrey,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(9),
                            borderSide: BorderSide(color: lightBlue)),
                      ),
                    ),
                    SizedBox(height: 16),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            String name = _nCtrl.text.trim();
                            int amount = int.tryParse(_nomCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                            if (name.isEmpty || amount <= 0) {
                              return;
                            }
                            setState(() {
                              _items.add(_BenefitItem(
                                name, amount, notes: _notesCtrl.text.trim()));
                            });
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            padding: EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text("Tambah", style: TextStyle(fontWeight: FontWeight.bold)),
                        ))
                  ]),
            ),
          );
        });
  }

  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: lightGrey,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan Reimbursement',
          style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w900, fontSize: 17, letterSpacing: 0.2),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Kebijakan reimbursement
            Text(
              'Kebijakan reimbursement *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _policyCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              decoration: InputDecoration(
                hintText: 'Standar Reimbursement',
                filled: true,
                fillColor: lightBlue.withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
            ),

            SizedBox(height: 16),
            // Tanggal transaksi
            Text(
              'Tanggal transaksi *',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: primaryBlue,
              ),
            ),
            SizedBox(height: 8),
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
              child: AbsorbPointer(
                child: TextFormField(
                  controller: TextEditingController(
                      text: DateFormat('dd MMMM yyyy', 'id_ID').format(_date)),
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Pilih tanggal transaksi',
                    suffixIcon: Icon(Icons.calendar_today, color: primaryBlue),
                    filled: true,
                    fillColor: lightBlue.withOpacity(.45),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
                        borderSide: BorderSide.none),
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),
            ),

            SizedBox(height: 16),
            // Lampiran
            Text(
              "Lampiran",
              style: TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue),
            ),
            Text(
              "Maksimal 5 file PDF, JPG, PNG, XLSX, DOCX, DOC, TXT, PPT (maks 10MB)",
              style:
                  TextStyle(fontSize: 12.2, color: darkGrey, fontWeight: FontWeight.normal, height: 1.2),
            ),
            SizedBox(height: 7),
            TextFormField(
              controller: _descCtrl,
              validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Deskripsi singkat',
                filled: true,
                fillColor: lightBlue.withOpacity(0.45),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(14),
              ),
            ),
            SizedBox(height: 7),
            InkWell(
              onTap: _pickFiles,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 22),
                decoration: BoxDecoration(
                  color: lightBlue.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: primaryBlue.withOpacity(0.13)),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_upload, size: 37, color: primaryBlue),
                    SizedBox(height: 7),
                    Text('Unggah File',
                        style: TextStyle(
                            color: primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (_files.isNotEmpty) ...[
              SizedBox(height: 9),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _files.map((file) {
                  return Chip(
                    label: Text(file.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    backgroundColor: lightBlue,
                    deleteIcon: Icon(Icons.close, size: 16, color: Colors.redAccent),
                    onDeleted: () {
                      setState(() => _files.remove(file));
                    },
                  );
                }).toList(),
              ),
            ],

            SizedBox(height: 16),

            Text('Item benefit',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15, color: primaryBlue)),
            Text('Rincian benefit yang akan diajukan',
                style: TextStyle(color: darkGrey, fontSize: 12.3)),
            SizedBox(height: 12),

            ..._items.map((item) => Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11)),
                  margin: EdgeInsets.only(bottom: 5),
                  child: ListTile(
                    contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                    title: Text(item.name,
                        style: TextStyle(
                            color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 14.5)),
                    subtitle: item.notes != null && item.notes!.isNotEmpty
                        ? Text(item.notes!,
                            style: TextStyle(fontSize: 11.2, color: darkGrey))
                        : null,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Rp${NumberFormat('#,###').format(item.amount)}',
                          style: TextStyle(
                              color: Colors.black, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        IconButton(
                            icon: Icon(Icons.delete_outline_rounded,
                                color: Colors.redAccent, size: 22),
                            onPressed: () {
                              setState(() => _items.remove(item));
                            }),
                      ],
                    ),
                  ),
                )),
            SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showAddItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: EdgeInsets.symmetric(vertical: 12),
                  minimumSize: Size(90, 46),
                ),
                icon: Icon(Icons.add, color: Colors.white),
                label: Text(
                  "Tambahkan Item",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14.5),
                ),
              ),
            ),
            SizedBox(height: 15),
            Card(
              margin: EdgeInsets.symmetric(vertical: 7),
              color: Colors.white,
              elevation: 3,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 23, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total Jumlah pengajuan',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                            fontSize: 15.2)),
                    Text(
                      'Rp${NumberFormat('#,###').format(_total)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                          fontSize: 16.4),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 9),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  padding: EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                  minimumSize: Size(110, 48),
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
                          fontSize: 16.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}