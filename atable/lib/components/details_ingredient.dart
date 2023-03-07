import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DetailsIngredient extends StatefulWidget {
  final DBApi db;
  final Ingredient initialValue;

  const DetailsIngredient(this.db, this.initialValue, {super.key});

  @override
  State<DetailsIngredient> createState() => _DetailsIngredientState();
}

class _DetailsIngredientState extends State<DetailsIngredient> {
  late Ingredient ingredient;

  UtilisationsIngredient? utilisations;

  @override
  void initState() {
    ingredient = widget.initialValue;
    _loadUtilisations();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final u = utilisations;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails de l'ingrédient"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(children: [
          TextFormField(
            decoration: const InputDecoration(labelText: "Nom"),
            initialValue: ingredient.nom,
            onFieldSubmitted: _updateNom,
            inputFormatters: [
              TextInputFormatter.withFunction((oldValue, newValue) =>
                  newValue.copyWith(text: capitalize(newValue.text)))
            ],
          ),
          CategorieIngredientEditor(ingredient.categorie, _updateCategorie),
          AnimatedCrossFade(
              duration: const Duration(milliseconds: 400),
              crossFadeState: u != null
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(),
              secondChild: Card(
                margin: const EdgeInsets.symmetric(vertical: 20),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                      "Utilisé dans ${u?.recettes} recette(s) et ${u?.menus} menu(s)."),
                ),
              )),
        ]),
      ),
    );
  }

  _loadUtilisations() async {
    final u = await widget.db.getIngredientUses(ingredient.id);
    setState(() {
      utilisations = u;
    });
  }

  _update(Ingredient ing) async {
    setState(() {
      ingredient = ing;
    });

    await widget.db.updateIngredient(ing);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Ingrédient mis à jour."),
      backgroundColor: Colors.green,
    ));
  }

  _updateCategorie(CategorieIngredient cat) {
    final ing = ingredient.copyWith(categorie: cat);
    _update(ing);
  }

  _updateNom(String nom) {
    final ing = ingredient.copyWith(nom: nom);
    _update(ing);
  }
}
