import 'package:atable/logic/ingredients_table.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class IngredientEditor extends StatefulWidget {
  final List<Ingredient> candidatesIngredients;
  final void Function(Ingredient ing, bool isNew) onDone;
  final Ingredient? initialValue;

  final String title;
  final void Function()? onAbort;

  const IngredientEditor(this.candidatesIngredients, this.onDone,
      {super.key,
      this.initialValue,
      this.onAbort,
      this.title = "Ajouter un ingrédient"});

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
  void didUpdateWidget(covariant IngredientEditor oldWidget) {
    if (widget.initialValue != null) edited = widget.initialValue!;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              widget.title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          _IngredientNomField(
              widget.candidatesIngredients, edited.nom, _onAutoComplete,
              (text) {
            setState(() {
              edited = edited.copyWith(nom: text);
            });
          }),

          // categorie editor
          CategorieIngredientEditor(
              edited.categorie,
              (c) => setState(() {
                    edited = edited.copyWith(categorie: c);
                  })),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: widget.onAbort != null
                ? MainAxisAlignment.spaceBetween
                : MainAxisAlignment.center,
            children: [
              if (widget.onAbort != null)
                ElevatedButton(
                  onPressed: widget.onAbort,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Ignorer"),
                ),
              ElevatedButton(
                  onPressed: isEntryValid ? _addNewIngredient : null,
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.green),
                  child: const Text("Ajouter")),
            ],
          )
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

class CategorieIngredientEditor extends StatelessWidget {
  final CategorieIngredient value;
  final void Function(CategorieIngredient) onChange;

  const CategorieIngredientEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<CategorieIngredient>(
        decoration: const InputDecoration(labelText: "Catégorie"),
        value: value,
        items: CategorieIngredient.values
            .map((e) => DropdownMenuItem<CategorieIngredient>(
                value: e, child: Text(formatCategorieIngredient(e))))
            .toList(),
        onChanged: (u) => u == null ? {} : onChange(u));
  }
}

class _IngredientNomField extends StatefulWidget {
  final List<Ingredient> candidatesIngredients;
  final String initialValue;

  final void Function(Ingredient) onSelected;
  final void Function(String) onDone;

  const _IngredientNomField(this.candidatesIngredients, this.initialValue,
      this.onSelected, this.onDone,
      {super.key});

  @override
  State<_IngredientNomField> createState() => _IngredientNomFieldState();
}

class _IngredientNomFieldState extends State<_IngredientNomField> {
  var controller = TextEditingController();

  @override
  void initState() {
    controller.text = widget.initialValue;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _IngredientNomField oldWidget) {
    controller.text = widget.initialValue;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => RawAutocomplete<Ingredient>(
        focusNode: FocusNode(),
        fieldViewBuilder:
            (context, textEditingController, focusNode, onFieldSubmitted) =>
                TextField(
          autofocus: true,
          decoration: const InputDecoration(
              labelText: "Nom", helperText: "Tapper pour rechercher..."),
          controller: textEditingController,
          focusNode: focusNode,
          onSubmitted: (text) {
            widget.onDone(text);
            onFieldSubmitted();
          },
          inputFormatters: [
            TextInputFormatter.withFunction((oldValue, newValue) =>
                newValue.copyWith(text: capitalize(newValue.text)))
          ],
        ),
        optionsViewBuilder: (context, onSelected, options) => Align(
          alignment: Alignment.topLeft,
          child: Material(
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(4.0)),
            ),
            child: SizedBox(
              height: 52.0 * options.length,
              width: constraints.biggest.width, // <-- Right here !
              child: ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: options.length,
                shrinkWrap: false,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return InkWell(
                    onTap: () => onSelected(option),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(option.nom),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
        optionsBuilder: (textEditingValue) => textEditingValue.text.length >= 2
            ? searchIngredients([
                ...widget.candidatesIngredients,
                ...ingredientsSuggestions,
              ], textEditingValue.text)
            : [],
        displayStringForOption: (option) => option.nom,
        textEditingController: controller,
        onSelected: widget.onSelected,
      ),
    );
  }
}
