import 'attendance_service.dart';
import 'leave_request_service.dart';
import 'message_service.dart';
import 'reimbursement_service.dart';
import '../models/attendance.dart';
import '../models/leave_request.dart';
import '../models/message.dart';
import '../models/reimbursement_request.dart';

/// ============================================================================
/// 🌐 API LAYER
/// ----------------------------------------------------------------------------
/// Layer ini menjadi "API" internal aplikasi yang menggabungkan semua service
/// Firebase (Attendance, Leave, Message, Reimbursement) dalam satu tempat.
///
/// Setiap fungsi yang melakukan penyimpanan / perubahan data ke Firebase
/// diberi tanda khusus:
///   👉  // [API -> FIREBASE WRITE]
///   👉  // [API -> FIREBASE UPDATE]
///   👉  // [API -> FIREBASE DELETE]
///   👉  // [API -> FIREBASE READ]
///
/// Sehingga mudah dilacak bagian mana yang berinteraksi langsung dengan
/// database (Firestore / Storage) melalui service-service yang sudah ada.
/// ============================================================================
class ApiService {
  ApiService._internal() {
    _attendanceService = AttendanceService();
    _leaveRequestService = LeaveRequestService();
    _messageService = MessageService();
    _reimbursementService = ReimbursementService();
  }
  static final ApiService instance = ApiService._internal();

  // Service Firebase yang sudah ada
  late AttendanceService _attendanceService;
  late LeaveRequestService _leaveRequestService;
  late MessageService _messageService;
  late ReimbursementService _reimbursementService;

  /// Untuk keperluan testing: inject service mock agar tidak mengakses Firebase langsung
  void injectServicesForTesting({
    AttendanceService? attendanceService,
    LeaveRequestService? leaveRequestService,
    MessageService? messageService,
    ReimbursementService? reimbursementService,
  }) {
    if (attendanceService != null) _attendanceService = attendanceService;
    if (leaveRequestService != null) _leaveRequestService = leaveRequestService;
    if (messageService != null) _messageService = messageService;
    if (reimbursementService != null) _reimbursementService = reimbursementService;
  }

  // ---------------------------------------------------------------------------
  // 📌 ATTENDANCE (ABSEN)
  // ---------------------------------------------------------------------------

  /// Mencatat kehadiran baru
  /// [API -> FIREBASE WRITE]
  Future<String> createAttendance(Attendance attendance) {
    return _attendanceService.recordAttendance(attendance);
  }

