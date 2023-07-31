import 'dart:async';

import 'package:atable/logic/shop.dart';
import 'package:atable/logic/sql.dart';
import 'package:atable/logic/utils.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// ShopSessionMaster est utilisé pour une séance de course
/// par l'application maitre (mobile)
class ShopSessionMaster extends StatefulWidget {
  final List<MealExt> repass;

  const ShopSessionMaster(this.repass, {super.key});

  @override
  State<ShopSessionMaster> createState() => _ShopSessionMasterState();
}

class _ShopSessionMasterState extends State<ShopSessionMaster> {
  late ShopController shopController;

  @override
  void initState() {
    shopController = ShopControllerLocal(ShopList.fromMeals(widget.repass));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Liste de course"), actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _startSharing,
          )
        ]),
        body: _ShopListImpl(shopController));
  }

  _startSharing() async {
    if (shopController is ShopControllerShared) {
      // si la session est déjà partagée, on ré-utilise le même code
    } else {
      final ctL = shopController as ShopControllerLocal;
      // demande au serveur de créer une nouvelle session partagée
      try {
        final ct = await ShopControllerShared.createSession(ctL.list);
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

class _IngredientRow extends StatelessWidget {
  final IngredientQuantite ingredient;
  final void Function(int, bool) onUpdate;

  const _IngredientRow(this.ingredient, this.onUpdate, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !ingredient.checked,
      dense: true,
      leading: Text(ingredient.quantite),
      title: Text(ingredient.nom),
      onTap: () => onUpdate(ingredient.id, !ingredient.checked),
      trailing: Checkbox(
        activeColor: Colors.blue.shade100,
        checkColor: Colors.grey,
        value: ingredient.checked,
        onChanged: (value) => onUpdate(ingredient.id, value!),
      ),
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

  ShopList list = ShopList([]);

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
    }
  }
}

/// ShopSessionGuest est utilisé pour une session de course
/// par les applications invitées (web)
class ShopSessionGuest extends StatelessWidget {
  final String sessionID;

  const ShopSessionGuest(this.sessionID, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Liste de courses partagées")),
      body: sessionID.isEmpty
          ? const Center(child: Text("Aucun code de session."))
          : _ShopListImpl(ShopControllerShared(sessionID)),
    );
  }
}
