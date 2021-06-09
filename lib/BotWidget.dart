import 'package:date_time_picker/date_time_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:group_button/group_button.dart';
import 'package:http/http.dart';
import 'package:intl/intl.dart';
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

  Future<void> doRequest() async {
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
      if (await canLaunch(r.body)) {
        await launch(r.body);
      } else {
        print("cant launch url");
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
    return Material(
      child: FractionallySizedBox(
        widthFactor: isLandscape(context) ? 0.5 : 0.8,
        child: Container(
          color: Colors.white,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
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
                    onSelected: (index, isSelected) =>
                        timingType = timingType + 1,
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
                                doRequest();
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
  }
}
