import '../services/language_provider.dart';
import '../l10n/translations.dart';

class FoodProduct {
  final String nameRu;
  final String nameKk;
  final String nameEn;
  final String categoryKey;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? gramsPerUnit;
  final String? unitLabel;

  FoodProduct({
    required this.nameRu,
    required this.nameKk,
    required this.nameEn,
    required this.categoryKey,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.gramsPerUnit,
    this.unitLabel,
  });

  String name(AppLanguage lang) {
    switch (lang) {
      case AppLanguage.ru:
        return nameRu;
      case AppLanguage.kk:
        return nameKk;
      case AppLanguage.en:
        return nameEn;
    }
  }

  String category(AppLanguage lang) => Translations.get(lang, categoryKey);

  /// Matches a search query against the name in any language, so a food
  /// logged or searched in one language is still found after switching.
  bool matches(String query) {
    final q = query.toLowerCase();
    return nameRu.toLowerCase().contains(q) ||
        nameKk.toLowerCase().contains(q) ||
        nameEn.toLowerCase().contains(q);
  }
}

final List<FoodProduct> foodDatabase = [
  // ── Proteins ──────────────────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Куриная грудка (отварная)',
      nameKk: 'Тауық төс еті (қайнатылған)',
      nameEn: 'Chicken Breast (boiled)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
  FoodProduct(
      nameRu: 'Индейка (отварная)',
      nameKk: 'Күркетауық (қайнатылған)',
      nameEn: 'Turkey (boiled)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 135, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 1.8),
  FoodProduct(
      nameRu: 'Яйцо (варёное)',
      nameKk: 'Жұмыртқа (пісірілген)',
      nameEn: 'Egg (boiled)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, gramsPerUnit: 60, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Лосось (на пару)',
      nameKk: 'Лосось (буға пісірілген)',
      nameEn: 'Salmon (steamed)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13),
  FoodProduct(
      nameRu: 'Белая рыба (отварная)',
      nameKk: 'Ақ балық (қайнатылған)',
      nameEn: 'White Fish (boiled)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 96, proteinPer100g: 21, carbsPer100g: 0, fatPer100g: 1.2),
  FoodProduct(
      nameRu: 'Творог (нежирный)',
      nameKk: 'Сүзбе (майсыз)',
      nameEn: 'Cottage Cheese (low fat)',
      categoryKey: 'cat_protein',
      caloriesPer100g: 72, proteinPer100g: 12, carbsPer100g: 3.4, fatPer100g: 1.0, gramsPerUnit: 200, unitLabel: 'уп'),

  // ── Grains & Carbs ────────────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Белый рис (варёный)',
      nameKk: 'Ақ күріш (пісірілген)',
      nameEn: 'White Rice (cooked)',
      categoryKey: 'cat_grains',
      caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3),
  FoodProduct(
      nameRu: 'Овсянка (варёная)',
      nameKk: 'Сұлы ботқасы (пісірілген)',
      nameEn: 'Oatmeal (cooked)',
      categoryKey: 'cat_grains',
      caloriesPer100g: 71, proteinPer100g: 2.5, carbsPer100g: 12, fatPer100g: 1.5),
  FoodProduct(
      nameRu: 'Белый хлеб',
      nameKk: 'Ақ нан',
      nameEn: 'White Bread',
      categoryKey: 'cat_grains',
      caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2),
  FoodProduct(
      nameRu: 'Гречка (варёная)',
      nameKk: 'Қарақұмық (пісірілген)',
      nameEn: 'Buckwheat (cooked)',
      categoryKey: 'cat_grains',
      caloriesPer100g: 92, proteinPer100g: 3.4, carbsPer100g: 20, fatPer100g: 0.6),
  FoodProduct(
      nameRu: 'Макароны (варёные)',
      nameKk: 'Макарон (пісірілген)',
      nameEn: 'Pasta (cooked)',
      categoryKey: 'cat_grains',
      caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1),

  // ── Vegetables ────────────────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Картофель (отварной)',
      nameKk: 'Картоп (қайнатылған)',
      nameEn: 'Potato (boiled)',
      categoryKey: 'cat_vegetables',
      caloriesPer100g: 87, proteinPer100g: 1.9, carbsPer100g: 20, fatPer100g: 0.1),
  FoodProduct(
      nameRu: 'Морковь (отварная)',
      nameKk: 'Сәбіз (қайнатылған)',
      nameEn: 'Carrot (boiled)',
      categoryKey: 'cat_vegetables',
      caloriesPer100g: 35, proteinPer100g: 0.8, carbsPer100g: 8, fatPer100g: 0.2),
  FoodProduct(
      nameRu: 'Кабачок (отварной)',
      nameKk: 'Кабак (қайнатылған)',
      nameEn: 'Zucchini (boiled)',
      categoryKey: 'cat_vegetables',
      caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3),
  FoodProduct(
      nameRu: 'Тыква (отварная)',
      nameKk: 'Асқабақ (қайнатылған)',
      nameEn: 'Pumpkin (boiled)',
      categoryKey: 'cat_vegetables',
      caloriesPer100g: 20, proteinPer100g: 0.7, carbsPer100g: 4.9, fatPer100g: 0.1),
  FoodProduct(
      nameRu: 'Брокколи (на пару)',
      nameKk: 'Брокколи (буға пісірілген)',
      nameEn: 'Broccoli (steamed)',
      categoryKey: 'cat_vegetables',
      caloriesPer100g: 35, proteinPer100g: 2.4, carbsPer100g: 7, fatPer100g: 0.4),

  // ── Fruits ────────────────────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Яблоко', nameKk: 'Алма', nameEn: 'Apple',
      categoryKey: 'cat_fruits',
      caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, gramsPerUnit: 150, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Банан', nameKk: 'Банан', nameEn: 'Banana',
      categoryKey: 'cat_fruits',
      caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3, gramsPerUnit: 120, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Груша', nameKk: 'Алмұрт', nameEn: 'Pear',
      categoryKey: 'cat_fruits',
      caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1, gramsPerUnit: 150, unitLabel: 'шт'),

  // ── Dairy ─────────────────────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Йогурт (натуральный, нежирный)',
      nameKk: 'Йогурт (табиғи, майсыз)',
      nameEn: 'Yogurt (plain, low fat)',
      categoryKey: 'cat_dairy',
      caloriesPer100g: 56, proteinPer100g: 4.7, carbsPer100g: 6.8, fatPer100g: 0.6),
  FoodProduct(
      nameRu: 'Кефир (1%)',
      nameKk: 'Кефир (1%)',
      nameEn: 'Kefir (1%)',
      categoryKey: 'cat_dairy',
      caloriesPer100g: 40, proteinPer100g: 3.3, carbsPer100g: 4.7, fatPer100g: 1.0),

  // ── Soups (GI-friendly) ───────────────────────────────────────────────────
  FoodProduct(
      nameRu: 'Куриный суп',
      nameKk: 'Тауық сорпасы',
      nameEn: 'Chicken Soup',
      categoryKey: 'cat_soups',
      caloriesPer100g: 35, proteinPer100g: 3.5, carbsPer100g: 2.5, fatPer100g: 1.0),
  FoodProduct(
      nameRu: 'Овощной суп',
      nameKk: 'Көкөніс сорпасы',
      nameEn: 'Vegetable Soup',
      categoryKey: 'cat_soups',
      caloriesPer100g: 25, proteinPer100g: 1.2, carbsPer100g: 4.5, fatPer100g: 0.4),
  FoodProduct(
      nameRu: 'Рисовая каша',
      nameKk: 'Күріш ботқасы',
      nameEn: 'Rice Porridge',
      categoryKey: 'cat_soups',
      caloriesPer100g: 65, proteinPer100g: 1.5, carbsPer100g: 14, fatPer100g: 0.3),

  // ── Казахская и центральноазиатская кухня ─────────────────────────────────

  // Основные блюда
  FoodProduct(
      nameRu: 'Бешбармак', nameKk: 'Бешбармақ', nameEn: 'Beshbarmak',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 218, proteinPer100g: 14.5, carbsPer100g: 18, fatPer100g: 9.5),
  FoodProduct(
      nameRu: 'Плов', nameKk: 'Палау', nameEn: 'Plov',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 245, proteinPer100g: 8.5, carbsPer100g: 30, fatPer100g: 10.5),
  FoodProduct(
      nameRu: 'Манты', nameKk: 'Мәнті', nameEn: 'Manty',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 195, proteinPer100g: 11, carbsPer100g: 22, fatPer100g: 7, gramsPerUnit: 50, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Самса', nameKk: 'Самса', nameEn: 'Samsa',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 285, proteinPer100g: 10, carbsPer100g: 28, fatPer100g: 15, gramsPerUnit: 100, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Лагман', nameKk: 'Лағман', nameEn: 'Lagman',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 148, proteinPer100g: 8.5, carbsPer100g: 18, fatPer100g: 5),
  FoodProduct(
      nameRu: 'Шурпа', nameKk: 'Шорпа', nameEn: 'Shurpa',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 78, proteinPer100g: 5.5, carbsPer100g: 7, fatPer100g: 3),
  FoodProduct(
      nameRu: 'Куырдак', nameKk: 'Қуырдақ', nameEn: 'Kuyrdak',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 265, proteinPer100g: 17, carbsPer100g: 4, fatPer100g: 21),
  FoodProduct(
      nameRu: 'Думама', nameKk: 'Думама', nameEn: 'Dumama',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 175, proteinPer100g: 12, carbsPer100g: 14, fatPer100g: 8),
  FoodProduct(
      nameRu: 'Баурсак', nameKk: 'Бауырсақ', nameEn: 'Baursak',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 348, proteinPer100g: 7, carbsPer100g: 48, fatPer100g: 15, gramsPerUnit: 30, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Казы', nameKk: 'Қазы', nameEn: 'Kazy',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 394, proteinPer100g: 14, carbsPer100g: 0, fatPer100g: 37),
  FoodProduct(
      nameRu: 'Шужык', nameKk: 'Шұжық', nameEn: 'Shuzhyk',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 376, proteinPer100g: 15, carbsPer100g: 1, fatPer100g: 35),
  FoodProduct(
      nameRu: 'Карта', nameKk: 'Қарта', nameEn: 'Karta',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 192, proteinPer100g: 13, carbsPer100g: 0, fatPer100g: 15.5),
  FoodProduct(
      nameRu: 'Нарын', nameKk: 'Нарын', nameEn: 'Naryn',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 205, proteinPer100g: 13, carbsPer100g: 16, fatPer100g: 9),
  FoodProduct(
      nameRu: 'Пирожки с мясом', nameKk: 'Етті пирожки', nameEn: 'Meat Piroshki',
      categoryKey: 'cat_kazakh_main',
      caloriesPer100g: 258, proteinPer100g: 9.5, carbsPer100g: 30, fatPer100g: 11, gramsPerUnit: 80, unitLabel: 'шт'),

  // Супы
  FoodProduct(
      nameRu: 'Сорпа (бульон из баранины)', nameKk: 'Сорпа (қой сорпасы)', nameEn: 'Sorpa (lamb broth)',
      categoryKey: 'cat_kazakh_soups',
      caloriesPer100g: 45, proteinPer100g: 4, carbsPer100g: 2, fatPer100g: 2.5),
  FoodProduct(
      nameRu: 'Куп (суп из рёбер)', nameKk: 'Қуп (қабырға сорпасы)', nameEn: 'Kup (rib soup)',
      categoryKey: 'cat_kazakh_soups',
      caloriesPer100g: 92, proteinPer100g: 7, carbsPer100g: 5, fatPer100g: 5),
  FoodProduct(
      nameRu: 'Ашсорпа', nameKk: 'Ащы сорпа', nameEn: 'Ashsorpa',
      categoryKey: 'cat_kazakh_soups',
      caloriesPer100g: 68, proteinPer100g: 5, carbsPer100g: 6, fatPer100g: 2.5),
  FoodProduct(
      nameRu: 'Мастава', nameKk: 'Мастава', nameEn: 'Mastava',
      categoryKey: 'cat_kazakh_soups',
      caloriesPer100g: 95, proteinPer100g: 5, carbsPer100g: 12, fatPer100g: 3),

  // Напитки и молочные
  FoodProduct(
      nameRu: 'Кумыс', nameKk: 'Қымыз', nameEn: 'Kumys',
      categoryKey: 'cat_kazakh_drinks',
      caloriesPer100g: 50, proteinPer100g: 2.1, carbsPer100g: 5, fatPer100g: 1.9),
  FoodProduct(
      nameRu: 'Шубат (верблюжье молоко)', nameKk: 'Шұбат (түйе сүті)', nameEn: 'Shubat (camel milk)',
      categoryKey: 'cat_kazakh_drinks',
      caloriesPer100g: 58, proteinPer100g: 3.5, carbsPer100g: 4.5, fatPer100g: 2.5),
  FoodProduct(
      nameRu: 'Айран', nameKk: 'Айран', nameEn: 'Ayran',
      categoryKey: 'cat_kazakh_drinks',
      caloriesPer100g: 35, proteinPer100g: 1.4, carbsPer100g: 3.8, fatPer100g: 1.2),
  FoodProduct(
      nameRu: 'Катык', nameKk: 'Қатық', nameEn: 'Katyk',
      categoryKey: 'cat_kazakh_drinks',
      caloriesPer100g: 56, proteinPer100g: 2.8, carbsPer100g: 5.2, fatPer100g: 2.5),

  // Хлеб и выпечка
  FoodProduct(
      nameRu: 'Тандырный хлеб', nameKk: 'Тандыр нан', nameEn: 'Tandyr Bread',
      categoryKey: 'cat_kazakh_bread',
      caloriesPer100g: 255, proteinPer100g: 8, carbsPer100g: 50, fatPer100g: 3, gramsPerUnit: 250, unitLabel: 'шт'),
  FoodProduct(
      nameRu: 'Шелпек', nameKk: 'Шелпек', nameEn: 'Shelpek',
      categoryKey: 'cat_kazakh_bread',
      caloriesPer100g: 320, proteinPer100g: 7, carbsPer100g: 44, fatPer100g: 14, gramsPerUnit: 150, unitLabel: 'шт'),

  // Узбекские / общие блюда
  FoodProduct(
      nameRu: 'Шашлык из баранины', nameKk: 'Қой етінен шашлық', nameEn: 'Lamb Shashlik',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 230, proteinPer100g: 22, carbsPer100g: 0, fatPer100g: 15),
  FoodProduct(
      nameRu: 'Шашлык из говядины', nameKk: 'Сиыр етінен шашлық', nameEn: 'Beef Shashlik',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 218, proteinPer100g: 23, carbsPer100g: 0, fatPer100g: 14),
  FoodProduct(
      nameRu: 'Долма', nameKk: 'Долма', nameEn: 'Dolma',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 148, proteinPer100g: 8, carbsPer100g: 12, fatPer100g: 7.5),
  FoodProduct(
      nameRu: 'Чучвара', nameKk: 'Чучвара', nameEn: 'Chuchvara',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 175, proteinPer100g: 9, carbsPer100g: 22, fatPer100g: 5.5),
  FoodProduct(
      nameRu: 'Паровые пельмени', nameKk: 'Бумада пісірілген пельмень', nameEn: 'Steamed Dumplings',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 190, proteinPer100g: 10, carbsPer100g: 22, fatPer100g: 7),
  FoodProduct(
      nameRu: 'Гуручь (рисовый плов)', nameKk: 'Гуруч (күріш палауы)', nameEn: 'Gurich (rice pilaf)',
      categoryKey: 'cat_central_asian',
      caloriesPer100g: 220, proteinPer100g: 7, carbsPer100g: 32, fatPer100g: 7.5),
];
