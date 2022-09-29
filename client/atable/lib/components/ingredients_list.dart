import 'dart:math';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';

class IngredientList extends StatefulWidget {
  final DBApi db;

  const IngredientList(this.db, {Key? key}) : super(key: key);

  @override
  State<IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<IngredientList> {
  List<Ingredient> ingredients = [];

  fetchIngredients() async {
    final l = await widget.db.getIngredients();
    setState(() {
      ingredients = l;
    });
  }

  addIngredient() async {
    var ing = Ingredient(
      id: 0,
      nom: "Nouvel Ingredient ${Random().nextInt(1000)}",
      unite: Unite.values[Random().nextInt(Unite.values.length)],
      categorie: CategorieIngredient
          .values[Random().nextInt(CategorieIngredient.values.length)],
    );
    ing = await widget.db.insertIngredient(ing);
    setState(() {
      ingredients.add(ing);
    });
  }

  deleteIngredient(Ingredient ing) async {
    await widget.db.deleteIngredient(ing.id);
    await fetchIngredients();
  }

  @override
  void initState() {
    fetchIngredients();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: addIngredient, child: const Text("Ajouter")),
        Expanded(
          child: ListView(
              children: ingredients
                  .map((ing) => ListTile(
                        leading: Text(
                            ing.categorie == CategorieIngredient.inconnue
                                ? ""
                                : ing.categorie.name),
                        title: Text(ing.nom),
                        subtitle: Text(ing.unite.name),
                        trailing: IconButton(
                            onPressed: () => deleteIngredient(ing),
                            icon: const Icon(
                                IconData(0xe1b9, fontFamily: 'MaterialIcons'),
                                color: Colors.red)),
                      ))
                  .toList()),
        ),
      ],
    );
  }
}
