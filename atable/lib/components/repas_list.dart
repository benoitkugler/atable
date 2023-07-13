import 'package:atable/components/details_menu.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/components/shop_list.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class RepasList extends StatefulWidget {
  final DBApi db;
  final ValueNotifier<int> scrollTo;

  const RepasList(this.db, this.scrollTo, {super.key});

  @override
  State<RepasList> createState() => _RepasListState();
}

class _RepasListState extends State<RepasList> {
  List<RepasExt> repass = [];
  final _scrollController = ItemScrollController();

  // indices into [repass]
  Set<int> selectedRepas = {};

  @override
  void initState() {
    _loadRepas();
    widget.scrollTo.addListener(_scrollToRepas);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollTo.removeListener(_scrollToRepas);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Repas programmés"),
        actions: [
          IconButton(
              onPressed: selectedRepas.isEmpty ? null : _showShop,
              icon: const Icon(Icons.store))
        ],
      ),
      body: repass.isEmpty
          ? const Center(
              child: Text("Aucun repas."),
            )
          : ScrollablePositionedList.builder(
              padding: const EdgeInsets.only(
                  bottom: 50), // avoid add button hiding nbPersonnes field
              itemScrollController: _scrollController,
              itemCount: repass.length,
              itemBuilder: (context, index) => DismissibleDelete(
                    itemKey: repass[index].repas.id,
                    onDissmissed: () => _deleteRepas(repass[index]),
                    confirmDismiss: () => _confirmeDelete(repass[index]),
                    child: _RepasCard(
                      repass[index],
                      selectedRepas.contains(index),
                      () => _showMenuDetails(index),
                      () => _onSelectRepas(index),
                      (m) => _editRepas(index, m),
                    ),
                  )),
      floatingActionButton: FloatingActionButton(
        onPressed: _addRepas,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _onSelectRepas(int index) {
    // if the repas is currently selected, just unselect
    final isSelected = selectedRepas.contains(index);
    if (isSelected) {
      setState(() => selectedRepas.remove(index));
    } else {
      // select the range between the previous selected, if any
      final l = selectedRepas.where((element) => element < index).toList();
      l.sort();
      if (l.isEmpty) {
        // no selected element before index
        setState(() => selectedRepas.add(index));
      } else {
        final start = l.last;
        setState(() {
          for (var i = start; i <= index; i++) {
            selectedRepas.add(i);
          }
        });
      }
    }
  }

  void _scrollToRepas() async {
    final id = widget.scrollTo.value;
    final index = repass.indexWhere((element) => element.repas.id == id);
    await _scrollToIndex(index);
  }

  void _scrollToEnd() {
    _scrollToIndex(repass.length - 1);
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

  void _loadRepas() async {
    final l = await widget.db.getRepas();
    if (mounted) {
      setState(() {
        repass = l;
        selectedRepas = {};
      });
    }
  }

  void _addRepas() async {
    final newMenu = await widget.db
        .createMenu(const Menu(id: 0, nbPersonnes: 10, label: ""));
    final repasProps = (await widget.db.guessRepasProperties());

    final newRepas =
        await widget.db.createRepas(repasProps.copyWith(idMenu: newMenu.id));

    setState(() {
      repass.add(
          RepasExt(newRepas, MenuExt(newMenu, [], []))); // préserve l'ordre
    });

    _scrollToEnd();
  }

  void _editRepas(int oldRepasIndex, Repas newRepas) async {
    // met à jour le menu ...
    await widget.db.updateRepas(newRepas);

    setState(() {
      repass[oldRepasIndex] = repass[oldRepasIndex].copyWith(repas: newRepas);
      repass.sort((a, b) => a.repas.date.compareTo(b.repas.date));
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Repas mis à jour.'),
      backgroundColor: Colors.green,
    ));
  }

  Future<bool> _confirmeDelete(RepasExt repas) async {
    final isMenuEmpty =
        repas.menu.recettes.isEmpty && repas.menu.ingredients.isEmpty;
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

  void _deleteRepas(RepasExt repas) async {
    setState(() {
      repass.removeWhere((element) => element.repas.id == repas.repas.id);
      selectedRepas = {}; // the indices have changed
    });
    await widget.db.deleteRepas(repas.repas);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Repas supprimé.'), backgroundColor: Colors.green));
  }

  void _showMenuDetails(int menuIndex) async {
    var menu = repass[menuIndex].menu;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsMenu(widget.db, menu),
    ));

    // met à jour les données
    menu = await widget.db.getMenu(menu.menu.id);
    setState(() {
      for (var i = 0; i < repass.length; i++) {
        if (repass[i].menu.menu.id == menu.menu.id) {
          repass[i] = repass[i].copyWith(menu: menu);
        }
      }
    });
  }

  void _showShop() async {
    final selectedRepasL = selectedRepas.map((e) => repass[e]).toList();
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ShopSessionMaster(selectedRepasL),
    ));
    setState(() {
      selectedRepas.clear();
    });
  }
}

