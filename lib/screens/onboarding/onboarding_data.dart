// This is a plain Dart class — no widgets, no Flutter imports needed.
// It's just a container that holds all the answers the user gives
// across all 4 steps. The shell creates one instance and passes it
// to every step, so they all read/write to the same object.

class OnboardingData {
  // ── Step 1: Personal Info ──────────────────────────
  String fullName = '';
  int age = 25;
  String gender = '';

  // ── Step 2: Body Metrics ───────────────────────────
  double height = 170;
  double weight = 70;

  // ── Step 3: Diagnosis ──────────────────────────────
  String diagnosis = '';
  String medicalHistory = '';

  // ── Step 4: Restrictions ───────────────────────────
  List<String> allergies = [];
  List<String> chronicDiseases = [];
  List<String> dietaryRestrictions = [];

  // ── Calculated Nutrition Targets ─────────────────────
  double dailyCalories = 0;
  double dailyProtein = 0;
  double dailyCarbs = 0;
  double dailyFat = 0;
}
