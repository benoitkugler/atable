import 'dart:convert';

import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/predefined.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';

class QuantitiesNorm {
  final double pieces;
  final double l;
  final double kg;
  const QuantitiesNorm({this.pieces = 0, this.l = 0, this.kg = 0});

  @override
  bool operator ==(Object other) =>
      (other is QuantitiesNorm) &&
      other.pieces == pieces &&
      other.l == l &&
      other.kg == kg;

  @override
  int get hashCode => pieces.hashCode + l.hashCode + kg.hashCode;

  Map<String, dynamic> toJson() {
    return {
      "pieces": doubleToJson(pieces),
      "l": doubleToJson(l),
      "kg": doubleToJson(kg),
    };
  }

  factory QuantitiesNorm.fromJson(dynamic json_) {
    final json = (json_ as Map<String, dynamic>);
    return QuantitiesNorm(
      pieces: doubleFromJson(json['pieces']),
      l: doubleFromJson(json['l']),
      kg: doubleFromJson(json['kg']),
    );
  }

  QuantitiesNorm copyWith({
    double? pieces,
    double? l,
    double? kg,
  }) =>
      QuantitiesNorm(
          pieces: pieces ?? this.pieces, l: l ?? this.l, kg: kg ?? this.kg);

  factory QuantitiesNorm.fromQuantite(Quantite qu) {
    switch (qu.unite) {
      case Unite.piece:
        return QuantitiesNorm(pieces: qu.quantite);
      case Unite.l:
        return QuantitiesNorm(l: qu.quantite);
      case Unite.cL:
        return QuantitiesNorm(l: qu.quantite / 100);
      case Unite.kg:
        return QuantitiesNorm(kg: qu.quantite);
      case Unite.g:
        return QuantitiesNorm(kg: qu.quantite / 1000);
    }
  }

  factory QuantitiesNorm.fromList(List<Quantite> list) {
    QuantitiesNorm out = const QuantitiesNorm();
    for (var item in list) {
      out += QuantitiesNorm.fromQuantite(item);
    }
    return out;
  }

  @override
  String toString() {
    final list = [
      if (pieces != 0) (pieces, Unite.piece),
      if (l != 0) (l, Unite.l),
      if (kg != 0) (kg, Unite.kg),
    ];
    return list.map((e) => formatQuantiteU(e.$1, e.$2)).join(" et ");
  }

  QuantitiesNorm operator +(QuantitiesNorm other) {
    return QuantitiesNorm(
        pieces: pieces + other.pieces, l: l + other.l, kg: kg + other.kg);
  }

  QuantitiesNorm operator -(QuantitiesNorm other) {
    return QuantitiesNorm(
        pieces: pieces - other.pieces, l: l - other.l, kg: kg - other.kg);
  }

  bool isPositive() => pieces >= 0 && l >= 0 && kg >= 0;
}

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
  final Map<IdIngredient, QuantitiesNorm> _m;
  const Stock(this._m);

  factory Stock.fromList(Iterable<StockEntry> l) => Stock(
      Map.fromEntries(l.map((e) => MapEntry(e.idIngredient, e.quantites))));

  QuantitiesNorm get(IdIngredient id) => _m[id] ?? const QuantitiesNorm();

  int get length => _m.length;

  List<IngredientQuantitiesN> toList(
      Map<IdIngredient, Ingredient> allIngredients) {
    final out = _m.entries
        .map((e) => IngredientQuantitiesN(allIngredients[e.key]!, e.value))
        .toList();
    out.sort((a, b) => a.ingredient.kind.index - b.ingredient.kind.index);
    return out;
  }

  /// returns true if stock has enough for all units
  bool hasEnoughFor(IdIngredient id, QuantitiesNorm qu) {
    final existing = get(id);
    return (existing - qu).isPositive();
  }

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

    final missing = <IngredientQuantitiesN>[];
    for (var item in needed.entries) {
      final diff = get(item.key) - item.value;
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