class _RepasCard extends StatefulWidget {
  final RepasExt repas;
  final bool isSelected;

  final void Function() onTap;
  final void Function() onLongPress;
  final void Function(Repas repas) onEdit;

  const _RepasCard(
      this.repas, this.isSelected, this.onTap, this.onLongPress, this.onEdit,
      {super.key});

  @override
  State<_RepasCard> createState() => _RepasCardState();
}

class _RepasCardState extends State<_RepasCard> {
  bool isEditingNbPersonnes = false;

  @override
  Widget build(BuildContext context) {
    final repas = widget.repas.repas;
    final plats = widget.repas.requiredQuantites().entries.toList();
    plats.sort((a, b) => a.key.index - b.key.index);

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
                    widget.repas.repas.formatJour(),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const Text(" -  "),
                PopupMenuButton<MomentRepas>(
                  itemBuilder: (context) => MomentRepas.values
                      .map((e) => PopupMenuItem(value: e, child: Text(e.label)))
                      .toList(),
                  initialValue: MomentRepasE.fromDateTime(repas.date),
                  onSelected: (m) => widget
                      .onEdit(repas.copyWith(date: m.toDateTime(repas.date))),
                  child: Text(
                    widget.repas.repas.formatHeure(),
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
                        child: Text("Pour ${widget.repas.repas.nbPersonnes}")),
              ]),
            ),
            widget.repas.menu.ingredients.isEmpty &&
                    widget.repas.menu.recettes.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: Text(
                      "Aucun ingrédient",
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  )
                : Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Column(
                        children: plats
                            .map((item) => _PlatCard(item.key, item.value))
                            .toList()),
                  )
          ],
        ),
      ),
    );
  }

  void _onEditNbDone(String value) {
    widget.onEdit(widget.repas.repas.copyWith(nbPersonnes: int.parse(value)));
    setState(() {
      isEditingNbPersonnes = false;
    });
  }

  void _showDateEditor() async {
    final date = widget.repas.repas.date;
    final lastDate = DateTime.now().add(const Duration(days: 365));
    final newDate = await showDatePicker(
        context: context,
        initialDate: date,
        firstDate: date.subtract(const Duration(days: 365)),
        lastDate: lastDate);

    if (newDate == null) return;
    widget.onEdit(widget.repas.repas.copyWith(
        date: newDate.add(Duration(minutes: date.minute, hours: date.hour))));
  }
}

class _PlatCard extends StatelessWidget {
  final CategoriePlat plat;
  final List<IngQuant> ingredients;
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
  final IngQuant ing;
  const _IngQuantRow(this.ing, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(ing.ingredient.nom),
        const Spacer(),
        Text("${formatQuantite(ing.quantite)} ${formatUnite(ing.unite)}"),
      ],
    );
  }
}
