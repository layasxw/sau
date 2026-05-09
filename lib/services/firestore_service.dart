import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/onboarding/onboarding_data.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── Safe uid — never crashes if currentUser is briefly null ───────────────
  static String? get _uidOrNull => FirebaseAuth.instance.currentUser?.uid;
  static String get _uid {
    final uid = _uidOrNull;
    if (uid == null) throw Exception('FirestoreService: user not logged in');
    return uid;
  }

  // ── Onboarding ────────────────────────────────────────────────────────────

  static Future<void> saveUserData(OnboardingData data) async {
    await _db.collection('users').doc(_uid).set({
      'fullName': data.fullName,
      'age': data.age,
      'gender': data.gender,
      'height': data.height,
      'weight': data.weight,
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> saveMedicalProfile(OnboardingData data) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('medicalProfile')
        .doc('main')
        .set({
      'diagnosis': data.diagnosis,
      'medicalHistory': data.medicalHistory,
      'surgicalPeriod': data.surgicalPeriod,
      'surgeryDate': data.surgeryDate != null
          ? Timestamp.fromDate(data.surgeryDate!)
          : null,
    });
  }

  static Future<void> saveRestrictions(OnboardingData data) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('restrictions')
        .doc('main')
        .set({
      'allergies': data.allergies,
      'chronicDiseases': data.chronicDiseases,
      'dietaryRestrictions': data.dietaryRestrictions,
    });
  }

  static Future<void> completeOnboarding() async {
    await _db.collection('users').doc(_uid).set(
      {'onboardingComplete': true},
      SetOptions(merge: true),
    );
  }

  static Future<bool> isOnboardingComplete() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return doc.data()?['onboardingComplete'] == true;
    } catch (_) {
      return false;
    }
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getMedicalProfile() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('medicalProfile')
          .doc('main')
          .get()
          .timeout(const Duration(seconds: 8));
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getRestrictions() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('restrictions')
          .doc('main')
          .get()
          .timeout(const Duration(seconds: 8));
      return doc.data();
    } catch (_) {
      return null;
    }
  }

  static Future<void> updateUserProfile(Map<String, dynamic> fields) async {
    await _db.collection('users').doc(_uid).update(fields);
  }

  static Future<void> updateMedicalProfile(Map<String, dynamic> fields) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('medicalProfile')
        .doc('main')
        .update(fields);
  }

  // ── Role ──────────────────────────────────────────────────────────────────

  static Future<void> saveRole(String role, {String? fullName}) async {
    final data = <String, dynamic>{
      'role': role,
      'createdAt': FieldValue.serverTimestamp(),
      if (fullName != null) 'fullName': fullName,
    };
    if (role == 'doctor') data['doctorStatus'] = 'pending';
    await _db.collection('users').doc(_uid).set(data, SetOptions(merge: true));
  }

  static Future<String?> getRole() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 6));
      return doc.data()?['role'] as String?;
    } catch (_) {
      return null; // timeout or error → treat as regular user
    }
  }

  static Future<String?> getDoctorStatus() async {
    try {
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .get()
          .timeout(const Duration(seconds: 6));
      return doc.data()?['doctorStatus'] as String?;
    } catch (_) {
      return null;
    }
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReminders() async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('reminders')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addReminder(Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('reminders').add(data);
  }

  static Future<void> deleteReminder(String reminderId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  static Future<void> updateReminderCompleted(
      String reminderId, bool completed) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .doc(reminderId)
        .update({'completed': completed});
  }

  // ── Symptoms ──────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getSymptoms() async {
    try {
      final logs = await _db
          .collection('users')
          .doc(_uid)
          .collection('symptomLogs')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return logs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveSymptom(Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('symptomLogs').add(data);
  }

  // ── Meals ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMeals() async {
    try {
      final logs = await _db
          .collection('users')
          .doc(_uid)
          .collection('meals')
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return logs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> addMeal(Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('meals').add(data);
  }

  static Future<void> deleteMeal(String mealId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('meals')
        .doc(mealId)
        .delete();
  }

  // ── AI Cache ──────────────────────────────────────────────────────────────

  static Future<void> saveSuggestedReminders(
      List<Map<String, dynamic>> reminders) async {
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    await _db
        .collection('users')
        .doc(_uid)
        .collection('aiCache')
        .doc('suggestions')
        .set({'date': dateKey, 'reminders': reminders});
  }

  static Future<List<Map<String, dynamic>>?> getTodaySuggestedReminders() async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final doc = await _db
          .collection('users')
          .doc(_uid)
          .collection('aiCache')
          .doc('suggestions')
          .get()
          .timeout(const Duration(seconds: 6));
      if (!doc.exists) return null;
      final data = doc.data()!;
      if (data['date'] != dateKey) return null;
      return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
    } catch (_) {
      return null;
    }
  }

  // ── Doctor: patients assigned to this doctor ──────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .where('assignedDoctor', isEqualTo: _uid)
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientSymptoms(
      String patientId) async {
    try {
      final logs = await _db
          .collection('users')
          .doc(patientId)
          .collection('symptomLogs')
          .orderBy('date', descending: true)
          .limit(5)
          .get()
          .timeout(const Duration(seconds: 8));
      return logs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientSymptomsWeek(
      String patientId) async {
    try {
      final since =
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
      final logs = await _db
          .collection('users')
          .doc(patientId)
          .collection('symptomLogs')
          .where('date', isGreaterThanOrEqualTo: since)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return logs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientMealsWeek(
      String patientId) async {
    try {
      final since =
          Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
      final logs = await _db
          .collection('users')
          .doc(patientId)
          .collection('meals')
          .where('date', isGreaterThanOrEqualTo: since)
          .orderBy('date', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return logs.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getPatientTodayReminders(
      String patientId) async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(patientId)
          .collection('reminders')
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> adminGetAllPatients() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'patient')
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> adminGetAllDoctors() async {
    try {
      final snapshot = await _db
          .collection('users')
          .where('role', isEqualTo: 'doctor')
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> adminVerifyDoctor(String doctorId) async {
    await _db
        .collection('users')
        .doc(doctorId)
        .update({'doctorStatus': 'verified'});
  }

  static Future<void> adminAssignDoctor(
      String patientId, String doctorId, String doctorName) async {
    await _db.collection('users').doc(patientId).update({
      'assignedDoctor': doctorId,
      'assignedDoctorName': doctorName,
    });
  }

  static Future<void> adminUnassignDoctor(String patientId) async {
    await _db.collection('users').doc(patientId).update({
      'assignedDoctor': FieldValue.delete(),
      'assignedDoctorName': FieldValue.delete(),
    });
  }

  // ── Messages (doctor → patient) ───────────────────────────────────────────

  static Future<void> sendMessageToPatient(
      String patientId, String message) async {
    await _db
        .collection('users')
        .doc(patientId)
        .collection('messages')
        .add({
      'text': message,
      'fromDoctorId': _uid,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  static Future<List<Map<String, dynamic>>> getMyMessages() async {
    try {
      final snapshot = await _db
          .collection('users')
          .doc(_uid)
          .collection('messages')
          .orderBy('createdAt', descending: true)
          .get()
          .timeout(const Duration(seconds: 8));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (_) {
      return [];
    }
  }
}