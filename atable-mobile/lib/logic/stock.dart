import 'dart:convert';

import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';

class StockEntry {
  final IdIngredient idIngredient;
  final QuantitiesNorm quantites;

  const StockEntry(this.idIngredient, this.quantites);

  @override
  String toString() {
    return "$idIngredient : $quantites";
  }

  static StockEntry fromSQLMap(Map<String, dynamic> map) {
    return StockEntry(
      map["idIngredient"],
      QuantitiesNorm.fromJson(jsonDecode(map["quantites"])),
    );
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idIngredient": idIngredient,
      "quantites": jsonEncode(quantites.toJson()),
    };
  }

  StockEntry copyWith({
    int? idIngredient,
    QuantitiesNorm? quantites,
  }) {
    return StockEntry(
      idIngredient ?? this.idIngredient,
      quantites ?? this.quantites,
    );
  }
}

class IngredientQuantitiesN {
  final Ingredient ingredient;
  final QuantitiesNorm quantites;
  const IngredientQuantitiesN(this.ingredient, this.quantites);
}

class Stock {
  final List<IngredientQuantitiesN> l;
  const Stock(this.l);

  Map<IdIngredient, QuantitiesNorm> toMap() =>
      Map.fromEntries(l.map((e) => MapEntry(e.ingredient.id, e.quantites)));

  List<IngredientQuantitiesN> missingFor(ResolvedMealQuantity meal) {
    final ingredients = <IdIngredient, Ingredient>{};
    final needed = <IdIngredient, QuantitiesNorm>{};
    for (var plat in meal.values) {
      for (var ingredient in plat) {
        final current =
            needed[ingredient.ingredient.id] ?? const QuantitiesNorm();
        needed[ingredient.ingredient.id] =
            current + QuantitiesNorm.fromQuantite(ingredient.quantity);
        ingredients[ingredient.ingredient.id] = ingredient.ingredient;
      }
    }

    final stock = toMap();
    final missing = <IngredientQuantitiesN>[];
    for (var item in needed.entries) {
      final diff = (stock[item.key] ?? const QuantitiesNorm()) - item.value;
      // missing values are the one with negative values : clamp the other to 0
      final clamped = QuantitiesNorm(
        pieces: diff.pieces < 0 ? -diff.pieces : 0,
        l: diff.l < 0 ? -diff.l : 0,
        kg: diff.kg < 0 ? -diff.kg : 0,
      );
      if (clamped != const QuantitiesNorm()) {
        missing.add(IngredientQuantitiesN(ingredients[item.key]!, clamped));
      }
    }
    return missing;
  }
}

const stockSQLTable = """
  CREATE TABLE stock (
    idIngredient INTEGER NOT NULL,
    quantites TEXT NOT NULL,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE(idIngredient)
  );
""";
