import 'dart:math';

import 'package:flutter/material.dart';

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
        "#12 (000111) Упадок")
    .split('\n');

enum CardSuit { hearts, diamonds, clubs, spades }

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
  CardSuit.clubs: "К",
  CardSuit.diamonds: "Б",
  CardSuit.hearts: "Ч",
  CardSuit.spades: "П",
};

final cardsToHexLines = {
  0: [Nominal.nine, Nominal.seven],
  1: [Nominal.six, Nominal.eight],
  2: [Nominal.ten],
  3: [Nominal.queen, Nominal.jack],
  4: [Nominal.king],
  5: [Nominal.ace]
};

var hexToEmoji = {
  CardSuit.hearts: "♥️",
  CardSuit.diamonds: "♦️",
  CardSuit.clubs: "♣️️",
  CardSuit.spades: "♠️️"
};

class DeckTask {
  List<CardItem> mask;
  Map<CardSuit, List<int>> needHex;
  int maxTransits;
  int threadIdx;

  DeckTask(this.mask, this.needHex, this.maxTransits, this.threadIdx);
}

class CardItem {
  CardSuit? suit;
  Nominal? nominal;
  var indexInDeck = 0;
  var efl = 0;
  var maskCard = false;
  String? cardString;
  var fixed = false;
  RangeValues? minMaxEfl;
  var linked = <CardItem>[];

  CardItem(this.suit, this.nominal);

  @override
  String toString() {
    return "${nominalsToRu[nominal]}${suitsToRu[suit]!.toLowerCase()}";
  }

  CardItem.fromString(this.cardString) : super() {
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
      this.minMaxEfl =
          RangeValues(int.parse(lowerCased.substring(2)).toDouble(), 36);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardItem &&
          runtimeType == other.runtimeType &&
          suit == other.suit &&
          nominal == other.nominal;

  @override
  int get hashCode => suit.hashCode ^ nominal.hashCode;
}

class Deck {
  List<CardItem> stationars = [];
  List<CardItem> mobiles = [];
  List<CardItem> cards = [];
  Map<CardSuit, String> hex = {};
  Map<CardSuit, List<int>> needHex = {};
  CardItem? rightTransit;
  List<CardItem> maskCards = [];
  List<CardItem> fixedTransits = [];
  final okSymbols = nominalsToRu.values.map((e) => e.toLowerCase()).toList() +
      suitsToRu.values.map((e) => e.toLowerCase()).toList();

  Map<String, int> hexToNumberMap = {};

  Deck() {
    hexTable.forEach((element) {
      var val = element.substring(element.indexOf('(') + 1);
      val = val.substring(0, val.indexOf(')'));
      final inNum =
          int.parse(element.substring(0, element.indexOf(' ')).substring(1));
      hexToNumberMap[val] = inNum;
    });
    cards.clear();
    needHex.clear();
    CardSuit.values.forEach((suit) {
      Nominal.values.forEach((nominal) {
        cards.add(CardItem(suit, nominal));
      });
    });
  }

  String asString(bool efl, bool withoutEfl) {
    var retVal = "";
    cards.forEach((card) {
      var s = card.toString();
      retVal += s + (card.efl > 0 && efl ? "!${card.efl}" : "") + " ";
    });
    if (withoutEfl) {
      retVal += "\n";
      cards.forEach((card) {
        var s = card.toString();
        retVal += s + " ";
      });
    }
    var hexString = "";
    hex.forEach((key, value) {
      hexString += hexToEmoji[key]! +
          "${hexTable.firstWhere((element) => element.contains(value))}\n";
    });

    retVal += "\n" + hexString;
    return retVal.trim().replaceAll("X", "10");
  }

  void shuffle() {
    cards.shuffle();
    cards.removeWhere((element) => maskCards.contains(element));
    maskCards.forEach((element) {
      cards.insert(element.indexInDeck, element);
    });

    var allLinked = <CardItem>[];
    fixedTransits.forEach((item) {
      if (item.indexInDeck > 1) {
        item.linked.shuffle();
        for (var linkedItem in item.linked) {
          if (!allLinked.contains(linkedItem)) {
            allLinked.add(linkedItem);
            var linkedPos = cards.indexOf(linkedItem);
            var preTransitIdx = item.indexInDeck - 2;
            var temp = cards[preTransitIdx];
            cards[preTransitIdx] = linkedItem;
            cards[linkedPos] = temp;
            allLinked.add(linkedItem);
            break;
          }
        }
      }
    });
    cards = cards;
    cards.asMap().forEach((key, value) {
      value.indexInDeck = key;
      value.efl = 0;
    });
  }

  void setMask(String s) {
    final mask = s.split(" ");
    maskCards.clear();
    fixedTransits.clear();
    mask.asMap().forEach((key, value) {
      if (value != "*") {
        final card = CardItem.fromString(value);
        card.maskCard = true;
        card.indexInDeck = key;
        maskCards.add(card);
      }
    });
  }

