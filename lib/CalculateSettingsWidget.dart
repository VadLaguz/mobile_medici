import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_medici/Helpers.dart';
import 'package:mobile_medici/model/Settings.dart';
import 'package:universal_platform/universal_platform.dart';

class CalculateSettingsWidget extends StatefulWidget {
  CalcSettings settings;
  Function callback;

  CalculateSettingsWidget(this.settings, this.callback);

  @override
  CalculateSettingsState createState() => CalculateSettingsState();
}

class CalculateSettingsState extends State<CalculateSettingsWidget> {
  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor:
          UniversalPlatform.isMacOS || UniversalPlatform.isWindows ? 0.6 : 0.9,
      child: ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(10)),
        child: Container(
            color: Colors.white,
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: (showThreads()
                            ? <Widget>[
                                Text(
                                  "Threads count: ${widget.settings.threads.toString()}\n(change only if you know what it is)",
                                  style: TextStyle(fontSize: 24),
                                ),
                                Slider(
                                  label: widget.settings.threads.toString(),
                                  min: 1,
                                  max: UniversalPlatform.isMacOS ? 12 : 8,
                                  value: widget.settings.threads.toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      widget.settings.threads = value.toInt();
                                    });
                                    widget.callback();
                                  },
                                )
                              ]
                            : <Widget>[]) +
                        [
                          Text(
                            "Max transits count: ${widget.settings.maxTransits == 0 ? "∞" : widget.settings.maxTransits.toString()}",
                            style: TextStyle(fontSize: 24),
                          ),
                          Slider(
                            label: widget.settings.maxTransits.toString(),
                            min: 0,
                            max: 35,
                            value: widget.settings.maxTransits.toDouble(),
                            onChanged: (value) {
                              setState(() {
                                widget.settings.maxTransits = value.toInt();
                              });
                              widget.callback();
                            },
                          ),
                          Text(
                            "Balance lines",
                            style: TextStyle(fontSize: 24),
                          ),
                        ] +
                        [
                          Wrap(
                            children: List<Widget>.generate(6, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text("#${index + 1}"),
                                    Checkbox(
                                      value:
                                          widget.settings.balance[index] == 1,
                                      onChanged: (value) {
                                        setState(() {
                                          widget.settings.balance[index] =
                                              widget.settings
                                                          .balance[index] ==
                                                      0
                                                  ? 1
                                                  : 0;
                                        });
                                        widget.callback();
                                      },
                                    )
                                  ],
                                ),
                              );
                            }),
                          )
                        ] +
                        [
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Reverse chains only"),
                            value: widget.settings.reverse,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.reverse =
                                    !widget.settings.reverse;
                              });
                              widget.callback();
                            },
                          ),
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text(
                                "Mirror by nominal or suit (first <-> last cards etc.)"),
                            value: widget.settings.mirror,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.mirror =
                                    !widget.settings.mirror;
                              });
                              widget.callback();
                            },
                          ),
                          /*
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Full Balanced"),
                            value: widget.settings.fullBalanced,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.fullBalanced =
                                    !widget.settings.fullBalanced;
                              });
                              widget.callback();
                            },
                          ),*/
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Only different hexes by suits"),
                            value: widget.settings.onlyDifferentHexes,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.onlyDifferentHexes =
                                    !widget.settings.onlyDifferentHexes;
                              });
                              widget.callback();
                            },
                          ),
                          CheckboxListTile(
                            controlAffinity: ListTileControlAffinity.leading,
                            title: Text("Print mobiles with asterisk"),
                            value: widget.settings.showMobiles,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.showMobiles =
                                    !widget.settings.showMobiles;
                              });
                              widget.callback();
                            },
                          ),
                          Row(
                            children: [
                              Expanded(
                                  child: TextButton(
                                      onPressed: () {
                                        setState(() {
                                          widget.settings.setDefault();
                                        });
                                        widget.callback();
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text("Defaults"),
                                      ))),
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
                ))),
      ),
    );
  }
}
