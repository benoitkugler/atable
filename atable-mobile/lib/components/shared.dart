import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';

extension CategoriePlatColor on PlatKind {
  Color get color {
    switch (this) {
      case PlatKind.entree:
        return Colors.green.shade200;
      case PlatKind.platPrincipal:
        return Colors.deepOrange.shade200;
      case PlatKind.dessert:
        return Colors.pink.shade200;
      case PlatKind.empty:
        return Colors.grey.shade300;
    }
  }
}

class DismissibleDelete extends StatelessWidget {
  final int itemKey;
  final void Function() onDissmissed;
  final Widget child;

  final Future<bool> Function()? confirmDismiss;

  const DismissibleDelete(
      {required this.itemKey,
      required this.onDissmissed,
      required this.child,
      this.confirmDismiss,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key("$itemKey"),
        confirmDismiss: confirmDismiss != null
            ? (direction) async => await confirmDismiss!()
            : null,
        onDismissed: (direction) => onDissmissed(),
        background: Container(
          alignment: AlignmentDirectional.centerStart,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(5)),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        secondaryBackground: Container(
          alignment: AlignmentDirectional.centerEnd,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(5)),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        child: child);
  }
}

/// [IngredientRow] displays an ingredient and a quantity
class IngredientRow<T extends QuantifiedIngI> extends StatefulWidget {
  final T ingredient;

  final void Function(QuantityR qu) onEditQuantity;
  final void Function() onTap;
  final bool showFor;
  final bool allowDrag;

  const IngredientRow(
      this.ingredient, this.onEditQuantity, this.onTap, this.showFor,
      {super.key, this.allowDrag = false});

  @override
  State<IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState<T extends QuantifiedIngI>
    extends State<IngredientRow<T>> {
  bool isEditingQuantity = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient.iq();
    final showFor = widget.showFor ? " (pour ${ing.quantity.for_} per.)" : '';
    final child = ListTile(
        onTap: widget.onTap,
        visualDensity: const VisualDensity(vertical: -3),
        dense: true,
        title: Text(ing.ingredient.name),
        subtitle: Text(formatIngredientKind(ing.ingredient.kind)),
        trailing: OutlinedButton(
          onPressed: _showEditor,
          child: RichText(
              text: TextSpan(
                  style: Theme.of(context).textTheme.labelMedium,
                  children: [
                TextSpan(
                    text: "${formatQuantite(ing.quantity.val)} ",
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: formatUnite(ing.quantity.unite)),
                TextSpan(text: showFor, style: const TextStyle(fontSize: 10)),
              ])),
        ));
    return widget.allowDrag
        ? Draggable<T>(
            affinity: Axis.vertical,
            data: widget.ingredient,
            feedback: Card(
                child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(ing.ingredient.name),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        "${formatQuantite(ing.quantity.val)} ${formatUnite(ing.quantity.unite)}"),
                  )
                ],
              ),
            )),
            child: child)
        : child;
  }

  void _showEditor() async {
    final newQuantity = await showDialog<QuantityR>(
      context: context,
      builder: (context) => _QuantityEditor(widget.ingredient.iq().quantity),
    );
    if (newQuantity == null) return;
    widget.onEditQuantity(newQuantity);
  }
}

extension on QuantityR {
  QuantityR copyWith({double? val, Unite? unite, int? for_}) =>
      QuantityR(val ?? this.val, unite ?? this.unite, for_ ?? this.for_);
}

class QuantiteField extends StatelessWidget {
  final double val;
  final void Function(double) onChange;
  final String label;

  const QuantiteField(this.val, this.onChange,
      {this.label = "Quantité", super.key});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: formatQuantite(val),
      decoration: InputDecoration(labelText: label),
      autofocus: true,
      textAlign: TextAlign.center,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        final val = double.tryParse(value);
        if (val == null) return;
        onChange(val);
      },
    );
  }
}

class _QuantityEditor extends StatefulWidget {
  final QuantityR quantity;

  const _QuantityEditor(this.quantity, {super.key});

  @override
  State<_QuantityEditor> createState() => __QuantityEditorState();
}

class __QuantityEditorState extends State<_QuantityEditor> {
  late QuantityR quantity;

  @override
  void initState() {
    quantity = widget.quantity;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _QuantityEditor oldWidget) {
    quantity = widget.quantity;
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Modifier la quantité"),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(quantity),
          style: TextButton.styleFrom(foregroundColor: Colors.green),
          child: const Text("Enregistrer"),
        )
      ],
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 80,
                child: QuantiteField(
                    quantity.val,
                    (val) =>
                        setState(() => quantity = quantity.copyWith(val: val))),
              ),
              SizedBox(
                width: 80,
                child: DropdownButtonFormField<Unite>(
                  decoration: const InputDecoration(labelText: "Unité"),
                  value: quantity.unite,
                  onChanged: (u) =>
                      setState(() => quantity = quantity.copyWith(unite: u)),
                  items: Unite.values
                      .map((e) => DropdownMenuItem(
                          value: e, child: Text(formatUnite(e))))
                      .toList(),
                ),
              )
            ],
          ),
          const SizedBox(height: 20),
          TextFormField(
            initialValue: quantity.for_.toString(),
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            onChanged: (value) {
              final for_ = int.tryParse(value);
              if (for_ == null) return;
              setState(() => quantity = quantity.copyWith(for_: for_));
            },
            decoration: const InputDecoration(
                isDense: true,
                labelText: "Pour",
                helperText:
                    "La quantité est exprimé pour ce nombre de personnes.",
                helperMaxLines: 2),
          )
        ],
      ),
    );
  }
}

class PopupTextButton<T> extends StatelessWidget {
  final T value;
  final List<T> choices;
  final String Function(T value) formatter;

  final void Function(T) onChange;

  const PopupTextButton(this.value, this.choices, this.formatter, this.onChange,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<T>(
      initialValue: value,
      itemBuilder: (context) => choices
          .map((e) => PopupMenuItem<T>(
                value: e,
                child: Text(formatter(e)),
              ))
          .toList(),
      onSelected: onChange,
      child: Container(
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(4))),
        padding: const EdgeInsets.all(8),
        child: Text(
          formatter(value),
          style: TextStyle(
              fontWeight: FontWeight.w500,
              color: Theme.of(context).primaryColor),
        ),
      ),
    );
  }
}
