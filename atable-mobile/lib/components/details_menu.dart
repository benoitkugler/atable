import 'package:atable/components/details_ingredient.dart';
import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';

/// [DetailsMenu] exposes the content of a [Menu]
/// and its [Receipe]s
class DetailsMenu extends StatefulWidget {
  final DBApi db;

  final MenuExt initialValue;

  const DetailsMenu(this.db, this.initialValue, {super.key});

  @override
  State<DetailsMenu> createState() => _DetailsMenuState();
}

class _DetailsMenuState extends State<DetailsMenu> {
  late MenuExt menu;

  @override
  void initState() {
    menu = widget.initialValue;

    super.initState();
  }

  int? get hasSameFor {
    final allFors = menu.ingredients.map((e) => e.link.quantity.for_).toList();
    for (var e in menu.receipes) {
      allFors.addAll(e.ingredients.map((e) => e.link.quantity.for_));
    }
    final asSet = allFors.toSet();
    return asSet.length == 1 ? asSet.first : null;
  }

  @override
  Widget build(BuildContext context) {
    final platIngs = ingredientsByPlats(menu.ingredients);
    final platRecettes = recettesByPlats(menu.receipes);
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du menu"),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddIngredient,
        tooltip: "Ajouter un ingrédient",
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasSameFor != null)
            Card(
              margin: const EdgeInsets.all(8),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "Les quantités sont exprimées pour $hasSameFor personnes"),
              ),
            ),
          Expanded(
            child: ListView(
              children: PlatKind.values.reversed
                  .map((e) => _PlatCard(
                      e,
                      platIngs[e] ?? [],
                      platRecettes[e] ?? [],
                      hasSameFor == null,
                      _removeIngredient,
                      _swapCategorie,
                      _updateMenuIng,
                      _updateReceipeIng,
                      _showIngredient))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIngredient() async {
    final allIngredients = (await widget.db.getIngredients()).toList();
    if (!mounted) return;

    await showDialog(
        context: context,
        builder: (context) => Dialog(
              child: IngredientSelector(
                allIngredients,
                (ing) {
                  Navigator.of(context).pop();
                  _addIngredient(ing);
                },
              ),
            ));
  }

  void _addIngredient(Ingredient ing) async {
    if (ing.id < 0) {
      // register first the new ingredient
      ing = await widget.db.insertIngredient(ing);
    }
    var for_ = 10;
    if (menu.ingredients.isNotEmpty) {
      for_ = menu.ingredients.last.link.quantity.for_;
    } else if (menu.receipes.isEmpty) {
      final receipe = menu.receipes.last;
      if (receipe.ingredients.isNotEmpty) {
        for_ = receipe.ingredients.last.link.quantity.for_;
      }
    }
    final link = MenuIngredient(
        menu.menu.id, ing.id, QuantityR(1, Unite.kg, for_), PlatKind.entree);
    final newIngredients = await widget.db.insertMenuIngredient(link);
    setState(() {
      menu = menu.copyWith(ingredients: newIngredients);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Ingrédient ${ing.name} ajouté.'),
      backgroundColor: Colors.green,
    ));
  }

  void _removeIngredient(MenuIngredientExt ing) async {
    await widget.db.deleteMenuIngredient(ing.link);
    setState(() {
      menu.ingredients
          .removeWhere((element) => element.ingredient.id == ing.ingredient.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Ingrédient ${ing.ingredient.name} supprimé.'),
      backgroundColor: Colors.green,
    ));
  }

  void _swapCategorie(MenuIngredientExt ing, PlatKind newPlat) async {
    if (ing.link.plat == newPlat) return;

    await widget.db.deleteMenuIngredient(ing.link);

    final newLink = ing.link.copyWith(plat: newPlat);
    final newIngredients = await widget.db.insertMenuIngredient(newLink);
    setState(() {
      menu = menu.copyWith(ingredients: newIngredients);
    });
  }

  void _updateMenuIng(MenuIngredientExt ing, QuantityR newQuantity) async {
    if (ing.link.quantity.val == newQuantity.val &&
        ing.link.quantity.unite == newQuantity.unite &&
        ing.link.quantity.for_ == newQuantity.for_) return;

    final newLink = ing.link.copyWith(quantity: newQuantity);
    await widget.db.updateMenuIngredient(newLink);

    setState(() {
      final index = menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      menu.ingredients[index] = menu.ingredients[index].copyWith(link: newLink);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Quantité pour ${ing.ingredient.name} modifiée.'),
      backgroundColor: Colors.green,
    ));
  }

  void _updateReceipeIng(
      ReceipeIngredientExt toChange, QuantityR newQuantity) async {
    if (toChange.link.quantity.val == newQuantity.val &&
        toChange.link.quantity.unite == newQuantity.unite &&
        toChange.link.quantity.for_ == newQuantity.for_) return;

    final newLink = toChange.link.copyWith(quantity: newQuantity);
    await widget.db.updateReceipeIngredient(newLink);

    setState(() {
      menu.receipes
          .where((rec) => rec.receipe.id == toChange.link.idReceipe)
          .forEach((rec) {
        final index = rec.ingredients
            .indexWhere((ing) => ing.ingredient.id == toChange.ingredient.id);
        rec.ingredients[index] = rec.ingredients[index].copyWith(link: newLink);
      });
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Quantité pour ${toChange.ingredient.name} modifiée.'),
      backgroundColor: Colors.green,
    ));
  }

  _showIngredient(Ingredient e) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsIngredient(widget.db, e),
    ));
    final updatedMenu = await widget.db.getMenu(menu.menu.id);
    setState(() {
      menu = updatedMenu;
    });
  }
}

