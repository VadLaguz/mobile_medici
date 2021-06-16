import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';

import 'package:adaptive_dialog/adaptive_dialog.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttericon/elusive_icons.dart';
import 'package:fluttericon/entypo_icons.dart';
import 'package:fluttericon/font_awesome_icons.dart';
import 'package:fluttericon/linearicons_free_icons.dart';
import 'package:graphite/core/matrix.dart';
import 'package:graphite/graphite.dart';
import 'package:mobile_medici/BalanceWidget.dart';
import 'package:mobile_medici/BotWidget.dart';
import 'package:mobile_medici/CalculateSettingsWidget.dart';
import 'package:mobile_medici/Helpers.dart';
import 'package:mobile_medici/model/Settings.dart';
import 'package:mobile_medici/reorderables/src/widgets/reorderable_wrap.dart';
import 'package:mobile_medici/shared_ui.dart';
import 'package:oktoast/oktoast.dart';
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
    return OKToast(
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Medici Calculator',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Medici Calculator'),
      ),
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
  SendPort? sendPort;

  IsolateInitializer(this.index, this.onUpdate) {
    port = ReceivePort();
    port.listen((message) {
      if (message is int) {
        count = message;
      } else if (message is Deck) {
        //message.printStats();
        onUpdate(message);
      } else if (message is SendPort) {
        sendPort = message;
      } else if (message is String) {
        onUpdate(message);
      }
    });
  }
}

