import 'package:atable/components/import_dialog.dart';
import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/logic/ingredientsDB.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

extension CategoriePlatColor on CategoriePlat {
  Color get color {
    switch (this) {
      case CategoriePlat.entree:
        return Colors.green.shade300;
      case CategoriePlat.platPrincipal:
        return Colors.deepOrange.shade200;
      case CategoriePlat.dessert:
        return Colors.pink.shade300;
      case CategoriePlat.divers:
        return Colors.grey.shade400;
    }
  }
}

/// [DetailsMenu] est utilisé pour modifier les ingrédients d'un repas
class DetailsMenu extends StatefulWidget {
  final DBApi db;

  final MenuExt menu;

  const DetailsMenu(this.db, this.menu, {super.key});

  @override
  State<DetailsMenu> createState() => _DetailsMenuState();
}

class _DetailsMenuState extends State<DetailsMenu> {
  List<Ingredient> allIngredients = [];

  @override
  void initState() {
    _loadIngredients();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final plats = widget.menu.plats();
    return Scaffold(
      appBar: AppBar(
        title: Text("Ingrédients pour ${widget.menu.menu.nbPersonnes}"),
        actions: [
          IconButton(
              onPressed: _showImportDialog, icon: const Icon(Icons.upload))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: false,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: CategoriePlat.values
            .map((e) => _PlatCard(e, plats[e] ?? [], _removeIngredient,
                _swapCategorie, _updateLink))
            .toList(),
      ),
    );
  }

  void _showEditDialog() async {
    await showDialog(
        context: context,
        builder: (context) => Dialog(
              child: IngredientEditor(
                _candidates(),
                (ing, isNew) {
                  Navigator.of(context).pop();
                  _addIngredient(ing, isNew);
                },
              ),
            ));
  }

  void _showImportDialog() async {
    final cp = await Clipboard.getData(Clipboard.kTextPlain);
    if (cp == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Le presse-papier est vide !")));
      }
      return;
    }
    final newIngredients = await showDialog<List<MenuIngredientExt>>(
        context: context,
        builder: (context) => Dialog(
              child: ImportDialog(_candidates(), cp.text ?? "",
                  (l) => Navigator.of(context).pop(l)),
            ));
    if (newIngredients == null) return; // import annulé
    // ajout des ingrédients
    for (var item in newIngredients) {
      Ingredient ing = item.ingredient;
      if (ing.id < 0) {
        // register first the new ingredient
        ing = await widget.db.insertIngredient(ing);
      }
      final link =
          item.link.copyWith(idMenu: widget.menu.menu.id, idIngredient: ing.id);
      await widget.db.insertMenuIngredient(link);
      setState(() {
        widget.menu.ingredients.add(MenuIngredientExt(ing, link));
      });
    }
  }

  void _loadIngredients() async {
    allIngredients = await widget.db.getIngredients();
  }

  // enlève les ingrédients déjà présent dans le menu
  List<Ingredient> _candidates() {
    final existingIngs =
        widget.menu.ingredients.map((e) => e.ingredient.id).toSet();
    return allIngredients
        .where((element) => !existingIngs.contains(element.id))
        .toList();
  }

  void _addIngredient(Ingredient ing, bool isNew) async {
    if (isNew) {
      // register first the new ingredient
      ing = await widget.db.insertIngredient(ing);
    }
    final link = MenuIngredient(
        idMenu: widget.menu.menu.id,
        idIngredient: ing.id,
        quantite: 1,
        unite: Unite.kg,
        categorie: CategoriePlat.entree);
    await widget.db.insertMenuIngredient(link);
    setState(() {
      widget.menu.ingredients.add(MenuIngredientExt(ing, link));
    });
  }

