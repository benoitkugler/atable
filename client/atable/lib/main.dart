import 'dart:math';

import 'package:atable/logic/models.dart';
import 'package:atable/logic/sql.dart';
import 'package:flutter/material.dart';

void main() async {
  final db = await DBApi.open();
  runApp(MyApp(db));
}

class MyApp extends StatelessWidget {
  final DBApi db;
  const MyApp(this.db, {Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      // home: const ExampleHomePage(title: 'Flutter Demo Home Page'),
      home: Scaffold(
          appBar: AppBar(
            title: const Text("Ingrédients"),
          ),
          body: IngredientList(db)),
    );
  }
}

class ExampleHomePage extends StatefulWidget {
  const ExampleHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<ExampleHomePage> createState() => _ExampleHomePageState();
}

class _ExampleHomePageState extends State<ExampleHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class IngredientList extends StatefulWidget {
  final DBApi db;

  const IngredientList(this.db, {Key? key}) : super(key: key);

  @override
  State<IngredientList> createState() => _IngredientListState();
}

class _IngredientListState extends State<IngredientList> {
  List<Ingredient> ingredients = [];

  fetchIngredients() async {
    final l = await widget.db.getIngredients();
    setState(() {
      ingredients = l;
    });
  }

  addIngredient() async {
    var ing = Ingredient(
      id: 0,
      nom: "Nouvel Ingredient ${Random().nextInt(1000)}",
      unite: Unite.values[Random().nextInt(Unite.values.length)],
      categorie: CategorieIngredient
          .values[Random().nextInt(CategorieIngredient.values.length)],
    );
    ing = await widget.db.insertIngredient(ing);
    setState(() {
      ingredients.add(ing);
    });
  }

  deleteIngredient(Ingredient ing) async {
    await widget.db.deleteIngredient(ing.id);
    await fetchIngredients();
  }

  @override
  void initState() {
    fetchIngredients();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(onPressed: addIngredient, child: const Text("Ajouter")),
        Expanded(
          child: ListView(
              children: ingredients
                  .map((ing) => ListTile(
                        leading: Text(
                            ing.categorie == CategorieIngredient.inconnue
                                ? ""
                                : ing.categorie.name),
                        title: Text(ing.nom),
                        subtitle: Text(ing.unite.name),
                        trailing: IconButton(
                            onPressed: () => deleteIngredient(ing),
                            icon: const Icon(
                                IconData(0xe1b9, fontFamily: 'MaterialIcons'),
                                color: Colors.red)),
                      ))
                  .toList()),
        ),
      ],
    );
  }
}
