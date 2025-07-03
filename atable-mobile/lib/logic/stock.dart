import 'dart:convert';

import 'package:atable/logic/types/predefined.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';

class StockQuantite {
  final Unite unite;
  final double quantite;
  const StockQuantite(this.unite, this.quantite);

  @override
  String toString() {
    return "$quantite $unite";
  }
}

Map<String, dynamic> stockQuantiteToJson(StockQuantite item) {
  return {
    "unite": uniteToJson(item.unite),
    "quantite": doubleToJson(item.quantite),
  };
}

StockQuantite stockQuantiteFromJson(dynamic json_) {
  final json = (json_ as Map<String, dynamic>);
  return StockQuantite(
    uniteFromJson(json['unite']),
    doubleFromJson(json['quantite']),
  );
}

List<StockQuantite> listStockQuantiteFromJson(dynamic json) {
  if (json == null) {
    return [];
  }
  return (json as List<dynamic>).map(stockQuantiteFromJson).toList();
}

List<dynamic> listStockQuantiteToJson(List<StockQuantite> item) {
  return item.map(stockQuantiteToJson).toList();
}

class StockEntry {
  final IdIngredient idIngredient;
  final List<StockQuantite> quantites;

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
    List<StockQuantite>? quantites,
  }) {
    return StockEntry(
      idIngredient ?? this.idIngredient,
      quantites ?? this.quantites,
    );
  }
}

class StockIngredient {
  final Ingredient ingredient;
  final List<StockQuantite> quantites;
  const StockIngredient(this.ingredient, this.quantites);
}

typedef Stock = List<StockIngredient>;

const stockSQLTable = """
  CREATE TABLE stock (
    idIngredient INTEGER NOT NULL,
    quantites TEXT NOT NULL,
    FOREIGN KEY(idIngredient) REFERENCES ingredients(id) ON DELETE CASCADE,
    UNIQUE(idIngredient)
  );
""";
