import 'package:atable/components/meal_list.dart';
import 'package:atable/logic/env.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_sejours.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';

const env = Env(BuildMode.prod);
// const env = Env(BuildMode.dev);

void main() async {
  runApp(MaterialApp.router(
    title: 'Mesapi',
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

const _importLinkSaveKey = "import-sejour-link";

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
    final db = await DBApi.open(env.bm);
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

  void _showImportDialogFromApp() async {
    // first, try to read the saved path
    final prefs = await SharedPreferences.getInstance();

    var link = prefs.getString(_importLinkSaveKey) ?? "";
    if (link.isEmpty) {
      // default to clipboard
      final cp = await Clipboard.getData("text/plain");
      link = cp?.text ?? "";
    }

    final url = Uri.tryParse(link);
    _showImportDialog(url);
  }

  /// if [url] is null, shows a notice
  void _showImportDialog(Uri? url) async {
    // save the link for futur use
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_importLinkSaveKey, url?.toString() ?? "");

    final db = this.db!;
    final hasMeals = (await db.getMeals()).isNotEmpty;
    if (!mounted) return;

    final String content;
    if (url == null) {
      content =
          "Vous pouvez importer un séjour depuis l'application Web en copiant le lien ou en scannant le QR code.";
    } else {
      final sejour = url.queryParameters["sejour"] ?? "";
      content = """Importer le séjour $sejour : 

${url.toString()}

${hasMeals ? 'Attention, les repas en cours seront effacés.' : ''}
            """;
    }

    final doImport = await showDialog<Uri>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Importer un séjour"),
        content: Text(content),
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
    final json = jsonDecodeResp(resp);
    return tablesMFromJson(json);
  }

  @override
  Widget build(BuildContext context) {
    switch (loadState) {
      case _LoadState.completed:
        return NotificationListener<ImportSejourNotification>(
            onNotification: (_) {
              _showImportDialogFromApp();
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
