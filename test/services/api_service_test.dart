import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:peresenceapp/models/attendance.dart';
import 'package:peresenceapp/models/leave_request.dart';
import 'package:peresenceapp/models/message.dart';
import 'package:peresenceapp/models/reimbursement_request.dart';
import 'package:peresenceapp/services/api_service.dart';
import 'package:peresenceapp/services/attendance_service.dart';
import 'package:peresenceapp/services/leave_request_service.dart';
import 'package:peresenceapp/services/message_service.dart';
import 'package:peresenceapp/services/reimbursement_service.dart';

// Lightweight fakes to avoid Firebase calls and capture invocations
class FakeAttendanceService extends AttendanceService {
  Attendance? lastRecorded;
  String recordReturnId = 'att-1';

  List<Attendance> getUserAttendanceReturn = const [];
  String? lastGetUserAttendanceEmployeeId;
  DateTime? lastStartDate;
  DateTime? lastEndDate;

  String? lastUpdateCheckOutId;
  String? lastCheckOutTime;

  Map<String, int> attendanceStatsReturn = const {'Hadir': 3, 'Izin': 1};
  String? lastStatsEmployeeId;

  final _attendanceStreamController = StreamController<List<Attendance>>.broadcast();
  String? lastAttendanceStreamEmployeeId;

  @override
  Future<String> recordAttendance(Attendance attendance) async {
    lastRecorded = attendance;
    return recordReturnId;
  }

  @override
  Future<List<Attendance>> getUserAttendance(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastGetUserAttendanceEmployeeId = employeeId;
    lastStartDate = startDate;
    lastEndDate = endDate;
    return getUserAttendanceReturn;
  }

  @override
  Future<void> updateCheckOutTime(String id, String checkOutTime) async {
    lastUpdateCheckOutId = id;
    lastCheckOutTime = checkOutTime;
  }

  @override
  Future<Map<String, int>> getAttendanceStats(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    lastStatsEmployeeId = employeeId;
    return attendanceStatsReturn;
  }

  @override
  Stream<List<Attendance>> getUserAttendanceStream(String employeeId) {
    lastAttendanceStreamEmployeeId = employeeId;
    return _attendanceStreamController.stream;
  }

  void emitAttendanceStream(List<Attendance> data) {
    _attendanceStreamController.add(data);
  }

  Future<void> close() async {
    await _attendanceStreamController.close();
  }
}

class FakeLeaveRequestService extends LeaveRequestService {
  String? lastUpdateId;
  String? lastNewStatus;
  String? lastApprovedBy;

  @override
  Future<void> updateLeaveRequestStatus(
    String id,
    String newStatus, {
    String? approvedBy,
  }) async {
    lastUpdateId = id;
    lastNewStatus = newStatus;
    lastApprovedBy = approvedBy;
  }
}

class FakeMessageService extends MessageService {
  String? lastMarkAllRecipientId;
  int unreadCountReturn = 5;

  final _messagesStreamController = StreamController<List<Message>>.broadcast();
  String? lastMessagesStreamRecipientId;

  @override
  Future<void> markAllMessagesAsRead(String recipientId) async {
    lastMarkAllRecipientId = recipientId;
  }

  @override
  Future<int> getUnreadMessageCount(String recipientId) async {
    return unreadCountReturn;
  }

  @override
  Stream<List<Message>> getUserMessagesStream(String recipientId) {
    lastMessagesStreamRecipientId = recipientId;
    return _messagesStreamController.stream;
  }

  void emitMessagesStream(List<Message> data) {
    _messagesStreamController.add(data);
  }

  Future<void> close() async {
    await _messagesStreamController.close();
  }
}

class FakeReimbursementService extends ReimbursementService {
  String? lastUpdateId;
  String? lastNewStatus;
  String? lastApprovedBy;
  String? lastRejectionReason;
  String? lastDeletedId;

  @override
  Future<void> updateReimbursementStatus(
    String id,
    String newStatus, {
    String? approvedBy,
    String? rejectionReason,
  }) async {
    lastUpdateId = id;
    lastNewStatus = newStatus;
    lastApprovedBy = approvedBy;
    lastRejectionReason = rejectionReason;
  }

  @override
  Future<void> deleteReimbursement(String id) async {
    lastDeletedId = id;
  }
}

