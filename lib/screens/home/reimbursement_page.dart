import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

/// ================= CONFIG CLOUDINARY =================
const String cloudinaryUploadPreset = "facesign_unsigned";
const primaryBlue = Color(0xFF3F7DF4);
const lightGrey = Color(0xFFF7F8FA);
const darkGrey = Color(0xFF8E8E93);
const lightBlue = Color(0xFFE8F4FD);

class ReimbursementRequest {
  final String id;
  final String description;
  final String policy;
  final DateTime startDate;
  final double amount;
  final DateTime createdAt;
  final String status;
  final String refCode;

  ReimbursementRequest({
    required this.id,
    required this.description,
    required this.policy,
    required this.startDate,
    required this.amount,
    required this.createdAt,
    required this.status,
    required this.refCode,
  });

  factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
    return ReimbursementRequest(
      id: id,
      description: map['description'] ?? '',
      policy: map['policy'] ?? '',
      startDate: (map['startDate'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toDouble(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      status: (map['status'] ?? 'Menunggu') as String,
      refCode: (map['refCode'] ?? 'REF-XXXXX-XXX') as String,
    );
  }
}

class _BenefitItem {
  String name;
  int amount;
  String? notes;
  _BenefitItem(this.name, this.amount, {this.notes});
}

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

  // NEW - untuk riwayat pengajuan (Firestore)
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  List<ReimbursementRequest> _history = [];

  /// PICK FILE
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
        if (_files.length + result.files.length > 5) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Maksimal 5 file')));
        } else {
          _files.addAll(
            result.files.where((f) => f.bytes != null && f.size <= 10 * 1024 * 1024),
          );
        }
      });
    }
  }

  /// UPLOAD CLOUDINARY
  Future<List<String>> _uploadFiles() async {
    List<String> urls = [];
    for (final file in _files) {
      final uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload",
      );
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = cloudinaryUploadPreset
        ..files.add(
          http.MultipartFile.fromBytes('file', file.bytes!, filename: file.name),
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

  /// RESET FORM
  void _resetForm() {
    _policyCtrl.clear();
    _descCtrl.clear();
    setState(() {
      _date = DateTime.now();
      _items.clear();
      _files.clear();
    });
  }

  /// SUBMIT
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tambahkan item benefit')));
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      String employeeName = 'User';
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (userDoc.exists && userDoc.data() != null && userDoc.data()!.containsKey('name')) {
          employeeName = userDoc['name'] ?? 'User';
        } else if (user.displayName != null && user.displayName!.isNotEmpty) {
          employeeName = user.displayName!;
        }
      }

      final urls = await _uploadFiles();
      // Generate REF code misal: REF-YYYYMMDD-UID
      final refCode = 'REF-${DateFormat('yyyyMMdd').format(DateTime.now())}-${user?.uid?.substring(0, 3) ?? '001'}';
      final Map<String, dynamic> firestoreData = {
        'employeeId': user?.uid ?? 'anon',
        'employeeName': employeeName,
        'description': _descCtrl.text.trim(),
        'policy': _policyCtrl.text.trim(),
        'startDate': _date,
        'amount': _total.toDouble(),
        'attachmentUrls': urls,
        'createdAt': DateTime.now(),
        'status': 'Menunggu', // Default status
        'refCode': refCode,
      };

      final docRef = await FirebaseFirestore.instance.collection('reimbursement_requests').add(firestoreData);

      // Fetch doc just created, then update riwayat
      final doc = await docRef.get();
      final newReq = ReimbursementRequest.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      setState(() {
        _history.insert(0, newReq);
      });
      _resetForm();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pengajuan berhasil!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
    setState(() => _loading = false);
  }

  void _showAddItem() {
    final _nCtrl = TextEditingController();
    final _nomCtrl = TextEditingController();
    final _notesCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 22,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 38, height: 4, margin: EdgeInsets.only(bottom: 10), decoration: BoxDecoration(
                color: Colors.grey[300], borderRadius: BorderRadius.circular(2),
              )),
              const Text("Tambah Item", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF0C75BA))),
              const SizedBox(height: 10),
              TextField(
                controller: _nCtrl,
                decoration: InputDecoration(hintText: "Nama item", filled: true, fillColor: lightGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Color(0xFFE5E5EA))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _nomCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: "Nominal", prefixText: "Rp ", filled: true, fillColor: lightGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Color(0xFFE5E5EA))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
              ),
              const SizedBox(height: 7),
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(hintText: "Catatan singkat (opsional)", filled: true, fillColor: lightGrey,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: Color(0xFFE5E5EA))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                ),
              ),
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF3F7DF4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  onPressed: () {
                    String name = _nCtrl.text.trim();
                    int amount = int.tryParse(_nomCtrl.text.replaceAll('.', '').replaceAll(',', '')) ?? 0;
                    setState(() {
                      if (name.isNotEmpty && amount > 0) {
                        _items.add(_BenefitItem(name, amount, notes: _notesCtrl.text.trim()));
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Ambil riwayat dari Firestore menurut bulan & tahun
  Future<void> _fetchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final firstDay = DateTime(_selectedYear, _selectedMonth, 1);
    final lastDay = DateTime(_selectedYear, _selectedMonth + 1, 0, 23, 59, 59);

    final qSnap = await FirebaseFirestore.instance
        .collection('reimbursement_requests')
        .where('employeeId', isEqualTo: user.uid)
        .where('startDate', isGreaterThanOrEqualTo: firstDay)
        .where('startDate', isLessThanOrEqualTo: lastDay)
        .orderBy('startDate', descending: true)
        .limit(5)
        .get();

    setState(() {
      _history = qSnap.docs.map((doc) => ReimbursementRequest.fromMap(doc.data(), doc.id)).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => DateFormat.MMMM('id_ID').format(DateTime(0, i + 1)));
    final years = List.generate(5, (i) => DateTime.now().year - 2 + i);

    return Scaffold(
      backgroundColor: lightGrey,
      appBar: AppBar(
        backgroundColor: Color(0xFF0C75BA),
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        title: const Text('Pengajuan Reimbursement', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 21)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(13, 16, 13, 18),
          children: [
            // FORM
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // (isi form reimbursement tetap)
                  // Kebijakan reimbursement dropdown
                  const Text('Kebijakan reimbursement *', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  DropdownButtonFormField<String>(
                    hint: const Text('Standar Reimbursement'),
                    decoration: InputDecoration(
                      filled: true, fillColor: Color(0xFFF4F4F7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Color(0xFFF0F0F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    value: _policyCtrl.text != '' ? _policyCtrl.text : null,
                    items: ['Standar Reimbursement', 'Reimbursement Transport', 'Reimbursement Konsumsi'].map(
                      (v) => DropdownMenuItem(value: v, child: Text(v)),
                    ).toList(),
                    onChanged: (v) => setState(() => _policyCtrl.text = v ?? ''),
                    validator: (v) => (v == null || v.isEmpty) ? 'Wajib dipilih' : null,
                  ),
                  const SizedBox(height: 17),
                  // Tanggal transaksi
                  const Text('Tanggal transaksi *', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 7),
                  GestureDetector(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2030),
                      );
                      if (picked != null) setState(() => _date = picked);
                    },
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: DateFormat('dd MMMM yyyy', 'id_ID').format(_date),
                        ),
                        readOnly: true,
                        decoration: InputDecoration(
                          filled: true, fillColor: Color(0xFFF4F4F7),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(9), borderSide: BorderSide(color: Color(0xFFF0F0F0))),
                          suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF3F7DF4), size: 22),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        style: const TextStyle(fontSize: 14.6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  // Lampiran
                  const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                  const SizedBox(height: 7),
                  TextFormField(
                    controller: _descCtrl,
                    validator: (v) => v == null || v.isEmpty ? 'Wajib diisi' : null,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Deskripsi',
                      filled: true, fillColor: Color(0xFFF4F4F7),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Color(0xFFF0F0F0))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Anda dapat mengunggah maksimal 5 file dan harus berformat PDF, JPG, PNG, XLSX, DOCX, DOC, TXT, PPT, maksimum 10MB',
                    style: TextStyle(fontSize: 11.5, color: darkGrey, height: 1.3),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickFiles,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 47, height: 47,
                      decoration: BoxDecoration(
                        color: Colors.white, border: Border.all(color: Color(0xFFD1D5DB), style: BorderStyle.solid, width: 1.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.add, color: Color(0xFF0C75BA), size: 32),
                    ),
                  ),
                  if (_files.isNotEmpty) ...[
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 7, runSpacing: 7,
                      children: _files.map((file) {
                        return Chip(
                          label: Text(file.name, style: TextStyle(fontSize: 12, color: Colors.black)),
                          backgroundColor: lightBlue,
                          deleteIcon: Icon(Icons.close, size: 16, color: Colors.red),
                          onDeleted: () { setState(() => _files.remove(file)); },
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 19),
                  // Item benefit
                  Text('Item benefit', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5, color: primaryBlue)),
                  Text('Rincian benefit yang akan diajukan', style: TextStyle(color: Colors.black, fontSize: 12.2)),
                  SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _showAddItem,
                      icon: Icon(Icons.add, color: Colors.white),
                      label: Text(
                        "Tambahkan Item",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF0C75BA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_items.isNotEmpty) ...[
                    SizedBox(height: 13),
                    Column(
                      children: List.generate(_items.length, (i) {
                        final item = _items[i];
                        return Container(
                          margin: EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(color: Color(0xFFF8F8FA), border: Border.all(color: Color(0xFFE5E5EA)), borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            title: Text(item.name, style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black)),
                            subtitle: (item.notes != null && item.notes!.isNotEmpty)
                                ? Text(item.notes!, style: TextStyle(fontSize: 12, color: darkGrey))
                                : null,
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Rp${NumberFormat('#,###').format(item.amount)}', style: TextStyle(color: Color(0xFF0C75BA), fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red, size: 21),
                                  onPressed: () => setState(() => _items.removeAt(i)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                  const SizedBox(height: 7),
                  // Total pengajuan & tombol Kirim
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Jumlah pengajuan', style: TextStyle(fontSize: 15, color: Colors.black, fontWeight: FontWeight.w700)),
                      Text('Rp${NumberFormat('#,###').format(_total)}',
                        style: const TextStyle(fontSize: 16.5, color: Color(0xFF0C75BA), fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : () async {
                        await _submit();
                        _fetchHistory();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF3A65FE),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                        minimumSize: Size(110, 46),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24, height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Kirim', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  //  ===== RIWAYAT PENGAJUAN (CARD), mirip gambar yang kamu kirim =====
                  SizedBox(height: 28),
                  Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    elevation: 0.5,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(15, 18, 15, 15),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Riwayat Pengajuan', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.7)),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              // Dropdown bulan/tahun
                              DropdownButton<int>(
                                value: _selectedMonth,
                                borderRadius: BorderRadius.circular(11),
                                onChanged: (v) {
                                  setState(() => _selectedMonth = v!);
                                  _fetchHistory();
                                },
                                items: List.generate(12, (i) => DropdownMenuItem(value: i+1, child: Text(months[i]))),
                              ),
                              SizedBox(width: 10),
                              DropdownButton<int>(
                                value: _selectedYear,
                                borderRadius: BorderRadius.circular(11),
                                onChanged: (v) {
                                  setState(() => _selectedYear = v!);
                                  _fetchHistory();
                                },
                                items: years.map((y) => DropdownMenuItem(value: y, child: Text(y.toString()))).toList(),
                              ),
                              Spacer(),
                              Text('${_history.length} item pengajuan', style: TextStyle(fontSize: 13.5, color: darkGrey, fontWeight: FontWeight.w500)),
                              SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  // TODO: fitur lihat semua (optional)
                                },
                                child: Text('Lihat semua', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.w600, fontSize: 13)),
                              ),
                            ],
                          ),
                          SizedBox(height: 13),
                          // isi riwayat pengajuan
                          ..._history.map((item) => Container(
                            margin: EdgeInsets.only(bottom: 13),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                            decoration: BoxDecoration(
                              color: Color(0xFFF7F8FA),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: Colors.grey.shade300, width: 1.1),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.description, color: primaryBlue, size: 29),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(DateFormat('dd MMMM yyyy', 'id_ID').format(item.startDate),
                                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                                      SizedBox(height: 3),
                                      Text(item.refCode, style: TextStyle(color: darkGrey, fontSize: 12.2)),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0).format(item.amount),
                                      style: TextStyle(fontWeight: FontWeight.w600, color: Colors.black, fontSize: 15.2),
                                    ),
                                    SizedBox(height: 5),
                                    _buildStatusBadge(item.status),
                                    SizedBox(height: 3),
                                    GestureDetector(
                                      onTap: () {
                                        // TODO: Lihat detail (optional, bisa buat dialog/konten detail)
                                      },
                                      child: Text("Lihat Detail", style: TextStyle(color: primaryBlue, fontSize: 12.7, fontWeight: FontWeight.w500)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )),
                          if (_history.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              child: Text('Belum ada pengajuan bulan ini', style: TextStyle(color: darkGrey, fontSize: 13)),
                            )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Badge status untuk pengajuan
  Widget _buildStatusBadge(String status) {
    Color color;
    String text = status;
    switch (status.toLowerCase()) {
      case 'disetujui':
        color = Colors.green;
        text = 'Disetujui';
        break;
      case 'ditolak':
        color = Colors.red;
        text = 'Ditolak';
        break;
      case 'menunggu':
        color = Colors.orange;
        text = 'Menunggu';
        break;
      default:
        color = Colors.grey;
        break;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(text, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.8, color: color)),
    );
  }
}

// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:file_picker/file_picker.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import 'package:http/http.dart' as http;

// /// ================= CONFIG CLOUDINARY =================
// const String cloudinaryUploadPreset = "facesign_unsigned";

// const primaryBlue = Color(0xFF3F7DF4);
// const lightGrey = Color(0xFFF7F8FA);
// const darkGrey = Color(0xFF8E8E93);
// const lightBlue = Color(0xFFE8F4FD);

// class ReimbursementRequest {
//   final String id;
//   final String description;
//   final String policy;
//   final DateTime startDate;
//   final double amount;
//   final DateTime createdAt;

//   ReimbursementRequest({
//     required this.id,
//     required this.description,
//     required this.policy,
//     required this.startDate,
//     required this.amount,
//     required this.createdAt,
//   });

//   factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
//     return ReimbursementRequest(
//       id: id,
//       description: map['description'] ?? '',
//       policy: map['policy'] ?? '',
//       startDate: (map['startDate'] as Timestamp).toDate(),
//       amount: (map['amount'] as num).toDouble(),
//       createdAt: (map['createdAt'] as Timestamp).toDate(),
//     );
//   }
// }

// class _BenefitItem {
//   String name;
//   int amount;
//   String? notes;
//   _BenefitItem(this.name, this.amount, {this.notes});
// }

// class ReimbursementFormPage extends StatefulWidget {
//   const ReimbursementFormPage({super.key});

//   @override
//   State<ReimbursementFormPage> createState() => _ReimbursementFormPageState();
// }

// class _ReimbursementFormPageState extends State<ReimbursementFormPage> {
//   final _formKey = GlobalKey<FormState>();
//   final TextEditingController _descCtrl = TextEditingController();
//   final TextEditingController _policyCtrl = TextEditingController();

//   DateTime _date = DateTime.now();
//   bool _loading = false;
//   final List<PlatformFile> _files = [];
//   final List<_BenefitItem> _items = [];
//   int get _total => _items.fold(0, (s, e) => s + e.amount);

//   // NEW: List local untuk menampung riwayat pengajuan selama di form ini
//   List<ReimbursementRequest> _submittedHistory = [];

//   /// PICK FILE
//   Future<void> _pickFiles() async {
//     final result = await FilePicker.platform.pickFiles(
//       allowMultiple: true,
//       withData: true,
//       allowedExtensions: [
//         'pdf',
//         'jpg',
//         'png',
//         'xlsx',
//         'docx',
//         'doc',
//         'txt',
//         'ppt',
//       ],
//       type: FileType.custom,
//     );
//     if (result != null) {
//       setState(() {
//         if (_files.length + result.files.length > 5) {
//           ScaffoldMessenger.of(
//             context,
//           ).showSnackBar(SnackBar(content: Text('Maksimal 5 file')));
//         } else {
//           _files.addAll(
//             result.files.where(
//               (f) => f.bytes != null && f.size <= 10 * 1024 * 1024,
//             ),
//           );
//         }
//       });
//     }
//   }

//   /// UPLOAD CLOUDINARY
//   Future<List<String>> _uploadFiles() async {
//     List<String> urls = [];
//     for (final file in _files) {
//       final uri = Uri.parse(
//         "https://api.cloudinary.com/v1_1/dv8zwl76d/auto/upload",
//       );
//       final request = http.MultipartRequest('POST', uri)
//         ..fields['upload_preset'] = cloudinaryUploadPreset
//         ..files.add(
//           http.MultipartFile.fromBytes(
//             'file',
//             file.bytes!,
//             filename: file.name,
//           ),
//         );
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

//   /// RESET FORM
//   void _resetForm() {
//     _policyCtrl.clear();
//     _descCtrl.clear();
//     setState(() {
//       _date = DateTime.now();
//       _items.clear();
//       _files.clear();
//     });
//   }

//   /// SUBMIT
//   Future<void> _submit() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_items.isEmpty) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text('Tambahkan item benefit')));
//       return;
//     }
//     setState(() => _loading = true);
//     try {
//       final user = FirebaseAuth.instance.currentUser;
//       String employeeName = 'User';
//       if (user != null) {
//         // Ambil nama dari Firestore users collection (misal: 'users' dengan docId = uid)
//         final userDoc = await FirebaseFirestore.instance
//             .collection('users')
//             .doc(user.uid)
//             .get();
//         if (userDoc.exists &&
//             userDoc.data() != null &&
//             userDoc.data()!.containsKey('name')) {
//           employeeName = userDoc['name'] ?? 'User';
//         } else if (user.displayName != null && user.displayName!.isNotEmpty) {
//           employeeName = user.displayName!;
//         }
//       }
//       final urls = await _uploadFiles();
//       final docRef = await FirebaseFirestore.instance
//           .collection('reimbursement_requests')
//           .add({
//             'employeeId': user?.uid ?? 'anon',
//             'employeeName': employeeName,
//             'description': _descCtrl.text.trim(),
//             'policy': _policyCtrl.text.trim(),
//             'startDate': _date,
//             'amount': _total.toDouble(),
//             'attachmentUrls': urls,
//             'createdAt': DateTime.now(),
//           });
//       // Fetch doc just created, then add to _submittedHistory show below
//       final doc = await docRef.get();
//       final newReq = ReimbursementRequest.fromMap(
//         doc.data() as Map<String, dynamic>,
//         doc.id,
//       );
//       setState(() {
//         _submittedHistory.insert(0, newReq); // insert paling atas
//       });
//       _resetForm();
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Pengajuan berhasil!'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     } catch (e) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text('Error: $e')));
//     }
//     setState(() => _loading = false);
//   }

//   void _showAddItem() {
//     final _nCtrl = TextEditingController();
//     final _nomCtrl = TextEditingController();
//     final _notesCtrl = TextEditingController();
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
//       ),
//       builder: (_) {
//         return Padding(
//           padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom,
//             left: 16,
//             right: 16,
//             top: 22,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Container(
//                 width: 38,
//                 height: 4,
//                 margin: EdgeInsets.only(bottom: 10),
//                 decoration: BoxDecoration(
//                   color: Colors.grey[300],
//                   borderRadius: BorderRadius.circular(2),
//                 ),
//               ),
//               const Text(
//                 "Tambah Item",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: 16,
//                   color: Color(0xFF0C75BA),
//                 ),
//               ),
//               const SizedBox(height: 10),
//               TextField(
//                 controller: _nCtrl,
//                 decoration: InputDecoration(
//                   hintText: "Nama item",
//                   filled: true,
//                   fillColor: lightGrey,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(7),
//                     borderSide: BorderSide(color: Color(0xFFE5E5EA)),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 13,
//                     vertical: 9,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 7),
//               TextField(
//                 controller: _nomCtrl,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   hintText: "Nominal",
//                   prefixText: "Rp ",
//                   filled: true,
//                   fillColor: lightGrey,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(7),
//                     borderSide: BorderSide(color: Color(0xFFE5E5EA)),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 13,
//                     vertical: 9,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 7),
//               TextField(
//                 controller: _notesCtrl,
//                 decoration: InputDecoration(
//                   hintText: "Catatan singkat (opsional)",
//                   filled: true,
//                   fillColor: lightGrey,
//                   border: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(7),
//                     borderSide: BorderSide(color: Color(0xFFE5E5EA)),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(
//                     horizontal: 13,
//                     vertical: 9,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 17),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: Color(0xFF3F7DF4),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(11),
//                     ),
//                     padding: const EdgeInsets.symmetric(vertical: 13),
//                   ),
//                   onPressed: () {
//                     String name = _nCtrl.text.trim();
//                     int amount =
//                         int.tryParse(
//                           _nomCtrl.text.replaceAll('.', '').replaceAll(',', ''),
//                         ) ??
//                         0;
//                     setState(() {
//                       if (name.isNotEmpty && amount > 0) {
//                         _items.add(
//                           _BenefitItem(
//                             name,
//                             amount,
//                             notes: _notesCtrl.text.trim(),
//                           ),
//                         );
//                       }
//                     });
//                     Navigator.pop(context);
//                   },
//                   child: const Text(
//                     'Simpan',
//                     style: TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: lightGrey,
//       appBar: AppBar(
//         backgroundColor: Color(0xFF0C75BA),
//         elevation: 0,
//         iconTheme: IconThemeData(color: Colors.white),
//         title: const Text(
//           'Pengajuan Reimbursement',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//             fontSize: 21,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Form(
//         key: _formKey,
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(13, 16, 13, 18),
//           children: [
//             // FORM KONTEN
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(18),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Kebijakan reimbursement dropdown
//                   const Text(
//                     'Kebijakan reimbursement *',
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.black,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 7),
//                   DropdownButtonFormField<String>(
//                     hint: const Text('Standar Reimbursement'),
//                     decoration: InputDecoration(
//                       filled: true,
//                       fillColor: Color(0xFFF4F4F7),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(9),
//                         borderSide: BorderSide(color: Color(0xFFF0F0F0)),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 14,
//                         vertical: 12,
//                       ),
//                     ),
//                     value: _policyCtrl.text != '' ? _policyCtrl.text : null,
//                     items:
//                         [
//                               'Standar Reimbursement',
//                               'Reimbursement Transport',
//                               'Reimbursement Konsumsi',
//                             ]
//                             .map(
//                               (v) => DropdownMenuItem(value: v, child: Text(v)),
//                             )
//                             .toList(),
//                     onChanged: (v) =>
//                         setState(() => _policyCtrl.text = v ?? ''),
//                     validator: (v) =>
//                         (v == null || v.isEmpty) ? 'Wajib dipilih' : null,
//                   ),
//                   const SizedBox(height: 17),
//                   // Tanggal transaksi
//                   const Text(
//                     'Tanggal transaksi *',
//                     style: TextStyle(
//                       fontSize: 15,
//                       color: Colors.black,
//                       fontWeight: FontWeight.w700,
//                     ),
//                   ),
//                   const SizedBox(height: 7),
//                   GestureDetector(
//                     onTap: () async {
//                       final picked = await showDatePicker(
//                         context: context,
//                         initialDate: _date,
//                         firstDate: DateTime(2020),
//                         lastDate: DateTime(2030),
//                       );
//                       if (picked != null) setState(() => _date = picked);
//                     },
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         controller: TextEditingController(
//                           text: DateFormat(
//                             'dd MMMM yyyy',
//                             'id_ID',
//                           ).format(_date),
//                         ),
//                         readOnly: true,
//                         decoration: InputDecoration(
//                           filled: true,
//                           fillColor: Color(0xFFF4F4F7),
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(9),
//                             borderSide: BorderSide(color: Color(0xFFF0F0F0)),
//                           ),
//                           suffixIcon: const Icon(
//                             Icons.calendar_today,
//                             color: Color(0xFF3F7DF4),
//                             size: 22,
//                           ),
//                           contentPadding: const EdgeInsets.symmetric(
//                             horizontal: 14,
//                             vertical: 14,
//                           ),
//                         ),
//                         style: const TextStyle(fontSize: 14.6),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 18),
//                   // Lampiran
//                   const Text(
//                     'Lampiran',
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 15,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const SizedBox(height: 7),
//                   TextFormField(
//                     controller: _descCtrl,
//                     validator: (v) =>
//                         v == null || v.isEmpty ? 'Wajib diisi' : null,
//                     maxLines: 3,
//                     decoration: InputDecoration(
//                       hintText: 'Deskripsi',
//                       filled: true,
//                       fillColor: Color(0xFFF4F4F7),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(8),
//                         borderSide: BorderSide(color: Color(0xFFF0F0F0)),
//                       ),
//                       contentPadding: const EdgeInsets.all(12),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   Text(
//                     'Anda dapat mengunggah maksimal 5 file dan harus berformat PDF, JPG, PNG, XLSX, DOCX, DOC, TXT, PPT, maksimum 10MB',
//                     style: TextStyle(
//                       fontSize: 11.5,
//                       color: darkGrey,
//                       height: 1.3,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   InkWell(
//                     onTap: _pickFiles,
//                     borderRadius: BorderRadius.circular(8),
//                     child: Container(
//                       width: 47,
//                       height: 47,
//                       decoration: BoxDecoration(
//                         color: Colors.white,
//                         border: Border.all(
//                           color: Color(0xFFD1D5DB),
//                           style: BorderStyle.solid,
//                           width: 1.1,
//                         ),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Icon(
//                         Icons.add,
//                         color: Color(0xFF0C75BA),
//                         size: 32,
//                       ),
//                     ),
//                   ),
//                   if (_files.isNotEmpty) ...[
//                     SizedBox(height: 12),
//                     Wrap(
//                       spacing: 7,
//                       runSpacing: 7,
//                       children: _files.map((file) {
//                         return Chip(
//                           label: Text(
//                             file.name,
//                             style: TextStyle(fontSize: 12, color: Colors.black),
//                           ),
//                           backgroundColor: lightBlue,
//                           deleteIcon: Icon(
//                             Icons.close,
//                             size: 16,
//                             color: Colors.red,
//                           ),
//                           onDeleted: () {
//                             setState(() => _files.remove(file));
//                           },
//                         );
//                       }).toList(),
//                     ),
//                   ],
//                   const SizedBox(height: 19),
//                   // Item benefit
//                   Text(
//                     'Item benefit',
//                     style: TextStyle(
//                       fontWeight: FontWeight.w700,
//                       fontSize: 14.5,
//                       color: primaryBlue,
//                     ),
//                   ),
//                   Text(
//                     'Rincian benefit yang akan diajukan',
//                     style: TextStyle(color: Colors.black, fontSize: 12.2),
//                   ),
//                   SizedBox(height: 12),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton.icon(
//                       onPressed: _showAddItem,
//                       icon: Icon(Icons.add, color: Colors.white),
//                       label: Text(
//                         "Tambahkan Item",
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontWeight: FontWeight.bold,
//                           fontSize: 15,
//                         ),
//                       ),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF0C75BA),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         padding: EdgeInsets.symmetric(vertical: 14),
//                       ),
//                     ),
//                   ),
//                   if (_items.isNotEmpty) ...[
//                     SizedBox(height: 13),
//                     Column(
//                       children: List.generate(_items.length, (i) {
//                         final item = _items[i];
//                         return Container(
//                           margin: EdgeInsets.only(bottom: 10),
//                           decoration: BoxDecoration(
//                             color: Color(0xFFF8F8FA),
//                             border: Border.all(color: Color(0xFFE5E5EA)),
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: ListTile(
//                             title: Text(
//                               item.name,
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w600,
//                                 color: Colors.black,
//                               ),
//                             ),
//                             subtitle:
//                                 (item.notes != null && item.notes!.isNotEmpty)
//                                 ? Text(
//                                     item.notes!,
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       color: darkGrey,
//                                     ),
//                                   )
//                                 : null,
//                             trailing: Row(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Text(
//                                   'Rp${NumberFormat('#,###').format(item.amount)}',
//                                   style: TextStyle(
//                                     color: Color(0xFF0C75BA),
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                                 IconButton(
//                                   icon: Icon(
//                                     Icons.delete,
//                                     color: Colors.red,
//                                     size: 21,
//                                   ),
//                                   onPressed: () =>
//                                       setState(() => _items.removeAt(i)),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         );
//                       }),
//                     ),
//                   ],
//                   const SizedBox(height: 7),
//                   // Total pengajuan & tombol Kirim
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       const Text(
//                         'Total Jumlah pengajuan',
//                         style: TextStyle(
//                           fontSize: 15,
//                           color: Colors.black,
//                           fontWeight: FontWeight.w700,
//                         ),
//                       ),
//                       Text(
//                         'Rp${NumberFormat('#,###').format(_total)}',
//                         style: const TextStyle(
//                           fontSize: 16.5,
//                           color: Color(0xFF0C75BA),
//                           fontWeight: FontWeight.bold,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 15),
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       onPressed: _loading ? null : _submit,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Color(0xFF3A65FE),
//                         padding: const EdgeInsets.symmetric(vertical: 15),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(11),
//                         ),
//                         minimumSize: Size(110, 46),
//                       ),
//                       child: _loading
//                           ? const SizedBox(
//                               width: 24,
//                               height: 24,
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: Colors.white,
//                               ),
//                             )
//                           : const Text(
//                               'Kirim',
//                               style: TextStyle(
//                                 fontSize: 15.5,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.white,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             // === RIWAYAT ===
//             if (_submittedHistory.isNotEmpty) ...[
//               SizedBox(height: 20),
//               Text(
//                 'Riwayat Pengajuan Terbaru',
//                 style: TextStyle(
//                   color: primaryBlue,
//                   fontWeight: FontWeight.bold,
//                   fontSize: 15,
//                 ),
//               ),
//               Column(
//                 children: _submittedHistory.map((item) {
//                   return Container(
//                     margin: EdgeInsets.only(top: 11),
//                     padding: EdgeInsets.symmetric(horizontal: 16, vertical: 13),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(13),
//                       boxShadow: [
//                         BoxShadow(
//                           color: Colors.black.withOpacity(0.01),
//                           blurRadius: 2,
//                         ),
//                       ],
//                     ),
//                     child: Row(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Icon(Icons.receipt_long, color: primaryBlue),
//                         SizedBox(width: 8),
//                         Expanded(
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 item.description,
//                                 style: TextStyle(
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                               SizedBox(height: 2),
//                               Text(
//                                 DateFormat(
//                                   'dd MMM yyyy',
//                                   'id_ID',
//                                 ).format(item.startDate),
//                                 style: TextStyle(
//                                   fontSize: 13,
//                                   color: Colors.black,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Text(
//                           NumberFormat.currency(
//                             locale: 'id_ID',
//                             symbol: 'Rp',
//                             decimalDigits: 0,
//                           ).format(item.amount),
//                           style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: Colors.black,
//                           ),
//                         ),
//                       ],
//                     ),
//                   );
//                 }).toList(),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
