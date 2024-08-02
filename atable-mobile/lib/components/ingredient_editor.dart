import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_users.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const IdUser idUser = 1;

class IngredientSelector extends StatefulWidget {
  final List<Ingredient> candidatesIngredients;
  final void Function(Ingredient ing) onDone;
  final Ingredient? initialValue;

  final String title;

  const IngredientSelector(this.candidatesIngredients, this.onDone,
      {super.key, this.initialValue, this.title = "Ajouter un ingrédient"});

  @override
  State<IngredientSelector> createState() => _IngredientSelectorState();
}

class _IngredientSelectorState extends State<IngredientSelector> {
  int id = -1;
  var name = TextEditingController();
  IngredientKind kind = IngredientKind.legumes;

  @override
  void initState() {
    _setup();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant IngredientSelector oldWidget) {
    _setup();
    super.didUpdateWidget(oldWidget);
  }

  void _setup() {
    final ing = widget.initialValue;
    if (ing != null) {
      id = ing.id;
      name.text = ing.name;
      kind = ing.kind;
    }
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

          LayoutBuilder(
            builder: (context, constraints) => RawAutocomplete<Ingredient>(
              focusNode: FocusNode(),
              fieldViewBuilder: (context, textEditingController, focusNode,
                      onFieldSubmitted) =>
                  TextField(
                autofocus: true,
                decoration: const InputDecoration(
                    labelText: "Nom", helperText: "Tapper pour rechercher..."),
                controller: textEditingController,
                focusNode: focusNode,
                onSubmitted: (text) {
                  onFieldSubmitted();
                  setState(() {});
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
                    borderRadius:
                        BorderRadius.vertical(bottom: Radius.circular(4.0)),
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
                            child: Text(option.name),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              optionsBuilder: (textEditingValue) =>
                  textEditingValue.text.length >= 2
                      ? _searchIngredients(
                          widget.candidatesIngredients, textEditingValue.text)
                      : [],
              displayStringForOption: (option) => option.name,
              textEditingController: name,
              onSelected: _onAutoComplete,
            ),
          ),

          // categorie editor
          IngredientKindEditor(
            kind,
            (c) => setState(() => kind = c),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
              onPressed: isEntryValid ? _addNewIngredient : null,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: const Text("Ajouter")),
        ],
      ),
    );
  }

  bool get isEntryValid => name.text.isNotEmpty;

  void _onAutoComplete(Ingredient ing) {
    if (ing.id >= 0) {
      // utilise l'ingrédient existant au lieu d'en créer un nouveau
      widget.onDone(ing);
    } else {
      // utilise juste la complétion
      setState(() {
        name.text = ing.name;
        kind = ing.kind;
      });
    }
  }

  // crée un nouvel ingrédient
  void _addNewIngredient() {
    widget.onDone(Ingredient(-1, name.text, kind, idUser));
  }
}

/// [_searchIngredients] filter the list by [name]
List<Ingredient> _searchIngredients(List<Ingredient> candidates, String name) {
  name = normalizeName(name);
  candidates = candidates
      .where((ing) => normalizeName(ing.name).contains(name))
      .toList();
  // remove duplicate
  final seen = <String>{};
  final List<Ingredient> out = [];
  for (var ing in candidates) {
    final name = normalizeName(ing.name);
    if (seen.contains(name)) continue;
    seen.add(name);
    out.add(ing);
  }
  return out;
}

class IngredientKindEditor extends StatelessWidget {
  final IngredientKind value;
  final void Function(IngredientKind) onChange;

  const IngredientKindEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<IngredientKind>(
        decoration: const InputDecoration(labelText: "Catégorie"),
        value: value,
        items: IngredientKind.values
            .map((e) => DropdownMenuItem<IngredientKind>(
                value: e, child: Text(formatIngredientKind(e))))
            .toList(),
        onChanged: (u) => u == null ? {} : onChange(u));
  }
}
