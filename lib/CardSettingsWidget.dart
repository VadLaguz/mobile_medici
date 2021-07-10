import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:universal_platform/universal_platform.dart';

class CardSettingsWidget extends StatefulWidget {
  final SfRangeValues? minMaxEFL;
  final int minDistance;
  final Null Function(SfRangeValues, int) callback;

  CardSettingsWidget(this.minMaxEFL, this.minDistance, this.callback);

  @override
  State createState() {
    var cardSettingsState = CardSettingsState();
    cardSettingsState.distanceValue = minDistance.toDouble();
    cardSettingsState.eflValues = minMaxEFL != null
        ? SfRangeValues(minMaxEFL!.start, minMaxEFL!.end)
        : SfRangeValues(0, 34);
    return cardSettingsState;
  }
}

class CardSettingsState extends State<CardSettingsWidget> {
  late SfRangeValues eflValues;
  double distanceValue = 0;

  @override
  Widget build(BuildContext context) {
    final width = UniversalPlatform.isWindows ||
            UniversalPlatform.isMacOS ||
            UniversalPlatform.isLinux
        ? MediaQuery.of(context).size.width / 2
        : MediaQuery.of(context).size.height * 0.8;

    final height = MediaQuery.of(context).size.height * 0.8;

    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(10)),
      child: Container(
        color: Colors.transparent,
        width: width,
        child: Material(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Min & Max EFL",
                  style: TextStyle(fontSize: 24),
                ),
                SfRangeSlider(
                  stepSize: 1,
                  min: 0.0,
                  max: 34.0,
                  values: eflValues,
                  interval: 10,
                  showTicks: true,
                  showLabels: true,
                  enableTooltip: true,
                  minorTicksPerInterval: 0,
                  onChanged: (value) {
                    setState(() {
                      eflValues = value;
                    });
                  },
                ),
                SizedBox(
                  height: 24,
                ),
                Text(
                  "Min distance to previous transit",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24),
                ),
                SfSlider(
                  stepSize: 1,
                  min: 0.0,
                  max: 35.0,
                  value: distanceValue,
                  interval: 10,
                  showTicks: true,
                  showLabels: true,
                  enableTooltip: true,
                  minorTicksPerInterval: 0,
                  onChanged: (value) {
                    setState(() {
                      distanceValue = value;
                    });
                  },
                ),
                SizedBox(
                  height: 24,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                        onPressed: () {
                          widget.callback(eflValues, distanceValue.toInt());
                          Navigator.pop(context);
                        },
                        child: Text(
                          "OK",
                          style: TextStyle(fontSize: 24),
                        )),
                    TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: Text(
                          "Cancel",
                          style: TextStyle(fontSize: 24),
                        )),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
