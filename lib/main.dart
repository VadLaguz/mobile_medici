import 'dart:async';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:isolate_handler/isolate_handler.dart';

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
      "Вп * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * Тп25 * * * *");
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
  MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  Timer? timer;

  @override
  _MyHomePageState createState() => _MyHomePageState();

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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Container(
        child: Center(
          child: ElevatedButton(
            onPressed: () {
              widget.doSpawn();
            },
            child: Text("Test"),
          ),
        ),
      ),
    );
  }
}
