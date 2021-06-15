import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_medici/Helpers.dart';

import 'BalanceWidget.dart';
import 'model/Deck.dart';

class AdvancedHexSelectWidget extends StatefulWidget {
  @override
  State createState() {
    return AdvancedHexSelectWidgetState();
  }
}

class AdvancedHexSelectWidgetState extends State<AdvancedHexSelectWidget> {
  var items = <Widget>[];

  @override
  void initState() {
    super.initState();
    items = suitsList.map((e) {
      return Expanded(
        child: generateHexWidget(Hex(), e, context),
        flex: 1,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Advanced HEX filtering"),
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) => items[index],
      ),
    );
  }
}
