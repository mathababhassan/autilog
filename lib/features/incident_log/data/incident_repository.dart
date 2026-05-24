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

  Future<String> uploadVideo({
    required String parentId,
    required String childId,
    required XFile file,
  }) async {
    final uniqueId = _firestore.collection('tmp').doc().id;
    final storageRef = _storage
        .ref()
        .child('incidents/$parentId/$childId/$uniqueId/video.mp4');

    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      await storageRef.putData(
        bytes,
        SettableMetadata(contentType: 'video/mp4'),
      );
    } else {
      await storageRef.putFile(File(file.path));
    }
    return storageRef.getDownloadURL();
  }
}
