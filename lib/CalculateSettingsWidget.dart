import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:mobile_medici/Helpers.dart';
import 'package:mobile_medici/model/Settings.dart';

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
      widthFactor: 0.6,
      child: Material(
          child: Container(
              color: Colors.white,
              child: Padding(
                  padding: const EdgeInsets.all(8.0),
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
                                  max: Platform.isMacOS ? 12 : 8,
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
                            title: Text("Full Balanced"),
                            value: widget.settings.fullBalanced,
                            onChanged: (value) {
                              setState(() {
                                widget.settings.fullBalanced =
                                    !widget.settings.fullBalanced;
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
                                        child: Text("🗑"),
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
                  )))),
    );
  }
}
