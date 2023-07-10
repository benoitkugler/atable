import 'dart:io';

import 'package:atable/components/menus_list.dart';
import 'package:atable/components/recettes_list.dart';
import 'package:atable/components/repas_list.dart';
import 'package:atable/components/shared.dart';
import 'package:atable/logic/sql.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

void main() async {
  runApp(const App());
}

class App extends StatelessWidget {
  const App({Key? key}) : super(key: key);

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
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home({super.key});

  @override
  State<_Home> createState() => __HomeState();
}

enum _View { repas, menus, recettes }

class __HomeState extends State<_Home> {
  DBApi? db;

  PageController controller = PageController();
  int _pageIndex = 0;

  var scrollToRepas = ValueNotifier<int>(-1);
  var scrollToMenu = ValueNotifier<int>(-1);

  @override
  void initState() {
    _openDB();
    super.initState();
  }

  _openDB() async {
    final db = await DBApi.open();
    setState(() {
      this.db = db;
    });
  }

  Widget body(int index) {
    final db = this.db;
    if (db == null) {
      return const Center(
          child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 10),
          Text("Chargement des données...")
        ],
      ));
    }
    switch (_View.values[index]) {
      case _View.repas:
        return RepasList(db, scrollToRepas);
      case _View.menus:
        return MenusList(db, scrollToMenu);
      case _View.recettes:
        return RecettesList(db);
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
      body: NotificationListener<MainNotification>(
        onNotification: (notification) {
          if (notification is GoToMenuNotification) {
            _showMenu(notification);
          } else if (notification is GoToRepasNotification) {
            _showRepas(notification);
          } else if (notification is ImportDBNotification) {
            _import();
          } else if (notification is ExportDBNotification) {
            _export();
          }
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

  _export() async {
    final String outFile;
    try {
      outFile = await DBApi.exportDB();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$e"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text("Base exportée dans $outFile."),
      backgroundColor: Colors.green,
    ));
  }

  _import() async {
    final dir = await downloadDir();
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      initialDirectory: dir.path,
      type: FileType.custom,
      allowedExtensions: ['tar'],
    );

    final path = result?.files.single.path;
    if (path == null) {
      // User canceled the picker
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Import annulé."),
          backgroundColor: Colors.orange,
        ));
      }
      return;
    }
    final dbFile = File(path);

    try {
      await DBApi.checkValidDB(dbFile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Fichier invalide :\n$e"),
          backgroundColor: Colors.red,
        ));
      }
      return;
    }

    await db?.close();
    setState(() {
      db = null;
    });
    final newDB = await DBApi.importDB(dbFile);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Import terminé."),
      backgroundColor: Colors.green,
    ));

    setState(() {
      db = newDB;
    });
  }
}
