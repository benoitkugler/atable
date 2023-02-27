import 'package:atable/components/menus_list.dart';
import 'package:atable/components/recettes_list.dart';
import 'package:atable/components/repas_list.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('fr'),
      ],
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

enum _View { repas, menus, recettes }

class __HomeState extends State<_Home> {
  PageController controller = PageController();
  int _pageIndex = 0;

  var scrollToRepas = ValueNotifier<int>(-1);
  var scrollToMenu = ValueNotifier<int>(-1);

  Widget body(int index) {
    switch (_View.values[index]) {
      case _View.repas:
        return RepasList(widget.db, scrollToRepas);
      case _View.menus:
        return MenusList(widget.db, scrollToMenu);
      case _View.recettes:
        return RecettesList(widget.db);
    }
  }

  void _showRepas(GoToRepasNotification notif) async {
    await controller.animateToPage(_View.repas.index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {});
    scrollToRepas.value = notif.repas.id;
  }

  void _showMenu(GoToMenuNotification notif) async {
    await controller.animateToPage(_View.menus.index,
        duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    setState(() {});
    scrollToMenu.value = notif.menu.id;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NotificationListener<GoToMenuNotification>(
        onNotification: (notification) {
          _showMenu(notification);
          return true;
        },
        child: NotificationListener<GoToRepasNotification>(
          onNotification: (notification) {
            _showRepas(notification);
            return true;
          },
          child: PageView.builder(
            controller: controller,
            itemCount: _View.values.length,
            itemBuilder: (context, index) => body(index),
            onPageChanged: (index) => setState(() {
              _pageIndex = index;
            }),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _pageIndex,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_view_day_rounded), label: "Repas"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood), label: "Menus favoris"),
          BottomNavigationBarItem(
              icon: Icon(Icons.fastfood), label: "Recettes"),
        ],
        onTap: (value) => setState(() {
          controller.jumpToPage(value);
        }),
      ),
    );
  }
}
