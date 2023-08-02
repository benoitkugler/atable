import 'dart:convert';

import 'package:atable/logic/env.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
import 'package:atable/logic/utils.dart';
import 'package:http/http.dart' as http;

typedef CQuantites = List<MapEntry<Unite, double>>;

extension E on IngredientUses {
  IngredientUses copyWith({
    Ingredient? ingredient,
    List<Quantite>? quantites,
    bool? checked,
  }) =>
      IngredientUses(
        ingredient ?? this.ingredient,
        quantites ?? this.quantites,
        checked ?? this.checked,
      );

  CQuantites compile() {
    final compiled = <Unite, double>{};
    for (var use in quantites) {
      final u = use.unite;
      compiled[u] = (compiled[u] ?? 0) + use.quantite;
    }
    final out =
        compiled.entries.where((element) => element.value != 0).toList();
    out.sort((a, b) => a.key.index - b.key.index);
    return out;
  }
}

class ShopSection {
  final IngredientKind categorie;
  final List<IngredientUses> ingredients;

  const ShopSection(this.categorie, this.ingredients);

  bool get isDone => ingredients.every((element) => element.checked);
}

class ShopListW {
  final List<IngredientUses> _list;
  ShopListW(this._list);

  /// [fromMeals] regroupe les ingrédients des [meals], regroupés par catégories
  factory ShopListW.fromMeals(List<MealExt> meals) {
    final uses = <IdIngredient, List<Quantite>>{};
    final ingredients = <IdIngredient, Ingredient>{};
    for (var repas in meals) {
      for (var platL in repas.requiredQuantities().values) {
        for (var ing in platL) {
          ingredients[ing.ingredient.id] = ing.ingredient;

          final usesList = uses.putIfAbsent(ing.ingredient.id, () => []);
          usesList.add(ing.quantity);
        }
      }
    }
    return ShopListW(uses.keys
        .map((id) => IngredientUses(ingredients[id]!, uses[id]!, false))
        .toList());
  }

  bool get isStarted => _list.any((element) => element.checked);

  List<ShopSection> bySections() {
    final byCategorie = <IngredientKind, List<IngredientUses>>{};
    for (var ing in _list) {
      final l = byCategorie.putIfAbsent(ing.ingredient.kind, () => []);
      l.add(ing);
    }
    return byCategorie.entries.map((e) => ShopSection(e.key, e.value)).toList();
  }
}

/// [ShopController] is the backend updating the
/// shop list, either in local or shared mode.
abstract class ShopController {
  Future<ShopListW> fetchList();
  Future<ShopListW> updateShop(int id, bool checked);
}

/// [ShopControllerLocal] use a local, in-memory data store
class ShopControllerLocal implements ShopController {
  final ShopListW list;
  const ShopControllerLocal(this.list);

  @override
  Future<ShopListW> fetchList() async => list;

  @override
  Future<ShopListW> updateShop(IdIngredient id, bool checked) async {
    final index =
        list._list.indexWhere((element) => element.ingredient.id == id);
    list._list[index] = list._list[index].copyWith(checked: checked);
    return list;
  }
}

/// [ShopControllerShared] uses a remote data store
class ShopControllerShared implements ShopController {
  final Env env;
  final String sessionID;

  ShopControllerShared(this.env, this.sessionID);

  // PUT : crée une session
  // GET (sessionID) : récupère la session demandée
  // POST (sessionID) : modifie la session demandée
  static const _apiEndpoint = "/api/shop-session";

  static const _guestEndpoint = "/shop-session";

  /// [guestURL] renvoie l'url de la page d'accueil destinée
  /// à un nouvel invité
  String guestURL() => env.urlFor(_guestEndpoint,
      queryParameters: {"sessionID": sessionID}).toString();

  /// [createSession] demande au serveur de créer une nouvelle session,
  /// avec le contenu de [list]
  static Future<ShopControllerShared> createSession(
      Env env, ShopListW list) async {
    final resp = await http.put(env.urlFor(_apiEndpoint),
        body: jsonEncode(shopListToJson(list._list)),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });
    final json = jsonDecodeResp(resp);
    final out = createSessionOutFromJson(json);
    return ShopControllerShared(env, out.sessionID);
  }

  @override
  Future<ShopListW> fetchList() async {
    final apiURL =
        env.urlFor(_apiEndpoint, queryParameters: {"sessionID": sessionID});
    final resp = await http.get(apiURL);
    final json = jsonDecodeResp(resp);
    return ShopListW(sessionFromJson(json).list);
  }

  @override
  Future<ShopListW> updateShop(int id, bool checked) async {
    final apiURL =
        env.urlFor(_apiEndpoint, queryParameters: {"sessionID": sessionID});
    final resp = await http.post(apiURL,
        body: jsonEncode(updateSessionInToJson(UpdateSessionIn(id, checked))),
        headers: {
          'Content-type': 'application/json',
          'Accept': 'application/json',
        });
    final json = jsonDecodeResp(resp);
    return ShopListW(sessionFromJson(json).list);
  }
}