class _PlatCard extends StatelessWidget {
  final PlatKind plat;
  final List<MenuIngredientExt> ingredients;
  final List<ReceipeExt> recettes;
  final bool showFor;
  final void Function(MenuIngredientExt) removeIngredient;
  final void Function(MenuIngredientExt ing, PlatKind newCategorie)
      swapCategorie;
  final void Function(MenuIngredientExt ing, QuantityR newQuantity)
      updateMenuIng;
  final void Function(ReceipeIngredientExt ing, QuantityR newQuantity)
      updateReceipeIng;

  final void Function(Ingredient) showIngredient;

  const _PlatCard(
      this.plat,
      this.ingredients,
      this.recettes,
      this.showFor,
      this.removeIngredient,
      this.swapCategorie,
      this.updateMenuIng,
      this.updateReceipeIng,
      this.showIngredient,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return DragTarget<MenuIngredientExt>(
      onAccept: (data) => swapCategorie(data, plat),
      builder: (context, candidateData, rejectedData) => Card(
        color: plat.color,
        elevation: candidateData.isEmpty ? null : 10,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                formatPlatKind(plat),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: ingredients.isEmpty && recettes.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Text(
                        "Aucun ingrédient ou recette.",
                        style: TextStyle(fontStyle: FontStyle.italic),
                      ),
                    )
                  : Container(
                      decoration: const BoxDecoration(
                        borderRadius: BorderRadius.all(Radius.circular(6)),
                        color: Colors.white,
                      ),
                      child: Column(children: [
                        ...ingredients.map((e) => DismissibleDelete(
                              itemKey: e.ingredient.id,
                              onDissmissed: () => removeIngredient(e),
                              child: IngredientRow(
                                e,
                                (q) => updateMenuIng(e, q),
                                () => showIngredient(e.ingredient),
                                showFor,
                                allowDrag: true,
                              ),
                            )),
                        ...recettes.map((e) => _RecetteCard(
                            e, showFor, updateReceipeIng, showIngredient))
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecetteCard extends StatefulWidget {
  final ReceipeExt receipe;
  final bool showFor;
  final void Function(ReceipeIngredientExt, QuantityR) updateReceipeIng;
  final void Function(Ingredient) showIngredient;

  const _RecetteCard(
      this.receipe, this.showFor, this.updateReceipeIng, this.showIngredient,
      {super.key});

  @override
  State<_RecetteCard> createState() => _RecetteCardState();
}

class _RecetteCardState extends State<_RecetteCard> {
  bool showIngredients = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          visualDensity: const VisualDensity(vertical: -3),
          dense: true,
          title: Text(widget.receipe.receipe.name),
          subtitle: const Text("Recette"),
          trailing: IconButton(
              onPressed: () =>
                  setState(() => showIngredients = !showIngredients),
              icon: showIngredients
                  ? const Icon(Icons.expand_less)
                  : const Icon(Icons.expand_more)),
        ),
        if (showIngredients)
          ...widget.receipe.ingredients.map((e) => IngredientRow(
              e,
              (qu) => widget.updateReceipeIng(e, qu),
              () => widget.showIngredient(e.ingredient),
              widget.showFor))
      ],
    );
  }
}

Map<PlatKind, List<MenuIngredientExt>> ingredientsByPlats(
    List<MenuIngredientExt> ingredients) {
  final Map<PlatKind, List<MenuIngredientExt>> crible = {};
  for (var ing in ingredients) {
    final l = crible.putIfAbsent(ing.link.plat, () => []);
    l.add(ing);
  }
  return crible;
}

Map<PlatKind, List<ReceipeExt>> recettesByPlats(List<ReceipeExt> recettes) {
  final Map<PlatKind, List<ReceipeExt>> crible = {};
  for (var ing in recettes) {
    final l = crible.putIfAbsent(ing.receipe.plat, () => []);
    l.add(ing);
  }
  return crible;
}
