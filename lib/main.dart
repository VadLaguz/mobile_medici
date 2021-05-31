import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_medici/reorderables/src/widgets/reorderable_wrap.dart';
import 'package:range_slider_dialog/range_slider_dialog.dart';

import 'IChingSelectWidget.dart';
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
  DeckTask task = message[2] as DeckTask;
  final deck = Deck();
  deck.setMaskByList(task.mask);
  deck.needHex = task.needHex;
  var counter = 0;
  var circleWatch = Stopwatch()..start();
  while (true) {
    counter++;
    deck.shuffle();
    if (deck.check()) {
      port.send(deck);
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
  Map<CardSuit, List<int>> needHex = {};
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
    initializers.clear();
    List.generate(5, (index) async {
      var isolateInitializer = IsolateInitializer(index, (Deck param) {
        setState(() {
          foundItems.insert(0, param);
        });
      });
      initializers.add(isolateInitializer);
      var deckTask = DeckTask(chain, needHex);
      isolateInitializer.isolate = await Isolate.spawn(
          isolateFunc, [index, isolateInitializer.port.sendPort, deckTask]);
    });
    timer = Timer.periodic(Duration(seconds: 1), (timer) {
      var sum = initializers.fold<int>(
          0, (previousValue, element) => previousValue + element.count);
      setState(() {
        checkedCount += sum;
        speed = sum;
      });
      //print("Computed $sum chains in second");
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
    needHex = {};
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

  void clearResults() {
    selectedItem = -1;
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
      final width = MediaQuery.of(context).size.width / 13;
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
                elevation: 5,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4.0),
                  child: Container(
                    height: height / 1.3,
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(0.0),
                          child: Image.asset(
                            "assets/cards/$name",
                            fit: BoxFit.cover,
                          ),
                        ),
                        FractionallySizedBox(
                          heightFactor: 0.2,
                          child: Column(
                            children: [
                              Container(
                                height: 1,
                                color: Colors.black12,
                              ),
                              Expanded(
                                child: Container(
                                  color: Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      eflDialog(context, element, () {
                                        setState(() {});
                                      });
                                    },
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: Text(
                                          efl == null
                                              ? "️⚙️"
                                              : "⚡️ ${efl.start.toInt()} - ${efl.end.toInt()}",
                                          style: TextStyle(
                                              fontSize: 18,
                                              color: Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
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

  void setIChing(BuildContext context, CardSuit suit) {
    if (needHex[suit] == null) {
      needHex[suit] = [];
    }
    showDialog(
      context: context,
      builder: (context) {
        return Center(
            child: IChingSelectWidget(needHex[suit]!, () {
          setState(() {
            print(suit);
            print(needHex[suit]);
          });
        }));
      },
    );
  }

  List<Widget> iChingButtons(BuildContext context) {
    var suits = [
      CardSuit.hearts,
      CardSuit.diamonds,
      CardSuit.spades,
      CardSuit.clubs
    ];
    return List.generate(4, (index) {
      var suit = suits[index];
      return Stack(
        children: [
          TextButton(
              onPressed: () async {
                setIChing(context, suit);
              },
              child: Text(
                ["♥️", "♦️️", "♠️️️", "♣️️"][index],
                style: TextStyle(fontSize: 48),
              )),
          IgnorePointer(
            child: Container(
              width: 10,
              height: 10,
              color: (needHex[suit] ?? []).length == 0
                  ? Colors.transparent
                  : Colors.red,
            ),
          )
        ],
        alignment: Alignment.center,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    makeTiles();
    var wrap = ReorderableWrap(
        spacing: 0.0,
        runSpacing: 0.0,
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
        appBar: MediaQuery.of(context).orientation == Orientation.portrait
            ? AppBar(
                title: Text("Medici Calculator"),
              )
            : null,
        body: Padding(
          padding:  EdgeInsets.only(top: MediaQuery.of(context).orientation == Orientation.landscape && Platform.isAndroid ? 20 : 0),
          child: Container(
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
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                                "$checkedCount ($speed / sec.), ${foundItems.length} found"),
                          ),
                          Wrap(
                            children: iChingButtons(context) +
                                [
                                  TextButton(
                                      onPressed: () {
                                        calculate();
                                      },
                                      child: Text(
                                        calculating ? "🛑" : "🚀",
                                        style: TextStyle(fontSize: 48),
                                      )),
                                  TextButton(
                                      onPressed: () async {
                                        var result = await showAlertDialog(
                                            actions: [
                                              AlertDialogAction(
                                                  key: 1,
                                                  label: "Clear results"),
                                              AlertDialogAction(
                                                  key: 2,
                                                  label:
                                                      "Clear Task & Results"),
                                              AlertDialogAction(
                                                  key: 3, label: "Cancel")
                                            ],
                                            context: context,
                                            title: "Clear? Really?");
                                        if (result == 1) {
                                          setState(() {
                                            clearResults();
                                          });
                                        } else if (result == 2) {
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
                        child: Card(
                          elevation: 2,
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
                      ),
                      Expanded(
                          flex: 2,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 8),
                            child: Card(
                              elevation: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  selectedItem >= 0
                                      ? TextButton(
                                          onPressed: () {
                                            Clipboard.setData(ClipboardData(
                                                text: foundItems[selectedItem]
                                                    .asString(true)));
                                          },
                                          child: Padding(
                                            padding: const EdgeInsets.all(8.0),
                                            child: Text("Копировать"),
                                          ))
                                      : Container()
                                ],
                              ),
                            ),
                          ))
                    ],
                  ),
                )
              ],
            ),
          ),
        ));
  }
}
