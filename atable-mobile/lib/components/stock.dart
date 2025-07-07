import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/shared.dart';
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
  Stock stock = const Stock([]);

  @override
  void initState() {
    _loadStock();
    super.initState();
  }

  _loadStock() async {
    final s = await widget.db.getStock();
    s.l.sort((a, b) => a.ingredient.kind.index - b.ingredient.kind.index);
    setState(() {
      stock = s;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock"),
      ),
      body: ListView(
          children: stock.l
              .map((ing) => DismissibleDelete(
                  itemKey: ing.ingredient.id,
                  onDissmissed: () => _deleteEntry(ing.ingredient),
                  child: _IngredientRow(ing, () => _startEditEntry(ing))))
              .toList()),
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

    final existingL =
        stock.l.where((ing) => ing.ingredient.id == ingredient.id);
    final IngredientQuantiteAbs existing;
    if (existingL.isNotEmpty) {
      existing = existingL.first;
    } else {
      final quantites = [const QuantityAbs(Unite.kg, 1)];
      await widget.db.insertStock(StockEntry(ingredient.id, quantites));
      existing = IngredientQuantiteAbs(ingredient, quantites);
    }
    _loadStock();
    _startEditEntry(existing);
  }

  _deleteEntry(Ingredient ing) async {
    await widget.db.deleteStock(ing.id);
    setState(() {
      stock.l.removeWhere((e) => e.ingredient.id == ing.id);
    });
  }

  _startEditEntry(IngredientQuantiteAbs ingredient) async {
    final newL = await showDialog<List<QuantityAbs>>(
        context: context,
        builder: (context) => _QuantityDialog(ingredient.quantites));
    if (newL == null) return;

    final id = ingredient.ingredient.id;
    await widget.db.updateStock(StockEntry(id, newL));
    setState(() {
      final index = stock.l.indexWhere((e) => e.ingredient.id == id);
      stock.l[index] = IngredientQuantiteAbs(ingredient.ingredient, newL);
    });
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientQuantiteAbs ingredient;
  final void Function() startEdit;
  const _IngredientRow(this.ingredient, this.startEdit, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(ingredient.ingredient.name),
        subtitle: Text(ingredientKindLabel(ingredient.ingredient.kind)),
        trailing: OutlinedButton(
          onPressed: startEdit,
          child: Text(ingredient.quantites.join(" et ")),
        ));
  }
}

class _QuantityDialog extends StatefulWidget {
  final List<QuantityAbs> initial;

  const _QuantityDialog(this.initial, {super.key});

  @override
  State<_QuantityDialog> createState() => __QuantityDialogState();
}

class __QuantityDialogState extends State<_QuantityDialog> {
  List<QuantityAbs> quantites = [];

  @override
  void initState() {
    quantites = widget.initial.toList();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifier les quantités"),
      content: ListView(
          children: List.generate(
        quantites.length,
        (index) => QuantityAbsEditor(
            quantites[index],
            (q) => setState(() {
                  quantites[index] = q;
                })),
      ).toList()),
      actions: [
        TextButton(
            onPressed: () => setState(
                () => quantites.add(const QuantityAbs(Unite.piece, 0))),
            child: const Text("Ajouter une unité")),
        TextButton(
            onPressed: () => Navigator.of(context).pop(quantites),
            child: const Text("Enregistrer"))
      ],
    );
  }
}
