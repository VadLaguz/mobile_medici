import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:mobile_medici/reorderables/src/widgets/WrapCardWidget.dart';
import 'package:mobile_medici/reorderables/src/widgets/reorderable_wrap.dart';

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

  IsolateInitializer(this.index) {
    port = ReceivePort();
    port.listen((message) {
      count = message;
    });
  }
}

void isolateFunc(List<Object> message) {
  SendPort port = message[1] as SendPort;
  print('Starting thread ${message[0]} at ${DateTime.now()}');
  final deck = Deck();
  deck.setMask(
      "Вп * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * Тп20 * * * *");
  var counter = 0;
  var circleWatch = Stopwatch()..start();
  while (true) {
    counter++;
    deck.shuffle();
    if (deck.check()) {
      var okDeck = true;
      deck.cards.forEach((element) {
        if (element.efl < element.minEfl) {
          okDeck = false;
        }
      });
      if (okDeck) {
        print("Found at ${DateTime.now()}: \n ${deck.asString(true)}");
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
  late List<Widget> _tiles = [];

  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  Timer? timer;

  @override
  _MyHomePageState createState() {
    return _MyHomePageState();
  }

  void doSpawn() {
    if (initializers.isNotEmpty) {
      timer!.cancel();
      print("Stopping ${initializers.length} threads");
      initializers.forEach((element) {
        element.isolate.kill(priority: Isolate.immediate);
      });
      return;
    }
    List.generate(5, (index) async {
      var isolateInitializer = IsolateInitializer(index);
      initializers.add(isolateInitializer);
      isolateInitializer.isolate = await Isolate.spawn(
          isolateFunc, [index, isolateInitializer.port.sendPort]);
    });
    timer = Timer.periodic(Duration(seconds: 5), (timer) {
      var sum = initializers.fold<int>(
          0, (previousValue, element) => previousValue + element.count);
      print("Computed $sum chains in second");
    });
  }
}

class _MyHomePageState extends State<MyHomePage> {
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      widget._tiles.insert(newIndex, widget._tiles.removeAt(oldIndex));
    });
  }

  void makeTiles() {
    if (widget._tiles.length == 0) {
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
      var position = 0;
      Nominal.values.forEach((nom) {
        CardSuit.values.forEach((suit) {
          var name =
              "${nom.toString().toLowerCase().replaceAll("nominal.", "")}_of_${suit.toString().toLowerCase().replaceAll("cardsuit.", "")}.png";
          replace.forEach((key, value) {
            name = name.replaceAll(key, value);
          });

          final width = MediaQuery.of(context).size.width / 14;
          final height = width * 1.3;
          var card = IgnorePointer(
              ignoring: position == 2,
              child: WrapCardWidget(
                  child: Container(
                child: Card(
                    child: Container(
                  child: Image.asset(
                    "assets/cards/$name",
                    fit: BoxFit.scaleDown,
                  ),
                )),
              )));
          //card.position =
          if (widget._tiles.length < 4 || true) {
            widget._tiles.add(card);
          }
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    makeTiles();
    var wrap = ReorderableWrap(
        spacing: 8.0,
        runSpacing: 4.0,
        needsLongPressDraggable: false,
        padding: const EdgeInsets.all(8),
        children: widget._tiles,
        onNoReorder: (int index) {
          //this callback is optional
          debugPrint(
              '${DateTime.now().toString().substring(5, 22)} reorder cancelled. index:$index');
        },
        onReorderStarted: (int index) {
          //this callback is optional
          debugPrint(
              '${DateTime.now().toString().substring(5, 22)} reorder started: index:$index');
        },
        onReorder: _onReorder);

    return Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Container(
          child: Column(
            children: [
              wrap,
            ],
          ),
        ));
  }
}
