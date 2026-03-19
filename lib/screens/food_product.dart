class FoodProduct {
  final String name;
  final String category;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;

  FoodProduct({
    required this.name,
    required this.category,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
  });
}

final List<FoodProduct> foodDatabase = [
  // ── Proteins ──────────────────────────────────────────────────────────────
  FoodProduct(name: 'Chicken Breast (boiled)', category: 'Protein',
      caloriesPer100g: 165, proteinPer100g: 31, carbsPer100g: 0, fatPer100g: 3.6),
  FoodProduct(name: 'Turkey (boiled)', category: 'Protein',
      caloriesPer100g: 135, proteinPer100g: 29, carbsPer100g: 0, fatPer100g: 1.8),
  FoodProduct(name: 'Egg (boiled)', category: 'Protein',
      caloriesPer100g: 155, proteinPer100g: 13, carbsPer100g: 1.1, fatPer100g: 11),
  FoodProduct(name: 'Salmon (steamed)', category: 'Protein',
      caloriesPer100g: 208, proteinPer100g: 20, carbsPer100g: 0, fatPer100g: 13),
  FoodProduct(name: 'White Fish (boiled)', category: 'Protein',
      caloriesPer100g: 96, proteinPer100g: 21, carbsPer100g: 0, fatPer100g: 1.2),
  FoodProduct(name: 'Cottage Cheese (low fat)', category: 'Protein',
      caloriesPer100g: 72, proteinPer100g: 12, carbsPer100g: 3.4, fatPer100g: 1.0),

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
      caloriesPer100g: 52, proteinPer100g: 0.3, carbsPer100g: 14, fatPer100g: 0.2),
  FoodProduct(name: 'Banana', category: 'Fruits',
      caloriesPer100g: 89, proteinPer100g: 1.1, carbsPer100g: 23, fatPer100g: 0.3),
  FoodProduct(name: 'Pear', category: 'Fruits',
      caloriesPer100g: 57, proteinPer100g: 0.4, carbsPer100g: 15, fatPer100g: 0.1),

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
];
