import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';

// --- TEMA ---
const primaryBlue = Color(0xFF242484);
const lightGrey = Color(0xFFEFEFF2);
const darkGrey = Color(0xFFC7C7C7);

// ROOT APP + LOCALIZATION MAT_SETTINGS

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Reimbursement Modern',
      // Fix untuk datePicker locale error:
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      home: const ReimbursementListPage(),
    );
  }
}

// PAGE 1: DAFTAR REIMBURSEMENT
class ReimbursementListPage extends StatefulWidget {
  const ReimbursementListPage({super.key});
  @override
  State<ReimbursementListPage> createState() => _ReimbursementListPageState();
}

class _ReimbursementListPageState extends State<ReimbursementListPage> {
  DateTime selectedMonth = DateTime.now();

  // Model dummy pengajuan; GANTI dengan modelmu bila perlu
  Stream<List<ReimbursementRequest>> _reimburseStream() {
    return FirebaseFirestore.instance
        .collection('reimbursement_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((doc) {
                try {
                  return ReimbursementRequest.fromMap(doc.data(), doc.id);
                } catch (_) {
                  return null;
                }
              })
              .whereType<ReimbursementRequest>()
              .toList(),
        );
  }

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
          // SALDO SAYA
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
                      Icon(
                        Icons.receipt_long_rounded,
                        size: 64,
                        color: primaryBlue,
                      ),
                      SizedBox(height: 13),
                      Text(
                        'Tidak ada kebijakan yang dibuat',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: primaryBlue,
                        ),
                      ),
                      SizedBox(height: 7),
                      Text(
                        'Kebijakan reimburse akan muncul jika\nAnda telah membuatnya.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // RIWAYAT pengajuan
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: primaryBlue, width: 2),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        color: primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      // Dropdown bulan/tahun
                      Expanded(
                        child: InkWell(
                          onTap: () async {
                            final picked = await showMonthYearPicker(
                              context,
                              selectedMonth,
                            );
                            if (picked != null)
                              setState(() => selectedMonth = picked);
                          },
                          child: Row(
                            children: [
                              Text(
                                DateFormat(
                                  'MMMM yyyy',
                                  'id_ID',
                                ).format(selectedMonth),
                                style: const TextStyle(
                                  color: primaryBlue,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const Icon(
                                Icons.keyboard_arrow_down,
                                color: primaryBlue,
                              ),
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
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: primaryBlue,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                StreamBuilder<List<ReimbursementRequest>>(
                  stream: _reimburseStream(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Error database',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      );
                    }
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: CircularProgressIndicator(),
                        ),
                      );
                    }
                    final all = snapshot.data ?? [];
                    final docs = all
                        .where(
                          (r) =>
                              r.createdAt.month == selectedMonth.month &&
                              r.createdAt.year == selectedMonth.year,
                        )
                        .toList();
                    if (docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: 32,
                          horizontal: 18,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.folder_open,
                              size: 96,
                              color: primaryBlue,
                            ),
                            SizedBox(height: 22),
                            Text(
                              'Tidak ada pengajuan',
                              style: TextStyle(
                                color: primaryBlue,
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 9),
                            Text(
                              'Anda dapat mengajukan reimburse melalui\n tombol dibawah ini.',
                              style: TextStyle(
                                color: Colors.black87,
                                fontSize: 15,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    }
                    return Column(
                      children: docs.map((r) {
                        return ListTile(
                          leading: const Icon(
                            Icons.assignment,
                            color: primaryBlue,
                            size: 30,
                          ),
                          title: Text(
                            r.description.isNotEmpty
                                ? r.description
                                : '(Tanpa deskripsi)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            DateFormat(
                              'dd MMM yyyy',
                              'id_ID',
                            ).format(r.startDate),
                            style: TextStyle(color: Colors.grey[800]),
                          ),
                          trailing: Text(
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp.',
                              decimalDigits: 0,
                            ).format(r.amount),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 26),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent, // biru cerah
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 18),
                      ),
                      onPressed: goToPengajuanForm,
                      child: const Text(
                        'Ajukan reimburse',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
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

// --- APPBAR MODERN REUSE ---
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

// --- Month/Year picker modern ---
Future<DateTime?> showMonthYearPicker(
  BuildContext context,
  DateTime initial,
) async {
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
                Expanded(
                  child: DropdownButton<int>(
                    value: tmpMonth,
                    items: List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          DateFormat(
                            'MMMM',
                            'id_ID',
                          ).format(DateTime(0, i + 1)),
                        ),
                      ),
                    ),
                    onChanged: (val) => setState(() => tmpMonth = val!),
                  ),
                ),
                Expanded(
                  child: DropdownButton<int>(
                    value: tmpYear,
                    items: List.generate(
                      6,
                      (i) => DropdownMenuItem(
                        value: DateTime.now().year - 2 + i,
                        child: Text('${DateTime.now().year - 2 + i}'),
                      ),
                    ),
                    onChanged: (val) => setState(() => tmpYear = val!),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () =>
                    Navigator.pop(ctx, DateTime(tmpYear, tmpMonth)),
                style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
                child: const Text(
                  'Pilih',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

// ===================================================
// ================ FORM PAGE MODERN =================
// ===================================================
const _primaryBlue = Color(0xFF242484);
const _greyBg = Color(0xFFEFEFF2);

class ReimbursementFormPage extends StatefulWidget {
  const ReimbursementFormPage({super.key});
  @override
  State<ReimbursementFormPage> createState() => _ReimbursementFormPageState();
}

class _ReimbursementFormPageState extends State<ReimbursementFormPage> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedPolicy;
  DateTime _date = DateTime.now();
  final TextEditingController _descCtrl = TextEditingController();

  final List<PlatformFile> _files = [];
  final List<_BenefitItem> _items = [];
  bool _loading = false;

  int get _total => _items.fold(0, (sum, i) => sum + i.amount);

  // File picker
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: true,
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'ppt',
        'pptx',
        'txt',
      ],
    );
    if (result != null) {
      if (_files.length + result.files.length > 5) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Maksimal 5 file')));
        return;
      }
      setState(() {
        _files.addAll(result.files.where((f) => f.bytes != null));
      });
    }
  }

  // Upload ke Firebase Storage, return list URL
  Future<List<String>> _uploadFiles() async {
    List<String> urls = [];
    for (final f in _files) {
      final ref = FirebaseStorage.instance.ref(
        'lampiran_reimburse/${DateTime.now().microsecondsSinceEpoch}_${f.name}',
      );
      final upload = await ref.putData(f.bytes!);
      urls.add(await upload.ref.getDownloadURL());
    }
    return urls;
  }

  // Tambah item benefit
  void _addItemDialog() {
    final nameCtrl = TextEditingController();
    final amtCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tambah Item Benefit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Nama item'),
            ),
            TextField(
              controller: amtCtrl,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: _primaryBlue),
            onPressed: () {
              if (nameCtrl.text.isEmpty || amtCtrl.text.isEmpty) return;
              setState(() {
                _items.add(
                  _BenefitItem(
                    nameCtrl.text,
                    int.tryParse(amtCtrl.text.replaceAll('.', '')) ?? 0,
                  ),
                );
              });
              Navigator.pop(context);
            },
            child: const Text('Tambah', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showCustomDatePicker(BuildContext context) {
    DateTime tempDate = _date;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: StatefulBuilder(
          builder: (context, setStateDialog) => Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header dengan bulan dan tahun
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _primaryBlue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            tempDate = DateTime(
                              tempDate.year,
                              tempDate.month - 1,
                            );
                          });
                        },
                      ),
                      Text(
                        DateFormat(
                          'MMMM yyyy',
                          'id_ID',
                        ).format(tempDate).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.chevron_right,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setStateDialog(() {
                            tempDate = DateTime(
                              tempDate.year,
                              tempDate.month + 1,
                            );
                          });
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Days of week header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Min', 'Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab']
                      .map(
                        (day) => SizedBox(
                          width: 45,
                          child: Text(
                            day,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _primaryBlue,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 8),

                // Calendar grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: _getDaysInMonth(tempDate),
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final date = DateTime(tempDate.year, tempDate.month, day);
                    final isSelected = _isSameDay(date, tempDate);
                    final isCurrentDay = _isSameDay(date, DateTime.now());

                    return GestureDetector(
                      onTap: () {
                        setStateDialog(() {
                          tempDate = date;
                        });
                      },
                      child: Container(
                        margin: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _primaryBlue
                              : isCurrentDay
                              ? Colors.blue.withValues(alpha: 0.2)
                              : Colors.transparent,
                          border: isCurrentDay && !isSelected
                              ? Border.all(color: Colors.blue, width: 2)
                              : null,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          day.toString(),
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.black87,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryBlue,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _date = tempDate;
                        });
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Pilih',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tambahkan minimal 1 item benefit')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final lampiranUrls = await _uploadFiles();
      final now = DateTime.now();
      await FirebaseFirestore.instance.collection('reimbursement_requests').add(
        {
          'employeeId': currentUser?.uid ?? 'anon',
          'employeeName': currentUser?.displayName ?? 'User',
          'policy': _selectedPolicy,
          'startDate': _date,
          'endDate': _date,
          'description': _descCtrl.text.trim(),
          'amount': _total.toDouble(),
          'status': 'Proses',
          'attachmentUrls': lampiranUrls,
          'benefitItems': _items
              .map((e) => {'name': e.name, 'amount': e.amount})
              .toList(),
          'createdAt': now,
        },
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Pengajuan berhasil dikirim!')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Gagal mengirim: $e')));
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final hPad = 16.0;
    final tStyleTitle = const TextStyle(
      color: _primaryBlue,
      fontWeight: FontWeight.bold,
      fontSize: 19,
    );
    final tStyleHint = TextStyle(color: Colors.grey[700], fontSize: 13);
    final tStyleRow = const TextStyle(
      color: Colors.black87,
      fontWeight: FontWeight.bold,
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: _primaryBlue, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pengajuan Reimbursement',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _primaryBlue,
            fontSize: 22,
            fontFamily: 'Georgia',
            letterSpacing: 0.2,
          ),
        ),
      ),
      body: AbsorbPointer(
        absorbing: _loading,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: _primaryBlue, width: 1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Kebijakan
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        filled: true,
                        fillColor: _greyBg,
                        border: OutlineInputBorder(
                          borderSide: BorderSide.none,
                          borderRadius: BorderRadius.all(Radius.circular(5)),
                        ),
                        hintText: 'Kebijakan reimbursement *',
                        hintStyle: TextStyle(color: Colors.black54),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      validator: (v) => v == null ? 'Wajib dipilih' : null,
                      value: _selectedPolicy,
                      items: const [
                        DropdownMenuItem(
                          value: 'Kesehatan',
                          child: Text('Kesehatan'),
                        ),
                        DropdownMenuItem(
                          value: 'Perjalanan',
                          child: Text('Perjalanan'),
                        ),
                      ],
                      onChanged: (v) {
                        setState(() => _selectedPolicy = v);
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _showCustomDatePicker(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: _primaryBlue, width: 1.5),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Tanggal transaksi *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat(
                                    'dd MMMM yyyy',
                                    'id_ID',
                                  ).format(_date),
                                  style: const TextStyle(
                                    color: _primaryBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: _primaryBlue,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 22, thickness: 1),
                    const Text(
                      'Lampiran',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final f in _files)
                          Chip(
                            backgroundColor: _greyBg,
                            label: Text(
                              f.name,
                              style: const TextStyle(color: Colors.black),
                            ),
                            deleteIcon: const Icon(
                              Icons.close,
                              color: Colors.redAccent,
                            ),
                            onDeleted: () => setState(() => _files.remove(f)),
                          ),
                      //   GestureDetector(
                      //   onTap: _pickFiles,
                      //   child: DottedBorder(
                      //     strokeColor: _primaryBlue, // GUNAKAN strokeColor, BUKAN color
                      //     dashPattern: const [3, 6],
                      //     borderType: BorderType.RRect,
                      //     radius: const Radius.circular(8),
                      //     strokeWidth: 1.5,
                      //     child: Container(
                      //       width: 56,
                      //       height: 56,
                      //       color: _greyBg,
                      //       child: const Icon(
                      //         Icons.add,
                      //         size: 27,
                      //         color: _primaryBlue,
                      //       ),
                      //     ),
                      //   ),
                      // ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Anda dapat mengunggah maksimal 5 file, dan harus berformat PDF, JPG, PNG, XLSX, XLS, JPEG, DOCX, DOC, TXT, PPT, DAN PPTX maksimum 10MB',
                      style: TextStyle(color: Colors.black54, fontSize: 11),
                    ),
                    const SizedBox(height: 9),

                    // Deskripsi
                    TextFormField(
                      controller: _descCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Deskripsi',
                        border: UnderlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 10,
                        ),
                      ),
                      style: const TextStyle(color: Colors.black, fontSize: 15),
                    ),
                  ],
                ),
              ),
              // ITEM BENEFIT SECTION
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                padding: EdgeInsets.fromLTRB(hPad, 17, hPad, 23),
                decoration: BoxDecoration(
                  color: _greyBg.withOpacity(0.57),
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item benefit', style: tStyleTitle),
                    const SizedBox(height: 4),
                    Text(
                      'Tambahkan rincian benefit yang akan diajukan.',
                      style: tStyleHint,
                    ),
                    const SizedBox(height: 9),
                    if (_items.isNotEmpty)
                      Column(
                        children: [
                          ..._items.map(
                            (e) => ListTile(
                              dense: true,
                              visualDensity: VisualDensity(vertical: -3),
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.more_horiz,
                                color: _primaryBlue,
                              ),
                              title: Text(
                                e.name,
                                style: const TextStyle(color: Colors.black),
                              ),
                              trailing: Text(
                                NumberFormat.currency(
                                  locale: 'id_ID',
                                  symbol: 'Rp.',
                                  decimalDigits: 0,
                                ).format(e.amount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                        ],
                      ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(9),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _addItemDialog,
                        child: const Text(
                          '+ tambahkan item',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total jumlah pengajuan',
                          style: tStyleRow.copyWith(
                            color: Colors.black54,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          'Rp.${NumberFormat('#,##0', 'id_ID').format(_total)}',
                          style: tStyleRow.copyWith(fontSize: 18),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                width: 26,
                                height: 26,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Kirim',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== MODEL DUMMY ==================
class ReimbursementRequest {
  final String id;
  final DateTime startDate;
  final double amount;
  final String description;
  final DateTime createdAt;
  ReimbursementRequest({
    required this.id,
    required this.startDate,
    required this.amount,
    required this.description,
    required this.createdAt,
  });

  factory ReimbursementRequest.fromMap(Map<String, dynamic> map, String id) {
    return ReimbursementRequest(
      id: id,
      startDate: (map['startDate'] as Timestamp).toDate(),
      amount: (map['amount'] as num).toDouble(),
      description: map['description'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Kelas item benefit
class _BenefitItem {
  final String name;
  final int amount;
  _BenefitItem(this.name, this.amount);
}
