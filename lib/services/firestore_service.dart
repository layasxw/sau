import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/onboarding/onboarding_data.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

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
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['onboardingComplete'] == true;
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data();
  }

  static Future<Map<String, dynamic>?> getMedicalProfile() async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('medicalProfile')
        .doc('main')
        .get();
    return doc.data();
  }

  static Future<Map<String, dynamic>?> getRestrictions() async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('restrictions')
        .doc('main')
        .get();
    return doc.data();
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

  /// Called on signup. Doctors get doctorStatus: 'pending' until admin verifies.
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
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['role'] as String?;
  }

  /// Returns 'pending' or 'verified' for doctor accounts.
  static Future<String?> getDoctorStatus() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data()?['doctorStatus'] as String?;
  }

  // ── Reminders ─────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getReminders() async {
    final snapshot = await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
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
    final logs = await _db
        .collection('users')
        .doc(_uid)
        .collection('symptomLogs')
        .orderBy('date', descending: true)
        .get();
    return logs.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<void> saveSymptom(Map<String, dynamic> data) async {
    await _db.collection('users').doc(_uid).collection('symptomLogs').add(data);
  }

  // ── Meals ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> getMeals() async {
    final logs = await _db
        .collection('users')
        .doc(_uid)
        .collection('meals')
        .orderBy('date', descending: true)
        .get();
    return logs.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
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
    final today = DateTime.now();
    final dateKey =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('aiCache')
        .doc('suggestions')
        .get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['date'] != dateKey) return null;
    return List<Map<String, dynamic>>.from(data['reminders'] ?? []);
  }

  // ── Doctor: patients assigned to this doctor ──────────────────────────────

  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .where('assignedDoctor', isEqualTo: _uid)
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPatientSymptoms(
      String patientId) async {
    final logs = await _db
        .collection('users')
        .doc(patientId)
        .collection('symptomLogs')
        .orderBy('date', descending: true)
        .limit(5)
        .get();
    return logs.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPatientSymptomsWeek(
      String patientId) async {
    final since =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    final logs = await _db
        .collection('users')
        .doc(patientId)
        .collection('symptomLogs')
        .where('date', isGreaterThanOrEqualTo: since)
        .orderBy('date', descending: true)
        .get();
    return logs.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPatientMealsWeek(
      String patientId) async {
    final since =
        Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 7)));
    final logs = await _db
        .collection('users')
        .doc(patientId)
        .collection('meals')
        .where('date', isGreaterThanOrEqualTo: since)
        .orderBy('date', descending: true)
        .get();
    return logs.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> getPatientTodayReminders(
      String patientId) async {
    final snapshot = await _db
        .collection('users')
        .doc(patientId)
        .collection('reminders')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  static Future<List<Map<String, dynamic>>> adminGetAllPatients() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'patient')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  static Future<List<Map<String, dynamic>>> adminGetAllDoctors() async {
    final snapshot = await _db
        .collection('users')
        .where('role', isEqualTo: 'doctor')
        .get();
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  /// Admin verifies a doctor → doctorStatus: 'verified'.
  static Future<void> adminVerifyDoctor(String doctorId) async {
    await _db
        .collection('users')
        .doc(doctorId)
        .update({'doctorStatus': 'verified'});
  }

  /// Admin assigns a verified doctor to a patient.
  static Future<void> adminAssignDoctor(
      String patientId, String doctorId, String doctorName) async {
    await _db.collection('users').doc(patientId).update({
      'assignedDoctor': doctorId,
      'assignedDoctorName': doctorName,
    });
  }

  /// Admin removes doctor assignment from a patient.
  static Future<void> adminUnassignDoctor(String patientId) async {
    await _db.collection('users').doc(patientId).update({
      'assignedDoctor': FieldValue.delete(),
      'assignedDoctorName': FieldValue.delete(),
    });
  }
}