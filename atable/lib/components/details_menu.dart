import 'package:atable/components/details_ingredient.dart';
import 'package:atable/components/details_recette.dart';
import 'package:atable/components/import_dialog.dart';
import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/recettes_list.dart';
import 'package:atable/components/shared.dart';
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

  @override
  void initState() {
    menu = widget.initialValue;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final isAnonyme = menu.menu.label.isEmpty;
    final hasIngredients = menu.ingredients
        .isNotEmpty; // true si le menu a au mois un ingrédient 'libre'
    final platIngs = ingredientsByPlats(menu.ingredients);
    final platRecettes = recettesByPlats(menu.recettes);
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
        onPressed: () {},
        child: PopupMenuButton<int>(
          onSelected: (value) =>
              value == 0 ? _showAddRecette() : _showAddIngredient(),
          itemBuilder: (context) => [
            const PopupMenuItem(
                value: 0, child: Text("Ajouter une recette...")),
            const PopupMenuItem(
                value: 1, child: Text("Ajouter un ingrédient...")),
          ],
          child: const Icon(Icons.add),
        ),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 400),
            crossFadeState: hasIngredients
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox(),
            secondChild: NombrePersonneEditor(menu.menu.nbPersonnes,
                (v) => _updateMenu(menu.menu.copyWith(nbPersonnes: v.toInt()))),
          ),
          Expanded(
            child: ListView(
              children: CategoriePlat.values
                  .map((e) => _PlatCard(
                      e,
                      platIngs[e] ?? [],
                      platRecettes[e] ?? [],
                      _removeIngredient,
                      _swapCategorie,
                      _updateLink,
                      _removeRecette,
                      _goToRecette,
                      _showIngredient))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddIngredient() async {
    final allIngredients = await widget.db.getIngredients();
    if (!mounted) return;

    await showDialog(
        context: context,
        builder: (context) => Dialog(
              child: IngredientEditor(
                allIngredients,
                (ing) {
                  Navigator.of(context).pop();
                  _addIngredient(ing);
                },
              ),
            ));
  }

  void _showAddRecette() async {
    final selectedRecette =
        await Navigator.of(context).push(MaterialPageRoute<Recette>(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text("Choisir une recette"),
        ),
        body: RecetteSelector(
            widget.db, (selected) => Navigator.of(context).pop(selected)),
      ),
    ));
    if (selectedRecette == null) return; // import annulé
    final recette =
        await widget.db.insertMenuRecette(menu.menu.id, selectedRecette.id);
    setState(() {
      menu.recettes.add(recette);
    });
  }

  void _showImportDialog() async {
    final allIngredients = await widget.db.getIngredients();
    if (!mounted) return;

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
    }

    final updated = await widget.db.getMenu(menu.menu.id);
    setState(() {
      menu = updated;
    });
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

  void _addIngredient(Ingredient ing) async {
    if (ing.id < 0) {
      // register first the new ingredient, and record it in the proposition
      ing = await widget.db.insertIngredient(ing);
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

  void _removeRecette(RecetteExt recette) async {
    await widget.db.deleteMenuRecette(
        MenuRecette(idMenu: menu.menu.id, idRecette: recette.recette.id));
    setState(() {
      menu.recettes
          .removeWhere((element) => element.recette.id == recette.recette.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Recette ${recette.recette.label} supprimée.'),
      backgroundColor: Colors.green,
    ));
  }

  void _goToRecette(RecetteExt recette) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsRecette(widget.db, recette, false),
    ));
    // met à jour les données
    recette = await widget.db.getRecette(recette.recette.id);
    setState(() {
      final index = menu.recettes
          .indexWhere((element) => element.recette.id == recette.recette.id);
      menu.recettes[index] = recette;
    });
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
  final CategoriePlat plat;
  final List<MenuIngredientExt> ingredients;
  final List<RecetteExt> recettes;

  final void Function(MenuIngredientExt) removeIngredient;
  final void Function(MenuIngredientExt ing, CategoriePlat newCategorie)
      swapCategorie;
  final void Function(MenuIngredientExt ing, double newQuantite, Unite newUnite)
      updateLink;

  final void Function(RecetteExt) removeRecette;
  final void Function(RecetteExt) goToRecette;
  final void Function(Ingredient) showIngredient;

  const _PlatCard(
      this.plat,
      this.ingredients,
      this.recettes,
      this.removeIngredient,
      this.swapCategorie,
      this.updateLink,
      this.removeRecette,
      this.goToRecette,
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
                formatCategoriePlat(plat),
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
                                (q) => updateLink(e, q, e.link.unite),
                                (u) => updateLink(e, e.link.quantite, u),
                                () => showIngredient(e.ingredient),
                              ),
                            )),
                        ...recettes.map((e) => DismissibleDelete(
                            itemKey: -e.recette.id,
                            onDissmissed: () => removeRecette(e),
                            child: _RecetteRow(e, () => goToRecette(e))))
                      ]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecetteRow extends StatelessWidget {
  final RecetteExt recette;
  final void Function() onGoTo;

  const _RecetteRow(this.recette, this.onGoTo, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onGoTo,
      visualDensity: const VisualDensity(vertical: -3),
      dense: true,
      title: Text(recette.recette.label),
      subtitle: const Text("Recette"),
      trailing: const Icon(Icons.navigate_next),
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
