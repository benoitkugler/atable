// import 'package:atable/components/details_menu.dart';
import 'dart:math';

import 'package:atable/components/details_menu.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/components/shop_list.dart';
import 'package:atable/logic/debug.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MealList extends StatefulWidget {
  final DBApi db;

  const MealList(this.db, {super.key});

  @override
  State<MealList> createState() => _MealListState();
}

class _MealListState extends State<MealList> {
  List<MealExt> meals = [];
  final _scrollController = ItemScrollController();

  // indices into [meals]
  Set<int> selectedMeal = {};

  @override
  void initState() {
    _loadMeals();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Repas programmés"),
        actions: [
          IconButton(
              onPressed: () async {
                await widget.db.importSejour(data);
                _loadMeals();
              },
              icon: const Icon(Icons.download)),
          IconButton(
              onPressed: selectedMeal.isEmpty ? null : _showShop,
              icon: const Icon(Icons.store))
        ],
      ),
      body: meals.isEmpty
          ? const Center(
              child: Text("Aucun repas."),
            )
          : ScrollablePositionedList.builder(
              padding: const EdgeInsets.only(
                  bottom: 50), // avoid add button hiding nbPersonnes field
              itemScrollController: _scrollController,
              itemCount: meals.length,
              itemBuilder: (context, index) => DismissibleDelete(
                    itemKey: meals[index].meal.id,
                    onDissmissed: () => _deleteMeal(meals[index]),
                    confirmDismiss: () => _confirmeDelete(meals[index]),
                    child: _MealCard(
                      meals[index],
                      selectedMeal.contains(index),
                      () => _showMenuDetails(index),
                      () => _onSelectMeal(index),
                      (m) => _editMeal(index, m),
                    ),
                  )),
    );
  }

  void _onSelectMeal(int index) {
    // if the meal is currently selected, just unselect
    final isSelected = selectedMeal.contains(index);
    if (isSelected) {
      setState(() => selectedMeal.remove(index));
    } else {
      // select the range between the previous selected, if any
      final l = selectedMeal.where((element) => element < index).toList();
      l.sort();
      if (l.isEmpty) {
        // no selected element before index
        setState(() => selectedMeal.add(index));
      } else {
        final start = l.last;
        setState(() {
          for (var i = start; i <= index; i++) {
            selectedMeal.add(i);
          }
        });
      }
    }
  }

  void _scrollToClosest() {
    if (meals.isEmpty) return;

    // find the closest meal from the current time
    final now = DateTime.now();
    final distances =
        meals.map((e) => now.difference(e.meal.date).inMinutes.abs()).toList();
    final minDiff = distances.reduce(min);
    final index = distances.indexOf(minDiff);
    _scrollToIndex(index);
  }

  Future<void> _scrollToIndex(int index) async {
    if (!_scrollController.isAttached) return; // widget not build yet
    // scroll à la fin de la liste
    await Future.delayed(
        const Duration(milliseconds: 50),
        () async => await _scrollController.scrollTo(
              index: index,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 500),
            ));
  }

  void _loadMeals() async {
    final l = await widget.db.getMeals();
    if (mounted) {
      setState(() {
        meals = l;
        selectedMeal = {};
      });
    }

    _scrollToClosest();
  }

  void _editMeal(int oldMealIndex, MealM newMeal) async {
    // met à jour le menu ...
    await widget.db.updateMeal(newMeal);

    setState(() {
      meals[oldMealIndex] = meals[oldMealIndex].copyWith(meal: newMeal);
      meals.sort((a, b) => a.meal.date.compareTo(b.meal.date));
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Repas mis à jour.'),
      backgroundColor: Colors.green,
    ));
  }

  Future<bool> _confirmeDelete(MealExt meal) async {
    final isMenuEmpty =
        meal.menu.receipes.isEmpty && meal.menu.ingredients.isEmpty;
    if (isMenuEmpty) return true;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirmer la suppression"),
        content: const Text("Confirmez-vous la suppression de ce repas ?"),
        actions: [
          TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Supprimer"))
        ],
      ),
    );
    return confirm ?? false;
  }

  void _deleteMeal(MealExt meal) async {
    setState(() {
      meals.removeWhere((element) => element.meal.id == meal.meal.id);
      selectedMeal = {}; // the indices have changed
    });
    await widget.db.deleteMeal(meal.meal.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Repas supprimé.'), backgroundColor: Colors.green));
  }

  void _showMenuDetails(int menuIndex) async {
    var menu = meals[menuIndex].menu;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsMenu(widget.db, menu),
    ));

    // met à jour les données
    menu = await widget.db.getMenu(menu.menu.id);
    setState(() {
      for (var i = 0; i < meals.length; i++) {
        if (meals[i].menu.menu.id == menu.menu.id) {
          meals[i] = meals[i].copyWith(menu: menu);
        }
      }
    });
  }

  void _showShop() async {
    final selectedMealL = selectedMeal.map((e) => meals[e]).toList();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ShopSessionMaster(selectedMealL),
    ));
    setState(() {
      selectedMeal.clear();
    });
  }
}

class _MealCard extends StatefulWidget {
  final MealExt meal;
  final bool isSelected;

  final void Function() onTap;
  final void Function() onLongPress;
  final void Function(MealM meal) onEdit;

