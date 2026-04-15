import './onboarding/onboarding_data.dart';

class NutritionCalculator {
  static void calculate(OnboardingData data) {
    if (data.gender.isEmpty ||
        data.height <= 0 ||
        data.weight <= 0 ||
        data.age <= 0) {
      return;
    }

    // 1️⃣ BMR — Mifflin-St Jeor
    double bmr;

    if (data.gender == 'Male') {
      bmr = 10 * data.weight +
          6.25 * data.height -
          5 * data.age +
          5;
    } else {
      bmr = 10 * data.weight +
          6.25 * data.height -
          5 * data.age -
          161;
    }

    // 2️⃣ Низкая активность (для восстановления ЖКТ)
    const activity = 1.2;

    final tdee = bmr * activity;
    data.dailyCalories = tdee;

    // 3️⃣ Белок 1.3 г/кг (важно для восстановления)
    final proteinGrams = data.weight * 1.3;
    data.dailyProtein = proteinGrams;

    // 4️⃣ Жиры 30%
    final fatCalories = tdee * 0.3;
    final fatGrams = fatCalories / 9;
    data.dailyFat = fatGrams;

    // 5️⃣ Углеводы — остаток
    final proteinCalories = proteinGrams * 4;
    final carbsCalories = tdee - proteinCalories - fatCalories;
    final carbsGrams = carbsCalories / 4;
    data.dailyCarbs = carbsGrams;
  }
}