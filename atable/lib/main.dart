import 'package:atable/components/meal_list.dart';
import 'package:atable/logic/sql.dart';
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

class __HomeState extends State<_Home> {
  DBApi? db;

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

  @override
  Widget build(BuildContext context) {
    final db = this.db;
    return Scaffold(
      body: db == null
          ? const Center(
              child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 10),
                Text("Chargement des données...")
              ],
            ))
          : MealList(db),
    );
  }
}
