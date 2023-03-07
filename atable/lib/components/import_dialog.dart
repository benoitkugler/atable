import 'package:atable/components/ingredient_editor.dart';
import 'package:atable/logic/import.dart';
import 'package:atable/logic/models.dart';
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
            child: IngredientEditor(
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
