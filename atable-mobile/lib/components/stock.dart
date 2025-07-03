import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/logic/env.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:flutter/material.dart';

class StockW extends StatefulWidget {
  final Env env;
  final DBApi db;

  const StockW(this.env, this.db, {super.key});

  @override
  State<StockW> createState() => _StockWState();
}

class _StockWState extends State<StockW> {
  Stock stock = [];

  @override
  void initState() {
    _loadStock();
    super.initState();
  }

  _loadStock() async {
    final l = await widget.db.getStock();
    l.sort((a, b) => a.ingredient.kind.index - b.ingredient.kind.index);
    setState(() {
      stock = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock"),
      ),
      body:
          ListView(children: stock.map((ing) => _IngredientRow(ing)).toList()),
      floatingActionButton: FloatingActionButton(
          onPressed: _addEntry, child: const Icon(Icons.add)),
    );
  }

  _addEntry() async {
    final allIngredients = (await widget.db.getIngredients()).toList();
    if (!mounted) return;
    final selected = await showDialog<Ingredient>(
        context: context,
        builder: (context) => Dialog(
              child: IngredientSelector(
                allIngredients,
                (ing) {
                  Navigator.of(context).pop(ing);
                },
              ),
            ));
    if (selected == null) return;
    final ingredient = selected.id >= 0
        ? selected
        : await widget.db.insertIngredient(selected);

    final alreadyHas =
        stock.where((ing) => ing.ingredient.id == ingredient.id).isNotEmpty;
    if (!alreadyHas) {
      await widget.db.insertStock(
          StockEntry(ingredient.id, [const StockQuantite(Unite.kg, 1)]));
    }
    _loadStock();
    _startEditEntry(ingredient.id);
  }

  _startEditEntry(IdIngredient id) {}
}

class _IngredientRow extends StatelessWidget {
  final StockIngredient ingredient;
  const _IngredientRow(this.ingredient, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(ingredient.ingredient.name),
      subtitle: Text(ingredientKindLabel(ingredient.ingredient.kind)),
    );
  }
}
