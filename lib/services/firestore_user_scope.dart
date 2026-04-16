import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class FirestoreUserScope {
  static const _prefsKey = 'local_user_scope_id';
  static String? _uid;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUid = prefs.getString(_prefsKey);

    if (savedUid != null && savedUid.isNotEmpty) {
      _uid = savedUid;
      return;
    }

    final generatedUid =
        'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(1 << 31)}';
    await prefs.setString(_prefsKey, generatedUid);
    _uid = generatedUid;
  }

  static String requireUid() {
    final uid = _uid;
    if (uid == null) {
      throw StateError('FirestoreUserScope.initialize() must be called first.');
    }
    return uid;
  }

  static CollectionReference<Map<String, dynamic>> subjects(
    FirebaseFirestore firestore,
  ) {
    return firestore
        .collection('users')
        .doc(requireUid())
        .collection('subjects');
  }

  static DocumentReference<Map<String, dynamic>> subjectDoc(
    FirebaseFirestore firestore,
    String subjectId,
  ) {
    return subjects(firestore).doc(subjectId);
  }

  static CollectionReference<Map<String, dynamic>> tasks(
    FirebaseFirestore firestore,
    String subjectId,
  ) {
    return subjectDoc(firestore, subjectId).collection('tasks');
  }

  static DocumentReference<Map<String, dynamic>> taskDoc(
    FirebaseFirestore firestore,
    String subjectId,
    String taskDocId,
  ) {
    return tasks(firestore, subjectId).doc(taskDocId);
  }
}
