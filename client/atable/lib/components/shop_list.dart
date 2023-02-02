import 'package:atable/logic/models.dart';
import 'package:atable/logic/shop.dart';
import 'package:flutter/material.dart';

class ShopSession extends StatefulWidget {
  final List<MenuExt> menus;

  const ShopSession(this.menus, {super.key});

  @override
  State<ShopSession> createState() => _ShopSessionState();
}

class _ShopSessionState extends State<ShopSession> {
  late ShopController shopController;

  ShopList list = ShopList([]);

  @override
  void initState() {
    shopController = ShopControllerLocal(ShopList.fromMenus(widget.menus));
    _refreshList();
    super.initState();
  }

  void _refreshList() async {
    final l = await shopController.fetchList();
    setState(() {
      list = l;
    });
  }

  void _updateChecked(int id, bool checked) async {
    final l = await shopController.updateShop(id, checked);
    setState(() {
      list = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Liste de course")),
        body: ListView(
            children: list
                .bySections()
                .map((e) => _ShopSection(e, _updateChecked))
                .toList()));
  }
}

class _ShopSection extends StatelessWidget {
  final ShopSection section;
  final void Function(int, bool) onUpdate;

  const _ShopSection(this.section, this.onUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: section.isDone ? Colors.green.shade100 : Colors.yellow.shade100,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                formatCategorieIngredient(section.categorie),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: section.ingredients
                  .map((e) => _IngredientRow(e, onUpdate))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

class _IngredientRow extends StatelessWidget {
  final IngredientQuantite ingredient;
  final void Function(int, bool) onUpdate;

  const _IngredientRow(this.ingredient, this.onUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !ingredient.checked,
      dense: true,
      leading: Text(ingredient.quantite),
      title: Text(ingredient.nom),
      trailing: Checkbox(
        activeColor: Colors.blue.shade100,
        checkColor: Colors.grey,
        value: ingredient.checked,
        onChanged: (value) => onUpdate(ingredient.id, value!),
      ),
    );
  }
}
