import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_medici/reorderables/src/widgets/reorderable_wrap.dart';
import 'package:range_slider_dialog/range_slider_dialog.dart';

import 'model/Deck.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Medici Calculator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Medici Calculator'),
    );
  }
}

List<IsolateInitializer> initializers = [];

class IsolateInitializer {
  late ReceivePort port;
  late int index;
  late Isolate isolate;
  var count = 0;
  Function onUpdate;

  IsolateInitializer(this.index, this.onUpdate) {
    port = ReceivePort();
    port.listen((message) {
      if (message is int) {
        count = message;
      } else if (message is Deck) {
        //message.printStats();
        onUpdate(message);
      }
    });
  }
}

void isolateFunc(List<Object> message) {
  SendPort port = message[1] as SendPort;
  List<CardItem> chainModel = message[2] as List<CardItem>;
  final deck = Deck();
  deck.setMaskByList(chainModel);
  var counter = 0;
  var circleWatch = Stopwatch()..start();
  while (true) {
    counter++;
    deck.shuffle();
    if (deck.check()) {
      var okDeck = true;
      deck.cards.forEach((element) {
        if (element.minMaxEfl != null) {
          final okCard = element.efl <= element.minMaxEfl!.end &&
              element.efl >= element.minMaxEfl!.start;
          if (!okCard) {
            okDeck = false;
          }
        }
      });
      if (okDeck) {
        port.send(deck);
      }
    }
    if (circleWatch.elapsedMilliseconds >= 1000) {
      circleWatch.reset();
      port.send(counter);
      counter = 0;
    }
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }
}

class _MyHomePageState extends State<MyHomePage> {
  var chainModel = <CardItem>[];
  Timer? timer;
  var calculating = false;
  var foundItems = <Deck>[];
  var selectedItem = -1;
  var checkedCount = 0;
  var speed = 0;

  void stop() {
    if (initializers.isNotEmpty) {
      timer!.cancel();
      print("Stopping ${initializers.length} threads");
      initializers.forEach((element) {
        element.isolate.kill(priority: Isolate.immediate);
      });
    }
    initializers.clear();
  }

  void doSpawn(List<CardItem> chain) {
    if (initializers.isNotEmpty) {
      timer!.cancel();
      print("Stopping ${initializers.length} threads");
      initializers.forEach((element) {
        element.isolate.kill(priority: Isolate.immediate);
      });
      return;
    }
    List.generate(5, (index) async {
      var isolateInitializer = IsolateInitializer(index, (Deck param) {
        setState(() {
          foundItems.insert(0, param);
        });
      });
      initializers.add(isolateInitializer);
      isolateInitializer.isolate = await Isolate.spawn(
          isolateFunc, [index, isolateInitializer.port.sendPort, chain]);
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      var sum = initializers.fold<int>(
          0, (previousValue, element) => previousValue + element.count);
      setState(() {
        checkedCount += sum;
        speed = sum;
      });
      print("Computed $sum chains in second");
    });
  }

  void onReorder(int oldIndex, int newIndex) {
    setState(() {
      chainModel.insert(newIndex, chainModel.removeAt(oldIndex));
    });
  }

  @override
  void initState() {
    super.initState();
    resetChain();
  }

  void resetChain() {
    checkedCount = 0;
    selectedItem = -1;
    speed = 0;
    chainModel.clear();
    Nominal.values.forEach((nom) {
      CardSuit.values.forEach((suit) {
        chainModel.add(CardItem(suit, nom));
      });
    });
    foundItems.clear();
  }