void main() {
  late FakeAttendanceService fakeAttendance;
  late FakeLeaveRequestService fakeLeave;
  late FakeMessageService fakeMessage;
  late FakeReimbursementService fakeReimb;

  setUp(() {
    fakeAttendance = FakeAttendanceService();
    fakeLeave = FakeLeaveRequestService();
    fakeMessage = FakeMessageService();
    fakeReimb = FakeReimbursementService();

    // Inject fakes into the singleton ApiService for isolation
    ApiService.instance.injectServicesForTesting(
      attendanceService: fakeAttendance,
      leaveRequestService: fakeLeave,
      messageService: fakeMessage,
      reimbursementService: fakeReimb,
    );
  });

  tearDown(() async {
    await fakeAttendance.close();
    await fakeMessage.close();
  });

  group('ApiService - Attendance', () {
    test('createAttendance delegates to service and returns id', () async {
      final attendance = Attendance(
        employeeId: 'emp1',
        employeeName: 'Alice',
        date: DateTime(2024, 1, 1),
        checkInTime: '08:00',
      );
      fakeAttendance.recordReturnId = 'new-att-42';

      final id = await ApiService.instance.createAttendance(attendance);

      expect(id, 'new-att-42');
      expect(fakeAttendance.lastRecorded, isNotNull);
      expect(fakeAttendance.lastRecorded!.employeeId, 'emp1');
    });

    test('getUserAttendance forwards filters and returns list', () async {
      final a1 = Attendance(
        id: 'a1',
        employeeId: 'emp2',
        employeeName: 'Bob',
        date: DateTime(2024, 2, 10),
      );
      fakeAttendance.getUserAttendanceReturn = [a1];

      final start = DateTime(2024, 2, 1);
      final end = DateTime(2024, 2, 28);

      final list = await ApiService.instance.getUserAttendance(
        'emp2',
        startDate: start,
        endDate: end,
      );

      expect(list, hasLength(1));
      expect(list.first.id, 'a1');
      expect(fakeAttendance.lastGetUserAttendanceEmployeeId, 'emp2');
      expect(fakeAttendance.lastStartDate, start);
      expect(fakeAttendance.lastEndDate, end);
    });

    test('updateCheckOutTime delegates with correct parameters', () async {
      await ApiService.instance.updateCheckOutTime('att-9', '17:30');
      expect(fakeAttendance.lastUpdateCheckOutId, 'att-9');
      expect(fakeAttendance.lastCheckOutTime, '17:30');
    });

    test('getAttendanceStats returns computed stats from service', () async {
      fakeAttendance.attendanceStatsReturn = {'Hadir': 2, 'Sakit': 1};
      final stats = await ApiService.instance.getAttendanceStats('emp3');
      expect(stats, containsPair('Hadir', 2));
      expect(stats, containsPair('Sakit', 1));
      expect(fakeAttendance.lastStatsEmployeeId, 'emp3');
    });

    test('getUserAttendanceStream yields real-time updates', () async {
      final stream = ApiService.instance.getUserAttendanceStream('emp4');

      final futureExpectation = expectLater(
        stream,
        emitsInOrder([
          predicate<List<Attendance>>((list) => list.isEmpty),
          predicate<List<Attendance>>((list) => list.length == 1 && list.first.employeeId == 'emp4'),
        ]),
      );

      fakeAttendance.emitAttendanceStream([]);
      fakeAttendance.emitAttendanceStream([
        Attendance(
          id: 's1',
          employeeId: 'emp4',
          employeeName: 'Cara',
          date: DateTime(2024, 3, 5),
        )
      ]);

      await futureExpectation;
      expect(fakeAttendance.lastAttendanceStreamEmployeeId, 'emp4');
    });
  });

  group('ApiService - Leave Requests', () {
    test('updateLeaveRequestStatus delegates with approvedBy', () async {
      await ApiService.instance.updateLeaveRequestStatus(
        'lr-10',
        'Disetujui',
        approvedBy: 'manager1',
      );
      expect(fakeLeave.lastUpdateId, 'lr-10');
      expect(fakeLeave.lastNewStatus, 'Disetujui');
      expect(fakeLeave.lastApprovedBy, 'manager1');
    });
  });

  group('ApiService - Messages', () {
    test('markAllMessagesAsRead delegates to service', () async {
      await ApiService.instance.markAllMessagesAsRead('u-100');
      expect(fakeMessage.lastMarkAllRecipientId, 'u-100');
    });

    test('getUnreadMessageCount returns value from service', () async {
      fakeMessage.unreadCountReturn = 7;
      final count = await ApiService.instance.getUnreadMessageCount('u-200');
      expect(count, 7);
    });

    test('getUserMessagesStream emits lists of messages', () async {
      final stream = ApiService.instance.getUserMessagesStream('u-300');

      final futureExpectation = expectLater(
        stream,
        emitsInOrder([
          predicate<List<Message>>((list) => list.isEmpty),
          predicate<List<Message>>((list) => list.length == 2 && list[0].title == 'Hello'),
        ]),
      );

      fakeMessage.emitMessagesStream([]);
      fakeMessage.emitMessagesStream([
        Message(
          id: 'm1',
          senderId: 's1',
          senderName: 'Sender',
          recipientId: 'u-300',
          title: 'Hello',
          body: 'World',
          sentAt: DateTime(2024, 1, 1),
        ),
        Message(
          id: 'm2',
          senderId: 's2',
          senderName: 'Sender2',
          recipientId: 'u-300',
          title: 'Hi',
          body: 'Again',
          sentAt: DateTime(2024, 1, 2),
        ),
      ]);

      await futureExpectation;
      expect(fakeMessage.lastMessagesStreamRecipientId, 'u-300');
    });
  });

  group('ApiService - Reimbursements', () {
    test('updateReimbursementStatus delegates with rejectionReason', () async {
      await ApiService.instance.updateReimbursementStatus(
        'rb-10',
        'Ditolak',
        approvedBy: 'manager2',
        rejectionReason: 'Incomplete docs',
      );
      expect(fakeReimb.lastUpdateId, 'rb-10');
      expect(fakeReimb.lastNewStatus, 'Ditolak');
      expect(fakeReimb.lastApprovedBy, 'manager2');
      expect(fakeReimb.lastRejectionReason, 'Incomplete docs');
    });

    test('deleteReimbursement delegates to service', () async {
      await ApiService.instance.deleteReimbursement('rb-99');
      expect(fakeReimb.lastDeletedId, 'rb-99');
    });
  });
}
