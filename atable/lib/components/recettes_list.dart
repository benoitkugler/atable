import 'dart:math';

import 'package:atable/components/details_recette.dart';
import 'package:atable/components/import_dialog.dart';
import 'package:atable/components/menus_list.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

class ExportDBNotification extends MainNotification {}

class ImportDBNotification extends MainNotification {}

enum _PopupAction { importRecettesFile, importRecettesMemory, saveDB, loadDB }

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
  void didUpdateWidget(covariant RecettesList oldWidget) {
    _loadRecettes();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Recettes"),
        actions: [
          PopupMenuButton<_PopupAction>(
            onSelected: _onPopupAction,
            itemBuilder: (context) => const <PopupMenuEntry<_PopupAction>>[
              PopupMenuItem(
                  value: _PopupAction.importRecettesFile,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.format_list_bulleted_add),
                    title: Text("Ajouter des recettes"),
                    subtitle: Text("depuis un fichier .CSV"),
                  )),
              PopupMenuItem(
                  value: _PopupAction.importRecettesMemory,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.format_list_bulleted_add),
                    title: Text("Ajouter des recettes"),
                    subtitle: Text("depuis le presse-papier (format .CSV)"),
                  )),
              PopupMenuDivider(),
              PopupMenuItem(
                  value: _PopupAction.saveDB,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.download),
                    title: Text("Enregistrer les données"),
                    subtitle: Text("sur le disque"),
                  )),
              PopupMenuItem(
                  value: _PopupAction.loadDB,
                  child: ListTile(
                    dense: true,
                    leading: Icon(Icons.upload),
                    title: Text("Charger les données"),
                    subtitle: Text("depuis le disque"),
                  ))
            ],
            icon: const Icon(Icons.import_export),
          )
        ],
      ),
      body: recettes.isEmpty
          ? const Center(
              child: Text("Aucune recette."),
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

  void _onPopupAction(_PopupAction action) async {
    switch (action) {
      case _PopupAction.importRecettesMemory:
        return _showImport(null);
      case _PopupAction.importRecettesFile:
        final file = await _pickCSVFile();
        if (file != null) _showImport(file);
        return;
      case _PopupAction.saveDB:
        return ExportDBNotification().dispatch(context);
      case _PopupAction.loadDB:
        return ImportDBNotification().dispatch(context);
    }
  }

  Future<String?> _pickCSVFile() async {
    final dir = await downloadDir();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: dir.path,
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    final path = result?.files.single.path;
    if (path == null) {
      // User canceled the picker
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Import annulé."),
          backgroundColor: Colors.orange,
        ));
      }
      return null;
    }

    return path;
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
      categorie: CategoriePlat.platPrincipal,
      description: "",
    ));
    setState(() {
      recettes.add(RecetteExt(newRecette, [])); // préserve l'ordre
    });
    await Future.delayed(
        const Duration(milliseconds: 100),
        () => _scrollController.jumpTo(
              _scrollController.position.maxScrollExtent + 100,
            ));
    // commence à éditer la recette
    _showRecetteDetails(recettes.length - 1, openDetails: true);
  }

  // verifie si le recette est utilisé dans un repas
  Future<bool> _checkDeleteRecette(RecetteExt recette) async {
    final menus = await widget.db.getMenusFromRecette(recette.recette);
    if (!mounted) return false;

    if (menus.isNotEmpty) {
      final target = menus.first;
      final notif = target.repas == null
          ? GoToMenuNotification(target.menu)
          : GoToRepasNotification(target.repas!);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'Cette recette est utilisé dans un menu.',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
            label: "Voir les menus",
            textColor: Colors.white,
            onPressed: () => notif.dispatch(context)),
      ));
      return false;
    }
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

  void _showRecetteDetails(int recetteIndex, {bool openDetails = false}) async {
    var recette = recettes[recetteIndex];
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsRecette(widget.db, recette, openDetails),
    ));
    // met à jour les données
    recette = await widget.db.getRecette(recette.recette.id);
    setState(() {
      recettes[recetteIndex] = recette;
    });
  }

// if file is null, use the clipboard
  void _showImport(String? file) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RecettesImporterW(widget.db, file),
    ));
    _loadRecettes();
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

/// RecetteSelector est une liste de recette
/// avec un champ de recherche
class RecetteSelector extends StatefulWidget {
  final DBApi db;
  final void Function(Recette) onSelect;

  const RecetteSelector(this.db, this.onSelect, {super.key});

  @override
  State<RecetteSelector> createState() => _RecetteSelectorState();
}

class _RecetteSelectorState extends State<RecetteSelector> {
  List<Recette> allRecettes = [];

  List<Recette> current = [];

  @override
  void initState() {
    _loadRecettes();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0, left: 8, right: 8),
            child: Row(
              children: [
                const Icon(Icons.search),
                const SizedBox(width: 10),
                Expanded(
                    child: TextFormField(
                  autofocus: true,
                  onChanged: _search,
                  decoration:
                      const InputDecoration(labelText: "Rechercher par nom"),
                )),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemBuilder: (context, index) => _RecetteRow(
                current[index], () => widget.onSelect(current[index])),
            itemCount: current.length,
          ),
        )
      ],
    );
  }

  void _loadRecettes() async {
    allRecettes = await widget.db.getRecettesMetas();
    setState(() {
      current = allRecettes;
    });
  }

  void _search(String text) async {
    setState(() {
      current = searchRecettes(allRecettes, text);
    });
  }
}

class _RecetteRow extends StatelessWidget {
  final Recette recette;
  final void Function() onTap;
  const _RecetteRow(this.recette, this.onTap, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(recette.label),
      subtitle: Text(formatCategoriePlat(recette.categorie)),
    );
  }
}
