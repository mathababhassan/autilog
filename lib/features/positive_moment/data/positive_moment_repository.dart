import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/activity_log_model.dart';
import '../../../shared/models/positive_moment_model.dart';

class PositiveMomentRepository {
  PositiveMomentRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  CollectionReference<Map<String, dynamic>> _momentsRef(
    String parentId,
    String childId,
  ) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('positiveMoments');
  }

  CollectionReference<Map<String, dynamic>> _activityRef(
    String parentId,
    String childId,
  ) {
    return _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('activityLogs');
  }

  Future<String> savePositiveMoment({
    required String parentId,
    required String childId,
    required PositiveMomentModel moment,
  }) async {
    final ref = moment.id.isEmpty
        ? _momentsRef(parentId, childId).doc()
        : _momentsRef(parentId, childId).doc(moment.id);
    print("Saving positive moment to path: parents/$parentId/children/$childId/positiveMoments/${ref.id}");

    await ref.set(moment.toMap());
    return ref.id;
  }

  Future<void> updatePositiveMoment({
    required String parentId,
    required String childId,
    required PositiveMomentModel moment,
  }) async {
    if (moment.id.isEmpty) {
      throw ArgumentError('moment.id is required for update');
    }
    await _momentsRef(parentId, childId).doc(moment.id).update({
      ...moment.toMap(),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<PositiveMomentModel> fetchPositiveMoment({
    required String parentId,
    required String childId,
    required String momentId,
  }) async {
    final doc = await _momentsRef(parentId, childId).doc(momentId).get();
    if (!doc.exists || doc.data() == null) {
      throw Exception('Positive moment not found');
    }
    return PositiveMomentModel.fromMap(doc.data()!, doc.id);
  }

  Future<List<PositiveMomentModel>> listPositiveMoments({
    required String parentId,
    required String childId,
    int limit = 50,
  }) async {
    final snap = await _momentsRef(parentId, childId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return snap.docs
        .map((d) => PositiveMomentModel.fromMap(d.data(), d.id))
        .toList();
  }

  Stream<List<PositiveMomentModel>> watchPositiveMoments({
    required String parentId,
    required String childId,
    int limit = 50,
  }) {
    return _momentsRef(parentId, childId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PositiveMomentModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<ActivityLogModel>> watchActivityLogs({
    required String parentId,
    required String childId,
    int limit = 30,
  }) {
    return _activityRef(parentId, childId)
        .orderBy('date', descending: true)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ActivityLogModel.fromMap(d.data(), d.id))
              .toList(),
        );
  }

  Future<void> deletePositiveMoment({
    required String parentId,
    required String childId,
    required String momentId,
  }) async {
    await _momentsRef(parentId, childId).doc(momentId).delete();
  }

  Future<String> uploadVideo({
    required String parentId,
    required String childId,
    required XFile file,
    String? momentId,
  }) async {
    final id = momentId ?? _firestore.collection('tmp').doc().id;
    final extension = _videoExtensionFor(file);
    final metadata = SettableMetadata(
      contentType: _videoContentTypeForExtension(extension),
    );
    final storageRef = _storage.ref().child(
      'positiveMoments/$parentId/$childId/$id/video.$extension',
    );

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await storageRef.putData(bytes, metadata);
    } else {
      await storageRef.putFile(File(file.path), metadata);
    }
    return storageRef.getDownloadURL();
  }

  String _videoExtensionFor(XFile file) {
    final name = file.name.trim();
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == name.length - 1) return 'mp4';
    final ext = name.substring(dotIndex + 1).toLowerCase();
    const supported = {
      'mp4', 'mov', 'm4v', 'webm', 'avi', 'wmv',
      '3gp', '3g2', 'mpeg', 'mpg', 'ogv', 'ts',
    };
    return supported.contains(ext) ? ext : 'mp4';
  }

  String _videoContentTypeForExtension(String ext) {
    switch (ext) {
      case 'mov':
        return 'video/quicktime';
      case 'm4v':
        return 'video/x-m4v';
      case 'webm':
        return 'video/webm';
      case 'avi':
        return 'video/x-msvideo';
      case 'wmv':
        return 'video/x-ms-wmv';
      case '3gp':
        return 'video/3gpp';
      case '3g2':
        return 'video/3gpp2';
      case 'mpeg':
      case 'mpg':
        return 'video/mpeg';
      case 'ogv':
        return 'video/ogg';
      case 'ts':
        return 'video/mp2t';
      default:
        return 'video/mp4';
    }
  }
}
