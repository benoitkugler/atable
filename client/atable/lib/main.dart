import 'package:atable/components/ingredients_list.dart';
import 'package:atable/components/menu_list.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';

void main() async {
  final db = await DBApi.open();
  runApp(App(db));
}

class App extends StatelessWidget {
  final DBApi db;
  const App(this.db, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'A table !',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: _Home(db),
    );
  }
}

class _Home extends StatefulWidget {
  final DBApi db;

  const _Home(this.db, {super.key});

  @override
  State<_Home> createState() => __HomeState();
}

enum _View { menus, ingredients }

class __HomeState extends State<_Home> {
  _View pageIndex = _View.menus;

  String get title {
    switch (pageIndex) {
      case _View.menus:
        return "Repas";
      case _View.ingredients:
        return "Ingrédients";
    }
  }

  Widget get body {
    switch (pageIndex) {
      case _View.menus:
        return MenuList(widget.db);
      case _View.ingredients:
        return IngredientList(widget.db);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: body,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: pageIndex.index,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_view_day_rounded), label: "Repas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood), label: "Ingrédients"),
        ],
        onTap: (value) => setState(() {
          pageIndex = _View.values[value];
        }),
      ),
    );
  }
}
