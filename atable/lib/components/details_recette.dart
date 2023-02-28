import 'package:atable/components/import_dialog.dart';
import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// [DetailsRecette] est utilisé pour modifier les ingrédients d'une recette
class DetailsRecette extends StatefulWidget {
  final DBApi db;

  final RecetteExt initialValue;

  final bool openDetails;

  const DetailsRecette(this.db, this.initialValue, this.openDetails,
      {super.key});

  @override
  State<DetailsRecette> createState() => _DetailsRecetteState();
}

class _DetailsRecetteState extends State<DetailsRecette> {
  late RecetteExt recette;
  List<Ingredient> allIngredients = [];

  @override
  void initState() {
    recette = widget.initialValue;
    _loadIngredients();

    super.initState();

    if (widget.openDetails) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _showEditDialog());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: recette.recette.categorie.color,
        title: Text(recette.recette.label),
        actions: [
          IconButton(onPressed: _showEditDialog, icon: const Icon(Icons.edit)),
          IconButton(
              onPressed: _showImportDialog, icon: const Icon(Icons.upload))
        ],
      ),
      floatingActionButton: FloatingActionButton(
        mini: false,
        onPressed: () => _showIngredientDialog(),
        child: const Icon(Icons.add),
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          NombrePersonneEditor(
              recette.recette.nbPersonnes,
              (v) => _updateRecette(
                  recette.recette.copyWith(nbPersonnes: v.toInt()))),
          Expanded(
            child: ListView(
              children: [
                ...recette.ingredients.map((e) => DismissibleDelete(
                      itemKey: e.ingredient.id,
                      onDissmissed: () => _removeIngredient(e),
                      child: IngredientRow(
                          e,
                          (q) => _updateLink(e, q, e.link.unite),
                          (u) => _updateLink(e, e.link.quantite, u)),
                    )),
                _Description(
                    recette.recette.description,
                    (p0) => _updateRecette(
                        recette.recette.copyWith(description: p0)))
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIngredientDialog() async {
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
      if (ing.id < 0) {
        // register first the new ingredient
        ing = await widget.db.insertIngredient(ing);
      }
      final link = RecetteIngredient(
          idRecette: recette.recette.id,
          idIngredient: ing.id,
          quantite: item.quantite,
          unite: item.unite);
      await widget.db.insertRecetteIngredient(link);
      setState(() {
        recette.ingredients.add(RecetteIngredientExt(ing, link));
      });
    }
  }

  void _updateRecette(Recette newRecette) async {
    setState(() {
      recette = recette.copyWith(recette: newRecette);
    });
    await widget.db.updateRecette(newRecette);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Recette modifiée.'),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.green,
    ));
  }

  void _showEditDialog() async {
    final newRecette = await showDialog<Recette>(
        context: context,
        builder: (context) => Dialog(
              child: _EditDialog(
                  recette.recette, (s) => Navigator.of(context).pop(s)),
            ));
    if (newRecette == null) return;

    _updateRecette(newRecette);
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
    final link = RecetteIngredient(
      idRecette: recette.recette.id,
      idIngredient: ing.id,
      quantite: 1,
      unite: Unite.kg,
    );
    final newIngredients = await widget.db.insertRecetteIngredient(link);
    setState(() {
      recette = recette.copyWith(ingredients: newIngredients);
    });
  }

  void _removeIngredient(RecetteIngredientExt ing) async {
    await widget.db.deleteRecetteIngredient(ing.link);
    setState(() {
      recette.ingredients
          .removeWhere((element) => element.ingredient.id == ing.ingredient.id);
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Ingrédient ${ing.ingredient.nom} supprimé.'),
      backgroundColor: Colors.green,
    ));
  }

  void _updateLink(
      RecetteIngredientExt ing, double newQuantite, Unite newUnite) async {
    if (ing.link.quantite == newQuantite && ing.link.unite == newUnite) return;

    final newLink = ing.link.copyWith(quantite: newQuantite, unite: newUnite);
    await widget.db.updateRecetteIngredient(newLink);

    setState(() {
      final index = recette.ingredients
          .indexWhere((element) => element.ingredient.id == ing.ingredient.id);
      recette.ingredients[index] =
          recette.ingredients[index].copyWith(link: newLink);
    });
  }
}

/// [_EditDialog] permet de renommer une menu ou une recette.
class _EditDialog extends StatefulWidget {
  final Recette initialValue;
  final void Function(Recette) onDone;

  const _EditDialog(this.initialValue, this.onDone, {super.key});

  @override
  State<_EditDialog> createState() => _EditDialogState();
}

class _EditDialogState extends State<_EditDialog> {
  final TextEditingController controller = TextEditingController();
  late CategoriePlat categoriePlat;

  @override
  void initState() {
    controller.text = widget.initialValue.label;
    controller.selection = TextSelection(
        baseOffset: 0, extentOffset: widget.initialValue.label.length);
    controller.addListener(() => setState(() {}));
    categoriePlat = widget.initialValue.categorie;
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
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              "Editer la recette",
              style: TextStyle(fontSize: 18),
            ),
          ),
          TextField(
            autofocus: true,
            controller: controller,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  newValue.copyWith(text: capitalize(newValue.text)))
            ],
            decoration: const InputDecoration(labelText: "Nom de la recette"),
          ),
          // categorie editor
          DropdownButtonFormField<CategoriePlat>(
              decoration: const InputDecoration(labelText: "Plat"),
              value: categoriePlat,
              items: CategoriePlat.values
                  .map((e) => DropdownMenuItem<CategoriePlat>(
                      value: e, child: Text(formatCategoriePlat(e))))
                  .toList(),
              onChanged: (u) => u == null
                  ? {}
                  : setState(
                      () {
                        categoriePlat = u;
                      },
                    )),
          const SizedBox(height: 20),
          TextButton(
            onPressed: isInputValid
                ? () => widget.onDone(widget.initialValue
                    .copyWith(label: controller.text, categorie: categoriePlat))
                : null,
            style: TextButton.styleFrom(
                backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Modifier"),
          )
        ],
      ),
    );
  }
}

class _Description extends StatefulWidget {
  final String initialValue;
  final void Function(String) onEdit;

  const _Description(this.initialValue, this.onEdit, {super.key});

  @override
  State<_Description> createState() => __DescriptionState();
}

class __DescriptionState extends State<_Description> {
  TextEditingController? ct;

  bool get isEditing => ct != null;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.only(left: 8.0, right: 8, bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text("Description", style: TextStyle(fontSize: 16)),
                const Spacer(),
                isEditing
                    ? IconButton(
                        onPressed: _endEdit,
                        icon: const Icon(
                          Icons.done,
                          color: Colors.green,
                        ))
                    : IconButton(
                        onPressed: _startEdit,
                        icon: widget.initialValue.isEmpty
                            ? const Icon(
                                Icons.add,
                                color: Colors.green,
                              )
                            : const Icon(Icons.edit))
              ],
            ),
            isEditing
                ? TextField(
                    maxLines: null,
                    controller: ct,
                    autofocus: true,
                  )
                : widget.initialValue.isNotEmpty
                    ? Text(widget.initialValue)
                    : const SizedBox(),
          ],
        ),
      ),
    );
  }

  void _startEdit() {
    setState(() {
      ct = TextEditingController(text: widget.initialValue);
    });
  }

  void _endEdit() {
    if (ct == null) return;
    widget.onEdit(ct!.text);
    setState(() {
      ct = null;
    });
  }
}
