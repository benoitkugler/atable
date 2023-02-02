import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';

class ImportDialog extends StatefulWidget {
  final List<Ingredient> candidates;
  final String clipboard;

  // idMenu est ignoré
  final void Function(List<MenuIngredientExt>) onDone;

  const ImportDialog(this.candidates, this.clipboard, this.onDone, {super.key});

  @override
  State<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<ImportDialog> {
  late final List<MenuImport> ingredients;

  late final List<Ingredient> matches;

  PageController controller = PageController();

  @override
  void initState() {
    ingredients = parseIngredients(widget.clipboard);
    // commence avec la recherche automatique
    matches = bestMatch(widget.candidates, ingredients);
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            "Importer un ingrédient",
            style: TextStyle(fontSize: 18),
          ),
        ),
        const SizedBox(height: 40),
        SizedBox(
          height: 260,
          child: PageView(
            controller: controller,
            children: List<_IngredientMapper>.generate(
              ingredients.length,
              (index) => _IngredientMapper(ingredients[index], matches[index],
                  widget.candidates, (ing) => _onValidMatch(index, ing)),
            ),
          ),
        ),
      ],
    );
  }

  List<MenuIngredientExt> items() {
    return List<MenuIngredientExt>.generate(
        ingredients.length,
        (index) => MenuIngredientExt(
            matches[index],
            MenuIngredient(
                idMenu: -1,
                idIngredient: -1,
                quantite: ingredients[index].quantite,
                unite: ingredients[index].unite,
                categorie: CategoriePlat.platPrincipal)));
  }

  _onValidMatch(int index, Ingredient match) {
    matches[index] = match;
    if (index == ingredients.length - 1) {
      // on a terminé
      final existant = matches.where((element) => element.id >= 0);
      if (existant.length != existant.toSet().length) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Les ingrédients doivent être distincts")));
        return;
      }
      widget.onDone(items());
    } else {
      setState(() {
        controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }
}

class _IngredientMapper extends StatelessWidget {
  final MenuImport ingredient;
  final Ingredient initialMatch;

  final List<Ingredient> allIngredients;

  final void Function(Ingredient) onDone;

  const _IngredientMapper(
      this.ingredient, this.initialMatch, this.allIngredients, this.onDone,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
                color: Colors.yellow.shade100,
                borderRadius: const BorderRadius.all(Radius.circular(6))),
            child: Row(
              children: [
                Text(ingredient.nom),
                const Spacer(),
                Text(
                    "${formatQuantite(ingredient.quantite)} ${formatUnite(ingredient.unite)}")
              ],
            ),
          ),
          const Icon(Icons.arrow_downward),
          Container(
            decoration: BoxDecoration(
                color: Colors.lightGreen.shade100,
                borderRadius: const BorderRadius.all(Radius.circular(6))),
            child: IngredientEditor(
              allIngredients,
              (ing, isNew) => onDone(ing),
              initialValue: initialMatch,
            ),
          )
        ],
      ),
    );
  }
}
