import 'dart:io';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
import 'package:keyboard_actions/keyboard_actions.dart';
import 'package:mobile_medici/model/Deck.dart';
import 'package:mobile_medici/shared_ui.dart';
import 'package:url_launcher/url_launcher.dart';

class BotWidget extends StatefulWidget {
  final Deck item;

  BotWidget(this.item);

  @override
  State createState() {
    return BotWidgetState();
  }
}

class BotWidgetState extends State<BotWidget> {
  final FocusNode _nodeText1 = FocusNode();
  final FocusNode _nodeText2 = FocusNode();
  final FocusNode _nodeText3 = FocusNode();

  KeyboardActionsConfig _buildConfig(BuildContext context) {
    return KeyboardActionsConfig(
      keyboardActionsPlatform: KeyboardActionsPlatform.ALL,
      keyboardBarColor: Colors.grey[200],
      nextFocus: true,
      actions: [
        KeyboardActionsItem(
          focusNode: _nodeText1,
          toolbarButtons: [
            //button 1
            (node) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "DONE",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
          ],
        ),
        KeyboardActionsItem(
          focusNode: _nodeText2,
          toolbarButtons: [
            //button 1
            (node) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "DONE",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
          ],
        ),
        KeyboardActionsItem(
          focusNode: _nodeText3,
          toolbarButtons: [
            //button 1
            (node) {
              return GestureDetector(
                onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                child: Container(
                  padding: EdgeInsets.all(8.0),
                  child: Text(
                    "DONE",
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
              );
            },
          ],
        ),
      ],
    );
  }

  var date = DateTime.now();
  var dateFormat = 'yyyy MM dd';
  var hourFormat = 'HH mm';
  late TextEditingController controller =
      TextEditingController(text: DateTime.now().toString());
  late TextEditingController timeZoneController =
      TextEditingController(text: "+" + date.timeZoneOffset.inHours.toString());
  var dayCardsCountController = TextEditingController(text: "36");
  var timingController = TextEditingController(text: "20");
  final format = DateFormat('yyyy-MM-dd HH:mm');
  final formatNetwork = DateFormat('yyyy MM dd HH mm');
  var timingType = 1;
  var isLoading = false;

  Future<void> doRequest(BuildContext context) async {
    Map<String, String> body = {
      'ce': widget.item.asShortString(),
      'p1': formatNetwork.format(date),
      'p2': timeZoneController.text,
      'p3': dayCardsCountController.text,
      'p4': timingController.text,
      'p5': timingType.toString(),
    };
    setState(() {
      isLoading = true;
    });
    try {
      Response r = await post(
        Uri.parse("https://doha.plus/ce/api.php"),
        body: body,
      );
      print(r.body);
      if (Platform.isAndroid || await canLaunch(r.body)) {
        await launch(r.body);
        FocusManager.instance.primaryFocus?.unfocus();
        //Navigator.pop(context);
      } else {
        //print("cant launch url");
        showAlertDialog(
            context: context,
            title: "Error",
            message: "Unhandled error, try again",
            actions: [AlertDialogAction(key: 1, label: "OK 🤨")]);
      }
    } catch (e) {
      print(e);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var titleStyle = TextStyle(fontSize: 18);

    var content = Material(
      child: GestureDetector(
        onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Chain start date and time",
                    style: titleStyle,
                  ),
                  DateTimePicker(
                    controller: controller,
                    type: DateTimePickerType.dateTimeSeparate,
                    timeLabelText: "Time",
                    //dateMask: dateFormat,
                    firstDate: date,
                    lastDate: DateTime(2100),
                    dateLabelText: 'Date',
                    validator: (val) {
                      return null;
                    },
                    onChanged: (value) {
                      date = format.parse(value);
                    },
                    onSaved: (val) {
                      print(val);
                    },
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "TimeZone",
                    style: titleStyle,
                  ),
                  TextField(
                    focusNode: _nodeText1,
                    keyboardType: TextInputType.number,
                    controller: timeZoneController,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Day cards count",
                    style: titleStyle,
                  ),
                  TextField(
                    focusNode: _nodeText2,
                    keyboardType: TextInputType.number,
                    controller: dayCardsCountController,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Timing in minutes",
                    style: titleStyle,
                  ),
                  TextField(
                    focusNode: _nodeText3,
                    keyboardType: TextInputType.number,
                    controller: timingController,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Text(
                    "Timing type",
                    style: titleStyle,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  GroupButton(
                    isRadio: true,
                    spacing: 10,
                    selectedButton: 0,
                    onSelected: (index, isSelected) => timingType = index + 1,
                    buttons: ["Default", "Tuning-fork", "Manual"],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                          flex: 1,
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: TextButton(
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  Navigator.pop(context);
                                },
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(fontSize: 20),
                                )),
                          )),
                      Expanded(
                        flex: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextButton(
                              onPressed: () {
                                doRequest(context);
                              },
                              child: isLoading
                                  ? CircularProgressIndicator()
                                  : Text(
                                      "Open Telegram",
                                      style: TextStyle(fontSize: 20),
                                    )),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400, maxHeight: 450),
      child: isMobile()
          ? KeyboardActions(config: _buildConfig(context), child: content)
          : Container(
              child: content,
            ),
    );
  }
}
