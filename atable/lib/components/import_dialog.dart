import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/components/recettes_list.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

Future<List<IngQuant>?> showImportDialog(
    List<Ingredient> allIngredients, BuildContext context) async {
  final newIngredients = await showDialog<List<IngQuant>>(
      context: context,
      builder: (context) => Dialog(
            child: _ImportDialog(
                allIngredients, (l) => Navigator.of(context).pop(l)),
          ));
  return newIngredients;
}

class _ImportDialog extends StatefulWidget {
  final List<Ingredient> candidates;

  final void Function(List<IngQuant>) onDone;

  const _ImportDialog(this.candidates, this.onDone, {super.key});

  @override
  State<_ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends State<_ImportDialog> {
  List<RecetteImport> ingredients =
      []; // ingrédients à relier à la base de données
  List<Ingredient> matches = []; // un pour chaque élément de [ingredients]

  PageController controller = PageController();

  @override
  void initState() {
    ingredients = [];
    matches = [];
    _processClipboard();
    super.initState();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _processClipboard() async {
    final cp = await Clipboard.getData(Clipboard.kTextPlain);
    if (cp == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le presse-papier est vide !")));
      Navigator.of(context).pop();
      return;
    }

    final ings = parseIngredients(cp.text ?? "");
    // commence avec la recherche automatique
    final m = bestMatch(widget.candidates, ings);
    setState(() {
      matches = m;
      ingredients = ings;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentPage =
        (controller.hasClients ? controller.page ?? 0 : 0).toInt() + 1;
    return ingredients.isEmpty
        ? Row(
            children: const [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircularProgressIndicator(),
              ),
              Text("Import en cours...")
            ],
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Text(
                  "Importer des ingrédients ($currentPage/${ingredients.length})",
                  style: const TextStyle(fontSize: 18),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 360,
                child: PageView(
                  controller: controller,
                  onPageChanged: (p) => setState(() {}),
                  children: List<_IngredientMapper>.generate(
                    ingredients.length,
                    (index) => _IngredientMapper(
                        ingredients[index],
                        matches[index],
                        widget.candidates,
                        (ing) => _onValidMatch(index, ing),
                        () => _removeDetected(index)),
                  ),
                ),
              ),
            ],
          );
  }

  List<IngQuant> items() {
    return List<IngQuant>.generate(
        ingredients.length,
        (index) => IngQuant(
              matches[index],
              ingredients[index].quantite,
              ingredients[index].unite,
            ));
  }

  _onValidMatch(int index, Ingredient match) {
    matches[index] = match;
    if (index == ingredients.length - 1) {
      // on a terminé
      final existant = matches.where((element) => element.id >= 0);
      if (existant.length != existant.toSet().length) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Les ingrédients doivent être distincts")));
        return;
      }
      widget.onDone(items());
    } else {
      setState(() {
        controller.nextPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  _removeDetected(int index) {
    setState(() {
      ingredients.removeAt(index);
      matches.removeAt(index);
    });
    if (ingredients.isEmpty) {
      Navigator.of(context).pop();
    }
  }
}

class _IngredientMapper extends StatelessWidget {
  final RecetteImport detected;
  final Ingredient initialMatch;

  final List<Ingredient> allIngredients;

  final void Function(Ingredient) onDone;
  final void Function() onAbort;

  const _IngredientMapper(this.detected, this.initialMatch, this.allIngredients,
      this.onDone, this.onAbort,
      {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        children: [
          Card(
            color: Colors.yellow.shade100,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  const Text("Ingrédient détecté",
                      style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Text(detected.nom),
                      const Spacer(),
                      Text(
                          "${formatQuantite(detected.quantite)} ${formatUnite(detected.unite)}")
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Icon(Icons.arrow_downward),
          Card(
            color: Colors.lightGreen.shade100,
            child: IngredientSelector(
              allIngredients,
              onDone,
              initialValue: initialMatch,
              title: "Importer en",
              onAbort: onAbort,
            ),
          )
        ],
      ),
    );
  }
}

class RecettesImporterW extends StatefulWidget {
  final DBApi db;

  const RecettesImporterW(this.db, {super.key});

  @override
  State<RecettesImporterW> createState() => _RecettesImporterWState();
}

class _RecettesImporterWState extends State<RecettesImporterW> {
  List<Ingredient>? candidates;

  RecettesImporter? importer;

  @override
  void initState() {
    super.initState();
    _loadCandidates();
    _processClipboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assistant d'import")),
      body: importer == null || candidates == null
          ? const Center(child: Text("Chargement..."))
          : IngredientImportList(
              candidates!, importer!.ingredients(), _showRecettes),
    );
  }

  void _loadCandidates() async {
    final l = await widget.db.getIngredients();
    setState(() {
      candidates = l;
    });
  }

  void _setInput(String content) async {
    try {
      final importer = RecettesImporter.fromCSV(content);
      setState(() {
        this.importer = importer;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Fichier invalide: $e")));
      Navigator.of(context).pop();
      return;
    }
  }

  void _processClipboard() async {
    final cp = await Clipboard.getData(Clipboard.kTextPlain);
    if (cp == null) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Le presse-papier est vide !")));
      Navigator.of(context).pop();
      return;
    }

    _setInput(cp.text ?? "");
  }

  void _showRecettes(Map<String, Ingredient> map) async {
    final recettes = importer!.applyIngredients(map);
    final recettesWithCat = await Navigator.of(context).push(
        MaterialPageRoute<List<RecetteExt>>(
            builder: (context) =>
                _RecetteList(recettes, (rs) => Navigator.of(context).pop(rs))));
    if (recettesWithCat == null) return;

    _doImport(recettesWithCat);
  }

  void _doImport(List<RecetteExt> recettes) async {
    setState(() {
      candidates = null;
      importer = null;
    });
    await RecettesImporter.write(recettes, widget.db);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Recettes importées avec succès."),
        backgroundColor: Colors.green));
    Navigator.of(context).pop();
  }
}

class IngredientImportList extends StatefulWidget {
  /// [candidates] contient toute la table des ingrédients.
  final List<Ingredient> candidates;

  /// [ingredients] sont les noms des ingrédients à identifier.
  final List<String> ingredients;

  final void Function(Map<String, Ingredient> map) onContinue;

  const IngredientImportList(this.candidates, this.ingredients, this.onContinue,
      {super.key});

  @override
  State<IngredientImportList> createState() => _IngredientImportListState();
}

class _IngredientImportListState extends State<IngredientImportList> {
  final scrollController = ScrollController();

  List<String> keys = [];
  List<Ingredient> matches = [];

  bool continueEnabled = false;

  @override
  void initState() {
    _loadSuggestions();
    scrollController.addListener(_onScroll);
    super.initState();
  }

  @override
  void didUpdateWidget(covariant IngredientImportList oldWidget) {
    _loadSuggestions();
    continueEnabled = false;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return keys.isEmpty
        ? Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text("Chargement...")
              ],
            ),
          )
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                  child: ListView.builder(
                controller: scrollController,
                itemBuilder: (context, index) => _MatchRow(
                    () => _editMatch(index), keys[index], matches[index]),
                itemCount: keys.length,
              )),
              ElevatedButton(
                onPressed: continueEnabled
                    ? () => widget.onContinue(Map.fromIterables(keys, matches))
                    : null,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Continuer"),
              )
            ],
          );
  }

  void _onScroll() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      setState(() {
        continueEnabled = true;
      });
    }
  }

  void _loadSuggestions() async {
    final keys = widget.ingredients;
    final matches = bestMatchNames(widget.candidates, keys);
    setState(() {
      this.keys = keys;
      this.matches = matches;
    });
  }

  void _editMatch(int index) async {
    final edited = await showDialog<Ingredient>(
      context: context,
      builder: (context) => Dialog(
        child: IngredientSelector(
          widget.candidates,
          (edited) => Navigator.of(context).pop(edited),
          onAbort: () => Navigator.of(context).pop(),
          title: "Identifier l'ingrédient ${keys[index]}",
        ),
      ),
    );
    if (edited == null) return; // édition annulée
    setState(() {
      matches[index] = edited;
    });
  }
}

