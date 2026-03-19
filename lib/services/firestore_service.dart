import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/onboarding/onboarding_data.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  static Future<void> saveUserData(OnboardingData data) async {
    await _db.collection('users').doc(_uid).set({
      'fullName' : data.fullName,
      'age' : data.age,
      'gender' : data.gender,
      'height': data.height,
      'weight': data.weight,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveMedicalProfile(OnboardingData data) async {
    await _db
      .collection('users') 
      .doc(_uid)
      .collection('medicalProfile')
      .doc('main')
      .set({
      'diagnosis' : data.diagnosis,
      'medicalHistory' : data.medicalHistory,
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

  static Future<Map<String, dynamic>?> getUserProfile() async {
    final doc = await _db.collection('users').doc(_uid).get();
    return doc.data(); // returns the fields as a Map, or null if doc doesn't exist
  }

  static Future<Map<String, dynamic>?> getMedicalProfile() async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('medicalProfile')
        .doc('main')
        .get();
    return doc.data(); // returns the fields as a Map, or null if doc doesn't exist
  }

  static Future<Map<String, dynamic>?> getRestrictions() async {
    final doc = await _db
        .collection('users')
        .doc(_uid)
        .collection('restrictions')
        .doc('main')
        .get();
    return doc.data(); // returns the fields as a Map, or null if doc doesn't exist
  }
  
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
    await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .add(data); // .add() auto-generates the document id
  }

  static Future<void> deleteReminder(String reminderId) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .doc(reminderId)
        .delete();
  }

  static Future<void> updateReminderCompleted(String reminderId, bool completed) async {
    await _db
        .collection('users')
        .doc(_uid)
        .collection('reminders')
        .doc(reminderId)
        .update({'completed': completed}); // only updates this one field
  }

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
}

