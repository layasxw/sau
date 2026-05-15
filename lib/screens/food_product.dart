class FoodProduct {
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? gramsPerUnit;
  final String? unitLabel;

  FoodProduct({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.gramsPerUnit,
    this.unitLabel,
  });
}
// todo проверить перевод, чтобы понятным был и казахский проверить исправить и чтоб разговорный ъ - передать девочкам
// ии ответы в целом чекнуть, на каз на рус чтобы отвечал на понятном казахском - риски - опасности қауіптер, улучшение ө жақсару/сауу
//граммы на штуку, уменьшить аутпуты ии в промпте написать
// у доктора чтобы видно было файлы прикрепленные
// добавить лекарство которого нет в списке
// на дашборде ввиде туду переименовать быстрые действия на туду лист - или напоминания от ии что нужно сделать
// в онбординге пре реабилитации написать чо это значитт
// можно сделать мед историю не обязательной а просто файл прикреплять
// мотивацию поменьше и туду лист выше поставить
// кнопки вырвнять


// напоминания несколько раз в день для лекарств и не только   автоматическое повторение
// на будущее ө ии который будет понимать почерк доктора на листочках для лекарств (протокол / назначение)
// сделать конкурс для докторов пациентов чтобы датасет собрать 

final List<FoodProduct> foodDatabase = [
  // ── Proteins ──────────────────────────────────────────────────────────────
  FoodProduct(name: 'Chicken Breast (boiled)', category: 'Protein',
      caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
  FoodProduct(name: 'Turkey (boiled)', category: 'Protein',
      caloriesPer100g: 135, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 1.8),
  FoodProduct(name: 'Egg (boiled)', category: 'Protein',
      caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11, gramsPerUnit: 60, unitLabel: 'шт'),
  FoodProduct(name: 'Salmon (steamed)', category: 'Protein',
      caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13),
  FoodProduct(name: 'White Fish (boiled)', category: 'Protein',
      caloriesPer100g: 96, proteinPer100g: 21, carbsPer100g: 0, fatPer100g: 1.2),
  FoodProduct(name: 'Cottage Cheese (low fat)', category: 'Protein',
      caloriesPer100g: 72, proteinPer100g: 12, carbsPer100g: 3.4, fatPer100g: 1.0, gramsPerUnit: 200, unitLabel: 'уп'),

  // ── Grains & Carbs ────────────────────────────────────────────────────────
  FoodProduct(name: 'White Rice (cooked)', category: 'Grains',
      caloriesPer100g: 130, proteinPer100g: 2.7, carbsPer100g: 28, fatPer100g: 0.3),
  FoodProduct(name: 'Oatmeal (cooked)', category: 'Grains',
      caloriesPer100g: 71, proteinPer100g: 2.5, carbsPer100g: 12, fatPer100g: 1.5),
  FoodProduct(name: 'White Bread', category: 'Grains',
      caloriesPer100g: 265, proteinPer100g: 9, carbsPer100g: 49, fatPer100g: 3.2),
  FoodProduct(name: 'Buckwheat (cooked)', category: 'Grains',
      caloriesPer100g: 92, proteinPer100g: 3.4, carbsPer100g: 20, fatPer100g: 0.6),
  FoodProduct(name: 'Pasta (cooked)', category: 'Grains',
      caloriesPer100g: 131, proteinPer100g: 5, carbsPer100g: 25, fatPer100g: 1.1),

  // ── Vegetables ────────────────────────────────────────────────────────────
  FoodProduct(name: 'Potato (boiled)', category: 'Vegetables',
      caloriesPer100g: 87, proteinPer100g: 1.9, carbsPer100g: 20, fatPer100g: 0.1),
  FoodProduct(name: 'Carrot (boiled)', category: 'Vegetables',
      caloriesPer100g: 35, proteinPer100g: 0.8, carbsPer100g: 8, fatPer100g: 0.2),
  FoodProduct(name: 'Zucchini (boiled)', category: 'Vegetables',
      caloriesPer100g: 17, proteinPer100g: 1.2, carbsPer100g: 3.1, fatPer100g: 0.3),
  FoodProduct(name: 'Pumpkin (boiled)', category: 'Vegetables',
      caloriesPer100g: 20, proteinPer100g: 0.7, carbsPer100g: 4.9, fatPer100g: 0.1),
  FoodProduct(name: 'Broccoli (steamed)', category: 'Vegetables',
      caloriesPer100g: 35, proteinPer100g: 2.4, carbsPer100g: 7, fatPer100g: 0.4),

  // ── Fruits ────────────────────────────────────────────────────────────────
  FoodProduct(name: 'Apple', category: 'Fruits',
      caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2, gramsPerUnit: 150, unitLabel: 'шт'),
  FoodProduct(name: 'Banana', category: 'Fruits',
      caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3, gramsPerUnit: 120, unitLabel: 'шт'),
  FoodProduct(name: 'Pear', category: 'Fruits',
      caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1, gramsPerUnit: 150, unitLabel: 'шт'),

  // ── Dairy ─────────────────────────────────────────────────────────────────
  FoodProduct(name: 'Yogurt (plain, low fat)', category: 'Dairy',
      caloriesPer100g: 56, proteinPer100g: 4.7, carbsPer100g: 6.8, fatPer100g: 0.6),
  FoodProduct(name: 'Kefir (1%)', category: 'Dairy',
      caloriesPer100g: 40, proteinPer100g: 3.3, carbsPer100g: 4.7, fatPer100g: 1.0),

  // ── Soups (GI-friendly) ───────────────────────────────────────────────────
  FoodProduct(name: 'Chicken Soup', category: 'Soups',
      caloriesPer100g: 35, proteinPer100g: 3.5, carbsPer100g: 2.5, fatPer100g: 1.0),
  FoodProduct(name: 'Vegetable Soup', category: 'Soups',
      caloriesPer100g: 25, proteinPer100g: 1.2, carbsPer100g: 4.5, fatPer100g: 0.4),
  FoodProduct(name: 'Rice Porridge', category: 'Soups',
      caloriesPer100g: 65, proteinPer100g: 1.5, carbsPer100g: 14, fatPer100g: 0.3),

  // ── Казахская и центральноазиатская кухня ─────────────────────────────────

  // Основные блюда
  FoodProduct(name: 'Бешбармак (Beshbarmak)', category: 'Казахская кухня',
      caloriesPer100g: 218, proteinPer100g: 14.5, carbsPer100g: 18, fatPer100g: 9.5),
  FoodProduct(name: 'Плов (Plov)', category: 'Казахская кухня',
      caloriesPer100g: 245, proteinPer100g: 8.5, carbsPer100g: 30, fatPer100g: 10.5),
  FoodProduct(name: 'Манты (Manty)', category: 'Казахская кухня',
      caloriesPer100g: 195, proteinPer100g: 11, carbsPer100g: 22, fatPer100g: 7, gramsPerUnit: 50, unitLabel: 'шт'),
  FoodProduct(name: 'Самса (Samsa)', category: 'Казахская кухня',
      caloriesPer100g: 285, proteinPer100g: 10, carbsPer100g: 28, fatPer100g: 15, gramsPerUnit: 100, unitLabel: 'шт'),
  FoodProduct(name: 'Лагман (Lagman)', category: 'Казахская кухня',
      caloriesPer100g: 148, proteinPer100g: 8.5, carbsPer100g: 18, fatPer100g: 5),
  FoodProduct(name: 'Шурпа (Shurpa)', category: 'Казахская кухня',
      caloriesPer100g: 78, proteinPer100g: 5.5, carbsPer100g: 7, fatPer100g: 3),
  FoodProduct(name: 'Куырдак (Kuirdak)', category: 'Казахская кухня',
      caloriesPer100g: 265, proteinPer100g: 17, carbsPer100g: 4, fatPer100g: 21),
  FoodProduct(name: 'Думама (Dumama)', category: 'Казахская кухня',
      caloriesPer100g: 175, proteinPer100g: 12, carbsPer100g: 14, fatPer100g: 8),
  FoodProduct(name: 'Баурсак (Baursak)', category: 'Казахская кухня',
      caloriesPer100g: 348, proteinPer100g: 7, carbsPer100g: 48, fatPer100g: 15, gramsPerUnit: 30, unitLabel: 'шт'),
  FoodProduct(name: 'Казы (Kazy)', category: 'Казахская кухня',
      caloriesPer100g: 394, proteinPer100g: 14, carbsPer100g: 0, fatPer100g: 37),
  FoodProduct(name: 'Шужык (Shuzhyk)', category: 'Казахская кухня',
      caloriesPer100g: 376, proteinPer100g: 15, carbsPer100g: 1, fatPer100g: 35),
  FoodProduct(name: 'Карта (Karta)', category: 'Казахская кухня',
      caloriesPer100g: 192, proteinPer100g: 13, carbsPer100g: 0, fatPer100g: 15.5),
  FoodProduct(name: 'Нарын (Naryn)', category: 'Казахская кухня',
      caloriesPer100g: 205, proteinPer100g: 13, carbsPer100g: 16, fatPer100g: 9),
  FoodProduct(name: 'Пирожки с мясом (Meat Piroshki)', category: 'Казахская кухня',
      caloriesPer100g: 258, proteinPer100g: 9.5, carbsPer100g: 30, fatPer100g: 11, gramsPerUnit: 80, unitLabel: 'шт'),

  // Супы
  FoodProduct(name: 'Сорпа (Sorpa — lamb broth)', category: 'Казахские супы',
      caloriesPer100g: 45, proteinPer100g: 4, carbsPer100g: 2, fatPer100g: 2.5),
  FoodProduct(name: 'Куп (Kup — rib soup)', category: 'Казахские супы',
      caloriesPer100g: 92, proteinPer100g: 7, carbsPer100g: 5, fatPer100g: 5),
  FoodProduct(name: 'Ашсорпа (Ashsorpa)', category: 'Казахские супы',
      caloriesPer100g: 68, proteinPer100g: 5, carbsPer100g: 6, fatPer100g: 2.5),
  FoodProduct(name: 'Мастава (Mastava)', category: 'Казахские супы',
      caloriesPer100g: 95, proteinPer100g: 5, carbsPer100g: 12, fatPer100g: 3),

  // Напитки и молочные
  FoodProduct(name: 'Кумыс (Kumys)', category: 'Казахские напитки',
      caloriesPer100g: 50, proteinPer100g: 2.1, carbsPer100g: 5, fatPer100g: 1.9),
  FoodProduct(name: 'Шубат (Shubat — camel milk)', category: 'Казахские напитки',
      caloriesPer100g: 58, proteinPer100g: 3.5, carbsPer100g: 4.5, fatPer100g: 2.5),
  FoodProduct(name: 'Айран (Ayran)', category: 'Казахские напитки',
      caloriesPer100g: 35, proteinPer100g: 1.4, carbsPer100g: 3.8, fatPer100g: 1.2),
  FoodProduct(name: 'Катык (Katyk)', category: 'Казахские напитки',
      caloriesPer100g: 56, proteinPer100g: 2.8, carbsPer100g: 5.2, fatPer100g: 2.5),

  // Хлеб и выпечка
  FoodProduct(name: 'Тандырный хлеб (Tandyr nan)', category: 'Казахский хлеб',
      caloriesPer100g: 255, proteinPer100g: 8, carbsPer100g: 50, fatPer100g: 3, gramsPerUnit: 250, unitLabel: 'шт'),
  FoodProduct(name: 'Казахский хлеб (Shelpek)', category: 'Казахский хлеб',
      caloriesPer100g: 320, proteinPer100g: 7, carbsPer100g: 44, fatPer100g: 14, gramsPerUnit: 150, unitLabel: 'шт'),

  // Узбекские / общеца блюда
  FoodProduct(name: 'Шашлык из баранины (Lamb Shashlik)', category: 'ЦА кухня',
      caloriesPer100g: 230, proteinPer100g: 22, carbsPer100g: 0, fatPer100g: 15),
  FoodProduct(name: 'Шашлык из говядины (Beef Shashlik)', category: 'ЦА кухня',
      caloriesPer100g: 218, proteinPer100g: 23, carbsPer100g: 0, fatPer100g: 14),
  FoodProduct(name: 'Долма (Dolma)', category: 'ЦА кухня',
      caloriesPer100g: 148, proteinPer100g: 8, carbsPer100g: 12, fatPer100g: 7.5),
  FoodProduct(name: 'Чучвара (Chuchvara)', category: 'ЦА кухня',
      caloriesPer100g: 175, proteinPer100g: 9, carbsPer100g: 22, fatPer100g: 5.5),
  FoodProduct(name: 'Мантышница (Steamed dumplings)', category: 'ЦА кухня',
      caloriesPer100g: 190, proteinPer100g: 10, carbsPer100g: 22, fatPer100g: 7),
  FoodProduct(name: 'Гурич (Gurich — rice pilaf)', category: 'ЦА кухня',
      caloriesPer100g: 220, proteinPer100g: 7, carbsPer100g: 32, fatPer100g: 7.5),
];