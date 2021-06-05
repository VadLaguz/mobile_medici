import 'package:flutter/cupertino.dart';
import 'package:mobile_medici/model/Deck.dart';

class BalanceWidget extends StatefulWidget {
  final Map<CardSuit, String> hex;

  BalanceWidget(this.hex);

  @override
  State<StatefulWidget> createState() {
    return BalanceWidgetState();
  }
}

class BalanceWidgetState extends State<BalanceWidget> {
  @override
  Widget build(BuildContext context) {
    return Wrap(
        /* children: widget.hex.keys.map<Widget>((suit) {
        final hex = widget.hex[suit];
        return Column(
          children: List.generate(6, (index) {
            var val =
            return Row(children: [],);
          }),
        );
      }).toList(),*/
        );
  }
}
