// import 'package:atable/components/details_menu.dart';
import 'dart:math';

import 'package:atable/components/details_menu.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/components/shop_list.dart';
import 'package:atable/components/stock.dart';
import 'package:atable/logic/env.dart';
import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_sql_menus.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ImportSejourNotification extends Notification {}

class MealList extends StatefulWidget {
  final Env env;
  final DBApi db;

  const MealList(this.env, this.db, {super.key});

  @override
  State<MealList> createState() => _MealListState();
}

class _MealListState extends State<MealList> {
  List<MealExt> meals = [];
  Stock stock = const Stock({});
  final _scrollController = ItemScrollController();

  // indices into [meals]
  Set<int> selectedMeals = {};

  @override
  void initState() {
    _loadMeals();
    _loadStock();
    super.initState();
  }

  @override
  void didUpdateWidget(covariant MealList oldWidget) {
    _loadMeals();
    _loadStock();
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Repas programmés"),
        actions: [
          IconButton(
              onPressed: () => ImportSejourNotification().dispatch(context),
              icon: const Icon(Icons.download)),
          IconButton(
              onPressed: selectedMeals.isEmpty ? null : _showShop,
              icon: const Icon(Icons.shop)),
          IconButton(onPressed: _showStock, icon: const Icon(Icons.store))
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
                        stock,
                        meals[index],
                        selectedMeals.contains(index),
                        () => _openMeal(index),
                        () => _onSelectMeal(index)),
                  )),
    );
  }

  void _onSelectMeal(int index) {
    // if the meal is currently selected, just unselect
    final isSelected = selectedMeals.contains(index);
    if (isSelected) {
      setState(() => selectedMeals.remove(index));
    } else {
      // select the range between the previous selected, if any
      final l = selectedMeals.where((element) => element < index).toList();
      l.sort();
      if (l.isEmpty) {
        // no selected element before index
        setState(() => selectedMeals.add(index));
      } else {
        final start = l.last;
        setState(() {
          for (var i = start; i <= index; i++) {
            selectedMeals.add(i);
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
        selectedMeals = {};
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToClosest());
  }

  void _loadStock() async {
    final s = await widget.db.getStock();
    setState(() => stock = s);
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
      selectedMeals = {}; // the indices have changed
    });
    await widget.db.deleteMeal(meal.meal.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Repas supprimé.'), backgroundColor: Colors.green));
  }

  void _openMeal(int mealIndex) async {
    final meal = meals[mealIndex];
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _MealPannel(
        widget.db,
        meal,
        (m) => _editMeal(mealIndex, m),
      ),
    ));

    // met à jour les données
    final menu = await widget.db.getMenu(meal.menu.menu.id);
    setState(() {
      for (var i = 0; i < meals.length; i++) {
        if (meals[i].menu.menu.id == menu.menu.id) {
          meals[i] = meals[i].copyWith(menu: menu);
        }
      }
    });
  }

  void _showShop() async {
    final selectedMealL = selectedMeals.map((e) => meals[e]).toList();
    final res = await Navigator.of(context).push(MaterialPageRoute<ShopList>(
      builder: (context) => ShopSessionMaster(widget.env, stock, selectedMealL),
    ));
    if (res != null) {
      // add to the stock
      await widget.db
          .addStockFromShop(res.where((item) => item.checked).toList());
      _loadStock();
    }
    setState(() {
      selectedMeals.clear();
    });
  }

  void _showStock() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => StockW(widget.env, widget.db),
    ));
    _loadStock();
  }
}

class _MealCard extends StatelessWidget {
  final Stock stock;
  final MealExt meal;
  final bool isSelected;

  final void Function() onTap;
  final void Function() onLongPress;

  const _MealCard(
      this.stock, this.meal, this.isSelected, this.onTap, this.onLongPress,
      {super.key});

  @override
  Widget build(BuildContext context) {
    final resolvedQuantities = meal.requiredQuantities();

    final plats = resolvedQuantities.entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    final style = TextStyle(
      color: Theme.of(context).primaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w500,
    );
    return Card(
      color: isSelected ? Colors.yellow.shade100 : Colors.white,
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(children: [
                Text(
                  formatDate(meal.meal.date),
                  style: style,
                ),
                const Text(" - "),
                Text(
                  formatHeure(meal.meal.date),
                  style: style,
                ),
                const Spacer(),
                Text(
                  "Pour ${meal.meal.for_}",
                  style: style,
                ),
              ]),
            ),
            meal.menu.ingredients.isEmpty && meal.menu.receipes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Aucun ingrédient",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : _MenuSummary(meal.menu)
          ],
        ),
      ),
    );
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
        Text(formatQuantiteU(ing.quantity.quantite, ing.quantity.unite)),
      ],
    );
  }
}

