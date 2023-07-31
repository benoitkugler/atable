import 'dart:math';

import 'package:atable/components/details_menu.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/models.back';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class GoToRepasNotification extends MainNotification {
  final Repas repas;
  GoToRepasNotification(this.repas);
}

class GoToMenuNotification extends MainNotification {
  final Menu menu;
  GoToMenuNotification(this.menu);
}

class MenusList extends StatefulWidget {
  final DBApi db;
  final ValueNotifier<int> scrollTo;

  const MenusList(this.db, this.scrollTo, {super.key});

  @override
  State<MenusList> createState() => _MenusListState();
}

class _MenusListState extends State<MenusList> {
  List<MenuExt> menus = [];
  final _scrollController = ItemScrollController();

  @override
  void initState() {
    _loadMenus();
    widget.scrollTo.addListener(_scrollToMenu);
    super.initState();
  }

  @override
  void dispose() {
    widget.scrollTo.removeListener(_scrollToMenu);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Menus favoris"),
      ),
      body: menus.isEmpty
          ? const Center(
              child: Text("Aucun menu dans les favoris."),
            )
          : ScrollablePositionedList.builder(
              itemScrollController: _scrollController,
              itemCount: menus.length,
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.all(2.0),
                child: DismissibleDelete(
                  itemKey: menus[index].menu.id,
                  confirmDismiss: () => _checkDeleteMenu(menus[index]),
                  onDissmissed: () => _deleteMenu(menus[index]),
                  child: _MenuCard(
                    menus[index],
                    () => _showMenuDetails(index),
                    () => _createRepas(menus[index].menu),
                  ),
                ),
              ),
            ),
      floatingActionButton: FloatingActionButton(
        // mini: true,
        onPressed: _addMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _loadMenus() async {
    final l = await widget.db.getMenusFavoris();
    if (mounted) setState(() => menus = l);
  }

  void _addMenu() async {
    final serial =
        menus.isEmpty ? 1 : menus.map((e) => e.menu.id).reduce(max) + 1;
    final nbPersonnes = menus.isEmpty ? 8 : menus.last.menu.nbPersonnes;

    final newMenu = await widget.db.createMenu(
        Menu(id: 0, nbPersonnes: nbPersonnes, label: "Menu $serial"));
    setState(() {
      menus.add(MenuExt(newMenu, [], [])); // préserve l'ordre
    });
    Future.delayed(
      const Duration(milliseconds: 100),
      () => _scrollToIndex(menus.length - 1),
    );
  }

  // verifie si le menu est utilisé dans un repas
  Future<bool> _checkDeleteMenu(MenuExt menu) async {
    final repas = await widget.db.getRepasFromMenu(menu.menu);
    if (!mounted) return false;

    if (repas.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
          'Ce menu est utilisé dans un repas.',
        ),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
            label: "Voir les repas",
            textColor: Colors.white,
            onPressed: () =>
                GoToRepasNotification(repas.first).dispatch(context)),
      ));
      return false;
    }
    return true;
  }

  void _deleteMenu(MenuExt menu) async {
    setState(() {
      menus.removeWhere((element) => element.menu.id == menu.menu.id);
    });
    await widget.db.deleteMenu(menu.menu.id);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Menu supprimé.'),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.green,
    ));
  }

  void _showMenuDetails(int menuIndex) async {
    var menu = menus[menuIndex];
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => DetailsMenu(widget.db, menu),
    ));
    // met à jour les données
    menu = await widget.db.getMenu(menu.menu.id);
    setState(() {
      menus[menuIndex] = menu;
    });
  }

  void _createRepas(Menu menu) async {
    final repasProps = await widget.db.guessRepasProperties();
    final repas =
        await widget.db.createRepas(repasProps.copyWith(idMenu: menu.id));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Repas ajouté.'),
      duration: Duration(seconds: 1),
      backgroundColor: Colors.green,
    ));
    GoToRepasNotification(repas).dispatch(context);
  }

  void _scrollToMenu() async {
    final id = widget.scrollTo.value;
    final index = menus.indexWhere((element) => element.menu.id == id);
    await _scrollToIndex(index);
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
}

class _MenuCard extends StatelessWidget {
  final MenuExt menu;

  final void Function() onTap;
  final void Function() onCreateRepas;

  const _MenuCard(this.menu, this.onTap, this.onCreateRepas, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selectedColor: Colors.yellow.shade100,
      title: Text(menu.menu.label),
      trailing: IconButton(
        onPressed: onCreateRepas,
        icon: const Icon(Icons.assignment_add),
        color: Colors.green,
      ),
      onTap: onTap,
    );
  }
}
