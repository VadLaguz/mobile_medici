import 'dart:io';

import 'model/Deck.dart';

bool showThreads() {
  return !Platform.isIOS;
}

bool ruLocale() {
  return true;
  //return Platform.localeName.contains("ru");
}



Map nominalsToLang() {
  if (!ruLocale() && false) {
    return nominalsToEn;
  } else {
    return nominalsToRu;
  }
}

Map suitsToLang() {
  if (!ruLocale() && false) {
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
