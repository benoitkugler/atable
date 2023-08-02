import 'dart:async';

import 'package:atable/logic/env.dart';
import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:atable/logic/types/stdlib_github.com_benoitkugler_atable_controllers_shop-session.dart';

/// ShopSessionMaster est utilisé pour une séance de course
/// par l'application maitre (mobile)
class ShopSessionMaster extends StatefulWidget {
  final Env env;
  final List<MealExt> repass;

  const ShopSessionMaster(this.env, this.repass, {super.key});

  @override
  State<ShopSessionMaster> createState() => _ShopSessionMasterState();
}

class _ShopSessionMasterState extends State<ShopSessionMaster> {
  late ShopController shopController;

  @override
  void initState() {
    shopController = ShopControllerLocal(ShopListW.fromMeals(widget.repass));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final ct = shopController;
        if (ct is ShopControllerLocal) {
          if (!ct.list.isStarted) return true;
        }

        final res = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
                    title: const Text("Confirmation"),
                    content: const Text(
                        "Souhaitez-vous vraiment quitter la session de courses ? Sa progression sera perdue."),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: TextButton.styleFrom(
                            foregroundColor: Colors.orange),
                        child: const Text("Quitter"),
                      )
                    ]));
        return res ?? false;
      },
      child: Scaffold(
          appBar: AppBar(title: const Text("Liste de course"), actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: _startSharing,
            )
          ]),
          body: _ShopListImpl(shopController)),
    );
  }

  _startSharing() async {
    if (shopController is ShopControllerShared) {
      // si la session est déjà partagée, on ré-utilise le même code
    } else {
      final ctL = shopController as ShopControllerLocal;
      // demande au serveur de créer une nouvelle session partagée
      try {
        final ct =
            await ShopControllerShared.createSession(widget.env, ctL.list);
        setState(() {
          shopController = ct;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Erreur pendant le partage :\n$e"),
          backgroundColor: Colors.red,
        ));
        return;
      }
    }
    final c = shopController as ShopControllerShared;

    if (!mounted) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => _ShareQRCode(c.guestURL()),
    ));
  }
}

class _ShopSection extends StatelessWidget {
  final ShopSection section;
  final void Function(int, bool) onUpdate;

  const _ShopSection(this.section, this.onUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: section.isDone ? Colors.green.shade100 : Colors.yellow.shade100,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                formatIngredientKind(section.categorie),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Column(
              children: section.ingredients
                  .map((e) => _IngredientRow(e, onUpdate))
                  .toList(),
            )
          ],
        ),
      ),
    );
  }
}

String formatQuantites(CQuantites quantite) {
  return quantite.map((e) => formatQuantiteU(e.value, e.key)).join(" et ");
}

class _IngredientRow extends StatefulWidget {
  final IngredientUses ingredient;
  final void Function(int, bool) onUpdate;

  const _IngredientRow(this.ingredient, this.onUpdate, {super.key});

  @override
  State<_IngredientRow> createState() => _IngredientRowState();
}

class _IngredientRowState extends State<_IngredientRow> {
  bool showUses = false;
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExpansionTile(
          leading: Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(formatQuantites(widget.ingredient.compile())),
          ),
          title: Text(widget.ingredient.ingredient.name),
          onExpansionChanged: (b) => setState(() => showUses = b),
          trailing: Checkbox(
            activeColor: Colors.blue.shade100,
            checkColor: Colors.grey,
            value: widget.ingredient.checked,
            onChanged: (value) =>
                widget.onUpdate(widget.ingredient.ingredient.id, value!),
          ),
          children: widget.ingredient.quantites
              .map((use) => ListTile(
                    dense: true,
                    titleAlignment: ListTileTitleAlignment.center,
                    leading: Text(formatQuantiteU(use.quantite, use.unite)),
                    title: Text(formatDate(use.origin.mealDate)),
                    subtitle: Text(use.origin.mealName),
                    trailing: use.origin.receipeName.isEmpty
                        ? null
                        : Text(use.origin.receipeName),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _ShareQRCode extends StatelessWidget {
  final String url;

  const _ShareQRCode(this.url, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Partager la liste"),
      ),
      body: Center(
        child: QrImageView(
          data: url,
          version: QrVersions.auto,
          // size: 200.0,
        ),
      ),
    );
  }
}

class _ShopListImpl extends StatefulWidget {
  final ShopController controller;

  const _ShopListImpl(this.controller, {super.key});

  @override
  State<_ShopListImpl> createState() => _ShopListImplState();
}

class _ShopListImplState extends State<_ShopListImpl> {
  late final Timer timer;
  int nbFails = 0;

  ShopListW list = ShopListW([]);

  @override
  void initState() {
    _refreshList();
    timer = Timer.periodic(const Duration(seconds: 2), (t) => _refreshList());
    super.initState();
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = list.bySections();
    return ListView.builder(
      itemBuilder: (context, index) =>
          _ShopSection(sections[index], _updateChecked),
      itemCount: sections.length,
    );
  }

  void _updateChecked(int id, bool checked) async {
    final l = await widget.controller.updateShop(id, checked);
    setState(() {
      list = l;
    });
  }

  void _refreshList() async {
    try {
      final l = await widget.controller.fetchList();
      setState(() {
        list = l;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Erreur :\n$e"),
        backgroundColor: Colors.red,
      ));
      // if the session in closed on the server,
      // do not repeat client calls
      nbFails += 1;
      if (nbFails >= 3) {
        timer.cancel();
      }
    }
  }
}

/// ShopSessionGuest est utilisé pour une session de course
/// par les applications invitées (web)
class ShopSessionGuest extends StatelessWidget {
  final Env env;
  final String sessionID;

  const ShopSessionGuest(this.env, this.sessionID, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste de courses partagées")),
      body: sessionID.isEmpty
          ? const Center(child: Text("Aucun code de session."))
          : _ShopListImpl(ShopControllerShared(env, sessionID)),
    );
  }
}