  void setMaskByList(List<CardItem> chainModel) {
    maskCards.clear();
    fixedTransits.clear();
    cards.clear();
    for (var i = 0; i < chainModel.length; i++) {
      var item = chainModel[i];
      if (item.fixed) {
        item.maskCard = true;
        item.indexInDeck = i;
        maskCards.add(item);
      } else {
        item.maskCard = false;
        item.indexInDeck = 0;
      }
      cards.add(item);
    }

    for (var item in cards) {
      if (item.minMaxEfl != null && item.minMaxEfl!.start > 0 && item.fixed) {
        item.linked.clear();
        CardSuit.values.forEach((suit) {
          Nominal.values.forEach((nom) {
            if (!(suit == item.suit && nom == item.nominal) &&
                (suit == item.suit || nom == item.nominal)) {
              //карта по номиналу или масти подходит для транзита, но не та же + не закрепленная
              var firstWhere = cards.firstWhere(
                  (element) => element.suit == suit && element.nominal == nom);
              if (!firstWhere.fixed) {
                item.linked.add(firstWhere);
              }
            }
          });
        });
        fixedTransits.add(item);
      }
    }
  }

  bool parse(String s) {
    cards.clear();
    try {
      var fixedChain = s.trim();
      if (fixedChain.contains("<")) {
        fixedChain = s
            .trim()
            .replaceAll("10", "X")
            .toLowerCase()
        
            .runes
            .toList()
            .fold("", (previousValue, element) {
          var s = String.fromCharCode(element);
          return (previousValue ?? "").toString() +
              (okSymbols.contains(s) ? s : "");
        });
      } else if (fixedChain.contains(" ")) {
        fixedChain = s
            .trim()
            .replaceAll("10", "X")
            .toLowerCase()
            .split(" ")
            .map((e) => e.substring(0, 2))
            .fold<String>(
                "", (previousValue, element) => previousValue + element)
            .runes
            .toList()
            .fold("", (previousValue, element) {
          var s = String.fromCharCode(element);
          return (previousValue ?? "").toString() +
              (okSymbols.contains(s) ? s : "");
        });
      } else {
        //гера формат
        fixedChain = s
            .trim()
            .replaceAll("10", "X")
            .toLowerCase()
            /*.split(" ")
          .map((e) => e.substring(0, 2))
          .fold<String>("", (previousValue, element) => previousValue + element)*/
            .runes
            .toList()
            .fold("", (previousValue, element) {
          var s = String.fromCharCode(element);
          return (previousValue ?? "").toString() +
              (okSymbols.contains(s) ? s : "");
        });
      }

      for (var i = 0; i < fixedChain.length; i += 2) {
        final card = CardItem.fromString(fixedChain.substring(i, i + 2));
        card.indexInDeck = cards.length;
        cards.add(card);
      }
      if (cards.length != 36) {
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  List<CardItem> process(List<CardItem> list) {
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
        mobiles.add(middle);
        if (!mobiles.contains(left)) {
          stationars.add(left);
        }
        return process(list.sublist(0, i) + list.sublist(i + 1, list.length));
      }
    }
    return list;
  }

  bool check({int maxTransits = 0}) {
    mobiles.clear();
    stationars.clear();
    hex.clear();
    rightTransit = null;
    final result = process(cards.toList());
    if (cards.isNotEmpty) {
      mobiles.add(cards.last);
    }
    var bool = result.length == 2;
    cards.forEach((element) {
      if (element.minMaxEfl != null) {
        final okCard = element.efl <= element.minMaxEfl!.end &&
            element.efl >= element.minMaxEfl!.start;
        if (!okCard) {
          bool = false;
        }
      }
    });
    if (maxTransits > 0) {
      if (cards.where((element) => element.efl > 0).length > maxTransits) {
        bool = false;
      }
    }
    if (bool) {
      CardSuit.values.forEach((suit) {
        var hex = "";
        List.generate(6, (index) {
          final cardsInLine = cardsToHexLines[index];
          if (mobiles.contains(CardItem(suit, cardsInLine!.first))) {
            hex += "1";
          } else {
            hex += "0";
          }
        });
        this.hex[suit] = hex;
      });
      needHex.keys.forEach((suit) {
        final val = needHex[suit] ?? [];
        if (val.length == 1) {
          if (val.first == -1) {
            //хорошие
          } else if (val.first == -2) {
            //G.-гексы
          } else {
            //точно
            if (!val.contains(hexToNumberMap[this.hex[suit]])) {
              bool = false;
            }
          }
        } else if (val.length > 1) {
          //любая точно
          //точно
          if (!val.contains(hexToNumberMap[this.hex[suit]])) {
            bool = false;
          }
        }
      });
    }
    return bool;
  }

  void printStats() {
    //print(asString(true));
  }
}