  const _MealCard(
      this.meal, this.isSelected, this.onTap, this.onLongPress, this.onEdit,
      {super.key});

  @override
  State<_MealCard> createState() => _MealCardState();
}

class _MealCardState extends State<_MealCard> {
  bool isEditingNbPersonnes = false;
  bool isShowingDetails = false;

  @override
  Widget build(BuildContext context) {
    final meal = widget.meal.meal;
    final plats = widget.meal.requiredQuantities().entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    return Card(
      color: widget.isSelected ? Colors.yellow.shade100 : Colors.white,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                TextButton(
                  onPressed: _showDateEditor,
                  child: Text(
                    formatDate(widget.meal.meal.date),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Text(" -  "),
                PopupMenuButton<Horaire>(
                  itemBuilder: (context) => Horaire.values
                      .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  initialValue: HoraireE.fromDateTime(meal.date),
                  onSelected: (m) => widget
                      .onEdit(meal.copyWith(date: m.toDateTime(meal.date))),
                  child: Text(
                    formatHeure(widget.meal.meal.date),
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                isEditingNbPersonnes
                    ? SizedBox(
                        width: 100,
                        child: TextField(
                          autofocus: true,
                          textAlign: TextAlign.center,
                          textAlignVertical: TextAlignVertical.center,
                          decoration: InputDecoration(
                              isDense: true,
                              prefixIcon: IconButton(
                                  onPressed: () => setState(
                                      () => isEditingNbPersonnes = false),
                                  icon: const Icon(
                                    Icons.clear,
                                    color: Colors.orange,
                                  ))),
                          keyboardType: const TextInputType.numberWithOptions(
                              signed: false, decimal: false),
                          onSubmitted: _onEditNbDone,
                        ))
                    : TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: const VisualDensity(vertical: -3)),
                        onPressed: () =>
                            setState(() => isEditingNbPersonnes = true),
                        child: Text("Pour ${widget.meal.meal.for_}")),
              ]),
            ),
            widget.meal.menu.ingredients.isEmpty &&
                    widget.meal.menu.receipes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Aucun ingrédient",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                        isShowingDetails
                            ? Expanded(
                                child: Padding(
                                padding: const EdgeInsets.all(4.0),
                                child: Column(
                                    children: plats
                                        .map((item) =>
                                            _PlatCard(item.key, item.value))
                                        .toList()),
                              ))
                            : Expanded(child: _MenuSummary(widget.meal.menu)),
                        Column(
                          children: [
                            IconButton(
                                onPressed: () {
                                  setState(() {
                                    isShowingDetails = !isShowingDetails;
                                  });
                                },
                                icon: isShowingDetails
                                    ? const Icon(Icons.clear)
                                    : const Icon(Icons.list)),
                            IconButton(
                                onPressed: _copy, icon: const Icon(Icons.copy)),
                          ],
                        )
                      ])
          ],
        ),
      ),
    );
  }

  void _copy() async {
    final plats = widget.meal.requiredQuantities().entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    final text = plats
        .map((e) => e.value
            .map((e) =>
                "${e.ingredient.name} : ${formatQuantite(e.quantite)} ${formatUnite(e.unite)}")
            .join("\n"))
        .join("\n\n");

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Menu copié dans le presse-papier")));
  }

  void _onEditNbDone(String value) {
    widget.onEdit(widget.meal.meal.copyWith(for_: int.parse(value)));
    setState(() {
      isEditingNbPersonnes = false;
    });
  }

  void _showDateEditor() async {
    final date = widget.meal.meal.date;
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final newDate = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: lastDate);

    if (newDate == null) return;
    widget.onEdit(widget.meal.meal.copyWith(
        date: newDate.add(Duration(minutes: date.minute, hours: date.hour))));
  }
}

class _MenuSummary extends StatelessWidget {
  final MenuExt menu;
  const _MenuSummary(this.menu, {super.key});

  @override
  Widget build(BuildContext context) {
    final byPlat = <PlatKind, List<String>>{};
    for (var ingredient in menu.ingredients) {
      final l = byPlat.putIfAbsent(ingredient.link.plat, () => []);
      l.add(ingredient.ingredient.name);
    }
    for (var receipe in menu.receipes) {
      final l = byPlat.putIfAbsent(receipe.receipe.plat, () => []);
      l.add(receipe.receipe.name);
    }
    for (var l in byPlat.values) {
      l.sort();
    }
    final plats = byPlat.entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: plats
              .map((item) => Card(
                    color: item.key.color.withOpacity(0.8),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Column(
                        children: item.value.map((e) => Text(e)).toList(),
                      ),
                    ),
                  ))
              .toList()),
    );
  }
}

class _PlatCard extends StatelessWidget {
  final PlatKind plat;
  final List<ResolvedQuantityIngredient> ingredients;
  const _PlatCard(this.plat, this.ingredients, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: plat.color.withOpacity(0.8),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: ingredients.map((e) => _IngQuantRow(e)).toList(),
        ),
      ),
    );
  }
}

class _IngQuantRow extends StatelessWidget {
  final ResolvedQuantityIngredient ing;
  const _IngQuantRow(this.ing, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(ing.ingredient.name),
        const Spacer(),
        Text("${formatQuantite(ing.quantite)} ${formatUnite(ing.unite)}"),
      ],
    );
  }
}
