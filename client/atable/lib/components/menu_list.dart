import 'package:atable/components/details_menu.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';

class MenuList extends StatefulWidget {
  final DBApi db;

  const MenuList(this.db, {super.key});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  List<MenuExt> menus = [];
  final _scrollController = ScrollController();

  @override
  void initState() {
    _loadMenus();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: menus.isEmpty
          ? const Center(
              child: Text("Aucun repas."),
            )
          : ListView.builder(
              controller: _scrollController,
              itemCount: menus.length,
              itemBuilder: (context, index) => Dismissible(
                    key: Key("${menus[index].menu.id}"),
                    onDismissed: (direction) => _deleteMenu(menus[index]),
                    background: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(5)),
                    ),
                    child: _MenuCard(
                        menus[index],
                        () => _showMenuDetails(index),
                        (m) => _editMenu(index, m)),
                  )),
      floatingActionButton: FloatingActionButton(
        mini: true,
        onPressed: _addMenu,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _loadMenus() async {
    final l = await widget.db.getMenus();
    if (mounted) setState(() => menus = l);
  }

  void _addMenu() async {
    // Utilise la date courante si aucun menu n'existe encore
    // Sinon utilise le dernier menu et passe au prochain repas
    final date = menus.isEmpty
        ? DateTime.now()
        : MomentRepasE.nextRepas(menus.last.menu.date);
    final nbPersonnes = menus.isEmpty ? 8 : menus.last.menu.nbPersonnes;
    final newMenu = await widget.db
        .insertMenu(Menu(id: 0, date: date, nbPersonnes: nbPersonnes));
    setState(() {
      menus.add(MenuExt(newMenu, [])); // préserve l'ordre
    });
    Future.delayed(
        const Duration(milliseconds: 100),
        () => _scrollController.animateTo(
              _scrollController.position.maxScrollExtent + 100,
              curve: Curves.fastOutSlowIn,
              duration: const Duration(milliseconds: 500),
            ));
  }

  void _editMenu(int oldMenuIndex, Menu newMenu) async {
    // met à jour le menu ...
    await widget.db.updateMenu(newMenu);

    final oldMenu = menus[oldMenuIndex];
    // ... et modifie les quantités liées
    double factor =
        newMenu.nbPersonnes.toDouble() / oldMenu.menu.nbPersonnes.toDouble();
    final newIngs = oldMenu.ingredients
        .map((e) => e.copyWith(
            link: e.link.copyWith(quantite: factor * e.link.quantite)))
        .toList();

    await widget.db.updateMenuIngredients(newIngs.map((e) => e.link).toList());
    setState(() {
      menus[oldMenuIndex] = MenuExt(newMenu, newIngs);
    });
  }

  void _deleteMenu(MenuExt menu) async {
    setState(() {
      menus.removeWhere((element) => element.menu.id == menu.menu.id);
    });
    await widget.db.deleteMenu(menu.menu.id);

    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Repas supprimé.')));
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
}

class _MenuCard extends StatefulWidget {
  final MenuExt menu;

  final void Function() onTap;
  final void Function(Menu menu) onEdit;

  const _MenuCard(this.menu, this.onTap, this.onEdit, {super.key});

  @override
  State<_MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<_MenuCard> {
  bool isEditingNbPersonnes = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        onTap: widget.onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                Text(
                  "${widget.menu.menu.formatJour()} - ${widget.menu.menu.formatHeure()}",
                  style: TextStyle(fontSize: 16),
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
                          onSubmitted: _onEditDone,
                        ))
                    : TextButton(
                        style: TextButton.styleFrom(
                            visualDensity: const VisualDensity(vertical: -3)),
                        onPressed: () =>
                            setState(() => isEditingNbPersonnes = true),
                        child: Text("Pour ${widget.menu.menu.nbPersonnes}")),
              ]),
            ),
            widget.menu.ingredients.isEmpty
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
                        children: widget.menu
                            .plats()
                            .entries
                            .map((item) => _PlatCard(item.key, item.value))
                            .toList()),
                  )
          ],
        ),
      ),
    );
  }

  void _onEditDone(String value) {
    widget.onEdit(widget.menu.menu.copyWith(nbPersonnes: int.parse(value)));
    setState(() {
      isEditingNbPersonnes = false;
    });
  }
}

class _PlatCard extends StatelessWidget {
  final CategoriePlat plat;
  final List<MenuIngredientExt> ingredients;
  const _PlatCard(this.plat, this.ingredients, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0.5,
      color: plat.color,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          children: ingredients.map((e) => _MenuIngredientRow(e)).toList(),
        ),
      ),
    );
  }
}

class _MenuIngredientRow extends StatelessWidget {
  final MenuIngredientExt ing;
  const _MenuIngredientRow(this.ing, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(ing.ingredient.nom),
        const Spacer(),
        Text(
            "${formatQuantite(ing.link.quantite)} ${formatUnite(ing.link.unite)}"),
      ],
    );
  }
}