  List<Widget> makeTiles() {
    var tiles = <Widget>[];
    final replace = {
      "two": "2",
      "three": "3",
      "four": "4",
      "five": "5",
      "six": "6",
      "seven": "7",
      "eight": "8",
      "nine": "9",
      "ten": "10",
    };
    chainModel.forEach((element) {
      var name =
          "${element.nominal.toString().toLowerCase().replaceAll("nominal.", "")}_of_${element.suit.toString().toLowerCase().replaceAll("cardsuit.", "")}.png";
      replace.forEach((key, value) {
        name = name.replaceAll(key, value);
      });
      final width = MediaQuery.of(context).size.width / 14;
      final height = width * 1.3;
      var efl = element.minMaxEfl;
      var card = GestureDetector(
          onTap: () {
            setState(() {
              element.fixed = !element.fixed;
            });
          },
          child: Container(
            color: element.fixed ? Colors.blue : Colors.transparent,
            width: width,
            height: height,
            child: Card(
                child: Column(
              children: [
                Container(
                  height: height / 1.3,
                  child: Image.asset(
                    "assets/cards/$name",
                    fit: BoxFit.scaleDown,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: width,
                    color: Colors.white,
                    child: InkWell(
                      onTap: () {
                        eflDialog(context, element, () {
                          setState(() {});
                        });
                      },
                      child: Center(
                        child: Text(
                          efl == null
                              ? "️😎"
                              : "😎 ${efl.start.toInt()} - ${efl.end.toInt()}",
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )),
          ));
      tiles.add(card);
    });
    return tiles;
  }

  Future<void> eflDialog(
      BuildContext context, CardItem item, Function onSet) async {
    //return Future<Void>.;
    await RangeSliderDialog.display<int>(context,
        minValue: 0,
        width: Platform.isWindows || Platform.isMacOS || Platform.isLinux
            ? MediaQuery.of(context).size.width / 2
            : null,
        maxValue: chainModel.length,
        acceptButtonText: 'OK',
        cancelButtonText: 'Cancel',
        headerText: 'Set Min And Max EFL',
        selectedRangeValues:
            item.minMaxEfl ?? RangeValues(0, chainModel.length.toDouble()),
        onApplyButtonClick: (value) {
      onSet();
      if (value != null && value.start == 0) {
        item.minMaxEfl = null;
      } else {
        item.minMaxEfl = value;
      }
      Navigator.pop(context);
    });
  }

  void calculate() {
    if (calculating) {
      stop();
      setState(() {
        calculating = false;
      });
    } else {
      selectedItem = -1;
      foundItems.clear();
      doSpawn(chainModel);
      setState(() {
        speed = 0;
        checkedCount = 0;
        calculating = true;
      });
    }
  }

  var scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    makeTiles();
    var wrap = ReorderableWrap(
        spacing: 0.0,
        runSpacing: 0.0,
        maxMainAxisCount: 12,
        needsLongPressDraggable: false,
        padding: const EdgeInsets.all(4),
        children: makeTiles(),
        controller: scrollController,
        buildDraggableFeedback: (context, constraints, child) => Container(
              child: child,
              color: Colors.transparent,
            ),
        onNoReorder: (int index) {
          //this callback is optional
          /*debugPrint(
              '${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');*/
        },
        onReorderStarted: (int index) {
          //this callback is optional
          /*debugPrint(
              '${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');*/
        },
        onReorder: onReorder);

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          child: Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.max,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        wrap,
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                                onPressed: () {
                                  calculate();
                                },
                                child: Text(
                                  calculating ? "🛑" : "🎲",
                                  style: TextStyle(fontSize: 48),
                                )),
                            TextButton(
                                onPressed: () async {
                                  var result = await showOkCancelAlertDialog(
                                      context: context,
                                      title: "Clear? Really?");
                                  if (result == OkCancelResult.ok) {
                                    setState(() {
                                      resetChain();
                                    });
                                  }
                                },
                                child: Text(
                                  "🗑",
                                  style: TextStyle(fontSize: 48),
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        child: ListView.builder(
                          itemBuilder: (context, index) {
                            var asString = foundItems[index].asString(true);
                            return InkWell(
                              onTap: () {
                                setState(() {
                                  selectedItem = index;
                                });
                              },
                              child: Container(
                                  color: selectedItem == index
                                      ? Colors.blue.withAlpha(100)
                                      : Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Text(asString),
                                  )),
                            );
                          },
                          itemCount: foundItems.length,
                        ),
                      ),
                    ),
                    Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              checkedCount > 0
                                  ? Text(
                                      "Checked: $checkedCount ($speed / sec.)\nFound: ${foundItems.length}")
                                  : Container(),
                              selectedItem >= 0
                                  ? TextButton(
                                      onPressed: () {
                                        Clipboard.setData(ClipboardData(
                                            text: foundItems[selectedItem]
                                                .asString(true)));
                                      },
                                      child: Text("Копировать"))
                                  : Container()
                            ],
                          ),
                        ))
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
