import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/env.dart';
import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';
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
    final IngredientQuantitiesN existing;
    if (existingL.isNotEmpty) {
      existing = existingL.first;
    } else {
      await widget.db
          .insertStock(StockEntry(ingredient.id, const QuantitiesNorm()));
      existing = IngredientQuantitiesN(ingredient, const QuantitiesNorm());
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

  _startEditEntry(IngredientQuantitiesN ingredient) async {
    final newL = await showDialog<QuantitiesNorm>(
        context: context,
        builder: (context) => _QuantityDialog(ingredient.quantites));
    if (newL == null) return;

    final id = ingredient.ingredient.id;
    await widget.db.updateStock(StockEntry(id, newL));
    setState(() {
      final index = stock.l.indexWhere((e) => e.ingredient.id == id);
      stock.l[index] = IngredientQuantitiesN(ingredient.ingredient, newL);
    });
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientQuantitiesN ingredient;
  final void Function() startEdit;
  const _IngredientRow(this.ingredient, this.startEdit, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
        title: Text(ingredient.ingredient.name),
        subtitle: Text(ingredientKindLabel(ingredient.ingredient.kind)),
        trailing: OutlinedButton(
          onPressed: startEdit,
          child: Text(ingredient.quantites.toString()),
        ));
  }
}

class _QuantityDialog extends StatefulWidget {
  final QuantitiesNorm initial;

  const _QuantityDialog(this.initial, {super.key});

  @override
  State<_QuantityDialog> createState() => __QuantityDialogState();
}

class __QuantityDialogState extends State<_QuantityDialog> {
  QuantitiesNorm quantites = const QuantitiesNorm();

  @override
  void initState() {
    quantites = widget.initial;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifier les quantités"),
      content: Column(children: [
        QuantiteField(
          quantites.pieces,
          (val) => setState(() => quantites = quantites.copyWith(pieces: val)),
          label: formatUnite(Unite.piece),
        ),
        QuantiteField(
          quantites.l,
          (val) => setState(() => quantites = quantites.copyWith(l: val)),
          label: formatUnite(Unite.l),
        ),
        QuantiteField(
          quantites.kg,
          (val) => setState(() => quantites = quantites.copyWith(kg: val)),
          label: formatUnite(Unite.kg),
        ),
      ]),
      actions: [
        TextButton(
            onPressed: () => Navigator.of(context).pop(quantites),
            child: const Text("Enregistrer"))
      ],
    );
  }
}
