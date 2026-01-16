import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/attendance.dart';
import 'dart:io';

// Firebase Service untuk Attendance (Kehadiran)
// FIREBASE: Mengelola CRUD operations di collection 'attendance'
class AttendanceService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _collectionName = 'attendance';
  static const _storagePath = 'attendance_photos';

  // Catat kehadiran baru ke Firebase
  // FIREBASE WRITE: Menyimpan dokumen baru ke Firestore
  Future<String> recordAttendance(Attendance attendance) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(attendance.toMap());

      print(' Attendance recorded with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print(' Error recording attendance: $e');
      rethrow;
    }
  }

  // Ambil kehadiran untuk user tertentu
  // FIREBASE READ: Query dokumen berdasarkan employeeId
  Future<List<Attendance>> getUserAttendance(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection(_collectionName)
          .where('employeeId', isEqualTo: employeeId);

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final snapshot = await query.orderBy('date', descending: true).get();

      return snapshot.docs
          .map((doc) => Attendance.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print(' Error fetching attendance: $e');
      return [];
    }
  }

  // Ambil kehadiran untuk tanggal tertentu
  // FIREBASE READ: Query dokumen berdasarkan date
  Future<Attendance?> getAttendanceByDate(
    String employeeId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay
          .add(const Duration(days: 1))
          .subtract(const Duration(microseconds: 1));

      final snapshot = await _firestore
          .collection(_collectionName)
          .where('employeeId', isEqualTo: employeeId)
          .where('date', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
          .where('date', isLessThanOrEqualTo: endOfDay.toIso8601String())
          .get();

      if (snapshot.docs.isNotEmpty) {
        return Attendance.fromMap(
          snapshot.docs.first.data(),
          snapshot.docs.first.id,
        );
      }
      return null;
    } catch (e) {
      print(' Error fetching attendance by date: $e');
      return null;
    }
  }

  // Ambil kehadiran berdasarkan ID
  // FIREBASE READ: Get dokumen spesifik
  Future<Attendance?> getAttendanceById(String id) async {
    try {
      final doc = await _firestore.collection(_collectionName).doc(id).get();

      if (doc.exists) {
        return Attendance.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print(' Error fetching attendance: $e');
      return null;
    }
  }

  // Upload foto kehadiran ke Firebase Storage
  // FIREBASE STORAGE: Menyimpan file foto
  Future<String> uploadAttendancePhoto(
    String filePath,
    String employeeId,
    DateTime date,
  ) async {
    try {
      final fileName =
          '${employeeId}_${date.toIso8601String().replaceAll(':', '-')}.jpg';
      final ref = _storage
          .ref()
          .child(_storagePath)
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .child(fileName);

      final file = File(filePath);
      await ref.putFile(file);

      final downloadUrl = await ref.getDownloadURL();
      print(' Photo uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print(' Error uploading photo: $e');
      rethrow;
    }
  }

  // Update kehadiran
  // FIREBASE UPDATE: Memperbarui dokumen yang ada
  Future<void> updateAttendance(String id, Attendance updatedAttendance) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(updatedAttendance.toMap());

      print(' Attendance updated: $id');
    } catch (e) {
      print(' Error updating attendance: $e');
      rethrow;
    }
  }

  // Update check-out time
  // FIREBASE UPDATE: Memperbarui hanya field checkOutTime
  Future<void> updateCheckOutTime(String id, String checkOutTime) async {
    try {
      await _firestore.collection(_collectionName).doc(id).update({
        'checkOutTime': checkOutTime,
      });

      print(' Check-out time updated');
    } catch (e) {
      print(' Error updating check-out time: $e');
      rethrow;
    }
  }

  // Hapus kehadiran
  // FIREBASE DELETE: Menghapus dokumen dari Firestore
  Future<void> deleteAttendance(String id) async {
    try {
      await _firestore.collection(_collectionName).doc(id).delete();

      print(' Attendance deleted: $id');
    } catch (e) {
      print(' Error deleting attendance: $e');
      rethrow;
    }
  }

  // Dapatkan statistik kehadiran
  // FIREBASE READ: Menghitung dokumen dengan status tertentu
  Future<Map<String, int>> getAttendanceStats(
    String employeeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _firestore
          .collection(_collectionName)
          .where('employeeId', isEqualTo: employeeId);

      if (startDate != null) {
        query = query.where(
          'date',
          isGreaterThanOrEqualTo: startDate.toIso8601String(),
        );
      }

      if (endDate != null) {
        query = query.where(
          'date',
          isLessThanOrEqualTo: endDate.toIso8601String(),
        );
      }

      final snapshot = await query.get();

      final stats = <String, int>{
        'Hadir': 0,
        'Izin': 0,
        'Sakit': 0,
        'Libur': 0,
        'Alpa': 0,
      };

      for (final doc in snapshot.docs) {
        final status = doc['status'] ?? 'Alpa';
        stats[status] = (stats[status] ?? 0) + 1;
      }

      return stats;
    } catch (e) {
      print(' Error getting attendance stats: $e');
      return {};
    }
  }

  // Stream untuk real-time attendance updates
  // FIREBASE STREAM: Listen ke perubahan kehadiran real-time
  Stream<List<Attendance>> getUserAttendanceStream(String employeeId) {
    return _firestore
        .collection(_collectionName)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Attendance.fromMap(doc.data(), doc.id))
              .toList(),
        );
  }
}