  void _removeIngredient(MenuIngredientExt ing) async {
    await widget.db
        .deleteMenuIngredient(widget.menu.menu.id, ing.ingredient.id);
    setState(() {
      widget.menu.ingredients
          .removeWhere((element) => element.ingredient.id == ing.ingredient.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ingrédient ${ing.ingredient.nom} supprimé.')));
  }

  void _swapCategorie(MenuIngredientExt ing, CategoriePlat newCategorie) async {
    if (ing.link.categorie == newCategorie) return;

    final newLink = ing.link.copyWith(categorie: newCategorie);
    await widget.db.updateMenuIngredient(newLink);

    setState(() {
      final index = widget.menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      widget.menu.ingredients[index] =
          widget.menu.ingredients[index].copyWith(link: newLink);
    });
  }

  void _updateLink(
      MenuIngredientExt ing, double newQuantite, Unite newUnite) async {
    if (ing.link.quantite == newQuantite && ing.link.unite == newUnite) return;

    final newLink = ing.link.copyWith(quantite: newQuantite, unite: newUnite);
    await widget.db.updateMenuIngredient(newLink);

    setState(() {
      final index = widget.menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      widget.menu.ingredients[index] =
          widget.menu.ingredients[index].copyWith(link: newLink);
    });
  }
}

class _PlatCard extends StatelessWidget {
  final CategoriePlat plat;
  final List<MenuIngredientExt> ingredients;

  final void Function(MenuIngredientExt) removeIngredient;
  final void Function(MenuIngredientExt ing, CategoriePlat newCategorie)
      swapCategorie;
  final void Function(MenuIngredientExt ing, double newQuantite, Unite newUnite)
      updateLink;

  const _PlatCard(this.plat, this.ingredients, this.removeIngredient,
      this.swapCategorie, this.updateLink,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return DragTarget<MenuIngredientExt>(
      onAccept: (data) => swapCategorie(data, plat),
      builder: (context, candidateData, rejectedData) => Card(
        color: plat.color,
        elevation: candidateData.isEmpty ? null : 10,
        child: Column(
          // crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                formatCategoriePlat(plat),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.all(Radius.circular(6)),
                  color: Colors.white,
                ),
                child: Column(
                    children: ingredients
                        .map((e) => Dismissible(
                              key: Key("${e.ingredient.id}"),
                              background: Container(
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(5)),
                              ),
                              onDismissed: (_) => removeIngredient(e),
                              child: _IngredientRow(
                                  e,
                                  (q) => updateLink(e, q, e.link.unite),
                                  (u) => updateLink(e, e.link.quantite, u)),
                            ))
                        .toList()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatefulWidget {
  final MenuIngredientExt ingredient;

  final void Function(double quantite) onEditQuantite;
  final void Function(Unite unite) onEditUnite;

  const _IngredientRow(this.ingredient, this.onEditQuantite, this.onEditUnite,
      {super.key});

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  bool isEditingQuantity = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient;
    return Draggable<MenuIngredientExt>(
        affinity: Axis.vertical,
        data: ing,
        feedback: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(ing.ingredient.nom),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "${formatQuantite(ing.link.quantite)} ${formatUnite(ing.link.unite)}"),
              )
            ],
          ),
        )),
        child: ListTile(
            visualDensity: const VisualDensity(vertical: -3),
            dense: true,
            title: Text(ing.ingredient.nom),
            subtitle: Text(formatCategorieIngredient(ing.ingredient.categorie)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isEditingQuantity
                    ? SizedBox(
                        width: 60,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            widget.onEditQuantite(double.parse(value));
                            setState(() => isEditingQuantity = false);
                          },
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: const VisualDensity(horizontal: -3)),
                        onPressed: () =>
                            setState(() => isEditingQuantity = true),
                        child: Text(formatQuantite(ing.link.quantite)),
                      ),
                _UniteEditor(
                    ing.link.unite,
                    (u) => setState(() {
                          widget.onEditUnite(u);
                        }))
              ],
            )));
  }
}

class _UniteEditor extends StatelessWidget {
  final Unite value;
  final void Function(Unite) onChange;

  const _UniteEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Unite>(
      initialValue: value,
      itemBuilder: (context) => Unite.values
          .map((e) => PopupMenuItem<Unite>(
                value: e,
                child: Text(formatUnite(e)),
              ))
          .toList(),
      onSelected: onChange,
      child: Text(
        formatUnite(value).padRight(2),
        style: TextStyle(
            fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
