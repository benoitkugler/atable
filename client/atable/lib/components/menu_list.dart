import 'package:atable/logic/debug.dart';
import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';

class MenuList extends StatefulWidget {
  final DBApi db;

  const MenuList(this.db, {super.key});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  List<MenuExt> menus = [];

  @override
  void initState() {
    _loadMenus();
    super.initState();
  }

  void _loadMenus() async {
    final l = await widget.db.getMenus();
    setState(() {
      menus = sampleMenus;
      // menus = l;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(children: menus.map((e) => _MenuDetails(e)).toList());
  }
}

class _MenuDetails extends StatelessWidget {
  final MenuExt menu;
  const _MenuDetails(this.menu, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          Row(children: [
            Text(menu.menu.formatJour()),
            const Spacer(),
            Text(menu.menu.formatHeure()),
          ]),
          Column(children: menu.ingredients.map((e) => Text("$e")).toList())
        ],
      ),
    );
  }
}
