import 'dart:convert';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:http/http.dart' as http;

const _serverHost = "https://intendance.alwaysdata.net"; // prod
// const _serverHost = "http://localhost:1323" // dev

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
        checked: map["checked"]);
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

  /// [fromRepass] regroupe les ingrédients des [repass], regroupés par catégories
  factory ShopList.fromRepass(List<RepasExt> repass) {
    final tmp = <int, Quantites>{}; // par ID
    final ingregients = <int, Ingredient>{}; // par ID
    for (var repas in repass) {
      for (var plat in repas.requiredQuantites().values) {
        for (var ing in plat) {
          ingregients[ing.ingredient.id] = ing.ingredient;

          final qus = tmp.putIfAbsent(ing.ingredient.id, () => {});
          final u = ing.unite;
          qus[u] = (qus[u] ?? 0) + ing.quantite;
        }
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
  final String sessionID;

  ShopControllerShared(this.sessionID);

  // PUT : crée une session
  // GET (sessionID) : récupère la session demandée
  // POST (sessionID) : modifie la session demandée
  static const _apiEndpoint = "$_serverHost/api/session";

  static const _guestEndpoint = "$_serverHost/shop";

  /// [guestURL] renvoie l'url de la page d'accueil destinée
  /// à un nouvel invité
  String guestURL() => Uri.parse(_guestEndpoint).replace(
        queryParameters: {"sessionID": sessionID},
      ).toString();

  /// [createSession] demande au serveur de créer une nouvelle session,
  /// avec le contenu de [list]
  static Future<ShopControllerShared> createSession(ShopList list) async {
    final resp = await http.put(Uri.parse(_apiEndpoint),
        body: jsonEncode(list._list.map((e) => e.toJson()).toList()),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });
    final sessionID =
        (jsonDecode(resp.body) as Map<String, dynamic>)["sessionID"];
    return ShopControllerShared(sessionID);
  }

  @override
  Future<ShopList> fetchList() async {
    final apiURL = Uri.parse(_apiEndpoint)
        .replace(queryParameters: {"sessionID": sessionID});
    final resp = await http.get(apiURL);
    final json = jsonDecode(resp.body);
    if (json is Map) {
      throw json["message"];
    } else if (json is! List) {
      throw "Réponse du serveur invalide.";
    }
    final l = jsonDecode(resp.body) as List;
    return ShopList(l
        .map((e) => IngredientQuantite.fromJson(e as Map<String, dynamic>))
        .toList());
  }

  @override
  Future<ShopList> updateShop(int id, bool checked) async {
    final apiURL = Uri.parse(_apiEndpoint)
        .replace(queryParameters: {"sessionID": sessionID});
    final resp = await http.post(apiURL,
        body: jsonEncode(
          {"checked": checked, "id": id},
        ),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });
    final l = jsonDecode(resp.body) as List;
    return ShopList(l
        .map((e) => IngredientQuantite.fromJson(e as Map<String, dynamic>))
        .toList());
  }
}
