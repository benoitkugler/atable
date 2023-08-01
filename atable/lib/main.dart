import 'dart:convert';

import 'package:atable/components/meal_list.dart';
import 'package:atable/logic/env.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';

// const env = Env(BuildMode.prod);
const env = Env(BuildMode.dev);

void main() async {
  runApp(MaterialApp.router(
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
    routerConfig: router,
  ));
}

final router = GoRouter(
  routes: [
    // regular start
    GoRoute(
      path: '/',
      builder: (_, state) => const _Home(null),
    ),
    // import sejour feature
    GoRoute(
        path: '/import-sejour',
        builder: (_, state) {
          final params = state.uri.queryParameters;
          if (params.containsKey("id")) {
            return _Home(env.importSejourLink(params["id"]!));
          }
          return const _Home(null);
        }),
  ],
);

class _Home extends StatefulWidget {
  final Uri? importSejourURL;
  const _Home(this.importSejourURL, {super.key});

  @override
  State<_Home> createState() => __HomeState();
}

enum _LoadState { completed, openingDB, downloadingSejour, importingSejour }

class __HomeState extends State<_Home> {
  DBApi? db;
  _LoadState loadState = _LoadState.openingDB;

  @override
  void initState() {
    _openDB();
    super.initState();
  }

  @override
  void didUpdateWidget(_Home oldWidget) {
    _openDB();
    super.didUpdateWidget(oldWidget);
  }

  _openDB() async {
    final db = await DBApi.open();
    setState(() {
      this.db = db;
      loadState = _LoadState.completed;
    });

    if (widget.importSejourURL != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showImportDialog(widget.importSejourURL!);
      });
    }
  }

  void _showImportDialogFromClipboard() async {
    final link = await Clipboard.getData("text/plain");
    final url = Uri.tryParse(link?.text ?? "");
    _showImportDialog(url);
  }

  /// if [url] is null, shows a notice
  void _showImportDialog(Uri? url) async {
    final db = this.db!;
    final hasMeals = (await db.getMeals()).isNotEmpty;
    if (!mounted) return;

    final doImport = await showDialog<Uri>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Importer un séjour"),
        content: Text(url != null
            ? """Importer depuis le lien : 

${url.toString()}

${hasMeals ? 'Attention, les repas en cours seront effacés.' : ''}
            """
            : "Vous pouvez importer un séjour depuis l'application Web en copiant le lien ou en scannant le QR code."),
        actions: [
          ElevatedButton(
            onPressed:
                url != null ? () => Navigator.of(context).pop(url) : null,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Importer"),
          )
        ],
      ),
    );

    if (doImport == null) return;

    setState(() {
      loadState = _LoadState.downloadingSejour;
    });
    final TablesM data;
    try {
      data = await _downloadSejour(doImport);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loadState = _LoadState.completed;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Impossible de télécharger le séjour: $e"),
        backgroundColor: Colors.red,
      ));
      return;
    }

    setState(() {
      loadState = _LoadState.importingSejour;
    });
    await db.importSejour(data);

    if (!mounted) return;
    setState(() {
      loadState = _LoadState.completed;
    });
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Séjour importé avec succès."),
      backgroundColor: Colors.green,
    ));
  }

  Future<TablesM> _downloadSejour(Uri url) async {
    final resp = await get(url);
    if (resp.statusCode != 200) throw "Réponse du serveur invalide";
    return tablesMFromJson(jsonDecode(resp.body));
  }

  @override
  Widget build(BuildContext context) {
    switch (loadState) {
      case _LoadState.completed:
        return NotificationListener<ImportSejourNotification>(
            onNotification: (_) {
              _showImportDialogFromClipboard();
              return false;
            },
            child: MealList(env, db!));
      case _LoadState.openingDB:
        return const Scaffold(
          body: Center(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Lecture de la base de données...")
            ],
          )),
        );
      case _LoadState.downloadingSejour:
        return const Scaffold(
          body: Center(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Téléchargement des données du séjour...")
            ],
          )),
        );
      case _LoadState.importingSejour:
        return const Scaffold(
          body: Center(
              child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 10),
              Text("Import des repas...")
            ],
          )),
        );
    }
  }
}
