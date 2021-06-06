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
  /*Widget generateHexWidget(Hex hex) {

  }*/

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.center,
                children: suitsList.map<Widget>((suit) {
                  final hex = deck.hex[suit];
                  final suitColor = [
                    Colors.pink,
                    Colors.orange,
                    Colors.blueAccent,
                    Colors.black45,
                  ][suit.index]
                      .withAlpha(150);
                  var lineWidth = 100.0;
                  var lineSpacing = 10.0;
                  var lineHeight = 10.0;
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                              Text(
                                "${suitIcons[suitsList.indexOf(suit)]}",
                                style: TextStyle(fontSize: 24),
                              ),
                              Container(
                                width: 0,
                                height: 8,
                              ),
                            ] +
                            List.generate(hex!.data.length, (index) {
                              var line = hex.data[hex.data.length - index - 1]!;
                              var widgets = <Widget>[];
                              var boxDecoration = BoxDecoration(
                                  color: suitColor,
                                  boxShadow: [
                                    /*BoxShadow(
                                      color: Colors.grey.withOpacity(0.5),
                                      spreadRadius: 1,
                                      blurRadius: 4,
                                      offset: Offset(0, 1),
                                    ),*/
                                  ],
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(5)));
                              var cardsToHexLine = cardsToHexLines[
                                  cardsToHexLines.length - index - 1];
                              widgets = cardsToHexLine!.map<Widget>((e) {
                                var color = line.first
                                    ? Colors.yellow
                                    : Colors.cyanAccent;
                                if (line.length > 1) {
                                  if (cardsToHexLine.first == e) {
                                    color = line.first
                                        ? Colors.yellow
                                        : Colors.cyanAccent;
                                  } else {
                                    color = line.last
                                        ? Colors.yellow
                                        : Colors.cyanAccent;
                                  }
                                }
                                return Container(
                                  decoration: boxDecoration.copyWith(
                                      color: color,
                                      borderRadius:
                                          BorderRadius.all(Radius.circular(2))),
                                  width: cardsToHexLine.length == 1
                                      ? lineWidth / 5
                                      : lineWidth / 10,
                                  height: lineHeight,
                                  child: Center(
                                    child: Text(
                                      nominalsToLang()[e],
                                      style: TextStyle(fontSize: 8),
                                    ),
                                  ),
                                );
                              }).toList();
                              if (line.first) {
                                widgets += [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          decoration: boxDecoration,
                                          width: lineWidth,
                                          height: lineHeight,
                                        )
                                      ],
                                    ),
                                  )
                                ];
                              } else {
                                widgets += [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width:
                                              lineWidth / 2 - (lineSpacing / 2),
                                          height: lineHeight,
                                          decoration: boxDecoration,
                                        ),
                                        Container(
                                          width: lineSpacing,
                                        ),
                                        Container(
                                          width:
                                              lineWidth / 2 - (lineSpacing / 2),
                                          height: lineHeight,
                                          decoration: boxDecoration,
                                        ),
                                      ],
                                    ),
                                  )
                                ];
                              }
                              return Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: widgets,
                                mainAxisSize: MainAxisSize.min,
                              );
                            })),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
