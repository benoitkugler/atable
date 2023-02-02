import 'package:atable/logic/ingredientsDB.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IngredientEditor extends StatefulWidget {
  final List<Ingredient> candidatesIngredients;
  final void Function(Ingredient ing, bool isNew) onDone;
  final Ingredient? initialValue;

  const IngredientEditor(this.candidatesIngredients, this.onDone,
      {super.key, this.initialValue});

  @override
  State<IngredientEditor> createState() => _IngredientEditorState();
}

class _IngredientEditorState extends State<IngredientEditor> {
  Ingredient edited =
      const Ingredient(id: 0, nom: "", categorie: CategorieIngredient.legumes);

  @override
  void initState() {
    if (widget.initialValue != null) edited = widget.initialValue!;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // name editor/selector
          Autocomplete<Ingredient>(
            initialValue: TextEditingValue(text: edited.nom),
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
        edited = edited.copyWith(nom: ing.nom, categorie: ing.categorie);
      });
    }
  }

// crée un nouvel ingrédient
  void _addNewIngredient() {
    widget.onDone(edited, true);
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
