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
        title: const Text("Modifier les ingrédients "),
      ),
      floatingActionButton: FloatingActionButton(
        mini: false,
        onPressed: () => _showEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: ListView(
        children: CategoriePlat.values
            .map((e) => _PlatCard(e, plats[e] ?? [], _removeIngredient,
                _swapCategorie, _updateQuantite))
            .toList(),
      ),
    );
  }

  void _showEditDialog() async {
    await showDialog(
        context: context,
        builder: (context) => Dialog(
              child: _NewIngredientEditor(
                _candidates(),
                (ing, isNew) {
                  Navigator.of(context).pop();
                  _addIngredient(ing, isNew);
                },
              ),
            ));
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
        categorie: CategoriePlat.entree);
    await widget.db.insertMenuIngredient(link);
    setState(() {
      widget.menu.ingredients.add(MenuIngredientExt.from(ing, link));
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
    if (ing.categorie == newCategorie) return;

    await widget.db.updateMenuIngredient(MenuIngredient(
        idMenu: widget.menu.menu.id,
        idIngredient: ing.ingredient.id,
        quantite: ing.quantite,
        categorie: newCategorie));

    setState(() {
      final index = widget.menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      widget.menu.ingredients[index] =
          widget.menu.ingredients[index].copyWith(categorie: newCategorie);
    });
  }

  void _updateQuantite(MenuIngredientExt ing, double newQuantite) async {
    if (ing.quantite == newQuantite) return;
    await widget.db.updateMenuIngredient(MenuIngredient(
        idMenu: widget.menu.menu.id,
        idIngredient: ing.ingredient.id,
        quantite: newQuantite,
        categorie: ing.categorie));

    setState(() {
      final index = widget.menu.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      widget.menu.ingredients[index] =
          widget.menu.ingredients[index].copyWith(quantite: newQuantite);
    });
  }
}

class _PlatCard extends StatelessWidget {
  final CategoriePlat plat;
  final List<MenuIngredientExt> ingredients;

  final void Function(MenuIngredientExt) removeIngredient;
  final void Function(MenuIngredientExt ing, CategoriePlat newCategorie)
      swapCategorie;
  final void Function(MenuIngredientExt ing, double newQuantite) updateQuantite;

  const _PlatCard(this.plat, this.ingredients, this.removeIngredient,
      this.swapCategorie, this.updateQuantite,
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
                                  e, (q) => updateQuantite(e, q)),
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

  const _IngredientRow(this.ingredient, this.onEditQuantite, {super.key});

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
              child:
                  Text("${ing.quantite} ${formatUnite(ing.ingredient.unite)}"),
            )
          ],
        ),
      )),
      child: ListTile(
          visualDensity: const VisualDensity(vertical: -3),
          dense: true,
          title: Text(ing.ingredient.nom),
          subtitle: Text(formatCategorieIngredient(ing.ingredient.categorie)),
          trailing: isEditingQuantity
              ? SizedBox(
                  width: 80,
                  child: TextField(
                    autofocus: true,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                        suffixText: formatUnite(ing.ingredient.unite)),
                    onSubmitted: (value) {
                      widget.onEditQuantite(double.parse(value));
                      setState(() => isEditingQuantity = false);
                    },
                  ),
                )
              : TextButton(
                  onPressed: () => setState(() => isEditingQuantity = true),
                  child: Text(
                      "${ing.quantite} ${formatUnite(ing.ingredient.unite)}"),
                )),
    );
  }
}

class _NewIngredientEditor extends StatefulWidget {
  final List<Ingredient> candidatesIngredients;
  final void Function(Ingredient ing, bool isNew) onDone;

  const _NewIngredientEditor(this.candidatesIngredients, this.onDone,
      {super.key});

  @override
  State<_NewIngredientEditor> createState() => __NewIngredientEditorState();
}

class __NewIngredientEditorState extends State<_NewIngredientEditor> {
  Ingredient edited = const Ingredient(
      id: 0, nom: "", unite: Unite.kg, categorie: CategorieIngredient.legumes);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // name editor/selector
          Autocomplete<Ingredient>(
            optionsBuilder: (textEditingValue) =>
                textEditingValue.text.length >= 2
                    ? searchIngredients([
                        ...widget.candidatesIngredients,
                        ...ingredientsSuggestions,
                      ], textEditingValue.text)
                    : [],
            fieldViewBuilder:
                (context, textEditingController, focusNode, onFieldSubmitted) =>
                    TextField(
              autofocus: true,
              decoration: const InputDecoration(
                  labelText: "Nom", helperText: "Tapper pour rechercher..."),
              controller: textEditingController,
              focusNode: focusNode,
              onSubmitted: (text) {
                setState(() {
                  edited = edited.copyWith(nom: text);
                });
                onFieldSubmitted();
              },
              inputFormatters: [
                TextInputFormatter.withFunction((oldValue, newValue) =>
                    newValue.copyWith(text: capitalize(newValue.text)))
              ],
            ),
            displayStringForOption: (option) => option.nom,
            onSelected: _onAutoComplete,
          ),

          // unite editor
          _UniteEditor(
              edited.unite,
              (u) => setState(() {
                    edited = edited.copyWith(unite: u);
                  })),

          // categorie editor
          _CategorieIngredientEditor(
              edited.categorie,
              (c) => setState(() {
                    edited = edited.copyWith(categorie: c);
                  })),

          ElevatedButton(
              onPressed: isEntryValid ? _addNewIngredient : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Ajouter"))
        ],
      ),
    );
  }

  bool get isEntryValid => edited.nom.isNotEmpty;

  void _onAutoComplete(Ingredient ing) {
    if (ing.id >= 0) {
      // utilise l'ingrédient existant au lieu d'en créer un nouveau
      widget.onDone(ing, false);
    } else {
      // utilise juste la complétion
      setState(() {
        edited = edited.copyWith(
            nom: ing.nom, categorie: ing.categorie, unite: ing.unite);
      });
    }
  }

// crée un nouvel ingrédient
  void _addNewIngredient() {
    widget.onDone(edited, true);
  }
}

class _UniteEditor extends StatelessWidget {
  final Unite value;
  final void Function(Unite) onChange;

  const _UniteEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<Unite>(
          hint: const Text("Unité"),
          value: value,
          items: Unite.values
              .map((e) => DropdownMenuItem<Unite>(
                    value: e,
                    child: Text(formatUnite(e)),
                  ))
              .toList(),
          onChanged: (u) => u == null ? {} : onChange(u)),
    );
  }
}

class _CategorieIngredientEditor extends StatelessWidget {
  final CategorieIngredient value;
  final void Function(CategorieIngredient) onChange;

  const _CategorieIngredientEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<CategorieIngredient>(
          hint: const Text("Catégorie"),
          value: value,
          items: CategorieIngredient.values
              .map((e) => DropdownMenuItem<CategorieIngredient>(
                  value: e, child: Text(formatCategorieIngredient(e))))
              .toList(),
          onChanged: (u) => u == null ? {} : onChange(u)),
    );
  }
}
