import 'package:flutter/cupertino.dart';
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
  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: suitsList.map((e) {
        return generateHexWidget(Hex(), e, context);
      }).toList(),
    );
  }
}