class _MatchRow extends StatelessWidget {
  final void Function() onEdit;
  final String toMatch;
  final Ingredient matched;

  const _MatchRow(this.onEdit, this.toMatch, this.matched, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4.0),
      child: InkWell(
        onTap: onEdit,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(toMatch),
                )),
            const Icon(Icons.arrow_right),
            Expanded(
              flex: 2,
              child: ListTile(
                title: Text(matched.nom),
                subtitle: Text(formatCategorieIngredient(matched.categorie)),
                trailing: matched.id > 0
                    ? const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(Icons.star, color: Colors.yellow),
                      )
                    : null,
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _RecetteList extends StatefulWidget {
  final List<RecetteExt> recettes;
  final void Function(List<RecetteExt>) onImport;

  const _RecetteList(this.recettes, this.onImport, {super.key});

  @override
  State<_RecetteList> createState() => __RecetteListState();
}

class __RecetteListState extends State<_RecetteList> {
  final scrollController = ScrollController();
  List<RecetteExt> recettes = [];
  bool continueEnabled = false;

  @override
  void initState() {
    scrollController.addListener(_onScroll);
    recettes = widget.recettes;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _RecetteList oldWidget) {
    recettes = widget.recettes;
    continueEnabled = false;
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Importer les ${recettes.length} recettes")),
      body: Column(
        children: [
          Expanded(
            child: ListView(
                controller: scrollController,
                children: List.generate(
                    recettes.length,
                    (index) => _RecetteCard(recettes[index],
                        (cat) => _updateCategorie(index, cat)))),
          ),
          ElevatedButton(
            onPressed: continueEnabled ? () => widget.onImport(recettes) : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Importer"),
          )
        ],
      ),
    );
  }

  void _updateCategorie(int index, CategoriePlat cat) {
    setState(() {
      recettes[index] = recettes[index]
          .copyWith(recette: recettes[index].recette.copyWith(categorie: cat));
    });
  }

  void _onScroll() {
    if (scrollController.offset >= scrollController.position.maxScrollExtent) {
      setState(() {
        continueEnabled = true;
      });
    }
  }
}

class _RecetteCard extends StatelessWidget {
  final RecetteExt recette;
  final void Function(CategoriePlat) onUpdateCategorie;

  const _RecetteCard(this.recette, this.onUpdateCategorie, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
        color: recette.recette.categorie.color,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      recette.recette.label,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const Spacer(),
                  PopupTextButton(
                      recette.recette.categorie,
                      CategoriePlat.values,
                      formatCategoriePlat,
                      onUpdateCategorie),
                ],
              ),
            ),
            Card(
              child: Column(
                  children: recette.ingredients
                      .map((e) => ListTile(
                            visualDensity: const VisualDensity(vertical: -2),
                            dense: true,
                            title: Text(e.ingredient.nom),
                            subtitle: Text(formatCategorieIngredient(
                                e.ingredient.categorie)),
                            trailing: Text(
                                "${formatQuantite(e.link.quantite)} ${formatUnite(e.link.unite)}"),
                          ))
                      .toList()),
            )
          ],
        ));
  }
}
