import 'package:flutter/material.dart';

class DismissibleDelete extends StatelessWidget {
  final int itemKey;
  final void Function() onDissmissed;
  final Widget child;

  final Future<bool> Function()? confirmDismiss;

  const DismissibleDelete(
      {required this.itemKey,
      required this.onDissmissed,
      required this.child,
      this.confirmDismiss,
      super.key});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: Key("$itemKey"),
        confirmDismiss: confirmDismiss != null
            ? (direction) async => await confirmDismiss!()
            : null,
        onDismissed: (direction) => onDissmissed(),
        background: Container(
          alignment: AlignmentDirectional.centerStart,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(5)),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        secondaryBackground: Container(
          alignment: AlignmentDirectional.centerEnd,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
              color: Colors.red, borderRadius: BorderRadius.circular(5)),
          child: const Padding(
            padding: EdgeInsets.all(8.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
        ),
        child: child);
  }
}
