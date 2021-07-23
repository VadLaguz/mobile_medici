import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/fontelico_icons.dart';
import 'package:mobile_medici/model/Deck.dart';
import 'package:mobile_medici/shared_ui.dart';
import 'package:sliding_panel_pro/sliding_panel_pro.dart';
import 'package:universal_platform/universal_platform.dart';

class IChingSelectWidget extends StatefulWidget {
  var selectedHexes = <int>[];
  Function onUpdate;
  final gHex = [3, 4, 6, 9, 12, 18, 21, 23, 26, 28, 29, 36, 38, 39, 44, 47, 52];
  final neutralHexIdx = [
    35,
    7,
    8,
    15,
    20,
    22,
    27,
    30,
    32,
    33,
    41,
    48,
    51,
    54,
    57,
    62
  ];

  var positivehex = [
    1,
    10,
    11,
    13,
    14,
    16,
    17,
    19,
    25,
    31,
    34,
    35,
    37,
    40,
    42,
    43,
    45,
    46,
    49,
    50,
    53,
    55,
    56,
    58,
    59,
    60,
    61,
    63,
    64,
  ];

  IChingSelectWidget(this.selectedHexes, this.onUpdate);

  @override
  IChingSelectState createState() => IChingSelectState();
}

class IChingSelectState extends State<IChingSelectWidget> {
  @override
  Widget build(BuildContext context) {
    var widthFactor = isMobile() ? 1 : 0.8;
    var heightFactor = isMobile() ? 0.55 : 0.8;
    final width = MediaQuery.of(context).size.width * widthFactor;
    final height = MediaQuery.of(context).size.height * heightFactor;
    return Container(
      width: isLandscape(context) ? width : width,
      height: isLandscape(context) ? width : height,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.start,
              //mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                TextButton(
                    onPressed: () {
                      setState(() {
                        widget.selectedHexes.clear();
                        widget.selectedHexes.addAll(widget.positivehex);
                        widget.onUpdate();
                      });
                    },
                    child: Icon(Fontelico.emo_happy)),
                TextButton(
                    onPressed: () {
                      setState(() {
                        widget.selectedHexes.clear();
                        widget.selectedHexes.addAll(widget.gHex);
                        widget.onUpdate();
                      });
                    },
                    child: Icon(Fontelico.emo_unhappy)),
                TextButton(
                    onPressed: () {
                      setState(() {
                        widget.selectedHexes.clear();
                        widget.onUpdate();
                      });
                    },
                    child: Icon(FontAwesome.trash)),
                TextButton(
                    onPressed: () async {
                      final result = await showTextInputDialog(
                          style: AdaptiveStyle.material,
                          title: "Hexagrams list separated by space or comma",
                          context: context,
                          textFields: [
                            DialogTextField(
                                maxLines: 3,
                                hintText:
                                    "Example: 45  12  15  52  39  53  62  56  31  33")
                          ]);
                      if (result != null && result.first.length > 0) {
                        var split = result.first.replaceAll(",", "").split(" ");
                        setState(() {
                          widget.selectedHexes.clear();
                          split.forEach((element) {
                            try {
                              var hex = int.parse(element);
                              if (hex > 0 && hex <= 64) {
                                widget.selectedHexes.add(hex);
                              }
                            } catch (e) {}
                          });
                          widget.onUpdate();
                        });
                      }
                    },
                    child: Icon(FontAwesome.pencil)),
              ],
            ),
            Expanded(
              child: GridView.count(
                crossAxisCount:
                    isMobile() ? (isLandscape(context) ? 16 : 8) : 8,
                children: List.generate(64, (index) {
                  var number = index + 1;
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (widget.selectedHexes.contains(number)) {
                          widget.selectedHexes.remove(number);
                        } else {
                          widget.selectedHexes.add(number);
                        }
                        widget.onUpdate();
                      });
                    },
                    child: Container(
                      color: widget.selectedHexes.contains(number)
                          ? Colors.blue.withAlpha(200)
                          : Colors.transparent,
                      width: width,
                      child: Center(
                          child: Text(
                        "${index + 1}",
                        style: TextStyle(fontSize: 20, decoration: null),
                      )),
                    ),
                  );
                }),
              ),
            ),
            Row(
              children: [
                Expanded(
                    child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text("Close"),
                        ))),
              ],
            )
          ],
        ),
      ),
    );
  }
}
