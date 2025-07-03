import 'package:atable/logic/env.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/stock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class StockW extends StatefulWidget {
  final Env env;
  final DBApi db;

  const StockW(this.env, this.db, {super.key});

  @override
  State<StockW> createState() => _StockWState();
}

class _StockWState extends State<StockW> {
  Stock stock = [];

  @override
  void initState() {
    _loadStock();
    super.initState();
  }

  _loadStock() async {
    final l = await widget.db.getStock();
    setState(() => (stock = l));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Stock"),
      ),
      body: const Placeholder(),
    );
  }
}
