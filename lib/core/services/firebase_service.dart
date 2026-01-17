import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // --- Lab Results ---

  Future<List<Map<String, dynamic>>> getLabResults({int limit = 10}) async {
    if (_userId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('lab_results')
          .orderBy('date', descending: true)
          .limit(limit)
          .get();
      
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Firestore fetch failed: $e');
      rethrow;
    }
  }

  Future<String?> createLabResult(Map<String, dynamic> data) async {
    if (_userId == null) return null;
    try {
      final List<dynamic> testResults = data['test_results'] ?? [];
      final status = testResults.any((t) => 
          (t['status']?.toString().toLowerCase() ?? '') == 'high' || 
          (t['status']?.toString().toLowerCase() ?? '') == 'low'
      ) ? 'Abnormal' : 'Normal';

      final docRef = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('lab_results')
          .add({
            'user_id': _userId,
            'lab_name': data['lab_name'] ?? 'Manual Upload',
            'date': data['date'] ?? DateTime.now().toIso8601String().split('T')[0],
            'status': status,
            'test_count': testResults.length,
            'test_results': testResults,
            'created_at': FieldValue.serverTimestamp(),
          });

      return docRef.id;
    } catch (e) {
      debugPrint('Error creating lab result: $e');
      rethrow;
    }
  }

  Future<void> deleteLabResult(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('lab_results')
        .doc(id)
        .delete();
  }

  // --- Profiles ---

  Future<Map<String, dynamic>?> getProfile() async {
    if (_userId == null) return null;
    try {
      final doc = await _firestore.collection('users').doc(_userId).get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      debugPrint('Firestore profile fetch failed: $e');
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> getProfileStream() {
    if (_userId == null) return Stream.value(null);
    return _firestore.collection('users').doc(_userId).snapshots().map((doc) => doc.data());
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_userId == null) return;
    await _firestore.collection('users').doc(_userId).set(data, SetOptions(merge: true));
  }

  Future<void> saveConditions(List<String> conditions) async {
    await updateProfile({'conditions': conditions});
  }

  // --- Prescriptions ---

  Future<List<Map<String, dynamic>>> getPrescriptions() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('prescriptions')
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching prescriptions: $e');
      rethrow;
    }
  }

  Future<void> addPrescription(Map<String, dynamic> data) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('prescriptions')
        .add({...data, 'created_at': FieldValue.serverTimestamp()});
  }

  Future<void> updatePrescription(String id, Map<String, dynamic> data) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('prescriptions')
        .doc(id)
        .update(data);
  }

  Future<void> deletePrescription(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('prescriptions')
        .doc(id)
        .delete();
  }

  Future<int> getActivePrescriptionsCount() async {
    if (_userId == null) return 0;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('prescriptions')
          .where('is_active', isEqualTo: true)
          .get();
      return snapshot.size;
    } catch (e) {
      return 0;
    }
  }

  // --- Trends & Search ---

  Future<List<Map<String, dynamic>>> getTrendData(String testName) async {
    if (_userId == null) return [];
    try {
      final results = await getLabResults(limit: 50);
      List<Map<String, dynamic>> trendPoints = [];
      
      for (var report in results) {
        final date = report['date'];
        final testResults = report['test_results'] as List?;
        if (testResults != null) {
          final match = testResults.firstWhere(
            (t) => (t['test_name'] ?? t['name']) == testName,
            orElse: () => null,
          );
          if (match != null) {
            trendPoints.add({
              'date': date,
              'value': double.tryParse(match['result_value']?.toString() ?? match['result']?.toString() ?? '0') ?? 0.0,
              'unit': match['unit'],
              'reference': match['reference_range'] ?? match['reference'],
            });
          }
        }
      }
      trendPoints.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));
      return trendPoints;
    } catch (e) {
      debugPrint('Error fetching trend data: $e');
      return [];
    }
  }

  Future<List<String>> getDistinctTests() async {
    if (_userId == null) return [];
    try {
      final results = await getLabResults(limit: 50);
      Set<String> testNames = {};
      for (var report in results) {
        final testResults = report['test_results'] as List?;
        if (testResults != null) {
          for (var t in testResults) {
            final name = t['test_name'] ?? t['name'];
            if (name != null) testNames.add(name);
          }
        }
      }
      return testNames.toList()..sort();
    } catch (e) {
      debugPrint('Error fetching distinct tests: $e');
      return [];
    }
  }

  // --- Notifications ---

  Future<List<Map<String, dynamic>>> getNotifications() async {
    if (_userId == null) return [];
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  Stream<List<Map<String, dynamic>>> getNotificationsStream() {
    if (_userId == null) return Stream.value([]);
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());
  }

  Future<void> markNotificationAsRead(String id) async {
    if (_userId == null) return;
    await _firestore
        .collection('users')
        .doc(_userId)
        .collection('notifications')
        .doc(id)
        .update({'is_read': true});
  }
}
