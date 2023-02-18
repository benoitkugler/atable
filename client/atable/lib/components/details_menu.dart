import 'package:atable/components/import_dialog.dart';
import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/ingredientsDB.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [DetailsMenu] est utilisé pour modifier les ingrédients d'un repas
class DetailsMenu extends StatefulWidget {
  final DBApi db;

  final MenuExt initialValue;

  const DetailsMenu(this.db, this.initialValue, {super.key});

  @override
  State<DetailsMenu> createState() => _DetailsMenuState();
}

class _DetailsMenuState extends State<DetailsMenu> {
  late MenuExt menu;
  List<Ingredient> allIngredients = [];

  @override
  void initState() {
    menu = widget.initialValue;
    _loadIngredients();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isAnonyme = menu.menu.label.isEmpty;
    final plats = buildPlats(menu.ingredients);
    return Scaffold(
      appBar: AppBar(
        title: Text(isAnonyme ? "Menu" : menu.menu.label),
        actions: [
          IconButton(
              onPressed: _showRenameDialog,
              icon: isAnonyme
                  ? const Icon(Icons.favorite)
                  : const Icon(Icons.edit)),
          IconButton(
              onPressed: _showImportDialog, icon: const Icon(Icons.upload))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: false,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          NombrePersonneEditor(menu.menu.nbPersonnes,
              (v) => _updateMenu(menu.menu.copyWith(nbPersonnes: v.toInt()))),
          Expanded(
            child: ListView(
              children: CategoriePlat.values
                  .map((e) => _PlatCard(e, plats[e] ?? [], _removeIngredient,
                      _swapCategorie, _updateLink))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog() async {
    await showDialog(
        context: context,
        builder: (context) => Dialog(
              child: IngredientEditor(
                allIngredients,
                (ing, isNew) {
                  Navigator.of(context).pop();
                  _addIngredient(ing, isNew);
                },
              ),
            ));
  }

  void _showImportDialog() async {
    final newIngredients = await showImportDialog(allIngredients, context);
    if (newIngredients == null) return; // import annulé

    // ajout des ingrédients
    for (var item in newIngredients) {
      Ingredient ing = item.ingredient;
      if (ing.id <= 0) {
        // register first the new ingredient
        ing = await widget.db.insertIngredient(ing);
      }

      final link = MenuIngredient(
          idMenu: menu.menu.id,
          idIngredient: ing.id,
          quantite: item.quantite,
          unite: item.unite,
          categorie: CategoriePlat.entree);
      await widget.db.insertMenuIngredient(link);
      setState(() {
        menu.ingredients.add(MenuIngredientExt(ing, link));
      });
    }
  }

  void _updateMenu(Menu newMenu) async {
    setState(() {
      menu = menu.copyWith(menu: newMenu);
    });
    await widget.db.updateMenu(newMenu);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Menu modifié.'),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.green,
    ));
  }

  void _showRenameDialog() async {
    final newLabel = await showDialog<String>(
        context: context,
        builder: (context) => Dialog(
              child: _RenameDialog(
                  menu.menu.label, (s) => Navigator.of(context).pop(s)),
            ));
    if (newLabel == null) return;

    _updateMenu(menu.menu.copyWith(label: newLabel));
  }

  void _loadIngredients() async {
    allIngredients = await widget.db.getIngredients();
  }

  void _addIngredient(Ingredient ing, bool isNew) async {
    if (isNew) {
      // register first the new ingredient, and record it in the proposition
      ing = await widget.db.insertIngredient(ing);
      allIngredients.add(ing);
    }
    final link = MenuIngredient(
        idMenu: menu.menu.id,
        idIngredient: ing.id,
        quantite: 1,
        unite: Unite.kg,
        categorie: CategoriePlat.entree);
    final newIngredients = await widget.db.insertMenuIngredient(link);
    setState(() {
      menu = menu.copyWith(ingredients: newIngredients);
    });
  }

  void _removeIngredient(MenuIngredientExt ing) async {
    await widget.db.deleteMenuIngredient(ing.link);
    setState(() {
      menu.ingredients
          .removeWhere((element) => element.ingredient.id == ing.ingredient.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Ingrédient ${ing.ingredient.nom} supprimé.'),
      backgroundColor: Colors.green,
    ));
  }

  void _swapCategorie(MenuIngredientExt ing, CategoriePlat newCategorie) async {
    if (ing.link.categorie == newCategorie) return;

    await widget.db.deleteMenuIngredient(ing.link);

    final newLink = ing.link.copyWith(categorie: newCategorie);
    final newIngredients = await widget.db.insertMenuIngredient(newLink);
    setState(() {
      menu = menu.copyWith(ingredients: newIngredients);
    });
  }

  void _updateLink(
      MenuIngredientExt ing, double newQuantite, Unite newUnite) async {
    if (ing.link.quantite == newQuantite && ing.link.unite == newUnite) return;

    final newLink = ing.link.copyWith(quantite: newQuantite, unite: newUnite);
    await widget.db.updateMenuIngredient(newLink);

    setState(() {
      final index = menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      menu.ingredients[index] = menu.ingredients[index].copyWith(link: newLink);
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
                        .map((e) => DismissibleDelete(
                              itemKey: e.ingredient.id,
                              onDissmissed: () => removeIngredient(e),
                              child: IngredientRow(
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

/// [_RenameDialog] permet de renommer un item
class _RenameDialog extends StatefulWidget {
  final String initialValue;
  final void Function(String) onDone;

  const _RenameDialog(this.initialValue, this.onDone, {super.key});

  @override
  State<_RenameDialog> createState() => _RenameDialogState();
}

class _RenameDialogState extends State<_RenameDialog> {
  final TextEditingController controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.initialValue;
    controller.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool get isInputValid => controller.text.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.initialValue.isEmpty ? "Ajouter en favori" : "Renommer",
              style: const TextStyle(fontSize: 18),
            ),
          ),
          TextField(
            autofocus: true,
            controller: controller,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  newValue.copyWith(text: capitalize(newValue.text)))
            ],
            decoration: const InputDecoration(labelText: "Nom"),
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed:
                isInputValid ? () => widget.onDone(controller.text) : null,
            style: TextButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Renommer"),
          )
        ],
      ),
    );
  }
}
