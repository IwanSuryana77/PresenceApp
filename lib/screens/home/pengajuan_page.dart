import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../models/leave_request.dart';
import '../../services/api_service.dart';
import '../../services/auth_helper.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});
  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  DateTime? _startDate;
  DateTime? _endDate;
  final TextEditingController _reasonController = TextEditingController();

  /// 💾 FIREBASE: Akses API terpusat untuk leave requests (UI -> API -> FIREBASE)
  final ApiService _api = ApiService.instance;

  /// 💾 FIREBASE: List untuk menyimpan data dari Firestore
  List<LeaveRequest> _leaveRequests = [];
  bool _isLoading = false;

  late int selectedMonth;
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedMonth = DateTime.now().month;
    selectedYear = DateTime.now().year;

    /// 💾 FIREBASE: Load leave requests ketika page terbuka
    _loadLeaveRequests();
  }

  /// 💾 FIREBASE READ: Load leave requests dari Firestore
  Future<void> _loadLeaveRequests() async {
    setState(() => _isLoading = true);
    try {
      /// 💾 FIREBASE READ: Ambil semua leave requests via ApiService
      final requests = await _api.getAllLeaveRequests();
      setState(() {
        _leaveRequests = requests;
        _isLoading = false;
      });
      print('✅ Leave requests loaded from Firebase');
    } catch (e) {
      setState(() => _isLoading = false);
      print('❌ Error loading leave requests: $e');
    }
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
    /// 💾 FIREBASE: Get available months dari Firestore data
    return _leaveRequests.map((r) => r.startDate.month).toSet().toList()
      ..sort();
  }

  List<int> _availableYears() {
    /// 💾 FIREBASE: Get available years dari Firestore data
    return _leaveRequests.map((r) => r.startDate.year).toSet().toList()..sort();
  }

  List<LeaveRequest> get _filteredRiwayat {
    /// 💾 FIREBASE: Filter leave requests berdasarkan bulan dan tahun yang dipilih
    return _leaveRequests
        .where(
          (r) =>
              r.startDate.month == selectedMonth &&
              r.startDate.year == selectedYear,
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

  void _submitPengajuan() async {
    if (_startDate != null &&
        _endDate != null &&
        _reasonController.text.trim().isNotEmpty) {
      try {
        setState(() => _isLoading = true);

        final daysCount = _endDate!.difference(_startDate!).inDays + 1;

        // 🔐 Ambil data user dari Firebase Auth
        final userId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
        final userEmail =
            FirebaseAuth.instance.currentUser?.email ?? 'user@example.com';
        final userName = await AuthHelper.getCurrentUserName();

        /// 💾 FIREBASE WRITE: Buat LeaveRequest object dengan data user real
        final leaveRequest = LeaveRequest(
          employeeId: userId,
          employeeName: userName,
          startDate: _startDate!,
          endDate: _endDate!,
          reason: _reasonController.text,
          status: 'Proses',
          createdAt: DateTime.now(),
          daysCount: daysCount,
        );

        /// 💾 FIREBASE WRITE: Simpan ke Firestore collection 'leave_requests' via ApiService
        await _api.createLeaveRequest(leaveRequest);
        print('✅ Leave Request berhasil disimpan ke Firebase!');

        /// 💾 FIREBASE READ: Refresh data dari Firestore
        await _loadLeaveRequests();

        /// Reset form
        setState(() {
          selectedMonth = _startDate!.month;
          selectedYear = _startDate!.year;
          _startDate = null;
          _endDate = null;
          _reasonController.clear();
          _isLoading = false;
        });

        FocusScope.of(context).unfocus();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Pengajuan cuti berhasil dikirim ke Firebase!"),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('❌ Error submitting leave request: $e');
        setState(() => _isLoading = false);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("❌ Gagal mengirim pengajuan: $e"),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("⚠️ Silakan isi semua field terlebih dahulu"),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorPrimary = AppColors.primary;
    final colorAccent = AppColors.primaryLight;
    final borderRadius = BorderRadius.circular(16);

    return Scaffold(
      backgroundColor: AppColors.extraLight,
      appBar: AppBar(
        title: const Text('Pengajuan Cuti'),
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
                    "Ajukan Cuti",
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
                          text: _endDate != null
                              ? DateFormat('dd MMM yyyy').format(_endDate!)
                              : '',
                        ),
                        style: const TextStyle(color: Colors.black87),
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
                      onPressed: _isLoading ? null : _submitPengajuan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[400],
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primary,
                                ),
                              ),
                            )
                          : const Text(
                              'Kirim Pengajuan',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),

            // Filter & Riwayat with Gradient
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: borderRadius,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Riwayat Pengajuan Cuti",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 16),

                  // Filter Bulan & Tahun
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedMonth,
                          items: _availableMonths().isEmpty
                              ? [
                                  DropdownMenuItem(
                                    value: DateTime.now().month,
                                    child: Text(
                                      'Bulan ${DateTime.now().month}',
                                    ),
                                  ),
                                ]
                              : _availableMonths()
                                    .map(
                                      (month) => DropdownMenuItem(
                                        value: month,
                                        child: Text('Bulan $month'),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedMonth = value);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: selectedYear,
                          items: _availableYears().isEmpty
                              ? [
                                  DropdownMenuItem(
                                    value: DateTime.now().year,
                                    child: Text('Tahun ${DateTime.now().year}'),
                                  ),
                                ]
                              : _availableYears()
                                    .map(
                                      (year) => DropdownMenuItem(
                                        value: year,
                                        child: Text('Tahun $year'),
                                      ),
                                    )
                                    .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedYear = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Loading Indicator
                  if (_isLoading)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: AppColors.primary),
                            const SizedBox(height: 12),
                            const Text(
                              'Memuat data...',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // List Riwayat
                  if (!_isLoading && _filteredRiwayat.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                          'Tidak ada data pengajuan untuk bulan ${_formatDate(DateTime(selectedYear, selectedMonth))}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  if (!_isLoading && _filteredRiwayat.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _filteredRiwayat.length,
                      itemBuilder: (context, index) {
                        final request = _filteredRiwayat[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[300]!,
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    request.employeeName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: request.status == 'Disetujui'
                                          ? Colors.green[100]
                                          : request.status == 'Ditolak'
                                          ? Colors.red[100]
                                          : Colors.orange[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      request.status,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: request.status == 'Disetujui'
                                            ? Colors.green
                                            : request.status == 'Ditolak'
                                            ? Colors.red
                                            : Colors.orange,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${_formatDate(request.startDate)} - ${_formatDate(request.endDate)}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Alasan: ${request.reason}',
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
// import '../../theme/app_theme.dart';
// import '../../models/leave_request.dart';
// import '../../services/api_service.dart';

// class PengajuanPage extends StatefulWidget {
//   const PengajuanPage({super.key});
//   @override
//   State<PengajuanPage> createState() => _PengajuanPageState();
// }

// class _PengajuanPageState extends State<PengajuanPage> {
//   DateTime? _startDate;
//   DateTime? _endDate;
//   final TextEditingController _reasonController = TextEditingController();

//   /// 💾 FIREBASE: Akses API terpusat untuk leave requests (UI -> API -> FIREBASE)
//   final ApiService _api = ApiService.instance;

//   /// 💾 FIREBASE: List untuk menyimpan data dari Firestore
//   List<LeaveRequest> _leaveRequests = [];
//   bool _isLoading = false;

//   late int selectedMonth;
//   late int selectedYear;

//   @override
//   void initState() {
//     super.initState();
//     selectedMonth = DateTime.now().month;
//     selectedYear = DateTime.now().year;

//     /// 💾 FIREBASE: Load leave requests ketika page terbuka
//     _loadLeaveRequests();
//   }

//   /// 💾 FIREBASE READ: Load leave requests dari Firestore
//   Future<void> _loadLeaveRequests() async {
//     setState(() => _isLoading = true);
//     try {
//       /// 💾 FIREBASE READ: Ambil semua leave requests via ApiService
//       final requests = await _api.getAllLeaveRequests();
//       setState(() {
//         _leaveRequests = requests;
//         _isLoading = false;
//       });
//       print('✅ Leave requests loaded from Firebase');
//     } catch (e) {
//       setState(() => _isLoading = false);
//       print('❌ Error loading leave requests: $e');
//     }
//   }

//   String _formatDate(DateTime d) {
//     const monthNames = [
//       'Jan',
//       'Feb',
//       'Mar',
//       'Apr',
//       'Mei',
//       'Jun',
//       'Jul',
//       'Agu',
//       'Sep',
//       'Okt',
//       'Nov',
//       'Des',
//     ];
//     return '${d.day} ${monthNames[d.month - 1]} ${d.year}';
//   }

//   List<int> _availableMonths() {
//     /// 💾 FIREBASE: Get available months dari Firestore data
//     return _leaveRequests.map((r) => r.startDate.month).toSet().toList()
//       ..sort();
//   }

//   List<int> _availableYears() {
//     /// 💾 FIREBASE: Get available years dari Firestore data
//     return _leaveRequests.map((r) => r.startDate.year).toSet().toList()..sort();
//   }

//   List<LeaveRequest> get _filteredRiwayat {
//     /// 💾 FIREBASE: Filter leave requests berdasarkan bulan dan tahun yang dipilih
//     return _leaveRequests
//         .where(
//           (r) =>
//               r.startDate.month == selectedMonth &&
//               r.startDate.year == selectedYear,
//         )
//         .toList();
//   }

//   Future<void> _selectDate(bool isStart) async {
//     final picked = await showDatePicker(
//       context: context,
//       initialDate: (isStart ? _startDate : _endDate) ?? DateTime.now(),
//       firstDate: DateTime(DateTime.now().year - 5),
//       lastDate: DateTime(DateTime.now().year + 2),
//       builder: (context, child) => Theme(
//         data: ThemeData(
//           colorScheme: ColorScheme.light(
//             primary: AppColors.primary,
//             onPrimary: Colors.white,
//             onSurface: Colors.black,
//           ),
//         ),
//         child: child!,
//       ),
//     );
//     if (picked != null) {
//       setState(() {
//         if (isStart) {
//           _startDate = picked;
//           if (_endDate != null && _endDate!.isBefore(picked)) _endDate = null;
//         } else {
//           _endDate = picked;
//         }
//       });
//     }
//   }

//   void _submitPengajuan() async {
//     if (_startDate != null &&
//         _endDate != null &&
//         _reasonController.text.trim().isNotEmpty) {
//       try {
//         final daysCount = _endDate!.difference(_startDate!).inDays + 1;

//         /// 💾 FIREBASE WRITE: Buat LeaveRequest object
//         final leaveRequest = LeaveRequest(
//           employeeId: 'emp_001', // TODO: Get dari logged in user
//           employeeName: 'Ramadhani Hibban', // TODO: Get dari logged in user
//           startDate: _startDate!,
//           endDate: _endDate!,
//           reason: _reasonController.text,
//           status: 'Proses',
//           createdAt: DateTime.now(),
//           daysCount: daysCount,
//         );

//         /// 💾 FIREBASE WRITE: Simpan ke Firestore collection 'leave_requests' via ApiService
//         await _api.createLeaveRequest(leaveRequest);

//         /// 💾 FIREBASE READ: Refresh data dari Firestore
//         await _loadLeaveRequests();

//         /// Reset form
//         setState(() {
//           selectedMonth = _startDate!.month;
//           selectedYear = _startDate!.year;
//           _startDate = null;
//           _endDate = null;
//           _reasonController.clear();
//         });

//         FocusScope.of(context).unfocus();

//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text("✅ Pengajuan cuti berhasil dikirim ke Firebase!"),
//               duration: Duration(seconds: 2),
//               backgroundColor: Colors.green,
//             ),
//           );
//         }
//       } catch (e) {
//         print('❌ Error submitting leave request: $e');
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("❌ Gagal mengirim pengajuan: $e"),
//               duration: const Duration(seconds: 2),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     final colorPrimary = AppColors.primary;
//     final colorAccent = AppColors.primaryLight;
//     final borderRadius = BorderRadius.circular(16);

//     return Scaffold(
//       backgroundColor: AppColors.extraLight,
//       appBar: AppBar(
//         title: const Text('Pengajuan Cuti'),
//         backgroundColor: AppColors.primary,
//         elevation: 0,
//       ),
//       body: SafeArea(
//         child: ListView(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//           children: [
//             // Form Card with Gradient
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   colors: [
//                     AppColors.primary,
//                     AppColors.primary.withOpacity(0.75),
//                   ],
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                 ),
//                 borderRadius: borderRadius,
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.primary.withOpacity(0.3),
//                     blurRadius: 16,
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Text(
//                     "Ajukan Cuti",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 18,
//                       color: Colors.white,
//                     ),
//                   ),
//                   const SizedBox(height: 18),

//                   // Tanggal Mulai
//                   GestureDetector(
//                     onTap: () => _selectDate(true),
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         decoration: InputDecoration(
//                           hintText: 'Tanggal Mulai ',
//                           hintStyle: const TextStyle(color: Colors.black54),
//                           prefixIcon: const Icon(
//                             Icons.calendar_month_rounded,
//                             color: Colors.black54,
//                           ),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         controller: TextEditingController(
//                           text: _startDate != null
//                               ? DateFormat('dd MMM yyyy').format(_startDate!)
//                               : '',
//                         ),
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Tanggal Akhir
//                   GestureDetector(
//                     onTap: () => _selectDate(false),
//                     child: AbsorbPointer(
//                       child: TextFormField(
//                         decoration: InputDecoration(
//                           hintText: 'Tanggal Akhir ',
//                           hintStyle: const TextStyle(color: Colors.black54),
//                           prefixIcon: const Icon(
//                             Icons.calendar_today,
//                             color: Colors.black54,
//                           ),
//                           filled: true,
//                           fillColor: Colors.white,
//                           border: OutlineInputBorder(
//                             borderRadius: BorderRadius.circular(12),
//                             borderSide: BorderSide.none,
//                           ),
//                         ),
//                         controller: TextEditingController(
//                           text: _endDate != null
//                               ? DateFormat('dd MMM yyyy').format(_endDate!)
//                               : '',
//                         ),
//                         style: const TextStyle(color: Colors.black87),
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 12),

//                   // Alasan Cuti
//                   TextFormField(
//                     controller: _reasonController,
//                     minLines: 3,
//                     maxLines: 4,
//                     decoration: InputDecoration(
//                       hintText: 'Misal: acara keluarga',
//                       hintStyle: const TextStyle(color: Colors.black54),
//                       filled: true,
//                       fillColor: Colors.white,
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide.none,
//                       ),
//                     ),
//                     style: const TextStyle(color: Colors.black87),
//                   ),
//                   const SizedBox(height: 18),

//                   // Tombol Kirim
//                   SizedBox(
//                     width: double.infinity,
//                     child: ElevatedButton(
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: Colors.white,
//                         elevation: 0,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         padding: const EdgeInsets.symmetric(vertical: 14),
//                       ),
//                       onPressed: _submitPengajuan,
//                       child: const Text(
//                         'Kirim Pengajuan',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           letterSpacing: 0.5,
//                           color: Colors.black87,
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),

//             const SizedBox(height: 26),

//             // Filter & Riwayat with Gradient
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: borderRadius,
//                 boxShadow: [
//                   BoxShadow(
//                     color: colorPrimary.withOpacity(0.1),
//                     blurRadius: 12,
//                     offset: const Offset(0, 3),
//                   ),
//                 ],
//               ),
//               padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     "Riwayat Pengajuan Cuti",
//                     style: TextStyle(
//                       fontWeight: FontWeight.bold,
//                       fontSize: 17,
//                       color: AppColors.primary,
//                     ),
//                   ),
//                   const SizedBox(height: 14),

//                   // Dropdown Filter
//                   Row(
//                     children: [
//                       Icon(
//                         Icons.calendar_today_rounded,
//                         color: AppColors.primary,
//                       ),
//                       const SizedBox(width: 10),
//                       DropdownButton<int>(
//                         value: selectedMonth,
//                         style: const TextStyle(
//                           fontSize: 15,
//                           color: Colors.black,
//                         ),
//                         dropdownColor: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         underline: SizedBox(),
//                         items: _availableMonths().map((m) {
//                           return DropdownMenuItem<int>(
//                             value: m,
//                             child: Text(
//                               [
//                                 'Jan',
//                                 'Feb',
//                                 'Mar',
//                                 'Apr',
//                                 'Mei',
//                                 'Jun',
//                                 'Jul',
//                                 'Agu',
//                                 'Sep',
//                                 'Okt',
//                                 'Nov',
//                                 'Des',
//                               ][m - 1],
//                             ),
//                           );
//                         }).toList(),
//                         onChanged: (val) {
//                           if (val != null) setState(() => selectedMonth = val);
//                         },
//                       ),
//                       const SizedBox(width: 7),
//                       DropdownButton<int>(
//                         value: selectedYear,
//                         style: const TextStyle(
//                           fontSize: 15,
//                           color: Colors.black,
//                         ),
//                         dropdownColor: Colors.white,
//                         borderRadius: BorderRadius.circular(12),
//                         underline: SizedBox(),
//                         items: _availableYears().map((y) {
//                           return DropdownMenuItem<int>(
//                             value: y,
//                             child: Text('$y'),
//                           );
//                         }).toList(),
//                         onChanged: (val) {
//                           if (val != null) setState(() => selectedYear = val);
//                         },
//                       ),
//                       const Spacer(),
//                       Container(
//                         decoration: BoxDecoration(
//                           color: AppColors.primaryLight,
//                           borderRadius: BorderRadius.circular(12),
//                         ),
//                         child: Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Icon(
//                             Icons.filter_list_rounded,
//                             color: AppColors.primary,
//                             size: 20,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),

//                   // List Riwayat
//                   if (_filteredRiwayat.isEmpty)
//                     Container(
//                       padding: const EdgeInsets.all(12),
//                       decoration: BoxDecoration(
//                         color: Colors.grey[100],
//                         borderRadius: BorderRadius.circular(10),
//                       ),
//                       child: Text(
//                         'Tidak ada riwayat pengajuan di bulan dan tahun ini.',
//                         style: TextStyle(
//                           color: Colors.grey[600],
//                           fontStyle: FontStyle.italic,
//                         ),
//                       ),
//                     ),
//                   ..._filteredRiwayat.map(
//                     (r) => Container(
//                       margin: const EdgeInsets.only(bottom: 16),
//                       decoration: BoxDecoration(
//                         color: colorAccent,
//                         borderRadius: BorderRadius.circular(12),
//                         boxShadow: [
//                           BoxShadow(color: Colors.black12, blurRadius: 2),
//                         ],
//                       ),
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(
//                           vertical: 10,
//                           horizontal: 14,
//                         ),
//                         title: Text(
//                           '${_formatDate(r.startDate)} - ${_formatDate(r.endDate)}',
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w800,
//                             fontSize: 15,
//                             color: Colors.black87,
//                           ),
//                         ),
//                         subtitle: Padding(
//                           padding: const EdgeInsets.only(top: 6),
//                           child: Text(
//                             '• Alasan: ${r.reason}',
//                             style: TextStyle(
//                               color: Colors.black.withOpacity(0.7),
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                         trailing: Container(
//                           padding: const EdgeInsets.symmetric(
//                             vertical: 5,
//                             horizontal: 18,
//                           ),
//                           decoration: BoxDecoration(
//                             color: r.status == "Proses"
//                                 ? Colors.red.shade400
//                                 : Colors.green,
//                             borderRadius: BorderRadius.circular(15),
//                           ),
//                           child: Text(
//                             r.status,
//                             style: const TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w600,
//                               fontSize: 14,
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
