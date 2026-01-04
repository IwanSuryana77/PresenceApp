import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dotted_border/dotted_border.dart';

class ReimbursementPage extends StatefulWidget {
  const ReimbursementPage({super.key});

  @override
  State<ReimbursementPage> createState() =>
      _PengajuanReimbursementPageState();
}

class _PengajuanReimbursementPageState
    extends State<ReimbursementPage> {
  String? selectedPolicy;
  DateTime? transactionDate;
  final TextEditingController _descController = TextEditingController();
  List<PlatformFile> _attachments = [];
  List<_ReimburseItem> _items = [];

  final brightBlue = const Color.fromARGB(255, 0, 67, 250); 
  final blueAccent = const Color(0xFFE3F0FB);

  final policies = ['Kesehatan', 'Transportasi', 'Pendidikan', 'Lainnya'];

  Future<void> _pickFile() async {
    if (_attachments.length >= 5) return;
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      allowedExtensions: [
        'pdf',
        'jpg',
        'png',
        'jpeg',
        'doc',
        'docx',
        'xls',
        'xlsx',
        'txt',
        'ppt',
        'pptx',
      ],
      type: FileType.custom,
      withData: true,
    );
    if (result != null) {
      setState(() {
        _attachments.addAll(result.files.take(5 - _attachments.length));
      });
    }
  }

  void _removeAttachment(int idx) {
    setState(() {
      _attachments.removeAt(idx);
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: transactionDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: brightBlue,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => transactionDate = picked);
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Tambah Item"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: "Nama item",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: "Nominal (Rp)",
                prefixText: "Rp ",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            child: Text("Batal"),
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: Text("Tambah"),
            onPressed: () {
              if (nameController.text.trim().isNotEmpty &&
                  num.tryParse(
                        amountController.text
                            .replaceAll('.', '')
                            .replaceAll(',', ''),
                      ) !=
                      null) {
                setState(() {
                  _items.add(
                    _ReimburseItem(
                      name: nameController.text.trim(),
                      amount: int.parse(
                        amountController.text
                            .replaceAll('.', '')
                            .replaceAll(',', ''),
                      ),
                    ),
                  );
                });
                Navigator.of(ctx).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  int get total => _items.fold(0, (sum, v) => sum + v.amount);

  void _submit() {
    // validasi sederhana
    if (selectedPolicy == null ||
        transactionDate == null ||
        _attachments.isEmpty ||
        _items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            "Semua field wajib diisi dan minimal 1 item serta 1 file lampiran!",
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    // Submit (mock)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Pengajuan reimbursement berhasil dikirim!"),
        backgroundColor: brightBlue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);
    final borderColor = brightBlue.withOpacity(0.25);
    return Scaffold(
      backgroundColor: blueAccent,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(0),
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(
                top: 12,
                left: 12,
                right: 12,
                bottom: 5,
              ),
              child: Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    clipBehavior: Clip.antiAlias,
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: brightBlue, size: 28),
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      "Pengajuan Reimbursement",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: brightBlue,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Divider(thickness: 1, height: 2, color: borderColor),

            // Main Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
              ),
              margin: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              padding: EdgeInsets.fromLTRB(18, 16, 18, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Policy Picker
                  DropdownButtonFormField<String>(
                    value: selectedPolicy,
                    items: policies
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (value) =>
                        setState(() => selectedPolicy = value),
                    decoration: InputDecoration(
                      label: const Text("Kebijakan reimbursement *"),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tanggal Transaksi
                  Text(
                    "Tanggal transaksi *",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 7),
                  GestureDetector(
                    onTap: _pickDate,
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: TextEditingController(
                          text: transactionDate != null
                              ? DateFormat(
                                  'dd MMM yyyy',
                                ).format(transactionDate!)
                              : '',
                        ),
                        decoration: InputDecoration(
                          hintText: "Pilih tanggal",
                          suffixIcon: Icon(
                            Icons.calendar_today_rounded,
                            color: brightBlue,
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: borderColor),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Lampiran
                  Text(
                    "Lampiran",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _pickFile,
                        child: DottedBorder(
                          color: brightBlue,
                          strokeWidth: 1.6,
                          dashPattern: [8, 3],
                          borderType: BorderType.RRect,
                          radius: Radius.circular(12),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.add,
                                color: brightBlue,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          children: List.generate(_attachments.length, (idx) {
                            final f = _attachments[idx];
                            return Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  margin: EdgeInsets.only(top: 6, bottom: 6),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: blueAccent,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    f.name,
                                    style: TextStyle(
                                      color: brightBlue,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Positioned(
                                  top: -10,
                                  right: -8,
                                  child: GestureDetector(
                                    onTap: () => _removeAttachment(idx),
                                    child: CircleAvatar(
                                      radius: 10,
                                      backgroundColor: Colors.red,
                                      child: Icon(
                                        Icons.close,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Anda dapat mengunggah maksimal 5 file, dan harus berformat PDF, JPG, PNG, XLSX, XLS, JPEG, DOCX, DOC, TXT, PPT, dan PPTX maksimum 10MB",
                    style: TextStyle(fontSize: 11, color: Colors.black54),
                  ),

                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Deskripsi",
                      border: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: borderColor),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Benefit part, bottom card
            Container(
              width: double.infinity,
              margin: EdgeInsets.fromLTRB(0, 0, 0, 0),
              padding: EdgeInsets.fromLTRB(0, 14, 0, 0),
              decoration: BoxDecoration(
                color: blueAccent,
                borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade100.withOpacity(0.16),
                    blurRadius: 6,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24),
                    child: Text(
                      'Item benefit',
                      style: TextStyle(
                        color: brightBlue,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 24, right: 24, top: 2),
                    child: Text(
                      'Tambahkan rincian benefit yang akan diajukan.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 13),
                        ),
                        onPressed: _showAddItemDialog,
                        child: Text(
                          "+ tambahkan item",
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_items.isNotEmpty)
                    Column(
                      children: List.generate(_items.length, (i) {
                        final item = _items[i];
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 4,
                          ),
                          child: Card(
                            margin: EdgeInsets.zero,
                            color: Colors.white,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: ListTile(
                              title: Text(
                                item.name,
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text(
                                "Rp${item.amount.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ".")}",
                                style: TextStyle(
                                  color: brightBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              trailing: IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    setState(() => _items.removeAt(i)),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total jumlah pengajuan",
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          "Rp${total.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (match) => ".")}",
                          style: TextStyle(
                            color: brightBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: brightBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.symmetric(vertical: 15),
                        ),
                        onPressed: _submit,
                        child: Text(
                          "Kirim",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReimburseItem {
  final String name;
  final int amount;
  _ReimburseItem({required this.name, required this.amount});
}
