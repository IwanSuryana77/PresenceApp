import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/reimbursement_request.dart';
import 'dart:io';


/// 📌 Firebase Service untuk Reimbursement Request (Pengembalian Dana)
/// 💾 FIREBASE: Mengelola CRUD operations di collection 'reimbursement_requests'
class ReimbursementService {
  static final _firestore = FirebaseFirestore.instance;
  static final _storage = FirebaseStorage.instance;
  static const _collectionName = 'reimbursement_requests';
  static const _storagePath = 'reimbursement_attachments';

  /// ➕ Tambah data reimbursement ke Firebase
  /// 💾 FIREBASE WRITE: Menyimpan dokumen baru ke Firestore
  Future<String> createReimbursement(ReimbursementRequest request) async {
    try {
      final docRef = await _firestore
          .collection(_collectionName)
          .add(request.toMap());

      print('✅ Reimbursement created with ID: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      print('❌ Error creating reimbursement: $e');
      rethrow;
    }
  }

  /// 📖 Ambil semua reimbursement untuk user tertentu
  /// 💾 FIREBASE READ: Query dokumen berdasarkan employeeId
  Future<List<ReimbursementRequest>> getUserReimbursements(
    String employeeId,
  ) async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .where('employeeId', isEqualTo: employeeId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReimbursementRequest.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching reimbursements: $e');
      return [];
    }
  }

  /// 📖 Ambil semua reimbursement (untuk admin/approval)
  /// 💾 FIREBASE READ: Query semua dokumen
  Future<List<ReimbursementRequest>> getAllReimbursements() async {
    try {
      final snapshot = await _firestore
          .collection(_collectionName)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ReimbursementRequest.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('❌ Error fetching all reimbursements: $e');
      return [];
    }
  }

  /// 📖 Ambil reimbursement berdasarkan ID
  /// 💾 FIREBASE READ: Get dokumen spesifik
  Future<ReimbursementRequest?> getReimbursementById(String id) async {
    try {
      final doc = await _firestore
          .collection(_collectionName)
          .doc(id)
          .get();

      if (doc.exists) {
        return ReimbursementRequest.fromMap(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }
      return null;
    } catch (e) {
      print('❌ Error fetching reimbursement: $e');
      return null;
    }
  }

  /// 📤 Upload file ke Firebase Storage
  /// 💾 FIREBASE STORAGE: Menyimpan file (bukti/lampiran)
  Future<String> uploadAttachment(String filePath, String fileName) async {
    try {
      final ref = _storage
          .ref()
          .child(_storagePath)
          .child(DateTime.now().millisecondsSinceEpoch.toString())
          .child(fileName);

      final uploadTask = await ref.putFile(
        await Future.value(File(filePath).readAsBytes()).then((_) => File(filePath)),
      );

      final downloadUrl = await ref.getDownloadURL();
      print('✅ File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ Error uploading file: $e');
      rethrow;
    }
  }

  /// ✏️ Update status reimbursement
  /// 💾 FIREBASE UPDATE: Memperbarui dokumen yang ada
  Future<void> updateReimbursementStatus(
    String id,
    String newStatus, {
    String? approvedBy,
    String? rejectionReason,
  }) async {
    try {
      final updateData = {
        'status': newStatus,
        'approvedAt': DateTime.now().toIso8601String(),
        'approvedBy': approvedBy,
      };

      if (rejectionReason != null) {
        updateData['rejectionReason'] = rejectionReason;
      }

      await _firestore
          .collection(_collectionName)
          .doc(id)
          .update(updateData);

      print('✅ Reimbursement status updated to: $newStatus');
    } catch (e) {
      print('❌ Error updating reimbursement: $e');
      rethrow;
    }
  }

  /// 🗑️ Hapus reimbursement
  /// 💾 FIREBASE DELETE: Menghapus dokumen dari Firestore
  Future<void> deleteReimbursement(String id) async {
    try {
      await _firestore
          .collection(_collectionName)
          .doc(id)
          .delete();

      print('✅ Reimbursement deleted: $id');
    } catch (e) {
      print('❌ Error deleting reimbursement: $e');
      rethrow;
    }
  }

  /// 📊 Stream untuk real-time updates
  /// 💾 FIREBASE STREAM: Listen ke perubahan data real-time
  Stream<List<ReimbursementRequest>> getUserReimbursementsStream(
    String employeeId,
  ) {
    return _firestore
        .collection(_collectionName)
        .where('employeeId', isEqualTo: employeeId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReimbursementRequest.fromMap(doc.data(), doc.id))
            .toList());
  }
}


