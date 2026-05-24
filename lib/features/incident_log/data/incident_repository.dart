import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../../../shared/models/incident_model.dart';

class IncidentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> saveIncident({
    required String parentId,
    required String childId,
    required IncidentModel incident,
  }) async {
    final ref = _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('incidents')
        .doc();

    await ref.set(incident.toMap());
    return ref.id;
  }

  Future<IncidentModel> fetchIncident({
    required String parentId,
    required String childId,
    required String incidentId,
  }) async {
    final doc = await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('incidents')
        .doc(incidentId)
        .get();

    if (!doc.exists || doc.data() == null) {
      throw Exception('Incident not found');
    }

    return IncidentModel.fromMap(doc.data()!, doc.id);
  }

  Future<void> deleteIncident({
    required String parentId,
    required String childId,
    required String incidentId,
  }) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('incidents')
        .doc(incidentId)
        .delete();
  }

  Future<void> updateIncident({
    required String parentId,
    required String childId,
    required String incidentId,
    required Map<String, dynamic> data,
  }) async {
    await _firestore
        .collection('parents')
        .doc(parentId)
        .collection('children')
        .doc(childId)
        .collection('incidents')
        .doc(incidentId)
        .update(data);
  }

  Future<void> deleteVideo(String videoUrl) async {
    try {
      await _storage.refFromURL(videoUrl).delete();
    } on FirebaseException catch (e) {
      if (e.code != 'object-not-found') rethrow;
    }
  }

  Future<String> uploadVideo({
    required String parentId,
    required String childId,
    required XFile file,
  }) async {
    final uniqueId = _firestore.collection('tmp').doc().id;
    final extension = _videoExtensionFor(file);
    final metadata = SettableMetadata(
      contentType: _videoContentTypeForExtension(extension),
    );
    final storageRef = _storage
        .ref()
        .child('incidents/$parentId/$childId/$uniqueId/video.$extension');

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
      case 'mov':  return 'video/quicktime';
      case 'm4v':  return 'video/x-m4v';
      case 'webm': return 'video/webm';
      case 'avi':  return 'video/x-msvideo';
      case 'wmv':  return 'video/x-ms-wmv';
      case '3gp':  return 'video/3gpp';
      case '3g2':  return 'video/3gpp2';
      case 'mpeg':
      case 'mpg':  return 'video/mpeg';
      case 'ogv':  return 'video/ogg';
      case 'ts':   return 'video/mp2t';
      default:     return 'video/mp4';
    }
  }
}
