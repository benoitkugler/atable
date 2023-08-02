import 'package:atable/components/shop_list.dart';
import 'package:atable/logic/env.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'dart:js' as js;

void main() async {
  // the static app is called via an url setting the session ID
  // note that the MaterialApp routing erase these parameters,
  // so that we need to fetch it early
  final uri = Uri.parse(js.context['location']['href'] as String);
  final sessionID = uri.queryParameters["sessionID"] ?? "";
  final isDev = uri.host == "localhost";
  runApp(ShopListGuestApp(
    sessionID,
    Env(isDev ? BuildMode.dev : BuildMode.prod),
  ));
}

/// [ShopListGuestApp] est une page web
/// permettant à un invité de rejoindre une session de courses.
class ShopListGuestApp extends StatelessWidget {
  final String sessionID;
  final Env env;

  const ShopListGuestApp(this.sessionID, this.env, {Key? key})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'A table - Liste de courses',
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
        home: ShopSessionGuest(env, sessionID));
  }
}
