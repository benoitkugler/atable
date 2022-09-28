import 'package:atable/logic/models.dart';
import 'package:flutter/material.dart';

class MenuList extends StatefulWidget {
  const MenuList({super.key});

  @override
  State<MenuList> createState() => _MenuListState();
}

class _MenuListState extends State<MenuList> {
  final List<MenuExt> menus = [];

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
      child: Text("Menu ${menu.menu.id}"),
    );
  }
}
