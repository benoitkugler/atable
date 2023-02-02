import 'dart:convert';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:http/http.dart' as http;

typedef Quantites = Map<Unite, double>;

String formatQuantites(Quantites quantite) {
  return quantite.entries
      .where((element) => element.value != 0)
      .map((e) => "${formatQuantite(e.value)} ${formatUnite(e.key)}")
      .join(", ");
}

class IngredientQuantite {
  final int id;
  final String nom;
  final CategorieIngredient categorie;
  final String quantite;

  bool checked;

  IngredientQuantite(this.id, this.nom, this.categorie, this.quantite,
      {this.checked = false});

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "nom": nom,
      "categorie": categorie.index,
      "quantite": quantite,
      "checked": checked,
    };
  }

  factory IngredientQuantite.fromJson(Map<String, dynamic> map) {
    return IngredientQuantite(map["id"], map["nom"],
        CategorieIngredient.values[map["categorie"] as int], map["quantite"],
        checked: map["cheked"]);
  }
}

class ShopSection {
  final CategorieIngredient categorie;
  final List<IngredientQuantite> ingredients;

  const ShopSection(this.categorie, this.ingredients);

  bool get isDone => ingredients.every((element) => element.checked);
}

class ShopList {
  final List<IngredientQuantite> _list;
  ShopList(this._list);

  /// [fromMenus] regroupe les ingrédients des [menus], regroupés par catégories
  factory ShopList.fromMenus(List<MenuExt> menus) {
    final tmp = <int, Quantites>{}; // par ID
    final ingregients = <int, Ingredient>{}; // par ID
    for (var menu in menus) {
      for (var ing in menu.ingredients) {
        ingregients[ing.ingredient.id] = ing.ingredient;

        final qus = tmp.putIfAbsent(ing.ingredient.id, () => {});
        final u = ing.link.unite;
        qus[u] = (qus[u] ?? 0) + ing.link.quantite;
      }
    }
    return ShopList(tmp.keys
        .map((id) => IngredientQuantite(id, ingregients[id]!.nom,
            ingregients[id]!.categorie, formatQuantites(tmp[id]!)))
        .toList());
  }

  List<ShopSection> bySections() {
    final byCategorie = <CategorieIngredient, List<IngredientQuantite>>{};
    for (var ing in _list) {
      final l = byCategorie.putIfAbsent(ing.categorie, () => []);
      l.add(ing);
    }
    return byCategorie.entries.map((e) => ShopSection(e.key, e.value)).toList();
  }
}

/// [ShopController] is the backend updating the
/// shop list, either in local or shared mode.
abstract class ShopController {
  Future<ShopList> fetchList();
  Future<ShopList> updateShop(int id, bool checked);
}

/// [ShopControllerLocal] use a local, in-memory data store
class ShopControllerLocal implements ShopController {
  final ShopList list;
  const ShopControllerLocal(this.list);

  @override
  Future<ShopList> fetchList() async => list;

  @override
  Future<ShopList> updateShop(int id, bool checked) async {
    final index = list._list.indexWhere((element) => element.id == id);
    list._list[index].checked = checked;
    return list;
  }
}

/// [ShopControllerShared] uses a remote data store
class ShopControllerShared implements ShopController {
  final Uri url;

  ShopControllerShared(String url) : url = Uri.parse(url);

  @override
  Future<ShopList> fetchList() async {
    final resp = await http.get(url);
    final l = jsonDecode(resp.body) as List;
    return ShopList(l
        .map((e) => IngredientQuantite.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  @override
  Future<ShopList> updateShop(int id, bool checked) async {
    final resp = await http.post(url, body: {"checked": checked, "id": id});
    final l = jsonDecode(resp.body) as List;
    return ShopList(l
        .map((e) => IngredientQuantite.fromJson(e as Map<String, dynamic>))
        .toList());
  }
}
