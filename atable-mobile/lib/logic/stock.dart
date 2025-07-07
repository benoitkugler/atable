import 'dart:convert';

import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/predefined.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';

class NormalizedQuantity {
  final double pieces;
  final double l;
  final double kg;
  const NormalizedQuantity({this.pieces = 0, this.l = 0, this.kg = 0});

  @override
  bool operator ==(Object other) =>
      (other is NormalizedQuantity) &&
      other.pieces == pieces &&
      other.l == l &&
      other.kg == kg;

  @override
  int get hashCode => pieces.hashCode + l.hashCode + kg.hashCode;

  NormalizedQuantity copyWith({
    double? pieces,
    double? l,
    double? kg,
  }) =>
      NormalizedQuantity(
          pieces: pieces ?? this.pieces, l: l ?? this.l, kg: kg ?? this.kg);

  factory NormalizedQuantity.fromList(List<QuantityAbs> list) {
    NormalizedQuantity out = const NormalizedQuantity();
    for (var item in list) {
      out += item.normalize();
    }
    return out;
  }

  NormalizedQuantity operator +(NormalizedQuantity other) {
    return NormalizedQuantity(
        pieces: pieces + other.pieces, l: l + other.l, kg: kg + other.kg);
  }

  NormalizedQuantity operator -(NormalizedQuantity other) {
    return NormalizedQuantity(
        pieces: pieces - other.pieces, l: l - other.l, kg: kg - other.kg);
  }

  bool isPositive() => pieces >= 0 && l >= 0 && kg >= 0;
}

class QuantityAbs {
  final Unite unite;
  final double val;
  const QuantityAbs(this.unite, this.val);

  @override
  String toString() {
    return "$val ${formatUnite(unite)}";
  }

  QuantityAbs copyWith({Unite? unite, double? val}) =>
      QuantityAbs(unite ?? this.unite, val ?? this.val);

  static QuantityAbs fromQuantite(Quantite qu) =>
      QuantityAbs(qu.unite, qu.quantite);

  NormalizedQuantity normalize() {
    switch (unite) {
      case Unite.piece:
        return NormalizedQuantity(pieces: val);
      case Unite.l:
        return NormalizedQuantity(l: val);
      case Unite.cL:
        return NormalizedQuantity(l: val / 100);
      case Unite.kg:
        return NormalizedQuantity(kg: val);
      case Unite.g:
        return NormalizedQuantity(kg: val / 1000);
    }
  }
}

Map<String, dynamic> stockQuantiteToJson(QuantityAbs item) {
  return {
    "unite": uniteToJson(item.unite),
    "quantite": doubleToJson(item.val),
  };
}

QuantityAbs stockQuantiteFromJson(dynamic json_) {
  final json = (json_ as Map<String, dynamic>);
  return QuantityAbs(
    uniteFromJson(json['unite']),
    doubleFromJson(json['quantite']),
  );
}

List<QuantityAbs> listStockQuantiteFromJson(dynamic json) {
  if (json == null) {
    return [];
  }
  return (json as List<dynamic>).map(stockQuantiteFromJson).toList();
}

List<dynamic> listStockQuantiteToJson(List<QuantityAbs> item) {
  return item.map(stockQuantiteToJson).toList();
}

class StockEntry {
  final IdIngredient idIngredient;
  final List<QuantityAbs> quantites;

  const StockEntry(this.idIngredient, this.quantites);

  @override
  String toString() {
    return "$idIngredient : $quantites";
  }

  static StockEntry fromSQLMap(Map<String, dynamic> map) {
    return StockEntry(
      map["idIngredient"],
      listStockQuantiteFromJson(jsonDecode(map["quantites"])),
    );
  }

  Map<String, dynamic> toSQLMap() {
    return {
      "idIngredient": idIngredient,
      "quantites": jsonEncode(listStockQuantiteToJson(quantites)),
    };
  }

  StockEntry copyWith({
    int? idIngredient,
    List<QuantityAbs>? quantites,
  }) {
    return StockEntry(
      idIngredient ?? this.idIngredient,
      quantites ?? this.quantites,
    );
  }
}

class IngredientQuantiteAbs {
  final Ingredient ingredient;
  final List<QuantityAbs> quantites;
  const IngredientQuantiteAbs(this.ingredient, this.quantites);
}

class Stock {
  final List<IngredientQuantiteAbs> l;
  const Stock(this.l);

  Map<IdIngredient, NormalizedQuantity> toMap() => Map.fromEntries(l.map((e) =>
      MapEntry(e.ingredient.id, NormalizedQuantity.fromList(e.quantites))));

  List<IngredientQuantiteAbs> missingFor(ResolvedMealQuantity meal) {
    final ingredients = <IdIngredient, Ingredient>{};
    final needed = <IdIngredient, NormalizedQuantity>{};
    for (var plat in meal.values) {
      for (var ingredient in plat) {
        final current =
            needed[ingredient.ingredient.id] ?? const NormalizedQuantity();
        needed[ingredient.ingredient.id] =
            current + QuantityAbs.fromQuantite(ingredient.quantity).normalize();
        ingredients[ingredient.ingredient.id] = ingredient.ingredient;
      }
    }

    final stock = toMap();
    final missing = <IngredientQuantiteAbs>[];
    for (var item in needed.entries) {
      final diff = (stock[item.key] ?? const NormalizedQuantity()) - item.value;
      final missingL = <QuantityAbs>[];
      if (diff.pieces < 0) missingL.add(QuantityAbs(Unite.piece, -diff.pieces));
      if (diff.l < 0) missingL.add(QuantityAbs(Unite.l, -diff.l));
      if (diff.kg < 0) missingL.add(QuantityAbs(Unite.kg, -diff.kg));
      if (missingL.isNotEmpty) {
        missing.add(IngredientQuantiteAbs(ingredients[item.key]!, missingL));
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
