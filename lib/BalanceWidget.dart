import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_medici/model/Deck.dart';

import 'Helpers.dart';

class BalanceWidget extends StatefulWidget {
  final Deck deck;

  BalanceWidget(this.deck);

  @override
  State<StatefulWidget> createState() {
    return BalanceWidgetState();
  }
}

class BalanceWidgetState extends State<BalanceWidget> {
  Widget generateHexWidget(Hex hex, CardSuit suit) {
    final suitColor = suitColors[suit.index];
    final strongColor = suitColor;
    final weakColor = Colors.black.withAlpha(30);
    var suitIndex = suitsList.indexOf(suit);

    var lineHeight = 15.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
                Icon(
                  suitIconsData[suitIndex],
                  color: suitColor,
                  size: 30,
                ),
                Container(
                  width: 0,
                  height: 8,
                ),
              ] +
              List.generate(hex.data.length, (index) {
                var line = hex.data[hex.data.length - index - 1]!;
                var widgets = <Widget>[];
                var boxDecoration = BoxDecoration(
                    color: suitColor,
                    borderRadius: BorderRadius.all(Radius.circular(5)));

                var cardsToHexLine =
                    cardsToHexLines[cardsToHexLines.length - index - 1];
                widgets = List<Widget>.generate(2, (index) {
                  var color = line.first ? strongColor : weakColor;
                  var e = index < cardsToHexLine!.length
                      ? cardsToHexLine[index]
                      : null;

                  if (line.length > 1) {
                    if (cardsToHexLine.first == e) {
                      color = line.first ? strongColor : weakColor;
                    } else {
                      color = line.last ? strongColor : weakColor;
                    }
                  }
                  return Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: Container(
                      decoration: boxDecoration.copyWith(
                          color: e == null ? Colors.transparent : color,
                          borderRadius: BorderRadius.all(Radius.circular(5))),
                      height: lineHeight,
                      child: Center(
                        child: Text(
                          e == null ? "0" : nominalsToLang()[e],
                          style: TextStyle(
                              color: e == null
                                  ? Colors.transparent
                                  : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  );
                }).toList();

                if (line.first) {
                  widgets += [
                    Expanded(
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Container(
                            decoration: boxDecoration,
                            height: lineHeight,
                          )),
                    )
                  ];
                } else {
                  widgets += [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Expanded(
                              flex: 8,
                              child: Container(
                                height: lineHeight,
                                decoration: boxDecoration,
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Container(),
                            ),
                            Expanded(
                              flex: 8,
                              child: Container(
                                height: lineHeight,
                                decoration: boxDecoration,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  ];
                }
                return Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: widgets,
                  mainAxisSize: MainAxisSize.max,
                );
              }) +
              [
                Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    hex.localizedName(MediaQuery.of(context).orientation == Orientation.landscape),
                    maxLines: 2,
                    textAlign: TextAlign.center,
                  ),
                )
              ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: suitsList.map<Widget>((suit) {
            final hex = deck.hex[suit];
            return Expanded(
              child: generateHexWidget(hex!, suit),
              flex: 1,
            );
          }).toList(),
        );
      },
    );
  }
}
