import 'dart:math';

import 'package:atable/components/details_recette.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';

class RecettesList extends StatefulWidget {
  final DBApi db;

  const RecettesList(this.db, {super.key});

  @override
  State<RecettesList> createState() => _RecettesListState();
}

class _RecettesListState extends State<RecettesList> {
  List<RecetteExt> recettes = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    _loadRecettes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recettes"),
      ),
      body: recettes.isEmpty
          ? const Center(
              child: Text("Aucun recette."),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: recettes.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(2.0),
                child: DismissibleDelete(
                  itemKey: recettes[index].recette.id,
                  confirmDismiss: () => _checkDeleteRecette(recettes[index]),
                  onDissmissed: () => _deleteRecette(recettes[index]),
                  child: _RecetteCard(
                    recettes[index],
                    () => _showRecetteDetails(index),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRecette,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _loadRecettes() async {
    final l = await widget.db.getRecettes();
    if (mounted) setState(() => recettes = l);
  }

  void _addRecette() async {
    final serial = recettes.isEmpty
        ? 1
        : recettes.map((e) => e.recette.id).reduce(max) + 1;
    final nbPersonnes =
        recettes.isEmpty ? 8 : recettes.last.recette.nbPersonnes;

    final newRecette = await widget.db.createRecette(Recette(
        id: 0,
        nbPersonnes: nbPersonnes,
        label: "Recette $serial",
        categorie: CategoriePlat.platPrincipal));
    setState(() {
      recettes.add(RecetteExt(newRecette, [])); // préserve l'ordre
    });
    Future.delayed(
        const Duration(milliseconds: 100),
        () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 100,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 500),
            ));
  }

  // verifie si le recette est utilisé dans un repas
  Future<bool> _checkDeleteRecette(RecetteExt recette) async {
    // TODO:
    // final repas = await widget.db.getRepasFromRecette(recette.recette);
    // if (!mounted) return false;

    // if (repas.isNotEmpty) {
    //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    //     content: const Text(
    //       'Ce recette est utilisé dans un repas.',
    //     ),
    //     backgroundColor: Colors.orange,
    //     action: SnackBarAction(
    //         label: "Voir les repas",
    //         textColor: Colors.white,
    //         onPressed: () =>
    //             GoToRepasNotification(repas.first).dispatch(context)),
    //   ));
    //   return false;
    // }
    return true;
  }

  void _deleteRecette(RecetteExt recette) async {
    setState(() {
      recettes
          .removeWhere((element) => element.recette.id == recette.recette.id);
    });
    await widget.db.deleteRecette(recette.recette.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Recette supprimée.'),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.green,
    ));
  }

  void _showRecetteDetails(int recetteIndex) async {
    var recette = recettes[recetteIndex];
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsRecette(widget.db, recette),
    ));
    // met à jour les données
    recette = await widget.db.getRecette(recette.recette.id);
    setState(() {
      recettes[recetteIndex] = recette;
    });
  }
}

class _RecetteCard extends StatelessWidget {
  final RecetteExt recette;

  final void Function() onTap;

  const _RecetteCard(this.recette, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selectedColor: Colors.yellow.shade100,
      title: Text(recette.recette.label),
      subtitle: Text(formatCategoriePlat(recette.recette.categorie)),
      onTap: onTap,
    );
  }
}
