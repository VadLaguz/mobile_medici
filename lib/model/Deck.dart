import 'package:flutter/material.dart';
import 'package:quiver/iterables.dart';

var hexTable = ("#11 (111000) Расцвет\n" +
    "#46 (011000) Подъем\n" +
    "#36 (101000) Поражение света\n" +
    "#15 (001000) Смирение\n" +
    "#19 (110000) Посещение\n" +
    "#7 (010000) Войско\n" +
    "#24 (100000) Возврат\n" +
    "#2 (000000) Исполнение\n" +
    "#34 (111100) Мощь великого\n" +
    "#32 (011100) Устойчивость\n" +
    "#55 (101100) Изобилие\n" +
    "#62 (001100) Переразвитие малого\n" +
    "#54 (110100) Невеста\n" +
    "#40 (010100) Разрешение\n" +
    "#51 (100100) Молния\n" +
    "#16 (000100) Вольность\n" +
    "#5 (111010) Необходимость ждать\n" +
    "#48 (011010) Колодец\n" +
    "#63 (101010) Уже конец\n" +
    "#39 (001010) Препятствие\n" +
    "#60 (110010) Ограничение\n" +
    "#29 (010010) Двойная опасность\n" +
    "#3 (100010) Начальная трудность\n" +
    "#8 (000010) Близость\n" +
    "#43 (111110) Выход\n" +
    "#28 (011110) Переразвитие великого\n" +
    "#49 (101110) Смена\n" +
    "#31 (001110) Взаимодействие\n" +
    "#58 (110110) Радость\n" +
    "#47 (010110) Истощение\n" +
    "#17 (100110) Последование\n" +
    "#45 (000110) Воссоединение\n" +
    "#26 (111001) Воспитание великим\n" +
    "#18 (011001) Исправление [порчи]\n" +
    "#22 (101001) Убранство\n" +
    "#52 (001001) Сосредоточенность\n" +
    "#41 (110001) Убыль\n" +
    "#4 (010001) Недоразвитость\n" +
    "#27 (100001) (Вос)Питание\n" +
    "#23 (000001) Разрушение\n" +
    "#14 (111101) Обладание великим\n" +
    "#50 (011101) Жертвенник\n" +
    "#30 (101101) Сияние\n" +
    "#56 (001101) Странствие\n" +
    "#38 (110101) Разлад\n" +
    "#64 (010101) Еще не конец\n" +
    "#21 (100101) Стиснутые зубы\n" +
    "#35 (000101) Восход\n" +
    "#9 (111011) Воспитание малым\n" +
    "#57 (011011) Проникновение\n" +
    "#37 (101011) Семья (Домашние)\n" +
    "#53 (001011) Течение\n" +
    "#61 (110011) Внутренняя правда\n" +
    "#59 (010011) Раздробление\n" +
    "#42 (100011) Прибыль\n" +
    "#20 (000011) Созерцание\n" +
    "#1 (111111) Творчество\n" +
    "#44 (011111) Перечение\n" +
    "#13 (101111) Родня (Единомышленники)\n" +
    "#33 (001111) Бегство\n" +
    "#10 (110111) Наступление\n" +
    "#6 (010111) Суд\n" +
    "#25 (100111) Безпорочность\n" +
    "#12 (000111) Упадок").split('\n');


enum Suit { hearts, diamonds, clubs, spades }

enum Nominal { six, seven, eight, nine, ten, jack, queen, king, ace }

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
  Suit.clubs: "К",
  Suit.diamonds: "Б",
  Suit.hearts: "Ч",
  Suit.spades: "П",
};

class Card {
  Suit? suit;
  Nominal? nominal;
  var indexInDeck = 0;
  var efl = 0;
  var minEfl = 0;
  var maskCard = false;
  String? cardString;

  Card(this.suit, this.nominal);

  @override
  String toString() {
    return "${nominalsToRu[nominal]}${suitsToRu[suit]!.toLowerCase()}";
  }

  Card.fromString(this.cardString) : super() {
    var lowerCased = cardString!.toLowerCase();
    suitsToRu.map((key, value) {
      if (value.toLowerCase() == lowerCased.substring(1, 2)) {
        suit = key;
      }
      return MapEntry(key, value);
    });
    nominalsToRu.map((key, value) {
      if (value.toLowerCase() == lowerCased.substring(0, 1)) {
        nominal = key;
      }
      return MapEntry(key, value);
    });
    if (suit == null || nominal == null) {
      throw Exception("Invalid card: $cardString");
    }
    if (lowerCased.length > 2) {
      this.minEfl = int.parse(lowerCased.substring(2));
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Card &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          nominal == other.nominal;

  @override
  int get hashCode => suit.hashCode ^ nominal.hashCode;
}

class Deck {
  List<Card> cards = [];
  Card? rightTransit;
  List<Card> maskCards = [];
  final okSymbols = nominalsToRu.values.map((e) => e.toLowerCase()).toList() +
      suitsToRu.values.map((e) => e.toLowerCase()).toList();

  Deck() {
    cards.clear();
    Suit.values.forEach((suit) {
      Nominal.values.forEach((nominal) {
        cards.add(Card(suit, nominal));
      });
    });
  }

  String asString(bool efl) {
    var retVal = "";
    cards.forEach((card) {
      var s = card.toString();
      retVal += s + (card.efl > 0 && efl ? "!${card.efl}" : "") + " ";
    });
    return retVal.trim().replaceAll("X", "10");
  }

  void shuffle() {
    cards.shuffle();
    cards.removeWhere((element) => maskCards.contains(element));
    maskCards.forEach((element) {
      cards.insert(element.indexInDeck, element);
    });
    cards.asMap().forEach((key, value) {
      value.indexInDeck = key;
      value.efl = 0;
    });
  }

  void setMask(String s) {
    final mask = s.split(" ");
    maskCards.clear();
    mask.asMap().forEach((key, value) {
      if (value != "*") {
        final card = Card.fromString(value);
        card.maskCard = true;
        card.indexInDeck = key;
        maskCards.add(card);
      }
    });
  }

  void parse(String s) {
    cards.clear();
    final fixedChain = s
        .replaceAll("10", "X")
        .toLowerCase()
        .runes
        .toList()
        .fold("", (previousValue, element) {
      var s = String.fromCharCode(element);
      return (previousValue ?? "").toString() +
          (okSymbols.contains(s) ? s : "");
    });

    for (var i = 0; i < fixedChain.length; i += 2) {
      final card = Card.fromString(fixedChain.substring(i, i + 2));
      card.indexInDeck = cards.length;
      cards.add(card);
    }
    print(cards);
  }

  List<Card> process(List<Card> list) {
    for (var i = 0; i < list.length - 2; i++) {
      var left = list[i];
      var middle = list[i + 1];
      var right = list[i + 2];
      if (left.suit == right.suit || left.nominal == right.nominal) {
        if (rightTransit == null) {
          rightTransit = right;
        } else if (right.indexInDeck > rightTransit!.indexInDeck) {
          rightTransit = right;
        }
        rightTransit!.efl++;
        return process(list.sublist(0, i) + list.sublist(i + 1, list.length));
      }
    }
    return list;
  }

  bool check() {
    rightTransit = null;
    final result = process(cards.toList());
    return result.length == 2;
  }

  void printStats() {
    print(asString(true));
  }
}
