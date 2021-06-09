import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttericon/rpg_awesome_icons.dart';

import 'model/Deck.dart';

bool showThreads() {
  return !Platform.isIOS;
}

bool ruLocale() {
  // return true;
  return Platform.localeName.contains("ru");
}

Map nominalsToLang() {
  if (!ruLocale() ) {
    return nominalsToEn;
  } else {
    return nominalsToRu;
  }
}

Map suitsToLang() {
  if (!ruLocale()) {
    return suitsToEn;
  } else {
    return suitsToRu;
  }
}

var nominalsToRu = {
  Nominal.six: "6",
  Nominal.seven: "7",
  Nominal.eight: "8",
  Nominal.nine: "9",
  Nominal.ten: "X",
  Nominal.jack: "В",
  Nominal.queen: "Д",
  Nominal.king: "К",
  Nominal.ace: "Т"
};

var suitsToRu = {
  CardSuit.clubs: "К",
  CardSuit.diamonds: "Б",
  CardSuit.hearts: "Ч",
  CardSuit.spades: "П",
};

var nominalsToEn = {
  Nominal.six: "6",
  Nominal.seven: "7",
  Nominal.eight: "8",
  Nominal.nine: "9",
  Nominal.ten: "X",
  Nominal.jack: "J",
  Nominal.queen: "Q",
  Nominal.king: "K",
  Nominal.ace: "A"
};

var suitsToEn = {
  CardSuit.clubs: "C",
  CardSuit.diamonds: "D",
  CardSuit.hearts: "H",
  CardSuit.spades: "S",
};

final suitColors = [
  Colors.pink.withAlpha(150),
  Colors.orange.withAlpha(150),
  Colors.brown.withAlpha(150),
  Colors.blueAccent.withAlpha(150),
];

var suitsList = [
  CardSuit.hearts,
  CardSuit.diamonds,
  CardSuit.clubs,
  CardSuit.spades
];
var suitIconsData = [
  RpgAwesome.hearts,
  RpgAwesome.diamonds,
  RpgAwesome.clovers,
  RpgAwesome.spades,
];