Future<void> isolateFunc(List<Object> message) async {
  SendPort port = message[1] as SendPort;
  DeckTask task = message[2] as DeckTask;

  ReceivePort mainToIsolateStream = ReceivePort();
  port.send(mainToIsolateStream.sendPort);

  var work = true;
  mainToIsolateStream.listen((data) {
    if (data == "kill") {
      work = false;
    }
  });
  port.send(task.threadIdx.toString());
  final deck = Deck();
  deck.setMaskByList(task.mask);
  deck.needHex = task.needHex;
  var counter = 0;
  var circleWatch = Stopwatch()..start();
  while (work) {
    //work = false;
    if (task.mirror) {
      if (!deck.shuffleMirror()) {
        continue;
      }
    } else if (task.maxTransits == 1) {
      deck.shuffle34();
    } else {
      deck.shuffle();
    }
    counter++;
    if (deck.check(
        maxTransits: task.maxTransits,
        reverse: task.reverse,
        fullBalanced: task.fullBalanced,
        onlyDifferentHexes: task.onlyDifferentHexes)) {
      port.send(deck);
    }
    if (circleWatch.elapsedMilliseconds >= 1000) {
      circleWatch.reset();
      port.send(counter);
      counter = 0;
    }
    //await Future.delayed(Duration.zero);
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

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  var chainModel = <CardItem>[];
  Map<CardSuit, List<int>> needHex = {};
  Timer? timer;
  var calculating = false;
  var foundItems = <Deck>[];
  var repeatsCount = 0;
  final MAX_REPEATS = 30;
  var selectedItem = -1;
  var checkedCount = 0;
  var speed = 0;
  var threadsLaunching = false;
  var threadsLaunchingCount = 0;
  var calcSettings = CalcSettings();
  CardItem? swapCard;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    print("didChangeAppLifecycleState: ${state}");
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    print("OnDispose");
    super.dispose();
  }

  void stop() {
    calculating = false;
    if (initializers.isNotEmpty) {
      timer!.cancel();
      print("Stopping ${initializers.length} threads");
      initializers.forEach((element) {
        if (element.sendPort != null) {
          element.sendPort!.send("kill");
        }
        element.isolate.kill(priority: Isolate.immediate);
      });
    }
    initializers.clear();
  }

  void forceStop() {
    if (threadsLaunching) {
      calculating = false;
    } else {
      setState(() {
        stop();
      });
    }
  }

  Future<void> doSpawn(List<CardItem> chain) async {
    if (initializers.isNotEmpty) {
      stop();
    }
    threadsLaunchingCount = calcSettings.threads;
    for (var index = 0; index < calcSettings.threads; index++) {
      var isolateInitializer = IsolateInitializer(index, (param) {
        if (param is Deck) {
          setState(() {
            if (foundItems.length > 1000) {
              forceStop();
            }
            if (foundItems.contains(param)) {
              repeatsCount++;
              if (repeatsCount > MAX_REPEATS) {
                forceStop();
              }
            } else {
              foundItems.insert(0, param);
              if (selectedItem > -1) {
                selectedItem++;
              }
            }
          });
        } else if (param is String) {
          threadsLaunchingCount--;
          if (threadsLaunchingCount <= 0) {
            setState(() {
              threadsLaunching = false;
              if (calculating == false) {
                stop();
              }
            });
          }
        }
      });
      initializers.add(isolateInitializer);
      var deckTask = DeckTask(
          chain,
          needHex,
          calcSettings.maxTransits,
          index,
          calcSettings.reverse,
          calcSettings.fullBalanced,
          calcSettings.mirror,
          calcSettings.onlyDifferentHexes);
      isolateInitializer.isolate = await Isolate.spawn(
          isolateFunc, [index, isolateInitializer.port.sendPort, deckTask]);
    }
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
    if (WidgetsBinding.instance != null) {
      WidgetsBinding.instance!.addObserver(this);
    }
  }

  void resetChain() {
    needHex = {};
    swapCard = null;
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
    swapCard = null;
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
    chainModel.forEach((widgetCard) {
      var name =
          "${widgetCard.nominal.toString().toLowerCase().replaceAll("nominal.", "")}_of_${widgetCard.suit.toString().toLowerCase().replaceAll("cardsuit.", "")}.png";
      replace.forEach((key, value) {
        name = name.replaceAll(key, value);
      });
      final width = MediaQuery.of(context).size.width /
          (MediaQuery.of(context).orientation == Orientation.portrait ? 7 : 13);
      final height = width * 1.3;
      var efl = widgetCard.minMaxEfl;
      var currentEfl = selectedItem > -1 ? widgetCard.efl : 0;
      var card = GestureDetector(
          onLongPress: () async {
            if (selectedItem != -1) {
              final result = await showModalActionSheet(
                  context: context,
                  title: "Actions",
                  actions: [
                    SheetAction(
                      label: "Swap with...",
                      key: 'helloKey',
                    )
                  ]);
              if (result == 'helloKey') {
                showToast("Choose card to swap with");
                swapCard = widgetCard;
              }
            }
          },
          onTap: () {
            setState(() {
              if (swapCard != null && selectedItem != -1) {
                var cards = <CardItem>[];
                var deck = foundItems[selectedItem];
                var i = 0;
                deck.cards.forEach((element) {
                  var cardItem = CardItem(element.suit, element.nominal);
                  cardItem.fixed = element.fixed;
                  cardItem.minMaxEfl = element.minMaxEfl;
                  if (cardItem.fixed) {
                    deck.maskCards.add(cardItem);
                  }
                  cardItem.indexInDeck = i;
                  //swapCard - исходная для замены
                  //element - очередная
                  //widgetCard - выбранная второй
                  //если нашли масть исходной для замены меняем нав выбранную второй
                  if (element.suit == swapCard!.suit) {
                    cardItem.suit = widgetCard.suit;
                  } else if (element.suit == widgetCard.suit) {
                    //а если нашли выбранную второй меняем на выбранну первой
                    cardItem.suit = swapCard!.suit;
                  }
                  //если нашли номинал выбранной первой карты
                  if (element.nominal == swapCard!.nominal) {
                    cardItem.nominal = widgetCard.nominal;
                  } else if (element.nominal == widgetCard.nominal) {
                    cardItem.nominal = swapCard!.nominal;
                  }
                  cards.add(cardItem);
                  i++;
                });
                var value = Deck();
                value.cards = cards;
                value.check();
                foundItems.insert(0, value);
                swapCard = null;
                selectedItem = 0;
                showSelectedDeck();
              } else {
                widgetCard.fixed = !widgetCard.fixed;
                selectedItem = -1;
                swapCard = null;
              }
            });
          },
          child: Container(
            color: widgetCard.fixed ? Colors.blue : Colors.transparent,
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
                          heightFactor: 0.3,
                          child: Column(
                            children: [
                              Container(
                                height: 1,
                                color: Colors.black12,
                              ),
                              Expanded(
                                child: Container(
                                  color: currentEfl > 0
                                      ? Colors.indigoAccent
                                      : Colors.white,
                                  child: InkWell(
                                    onTap: () {
                                      eflDialog(context, widgetCard, () {
                                        setState(() {});
                                      });
                                    },
                                    child: Center(
                                      child: FittedBox(
                                        fit: BoxFit.fitHeight,
                                        child: currentEfl > 0
                                            ? Text(
                                                "⚡️️ ${currentEfl}",
                                                style: TextStyle(
                                                    fontSize: 18,
                                                    color: Colors.white),
                                              )
                                            : Text(
                                                efl == null
                                                    ? "️⚙️"
                                                    : "⚙️ ${efl.start.toInt()}-${efl.end.toInt()}",
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
    setState(() {
      selectedItem = -1;
    });
    await RangeSliderDialog.display<int>(context,
        minValue: 0,
        width: Platform.isWindows || Platform.isMacOS || Platform.isLinux
            ? MediaQuery.of(context).size.width / 2
            : null,
        maxValue: chainModel.length - 2,
        acceptButtonText: 'OK',
        cancelButtonText: 'Cancel',
        headerText: 'Set Min And Max EFL',
        selectedRangeValues:
            item.minMaxEfl ?? RangeValues(0, chainModel.length.toDouble() - 2),
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

  Future<void> calculate() async {
    swapCard = null;
    if (threadsLaunching) {
      print("Spawning starting");
      return;
    }
    if (calculating) {
      stop();
      calculating = false;
      setState(() {});
    } else {
      selectedItem = -1;
      repeatsCount = 0;
      setState(() {
        calculating = true;
      });
      setState(() {
        threadsLaunching = true;
      });
      await doSpawn(chainModel);
      setState(() {
        speed = 0;
        checkedCount = 0;
      });
    }
  }

  var scrollController = ScrollController();
  var viewScrollController = ScrollController();

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
    return List.generate(4, (index) {
      var suit = suitsList[index];
      return Stack(
        children: [
          IconButton(
              iconSize: 36,
              color: suitColors[index],
              onPressed: () async {
                setIChing(context, suit);
              },
              icon: Icon(suitIconsData[index])),
          IgnorePointer(
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: (needHex[suit] ?? []).length == 0
                      ? Colors.transparent
                      : Colors.purpleAccent,
                  shape: BoxShape.circle),
            ),
          )
        ],
        alignment: Alignment.topRight,
      );
    });
  }

  void showSelectedDeck() {
    swapCard = null;
    if (selectedItem > -1) {
      setState(() {
        var item = foundItems[selectedItem];
        /*for (var i = 0; i < item.cards.length; i++) {
          chainModel.insert(i, chainModel.removeAt(chainModel.indexOf(item.cards[i])));
        }*/
        chainModel.clear();
        chainModel.addAll(item.cards);
      });
    }
  }

  Random r = Random();

  Widget rectangleWidget(int a) {
    if (selectedItem >= 0) {
      var item = foundItems[selectedItem];
      var cardItem =
          item.cards.firstWhere((element) => element.indexInDeck == a);
      return Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
            ],
          ),
          child: Text(
            '${cardItem.toString()}',
            style: TextStyle(fontSize: 15),
          ));
    }
    return Container();
  }

  Path customEdgePathBuilder(List<List<double>> points) {
    var path = Path();
    path.moveTo(points[0][0], points[0][1]);
    points.sublist(1).forEach((p) {
      path.lineTo(p[0], p[1]);
    });
    return path;
  }

  Widget getTreeView() {
    if (selectedItem >= 0) {
      var deck = foundItems[selectedItem];

      var nodeInputs = <NodeInput>[];
      for (var card in deck.cards) {
        if (card.prevTransit.length > 0) {
          nodeInputs.add(NodeInput(
              id: card.toString(),
              next: card.prevTransit.map((e) => e.toString()).toList()));
        } else {
          nodeInputs.add(NodeInput(id: card.toString(), next: []));
        }
      }

      return SingleChildScrollView(
        child: SizedBox(
          width: 1000,
          height: 570,
          child: DirectGraph(
            maxScale: 0.001,
            minScale: 0.00001,
            list: nodeInputs,
            cellWidth: 40.0,
            cellPadding: 4.0,
            contactEdgesDistance: 5.0,
            orientation: MatrixOrientation.Vertical,
            pathBuilder: customEdgePathBuilder,
            builder: (ctx, node) {
              return Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(color: Colors.blue[100]!, spreadRadius: 1),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '${node.id}',
                      style: TextStyle(fontSize: 10),
                    ),
                  ));
            },
            paintBuilder: (edge) {
              var p = Paint()
                ..color = Colors.blueGrey
                ..style = PaintingStyle.stroke
                ..strokeCap = StrokeCap.round
                ..strokeJoin = StrokeJoin.round
                ..strokeWidth = 2;
              return p;
            },
            onNodeTapDown: (_, node) {
              //_onItemSelected(node.id);
            },
          ),
        ),
      );
    }
    return Container();
  }

  Widget buildDetailsPane(BuildContext context) {
    //buildDetailsPane(context)
    if (selectedItem >= 0) {
      var item = foundItems[selectedItem];
      var transitCountsMap = CardSuit.values.map((e) => {
            e: item.cards.where((element) => element.suit == e).fold<int>(
                0,
                (previousValue, element) =>
                    previousValue + (element.efl > 0 ? 1 : 0))
          });
      var transitElfMap = CardSuit.values.map<Map<CardSuit, int>>((e) => {
            e: item.cards.where((element) => element.suit == e).fold<int>(
                0, (previousValue, element) => previousValue + element.efl)
          });
      //print(transitElfMap);

      var details = <Widget>[];
      for (var i = 0; i < suitsList.length; i++) {
        var suit = suitsList[i];
        var efl = transitElfMap
            .where((element) => element.keys.first == suit)
            .first
            .values
            .first
            .toInt();
        var count = transitCountsMap
            .where((element) => element.keys.first == suit)
            .first
            .values
            .first;
        var double = efl.toDouble();
        //print(double);
        var widget = Row(children: [
          Icon(
            suitIconsData[i],
            color: suitColors[i],
          ),
          Expanded(
            child: AbsorbPointer(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                    trackHeight: 10.0,
                    activeTrackColor: suitColors[i],
                    thumbShape: RoundSliderThumbShape(enabledThumbRadius: 0.0)),
                child: Slider(
                  label: "2",
                  value: double,
                  onChanged: (value) => {},
                  min: 0,
                  max: 36,
                ),
              ),
            ),
          ),
          Text("$efl : $count")
        ]);
        details.add(widget);
      }
      return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
              children: <Widget>[
                    Wrap(
                      children: [
                        TextButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(
                                  text: foundItems[selectedItem]
                                      .asString(true, true)));
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Copy to clipboard"),
                            )),
                        TextButton(
                            onPressed: () {
                              showDialog(
                                barrierDismissible: !isMobile(),
                                context: context,
                                builder: (context) {
                                  return Center(child: BotWidget(item));
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text("Send to bot"),
                            )),
                      ],
                    ),
                  ] +
                  details +
                  (isLandscape(context) ? [BalanceWidget(item)] : []) +
                  [
                    getTreeView(),
                  ]));
    }

    return Container();
  }

  LineChartData getLineCharData() {
    return LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
        ),
        touchCallback: (LineTouchResponse touchResponse) {},
        handleBuiltInTouches: true,
      ),
      gridData: FlGridData(
        show: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: SideTitles(
          showTitles: true,
          reservedSize: 22,
          getTextStyles: (value) => const TextStyle(
            color: Color(0xff72719b),
            fontWeight: FontWeight.w200,
            fontSize: 10,
          ),
          margin: 10,
          getTitles: (value) {
            return '${value.toInt()}';
          },
        ),
        leftTitles: SideTitles(
          showTitles: true,
          getTextStyles: (value) => const TextStyle(
            color: Colors.blue,
            fontWeight: FontWeight.w200,
            fontSize: 10,
          ),
          getTitles: (value) {
            return '${value.toInt()}';
          },
          margin: 8,
          reservedSize: 30,
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: const Border(
          bottom: BorderSide(
            color: Color(0xff4e4965),
            width: 4,
          ),
          left: BorderSide(
            color: Colors.transparent,
          ),
          right: BorderSide(
            color: Colors.transparent,
          ),
          top: BorderSide(
            color: Colors.transparent,
          ),
        ),
      ),
      minX: 1,
      maxX: 35,
      maxY: 36,
      minY: 0,
      lineBarsData: linesBarData1(),
    );
  }

  List<LineChartBarData> linesBarData1() {
    return CardSuit.values.map((e) {
      var deck = foundItems[selectedItem];
      var data = <FlSpot>[];
      deck.cards.forEach((element) {
        if (element.suit == e) {
          data.add(
              FlSpot(element.indexInDeck.toDouble(), element.efl.toDouble()));
        }
      });
      return LineChartBarData(
        spots: data,
        isCurved: false,
        colors: [
          const Color(0xff4af699),
        ],
        barWidth: 2,
        isStrokeCapRound: true,
        dotData: FlDotData(
          show: false,
        ),
        belowBarData: BarAreaData(
          show: false,
        ),
      );
    }).toList();
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
          setState(() {
            selectedItem = -1;
          });
        },
        onReorder: onReorder);

    return Scaffold(
        appBar: MediaQuery.of(context).orientation == Orientation.portrait
            ? AppBar(
                title: Text("Medici Calculator"),
              )
            : null,
        body: Padding(
          padding: EdgeInsets.only(
              top:
                  MediaQuery.of(context).orientation == Orientation.landscape &&
                          Platform.isAndroid
                      ? 20
                      : 0),
          child: SingleChildScrollView(
            controller: viewScrollController,
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
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: iChingButtons(context) +
                                  [
                                    /*Container(
                                      width: 8,
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: TextButton(
                                        child: Text("HEX"),
                                        onPressed: () {
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    AdvancedHexSelectWidget(),
                                              ));
                                        },
                                      ),
                                    ),*/
                                    Container(
                                      width: 8,
                                    ),
                                    IconButton(
                                      onPressed: () async {
                                        final result = await showTextInputDialog(
                                            title:
                                                "Chain input (pm3421, pmcalc.ru and this app formats allowed)",
                                            context: context,
                                            textFields: [
                                              DialogTextField(
                                                  maxLines: 3,
                                                  hintText:
                                                      "Examples: <[Вк][Вб]><[6п][8п]....,[Вч 9к Тк Вп 7ч 10ч Тп Дп 7б Дк],...Вч 6ч Тк Вп Тп!2...etc")
                                            ]);
                                        if (result != null) {
                                          final deck = Deck();
                                          if (deck.parse(result.first)) {
                                            chainModel.clear();
                                            chainModel.addAll(deck.cards);
                                            setState(() {
                                              if (deck.check(reverse: true) || deck.check()) {
                                                foundItems.insert(0, deck);
                                                selectedItem = 0;
                                              }
                                            });
                                          } else {
                                            showAlertDialog(
                                                context: context,
                                                title: "Error",
                                                message:
                                                    "Maybe the chain is too short (less than 36 cards) or the format is not supported.",
                                                actions: [
                                                  AlertDialogAction(
                                                      key: 1, label: "OK 🤨")
                                                ]);
                                          }
                                        }
                                      },
                                      icon: Icon(Entypo.pencil),
                                      iconSize: 36,
                                      color: Colors.cyan,
                                    ),
                                    Container(
                                      width: 8,
                                    ),
                                    Stack(
                                      alignment: Alignment.topRight,
                                      children: [
                                        IconButton(
                                            onPressed: () async {
                                              showDialog(
                                                context: context,
                                                builder: (context) {
                                                  return Center(
                                                      child:
                                                          CalculateSettingsWidget(
                                                              calcSettings, () {
                                                    setState(() {});
                                                  }));
                                                },
                                              );
                                            },
                                            icon: Icon(
                                              FontAwesome.cog,
                                              size: 36,
                                              color: Colors.orange,
                                            )),
                                        IgnorePointer(
                                          child: Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(
                                                color: calcSettings.isDefault()
                                                    ? Colors.transparent
                                                    : Colors.purpleAccent,
                                                shape: BoxShape.circle),
                                          ),
                                        )
                                      ],
                                    ),
                                    Container(
                                      width: 8,
                                    ),
                                    IconButton(
                                        color: calculating
                                            ? Colors.red
                                            : Colors.lightBlue,
                                        iconSize: 36,
                                        onPressed: () {
                                          calculate();
                                        },
                                        icon: threadsLaunching
                                            ? Stack(
                                                alignment: Alignment.center,
                                                children: [
                                                  Text(
                                                    "",
                                                    //костыль для центрирования крутилки по вертикали сорян
                                                    style:
                                                        TextStyle(fontSize: 48),
                                                  ),
                                                  CircularProgressIndicator(),
                                                ],
                                              )
                                            : Icon(
                                                calculating
                                                    ? Elusive.error_alt
                                                    : LineariconsFree.rocket,
                                              )),
                                    Container(
                                      width: 8,
                                    ),
                                    IconButton(
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
                                      icon: Icon(LineariconsFree.trash),
                                      iconSize: 36,
                                      color: Colors.red,
                                    ),
                                  ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SafeArea(
                    child: Container(
                      height: MediaQuery.of(context).orientation ==
                              Orientation.landscape
                          ? 1000
                          : 1000,
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Card(
                              elevation: 2,
                              child: Container(
                                child: ListView.builder(
                                  itemBuilder: (context, index) {
                                    var asString =
                                        foundItems[index].asString(true, false);
                                    return InkWell(
                                      onTap: () {
                                        setState(() {
                                          selectedItem = index;
                                          showSelectedDeck();
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
                                  child: buildDetailsPane(context),
                                ),
                              ))
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}
