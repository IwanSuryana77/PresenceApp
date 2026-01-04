import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});
  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class Pengajuan {
  DateTime start;
  DateTime end;
  String reason;
  String status;
  Pengajuan({
    required this.start,
    required this.end,
    required this.reason,
    required this.status,
  });
}

class _PengajuanPageState extends State<PengajuanPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  final List<Pengajuan> _riwayat = [
    Pengajuan(
      start: DateTime(2025, 12, 22),
      end: DateTime(2026, 1, 2),
      reason: "Acara Keluarga",
      status: "Proses",
    ),
    Pengajuan(
      start: DateTime(2025, 10, 21),
      end: DateTime(2025, 10, 23),
      reason: "Kontrol Sakit",
      status: "Disetujui",
    ),
    Pengajuan(
      start: DateTime(2025, 9, 25),
      end: DateTime(2025, 10, 26),
      reason: "Operasi ringan",
      status: "Disetujui",
    ),
  ];

  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = _riwayat.first.start.month;
    selectedYear = _riwayat.first.start.year;
  }

  String _formatDate(DateTime d) {
    const monthNames = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${d.day} ${monthNames[d.month - 1]} ${d.year}';
  }

  List<int> _availableMonths() {
    return _riwayat.map((r) => r.start.month).toSet().toList()..sort();
  }

  List<int> _availableYears() {
    return _riwayat.map((r) => r.start.year).toSet().toList()..sort();
  }

  List<Pengajuan> get _filteredRiwayat {
    return _riwayat
        .where(
          (r) => r.start.month == selectedMonth && r.start.year == selectedYear,
        )
        .toList();
  }

  Future<void> _selectDate(bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (context, child) => Theme(
        data: ThemeData(
          colorScheme: ColorScheme.light(
            primary: Colors.blue.shade700, // Warna utama biru
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  void _submitPengajuan() {
    if (_startDate != null &&
        _endDate != null &&
        _reasonController.text.trim().isNotEmpty) {
      setState(() {
        _riwayat.insert(
          0,
          Pengajuan(
            start: _startDate!,
            end: _endDate!,
            reason: _reasonController.text,
            status: "Proses",
          ),
        );
        selectedMonth = _startDate!.month;
        selectedYear = _startDate!.year;
        _startDate = null;
        _endDate = null;
        _reasonController.clear();
      });
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Pengajuan cuti berhasil dikirim!"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.blue.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = Colors.blue.shade700;
    final colorAccent = Colors.blue.shade50;
    final borderRadius = BorderRadius.circular(16);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            // AppBar Style
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // IconButton(
                //   icon: Icon(Icons.arrow_back, color: colorPrimary),
                //   onPressed: () {
                //     Navigator.of(context).maybePop();
                //   },
                // ),
                const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    'Pengajuan Cuti',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                      color: colorPrimary,
                    ),
                  ),
                ),
                const SizedBox(width: 44), // Agar judul tetap di tengah
              ],
            ),
            const SizedBox(height: 16),

            // Form Card
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withAlpha((0.09 * 255).round()),
                    blurRadius: 16,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ajukan Cuti",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                  ),
                  const SizedBox(height: 18),

                  // Tanggal Mulai
                  GestureDetector(
                    onTap: () => _selectDate(true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Tanggal Mulai ',
                          prefixIcon: Icon(
                            Icons.calendar_month_rounded,
                            color: colorPrimary,
                          ),
                          filled: true,
                          fillColor: colorAccent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(
                          text: _startDate != null
                              ? DateFormat('dd MMM yyyy').format(_startDate!)
                              : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tanggal Akhir
                  GestureDetector(
                    onTap: () => _selectDate(false),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Tanggal Akhir ',
                          prefixIcon: Icon(
                            Icons.calendar_today,
                            color: colorPrimary,
                          ),
                          filled: true,
                          fillColor: colorAccent,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        controller: TextEditingController(
                          text: _endDate != null
                              ? DateFormat('dd MMM yyyy').format(_endDate!)
                              : '',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alasan Cuti
                  TextFormField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Misal: acara keluarga',
                      filled: true,
                      fillColor: colorAccent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Tombol Kirim
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submitPengajuan,
                      child: Text(
                        'Kirim',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                          color:
                              Colors.white, // <--- UBAH WARNA SESUAI KEINGINAN
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Filter & Riwayat
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: colorPrimary.withAlpha((0.07 * 255).round()),
                    blurRadius: 10,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Riwayat Pengajuan Cuti",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: colorPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Filter
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: colorPrimary),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedMonth,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        underline: SizedBox(),
                        items: _availableMonths().map((m) {
                          return DropdownMenuItem<int>(
                            value: m,
                            child: Text(
                              [
                                'Jan',
                                'Feb',
                                'Mar',
                                'Apr',
                                'Mei',
                                'Jun',
                                'Jul',
                                'Agu',
                                'Sep',
                                'Okt',
                                'Nov',
                                'Des',
                              ][m - 1],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedMonth = val);
                        },
                      ),
                      const SizedBox(width: 7),
                      DropdownButton<int>(
                        value: selectedYear,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        underline: SizedBox(),
                        items: _availableYears().map((y) {
                          return DropdownMenuItem<int>(
                            value: y,
                            child: Text('$y'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedYear = val);
                        },
                      ),
                      const Spacer(),
                      Material(
                        color: colorAccent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: colorPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // List Riwayat
                  if (_filteredRiwayat.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Tidak ada riwayat pengajuan di bulan dan tahun ini.',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ..._filteredRiwayat.map(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorAccent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 2),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 14,
                        ),
                        title: Text(
                          '${_formatDate(r.start)} - ${_formatDate(r.end)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '• Alasan: ${r.reason}',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.7),
                              fontSize: 14,
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 18,
                          ),
                          decoration: BoxDecoration(
                            color: r.status == "Proses"
                                ? Colors.red.shade400
                                : Colors.green,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            r.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
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
      ),
    );
  }
}
