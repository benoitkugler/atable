import 'package:atable/logic/models.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';

extension CategoriePlatColor on CategoriePlat {
  Color get color {
    switch (this) {
      case CategoriePlat.entree:
        return Colors.green.shade200;
      case CategoriePlat.platPrincipal:
        return Colors.deepOrange.shade200;
      case CategoriePlat.dessert:
        return Colors.pink.shade200;
      case CategoriePlat.divers:
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

/// [NombrePersonneEditor] montre un 'slider' permettant
/// d'éditer un entier entre 1 et 40
class NombrePersonneEditor extends StatefulWidget {
  final int initialValue;
  final void Function(int) onDone;

  const NombrePersonneEditor(this.initialValue, this.onDone, {super.key});

  @override
  State<NombrePersonneEditor> createState() => _NombrePersonneEditorState();
}

class _NombrePersonneEditorState extends State<NombrePersonneEditor> {
  late int nbPersonnes;

  @override
  void initState() {
    nbPersonnes = widget.initialValue;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0, right: 12, left: 12),
            child: Row(
              children: [
                Text(
                  "Liste des ingrédients pour $nbPersonnes personnes",
                  style: const TextStyle(fontSize: 16),
                )
              ],
            ),
          ),
          Slider(
            label: "$nbPersonnes",
            value: nbPersonnes.toDouble(),
            min: 1,
            max: 40,
            divisions: 40 - 1,
            onChangeEnd: (v) => widget.onDone(v.toInt()),
            onChanged: (v) => setState(() {
              nbPersonnes = v.toInt();
            }),
          )
        ],
      ),
    );
  }
}

/// [IngredientRow] montre un ingrédient et sa quantité
class IngredientRow<T extends IngQuantI> extends StatefulWidget {
  final T ingredient;

  final void Function(double quantite) onEditQuantite;
  final void Function(Unite unite) onEditUnite;
  final void Function() onTap;

  const IngredientRow(
      this.ingredient, this.onEditQuantite, this.onEditUnite, this.onTap,
      {super.key});

  @override
  State<IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState<T extends IngQuantI> extends State<IngredientRow<T>> {
  bool isEditingQuantity = false;

  @override
  Widget build(BuildContext context) {
    final ing = widget.ingredient.iq();
    return Draggable<T>(
        affinity: Axis.vertical,
        data: widget.ingredient,
        feedback: Card(
            child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(ing.ingredient.nom),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                    "${formatQuantite(ing.quantite)} ${formatUnite(ing.unite)}"),
              )
            ],
          ),
        )),
        child: ListTile(
            onTap: widget.onTap,
            visualDensity: const VisualDensity(vertical: -3),
            dense: true,
            title: Text(ing.ingredient.nom),
            subtitle: Text(formatCategorieIngredient(ing.ingredient.categorie)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isEditingQuantity
                    ? SizedBox(
                        width: 60,
                        child: TextField(
                          decoration: const InputDecoration(isDense: true),
                          autofocus: true,
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          onSubmitted: (value) {
                            widget.onEditQuantite(double.parse(value));
                            setState(() => isEditingQuantity = false);
                          },
                        ),
                      )
                    : TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: const VisualDensity(horizontal: -3)),
                        onPressed: () =>
                            setState(() => isEditingQuantity = true),
                        child: Text(formatQuantite(ing.quantite)),
                      ),
                _UniteEditor(
                    ing.unite,
                    (u) => setState(() {
                          widget.onEditUnite(u);
                        }))
              ],
            )));
  }
}

class _UniteEditor extends StatelessWidget {
  final Unite value;
  final void Function(Unite) onChange;

  const _UniteEditor(this.value, this.onChange, {super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Unite>(
      initialValue: value,
      itemBuilder: (context) => Unite.values
          .map((e) => PopupMenuItem<Unite>(
                value: e,
                child: Text(formatUnite(e)),
              ))
          .toList(),
      onSelected: onChange,
      child: Text(
        formatUnite(value).padRight(2),
        style: TextStyle(
            fontWeight: FontWeight.w500, color: Theme.of(context).primaryColor),
      ),
    );
  }
}