class _MealPannel extends StatefulWidget {
  final DBApi db;
  final MealExt meal;
  final void Function(MealM meal) onEdit;

  const _MealPannel(this.db, this.meal, this.onEdit, {super.key});

  @override
  State<_MealPannel> createState() => __MealPannelState();
}

class __MealPannelState extends State<_MealPannel> {
  Stock stock = const Stock({});
  late MealExt meal;
  bool isEditingNbPersonnes = false;
  bool isShowingDetails = false;

  @override
  void initState() {
    meal = widget.meal;
    _loadStock();
    super.initState();
  }

  void _loadStock() async {
    final s = await widget.db.getStock();
    setState(() => stock = s);
  }

  void _removeFromStock() async {
    await widget.db.removeFromStock(meal.requiredQuantities().compile());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Stock mis à jour avec succès.")));
    _loadStock();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedQuantities = meal.requiredQuantities();
    final missing = stock.missingFor(resolvedQuantities);

    final plats = resolvedQuantities.entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    return Scaffold(
      appBar: AppBar(
        title: const Text("Détails du repas"),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                  onTap: _editMenu,
                  child: const ListTile(
                      title: Text("Editer les quantités"),
                      trailing: Icon(Icons.edit))),
              PopupMenuItem(
                  onTap: _copy,
                  child: const ListTile(
                      title: Text("Copier"), trailing: Icon(Icons.copy))),
            ],
            child: const Icon(Icons.more_vert),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Row(children: [
              TextButton(
                onPressed: _showDateEditor,
                child: Text(
                  formatDate(meal.meal.date),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const Text(" -  "),
              PopupMenuButton<Horaire>(
                itemBuilder: (context) => Horaire.values
                    .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                    .toList(),
                initialValue: HoraireE.fromDateTime(meal.meal.date),
                onSelected: (m) => _onEditMeal(
                    meal.meal.copyWith(date: m.toDateTime(meal.meal.date))),
                child: Text(
                  formatHeure(meal.meal.date),
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
                      child: Text("Pour ${meal.meal.for_}")),
            ]),
            Column(
                children: plats
                    .map((item) => _PlatCard(item.key, item.value))
                    .toList()),
            TextButton.icon(
                onPressed: _showStock,
                label: missing.isNotEmpty
                    ? const Text("Stock manquant")
                    : const Text("Retirer du stock"),
                icon: missing.isEmpty
                    ? const Icon(
                        Icons.checklist,
                        color: Colors.green,
                      )
                    : const Icon(Icons.warning, color: Colors.orange)),
          ],
        ),
      ),
    );
  }

  void _onEditMeal(MealM m) {
    final newMeal = meal.copyWith(meal: m);
    setState(() => meal = newMeal);
    widget.onEdit(m);
  }

  void _showDateEditor() async {
    final date = meal.meal.date;
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final newDate = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: lastDate);
    if (newDate == null) return;
    _onEditMeal(meal.meal.copyWith(
        date: newDate.add(Duration(minutes: date.minute, hours: date.hour))));
  }

  void _onEditNbDone(String value) {
    _onEditMeal(meal.meal.copyWith(for_: int.parse(value)));
    setState(() {
      isEditingNbPersonnes = false;
    });
  }

  void _copy() async {
    final plats = widget.meal.requiredQuantities().entries.toList();
    plats.sort((a, b) => -(a.key.index - b.key.index));

    final text = plats
        .map((e) => e.value
            .map((e) =>
                "${e.ingredient.name} : ${formatQuantiteU(e.quantity.quantite, e.quantity.unite)}")
            .join("\n"))
        .join("\n\n");

    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        backgroundColor: Colors.green,
        content: Text("Menu copié dans le presse-papier")));
  }

  void _editMenu() async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsMenu(widget.db, meal.menu),
    ));
    // met à jour les données
    final updatedMenu = await widget.db.getMenu(meal.menu.menu.id);
    setState(() => meal = meal.copyWith(menu: updatedMenu));
  }

  void _showStock() async {
    final resolvedQuantities = meal.requiredQuantities();
    final missing = stock.missingFor(resolvedQuantities);

    if (missing.isEmpty) {
      final confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
            title: const Text("Confirmation"),
            content: const Text("Le stock va être diminué des ingrédients."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text("Retirer du stock"))
            ]),
      );
      if (confirm ?? false) {
        _removeFromStock();
      }
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Stock manquant"),
          content: ListView(
              children: missing
                  .map((e) => ListTile(
                        title: Text(e.ingredient.name),
                        trailing: Text(e.quantites.toString()),
                      ))
                  .toList()),
        ),
      );
    }
  }
}