  /// Mengambil daftar kehadiran user
  /// [API -> FIREBASE READ]
  Future<List<Attendance>> getUserAttendance(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _attendanceService.getUserAttendance(
      employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Mengambil kehadiran berdasarkan tanggal
  /// [API -> FIREBASE READ]
  Future<Attendance?> getAttendanceByDate(
    String employeeId,
    DateTime date,
  ) {
    return _attendanceService.getAttendanceByDate(employeeId, date);
  }

  /// Mengambil kehadiran berdasarkan ID dokumen
  /// [API -> FIREBASE READ]
  Future<Attendance?> getAttendanceById(String id) {
    return _attendanceService.getAttendanceById(id);
  }

  /// Meng-update kehadiran
  /// [API -> FIREBASE UPDATE]
  Future<void> updateAttendance(String id, Attendance updatedAttendance) {
    return _attendanceService.updateAttendance(id, updatedAttendance);
  }

  /// Meng-update jam pulang (check-out time)
  /// [API -> FIREBASE UPDATE]
  Future<void> updateCheckOutTime(String id, String checkOutTime) {
    return _attendanceService.updateCheckOutTime(id, checkOutTime);
  }

  /// Menghapus data kehadiran
  /// [API -> FIREBASE DELETE]
  Future<void> deleteAttendance(String id) {
    return _attendanceService.deleteAttendance(id);
  }

  /// Statistik kehadiran (jumlah hadir, izin, sakit, dll.)
  /// [API -> FIREBASE READ]
  Future<Map<String, int>> getAttendanceStats(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _attendanceService.getAttendanceStats(
      employeeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Stream real-time attendance user
  /// [API -> FIREBASE STREAM]
  Stream<List<Attendance>> getUserAttendanceStream(String employeeId) {
    return _attendanceService.getUserAttendanceStream(employeeId);
  }

  // ---------------------------------------------------------------------------
  // 📌 LEAVE REQUEST (CUTI)
  // ---------------------------------------------------------------------------

  /// Membuat permintaan cuti baru
  /// [API -> FIREBASE WRITE]
  Future<String> createLeaveRequest(LeaveRequest request) {
    return _leaveRequestService.createLeaveRequest(request);
  }

  /// Mengambil semua permintaan cuti user
  /// [API -> FIREBASE READ]
  Future<List<LeaveRequest>> getUserLeaveRequests(String employeeId) {
    return _leaveRequestService.getUserLeaveRequests(employeeId);
  }

  /// Mengambil semua permintaan cuti (admin)
  /// [API -> FIREBASE READ]
  Future<List<LeaveRequest>> getAllLeaveRequests() {
    return _leaveRequestService.getAllLeaveRequests();
  }

  /// Mengambil permintaan cuti berdasarkan ID
  /// [API -> FIREBASE READ]
  Future<LeaveRequest?> getLeaveRequestById(String id) {
    return _leaveRequestService.getLeaveRequestById(id);
  }

  /// Update status permintaan cuti (approve/reject)
  /// [API -> FIREBASE UPDATE]
  Future<void> updateLeaveRequestStatus(
    String id,
    String newStatus, {
    String? approvedBy,
  }) {
    return _leaveRequestService.updateLeaveRequestStatus(
      id,
      newStatus,
      approvedBy: approvedBy,
    );
  }

  /// Hapus permintaan cuti
  /// [API -> FIREBASE DELETE]
  Future<void> deleteLeaveRequest(String id) {
    return _leaveRequestService.deleteLeaveRequest(id);
  }

  /// Stream permintaan cuti user
  /// [API -> FIREBASE STREAM]
  Stream<List<LeaveRequest>> getUserLeaveRequestsStream(String employeeId) {
    return _leaveRequestService.getUserLeaveRequestsStream(employeeId);
  }

  // ---------------------------------------------------------------------------
  // 📌 MESSAGE (PESAN / INBOX)
  // ---------------------------------------------------------------------------

  /// Mengirim pesan baru
  /// [API -> FIREBASE WRITE]
  Future<String> sendMessage(Message message) {
    return _messageService.sendMessage(message);
  }

  /// Mengambil pesan untuk user (sebagai penerima)
  /// [API -> FIREBASE READ]
  Future<List<Message>> getUserMessages(String recipientId) {
    return _messageService.getUserMessages(recipientId);
  }

  /// Mengambil pesan yang belum dibaca
  /// [API -> FIREBASE READ]
  Future<List<Message>> getUnreadMessages(String recipientId) {
    return _messageService.getUnreadMessages(recipientId);
  }

  /// Mengambil pesan berdasarkan ID
  /// [API -> FIREBASE READ]
  Future<Message?> getMessageById(String id) {
    return _messageService.getMessageById(id);
  }

  /// Tandai satu pesan sebagai sudah dibaca
  /// [API -> FIREBASE UPDATE]
  Future<void> markMessageAsRead(String messageId) {
    return _messageService.markMessageAsRead(messageId);
  }

  /// Tandai semua pesan user sebagai sudah dibaca
  /// [API -> FIREBASE UPDATE]
  Future<void> markAllMessagesAsRead(String recipientId) {
    return _messageService.markAllMessagesAsRead(recipientId);
  }

  /// Hapus pesan
  /// [API -> FIREBASE DELETE]
  Future<void> deleteMessage(String messageId) {
    return _messageService.deleteMessage(messageId);
  }

  /// Stream pesan user
  /// [API -> FIREBASE STREAM]
  Stream<List<Message>> getUserMessagesStream(String recipientId) {
    return _messageService.getUserMessagesStream(recipientId);
  }

  /// Stream pesan belum dibaca
  /// [API -> FIREBASE STREAM]
  Stream<List<Message>> getUnreadMessagesStream(String recipientId) {
    return _messageService.getUnreadMessagesStream(recipientId);
  }

  /// Hitung jumlah pesan belum dibaca
  /// [API -> FIREBASE READ]
  Future<int> getUnreadMessageCount(String recipientId) {
    return _messageService.getUnreadMessageCount(recipientId);
  }

  // ---------------------------------------------------------------------------
  // 📌 REIMBURSEMENT
  // ---------------------------------------------------------------------------

  /// Membuat reimbursement baru
  /// [API -> FIREBASE WRITE]
  Future<String> createReimbursement(ReimbursementRequest request) {
    return _reimbursementService.createReimbursement(request);
  }

  /// Mengambil reimbursement user
  /// [API -> FIREBASE READ]
  Future<List<ReimbursementRequest>> getUserReimbursements(
    String employeeId,
  ) {
    return _reimbursementService.getUserReimbursements(employeeId);
  }

  /// Mengambil semua reimbursement (admin)
  /// [API -> FIREBASE READ]
  Future<List<ReimbursementRequest>> getAllReimbursements() {
    return _reimbursementService.getAllReimbursements();
  }

  /// Mengambil reimbursement berdasarkan ID
  /// [API -> FIREBASE READ]
  Future<ReimbursementRequest?> getReimbursementById(String id) {
    return _reimbursementService.getReimbursementById(id);
  }

  /// Update status reimbursement
  /// [API -> FIREBASE UPDATE]
  Future<void> updateReimbursementStatus(
    String id,
    String newStatus, {
    String? approvedBy,
    String? rejectionReason,
  }) {
    return _reimbursementService.updateReimbursementStatus(
      id,
      newStatus,
      approvedBy: approvedBy,
      rejectionReason: rejectionReason,
    );
  }

  /// Hapus reimbursement
  /// [API -> FIREBASE DELETE]
  Future<void> deleteReimbursement(String id) {
    return _reimbursementService.deleteReimbursement(id);
  }

  /// Stream reimbursement user
  /// [API -> FIREBASE STREAM]
  Stream<List<ReimbursementRequest>> getUserReimbursementsStream(
    String employeeId,
  ) {
    return _reimbursementService.getUserReimbursementsStream(employeeId);
  }
}
