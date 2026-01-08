import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';

import '../../models/reimbursement_request.dart';
import '../../services/api_service.dart';

// --- WARNA & TEMA KONSISTEN ---
const primaryBlue = Color(0xFF242484);
const lightGrey = Color(0xFFEFEFF2);
const darkGrey = Color(0xFFC7C7C7);

// --- PAGE 1: REIMBURSEMENT LIST PAGE ---
class ReimbursementListPage extends StatefulWidget {
  const ReimbursementListPage({super.key});

  @override
  State<ReimbursementListPage> createState() => _ReimbursementListPageState();
}

class _ReimbursementListPageState extends State<ReimbursementListPage> {
  DateTime selectedMonth = DateTime.now();

  // Stream reimbuse dari Firestore (koleksi konsisten dengan service)
  Stream<List<ReimbursementRequest>> _reimburseStream() {
    return FirebaseFirestore.instance
        .collection('reimbursement_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              try {
                return ReimbursementRequest.fromMap(data, doc.id);
              } catch (_) {
                // Skip dokumen yang tidak sesuai skema
                return null;
              }
            }).whereType<ReimbursementRequest>().toList());
  }

  // Setelah submit pengajuan, refresh dengan reload (stream akan rebuild)
  void goToPengajuanForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ReimbursementFormPage()),
    );
    if (result == true) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildReimburseAppBar(context, 'Reimbursement'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // --- Saldo Saya ---
          Container(
            margin: const EdgeInsets.fromLTRB(22, 14, 22, 8),
            decoration: BoxDecoration(
              color: darkGrey,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 18, top: 16, bottom: 0),
                  child: Text(
                    'Saldo Saya',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  alignment: Alignment.center,
                  margin: const EdgeInsets.all(18),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.receipt_long_rounded, size: 64, color: primaryBlue),
                      SizedBox(height: 13),
                      Text('Tidak ada kebijakan yang dibuat',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: primaryBlue)),
                      SizedBox(height: 7),
                      Text('Kebijakan reimburse akan muncul jika\nAnda telah membuatnya.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.black54, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // --- Riwayat (Filter by bulan tahun & list minimalis modern) ---
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryBlue,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, color: primaryBlue),
                      const SizedBox(width: 8),
                      // Dropdown bulan/tahun
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showMonthYearPicker(context, selectedMonth);
                            if (picked != null) {
                              setState(() => selectedMonth = picked);
                            }
                          },
                          child: Row(
                            children: [
                              Text(
                                DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth),
                                style: const TextStyle(
                                    color: primaryBlue,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18),
                              ),
                              const Icon(Icons.keyboard_arrow_down, color: primaryBlue)
                            ],
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: lightGrey,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.filter_list_rounded,
                              color: primaryBlue, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // --- StreamBuilder untuk realtime riwayat pengajuan ---
                StreamBuilder<List<ReimbursementRequest>>(
                  stream: _reimburseStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: Text('Error database', style: TextStyle(color: Colors.red))));
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: CircularProgressIndicator()),
                      );
                    }
                    final all = snapshot.data ?? [];
                    final docs = all.where((r) => r.createdAt.month == selectedMonth.month && r.createdAt.year == selectedMonth.year).toList();
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32, horizontal: 18),
                        child: Column(
                          children: [
                            Icon(Icons.folder_open, size: 96, color: primaryBlue),
                            SizedBox(height: 22),
                            Text('Tidak ada pengajuan',
                                style: TextStyle(
                                  color: primaryBlue,
                                  fontSize: 19,
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(height: 9),
                            Text('Anda dapat mengajukan reimburse melalui\n tombol dibawah ini.',
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                ),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    }
                    // --- Jika ada data, show list ---
                    return Column(
                      children: docs.map((r) {
                        return ListTile(
                          leading: const Icon(Icons.assignment, color: primaryBlue, size: 30),
                          title: Text(
                            r.description.isNotEmpty ? r.description : '(Tanpa deskripsi)',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                          subtitle: Text(
                            DateFormat('dd MMM yyyy','id_ID').format(r.startDate),
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          trailing: Text(
                            NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0)
                                .format(r.amount),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                // Tombol Ajukan Reimburse (fixed bottom pada card)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // biru cerah
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: goToPengajuanForm,
                      child: const Text('Ajukan reimburse',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- APPBAR CUSTOM REUSE ---
AppBar buildReimburseAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.white,
    elevation: 0,
    leading: Padding(
      padding: const EdgeInsets.only(left: 8),
      child: IconButton(
        icon: const Icon(Icons.arrow_back, color: primaryBlue, size: 32),
        onPressed: () => Navigator.pop(context),
      ),
    ),
    centerTitle: true,
    title: Text(
      title,
      style: const TextStyle(
        color: primaryBlue,
        fontWeight: FontWeight.w700,
        fontSize: 25,
      ),
    ),
  );
}

// --- Month/Year picker dialog ---
Future<DateTime?> showMonthYearPicker(BuildContext context, DateTime initial) async {
  DateTime picked = initial;
  return await showDialog<DateTime>(
    context: context,
    builder: (ctx) {
      int tmpMonth = picked.month;
      int tmpYear = picked.year;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Pilih Bulan & Tahun'),
            content: Row(
              children: [
                Expanded(child: DropdownButton<int>(
                  value: tmpMonth,
                  items: List.generate(12, (i) => DropdownMenuItem(
                    value: i+1,
                    child: Text(DateFormat('MMMM','id_ID').format(DateTime(0,i+1))),
                  )),
                  onChanged: (val) => setState(() => tmpMonth = val!),
                )),
                Expanded(child: DropdownButton<int>(
                  value: tmpYear,
                  items: List.generate(6, (i) => DropdownMenuItem(
                    value: DateTime.now().year-2+i,
                    child: Text('${DateTime.now().year-2+i}'),
                  )),
                  onChanged: (val) => setState(() => tmpYear = val!),
                )),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, DateTime(tmpYear, tmpMonth)),
                  style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                  child: const Text('Pilih', style: TextStyle(color: Colors.white))),
            ],
          );
        },
      );
    },
  );
}

// --- PAGE 2: FORM PENGAJUAN REIMBURSE ---
// File item list model
class BenefitItem {
  String name;
  int amount;
  BenefitItem(this.name, this.amount);
}

class ReimbursementFormPage extends StatefulWidget {
  const ReimbursementFormPage({super.key});
  @override
  State<ReimbursementFormPage> createState() => _ReimbursementFormPageState();
}

class _ReimbursementFormPageState extends State<ReimbursementFormPage> {
  String? selectedPolicy;
  DateTime? selectedDate = DateTime.now();
  List<PlatformFile> uploadedFiles = [];
  final TextEditingController descCtrl = TextEditingController();
  List<BenefitItem> items = [];
  int get total => items.fold(0, (sum, e) => sum + e.amount);

  Future<void> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'xlsx', 'xls', 'doc', 'docx', 'ppt', 'pptx', 'txt'],
      withData: true,
    );
    if (result != null) {
      if ((uploadedFiles.length + result.files.length) > 5) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Maksimal 5 file')));
        return;
      }
      setState(() {
        // filter file tanpa bytes (jaga-jaga)
        uploadedFiles.addAll(result.files.where((f) => f.bytes != null));
      });
    }
  }

  Future<List<String>> uploadFilesToFirebase() async {
    List<String> urls = [];
    for (var file in uploadedFiles) {
      try {
        final ref = FirebaseStorage.instance
            .ref('reimbursement_attachments/${DateTime.now().microsecondsSinceEpoch}_${file.name}');
        final task = await ref.putData(file.bytes!);
        final url = await task.ref.getDownloadURL();
        urls.add(url);
      } catch (e) {
        debugPrint('Upload gagal untuk ${file.name}: $e');
        rethrow;
      }
    }
    return urls;
  }

  String _composeDescription() {
    final policyText = selectedPolicy != null ? '[${selectedPolicy}] ' : '';
    final desc = descCtrl.text.trim();
    if (desc.isEmpty) return policyText.isEmpty ? '-' : policyText;
    return '$policyText$desc';
  }

  Future<bool> submitForm() async {
    if (selectedPolicy == null || selectedDate == null) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih kebijakan & tanggal')));
      return false;
    }
    try {
      // 1. Upload file jika ada
      final fileUrls = await uploadFilesToFirebase();

      // 2. Build model sesuai API/Service
      final user = FirebaseAuth.instance.currentUser;
      final request = ReimbursementRequest(
        employeeId: user?.uid ?? 'anonymous',
        employeeName: user?.displayName ?? user?.email ?? 'User',
        startDate: selectedDate!,
        endDate: selectedDate!,
        description: _composeDescription(),
        amount: total.toDouble(),
        attachmentUrls: fileUrls,
        createdAt: DateTime.now(),
      );

      // 3. Simpan via API (ke koleksi reimbursement_requests)
      await ApiService.instance.createReimbursement(request);
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengirim: $e')),
      );
      return false;
    }
  }

  void showBenefitItemDialog() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tambah Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(hintText: 'Nama Item')),
            TextField(controller: amtCtrl, decoration: const InputDecoration(hintText: 'Nominal (Rp)'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              if (nameCtrl.text.isEmpty || amtCtrl.text.isEmpty) return;
              setState(() {
                items.add(BenefitItem(nameCtrl.text, int.tryParse(amtCtrl.text.replaceAll('.', '')) ?? 0));
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            child: const Text('OK', style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: buildReimburseAppBar(context, 'Pengajuan Reimbursement'),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // SECTION ATAS: Form Utama
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            padding: const EdgeInsets.only(top: 12, bottom: 18, left: 18, right: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: primaryBlue),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dropdown kebijakan reimbursement
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: darkGrey,
                    border: InputBorder.none,
                    labelText: 'Kebijakan reimbursement *',
                    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black),
                  ),
                  dropdownColor: Colors.white,
                  items: const [
                    DropdownMenuItem(value: 'Kesehatan', child: Text('Kesehatan')),
                    DropdownMenuItem(value: 'Perjalanan', child: Text('Perjalanan')),
                  ],
                  onChanged: (v) => setState(() => selectedPolicy = v),
                  value: selectedPolicy,
                ),
                const SizedBox(height: 14),
                // Tanggal transaksi
                const Text('Tanggal transaksi *', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                const SizedBox(height: 3),
                InkWell(
                  onTap: () async {
                    final result = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime(DateTime.now().year + 2),
                    );
                    if (result != null) setState(() => selectedDate = result);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yyyy', 'id_ID').format(selectedDate ?? DateTime.now()),
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15, color: Colors.black)),
                      ),
                      const Icon(Icons.calendar_month_rounded, color: primaryBlue)
                    ],
                  ),
                ),
                const Divider(height: 22, thickness: 1),
                const SizedBox(height: 5),
                // Lampiran File
                const Text('Lampiran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    for (var file in uploadedFiles)
                      Chip(
                        label: Text(file.name, style: const TextStyle(color: Colors.black)),
                        deleteIcon: const Icon(Icons.close, color: Colors.redAccent),
                        onDeleted: () => setState(() => uploadedFiles.remove(file)),
                        backgroundColor: lightGrey,
                      ),
                    GestureDetector(
                      onTap: pickFiles,
                      child: DottedBorder(
                        color: primaryBlue,
                        strokeWidth: 1.7,
                        dashPattern: const [3, 6],
                        borderType: BorderType.RRect,
                        radius: const Radius.circular(9),
                        child: Container(
                          width: 56,
                          height: 56,
                          color: lightGrey,
                          child: const Icon(Icons.add, color: primaryBlue, size: 32),
                        ),
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Anda dapat mengunggah maksimal 5 file, dan harus berformat PDF, JPG, PNG, XLSX, XLS, JPEG, DOCX, DOC, TXT, PPT, dan PPTX maksimum 10MB',
                    style: TextStyle(color: Colors.black54, fontSize: 11),
                  ),
                ),
                // Deskripsi
                TextField(
                  controller: descCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Deskripsi',
                    border: UnderlineInputBorder(),
                  ),
                  style: const TextStyle(color: Colors.black),
                ),
              ],
            ),
          ),

          // SECTION BAWAH: Item Benefit dan Total
          Container(
            margin: const EdgeInsets.only(left:8, right:8, top: 0, bottom: 18),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            decoration: BoxDecoration(
              color: darkGrey.withOpacity(0.18),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Item benefit', style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text('Tambahkan rincian benefit yang akan diajukan.', style: TextStyle(color: Colors.black)),
                const SizedBox(height: 10),
                if (items.isNotEmpty)
                  ...items.map((e) => ListTile(
                        title: Text(e.name, style: const TextStyle(color: Colors.black)),
                        trailing: Text(NumberFormat.currency(locale: 'id_ID', symbol: 'Rp.', decimalDigits: 0).format(e.amount), style: const TextStyle(color: Colors.black)),
                        leading: const Icon(Icons.add_box, color: primaryBlue),
                        dense: true,
                        minLeadingWidth: 0,
                        minVerticalPadding: 0,
                      )),
                const SizedBox(height: 2),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: showBenefitItemDialog,
                    child: const Text('+ tambahkan item',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const Divider(),
                // Total Ajukan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total jumlah pengajuan', style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.bold)),
                    Text('Rp.${NumberFormat('#,##0', 'id_ID').format(total)}', style: const TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.w500)),
                  ],
                ),
                const SizedBox(height: 15),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 15)),
                    onPressed: () async {
                      if (await submitForm()) {
                        if (!mounted) return;
                        // Pop ke halaman list dengan result true
                        Navigator.pop(context, true);
                      }
                    },
                    child: const Text('Kirim',
                        style: TextStyle(
                            fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
