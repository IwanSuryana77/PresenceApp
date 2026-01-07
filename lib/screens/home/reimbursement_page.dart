import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';

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
            primary: AppColors.primary,
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
          backgroundColor: const Color.fromARGB(255, 247, 251, 255),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(16);

    return Scaffold(
      backgroundColor: AppColors.extraLight,
      appBar: AppBar(
        title: const Text('Pengajuan Reimbursement'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            // Form Card with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withOpacity(0.75),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Ajukan Reimbursement",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Tanggal Mulai
                  GestureDetector(
                    onTap: () => _selectDate(true),
                    child: AbsorbPointer(
                      child: TextFormField(
                        decoration: InputDecoration(
                          hintText: 'Tanggal Mulai ',
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(
                            Icons.calendar_month_rounded,
                            color: Colors.black54,
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                        style: const TextStyle(color: Colors.black87),
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
                          hintStyle: const TextStyle(color: Colors.black54),
                          prefixIcon: const Icon(
                            Icons.calendar_today,
                            color: Colors.black54,
                          ),
                          filled: true,
                          fillColor: Colors.white,
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
                        style: const TextStyle(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Alasan/Keterangan
                  TextFormField(
                    controller: _reasonController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Misal: Biaya perjalanan dinas',
                      hintStyle: const TextStyle(color: Colors.black54),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(color: Colors.black87),
                  ),
                  const SizedBox(height: 18),

                  // Tombol Kirim
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _submitPengajuan,
                      child: const Text(
                        'Kirim Pengajuan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Filter & Riwayat with Modern Design
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Riwayat Pengajuan Reimbursement",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Filter
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 10),
                      DropdownButton<int>(
                        value: selectedMonth,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
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
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
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
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.filter_list_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // List Riwayat
                  if (_filteredRiwayat.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.extraLight,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.inbox_rounded,
                              size: 48,
                              color: AppColors.primary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Tidak ada riwayat pengajuan',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ..._filteredRiwayat.map(
                    (r) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primaryLight,
                            AppColors.primaryLight.withOpacity(0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        title: Text(
                          '${_formatDate(r.start)} - ${_formatDate(r.end)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            '• Keterangan: ${r.reason}',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.65),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 6,
                            horizontal: 14,
                          ),
                          decoration: BoxDecoration(
                            color: r.status == "Proses"
                                ? Colors.orange.shade400
                                : Colors.green.shade500,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            r.status,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
