import 'package:atable/components/repas_list.dart';
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

  // _export() async {
  //   final String outFile;
  //   try {
  //     outFile = await DBApi.exportDB();
  //   } catch (e) {
  //     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //       content: Text("$e"),
  //       backgroundColor: Colors.red,
  //     ));
  //     return;
  //   }

  //   if (!mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //     content: Text("Base exportée dans $outFile."),
  //     backgroundColor: Colors.green,
  //   ));
  // }

  // _import() async {
  //   final dir = await downloadDir();
  //   FilePickerResult? result = await FilePicker.platform.pickFiles(
  //     initialDirectory: dir.path,
  //     type: FileType.custom,
  //     allowedExtensions: ['tar'],
  //   );

  //   final path = result?.files.single.path;
  //   if (path == null) {
  //     // User canceled the picker
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //         content: Text("Import annulé."),
  //         backgroundColor: Colors.orange,
  //       ));
  //     }
  //     return;
  //   }
  //   final dbFile = File(path);

  //   try {
  //     await DBApi.checkValidDB(dbFile);
  //   } catch (e) {
  //     if (mounted) {
  //       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
  //         content: Text("Fichier invalide :\n$e"),
  //         backgroundColor: Colors.red,
  //       ));
  //     }
  //     return;
  //   }

  //   await db?.close();
  //   setState(() {
  //     db = null;
  //   });
  //   final newDB = await DBApi.importDB(dbFile);

  //   if (!mounted) return;
  //   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
  //     content: Text("Import terminé."),
  //     backgroundColor: Colors.green,
  //   ));

  //   setState(() {
  //     db = newDB;
  //   });
  // }
}
