import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:flutter/material.dart';

class ImportDialog extends StatelessWidget {
  final String clipboard;

  const ImportDialog(this.clipboard, {super.key});

  @override
  Widget build(BuildContext context) {
    final ingredients = parseIngredients(clipboard);
    return Card(
      child: ListView(
        children: ingredients
            .map((e) => ListTile(
                  title: Text(e.nom),
                  trailing: Text("${e.quantite} ${formatUnite(e.unite)}"),
                ))
            .toList(),
      ),
    );
  }
}
