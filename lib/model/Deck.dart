import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mobile_medici/MersenneTwister.dart';
import '../Helpers.dart';

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
  bool reverse = false;
  bool mirror = false;
  bool fullBalanced = false;
  bool onlyDifferentHexes = false;

  DeckTask(this.mask, this.needHex, this.maxTransits, this.threadIdx,
      this.reverse, this.fullBalanced, this.mirror, this.onlyDifferentHexes);
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
  CardItem? nextTransit;
  var prevTransit = <CardItem>[];

  CardItem(this.suit, this.nominal);

  @override
  String toString() {
    return "${nominalsToLang()[nominal]}${suitsToLang()[suit]!.toLowerCase()}";
  }

  CardItem.fromString(this.cardString) : super() {
    var lowerCased = cardString!.toLowerCase();
    suitsToLang().map((key, value) {
      if (value.toLowerCase() == lowerCased.substring(1, 2)) {
        suit = key;
      }
      return MapEntry(key, value);
    });
    nominalsToLang().map((key, value) {
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

class Hex {
  var data = Map<int, List<bool>>();
  var value = "";
  var fullValue = "";

  void makeStrings() {
    value = "";
    data.keys.forEach((element) {
      value += (data[element] as List<bool>)[0] ? "1" : "0";
    });
    fullValue = "";
    data.keys.forEach((element) {
      var list = (data[element] as List<bool>);
      fullValue += list[0] ? "1" : "0";
      if (list.length > 1) {
        fullValue += list[1] ? "+" : "-";
      }
    });
  }

  void clear() {
    data.clear();
    value = "";
    fullValue = "";
  }

  String localizedName(bool full) {
    var s = hexTable.firstWhere((element) => element.contains(value));
    var indexOf = s.indexOf(' ');
    return s.substring(1, indexOf) +
        (full ? (" " + s.substring(s.indexOf(")") + 1)) : "");
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Hex && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

class Deck {
  List<CardItem> stationars = [];
  List<CardItem> mobiles = [];
  List<CardItem> cards = [];
  Map<CardSuit, Hex> hex = {};
  Map<CardSuit, List<int>> needHex = {};
  CardItem? rightTransit;
  List<CardItem> maskCards = [];
  List<CardItem> fixedTransits = [];
  final okSymbols =
      nominalsToLang().values.map((e) => e.toLowerCase()).toList() +
          suitsToLang().values.map((e) => e.toLowerCase()).toList();
  Deck? reverseDeck;
  String printed = "";

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

  String asShortString() {
    var retVal = "";
    cards.forEach((card) {
      var s = card.toString();
      retVal += s + (card.efl > 0 && true ? "!${card.efl}" : "") + " ";
    });
    return retVal;
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
    //пришлось отключить вывод на русском для не-русских локалей для прохождения ревью в апстор
    if (ruLocale()) {
      var hexString = "";
      hex.forEach((key, value) {
        hexString += hexToEmoji[key]! +
            "${hexTable.firstWhere((element) => element.contains(value.value))}\n";
      });
      retVal += "\n" + hexString;
    }
    return retVal.trim().replaceAll("X", "10") +
        (reverseDeck == null
            ? ""
            : "\nReverse:\n" + reverseDeck!.asString(efl, withoutEfl));
  }

  void shuffle34() {
    cards.clear();
    var noms = <Nominal>[]..addAll(Nominal.values);
    final twoNoms = [
      noms.removeAt(Random().nextInt(noms.length)),
      noms.removeAt(Random().nextInt(noms.length))
    ];
    final microDeck = Deck();
    final microCards = <CardItem>[];
    twoNoms.forEach((nom) {
      CardSuit.values.forEach((suit) {
        microCards.add(CardItem(suit, nom));
      });
    });
    microDeck.cards.clear();
    microDeck.cards.addAll(microCards);
    final maxTrialCount = 10000;
    var trialIdx = 0;
    while (trialIdx < maxTrialCount) {
      microDeck.shuffle();
      if (microDeck.cards.last.suit ==
          microDeck.cards[microDeck.cards.length - 3].suit) {
        if (microDeck.check(maxTransits: 1)) {
          break;
        }
      }
      trialIdx++;
    }
    cards.addAll(microDeck.cards);
    var secondGroup = Deck().cards;
    secondGroup.shuffle();
    secondGroup.removeWhere((element) => microDeck.cards.contains(element));
    //масти которых такие же как и в двух последних карт нашей микро ЦС.
    var firstGroup = secondGroup
        .where((element) =>
            element.suit == microDeck.cards.last.suit ||
            element.suit == microDeck.cards[microDeck.cards.length - 2].suit)
        .toList();
    secondGroup.removeWhere((element) => firstGroup.contains(element));
    var suitsSecondGroup =
        secondGroup.fold<List<CardSuit>>([], (previousValue, element) {
      if (!previousValue.contains(element.suit)) {
        previousValue.add(element.suit!);
      }
      return previousValue;
    });
    var lastSuit = suitsSecondGroup[Random().nextInt(1)];
    for (var i = 0; i < 28; i++) {
      //Теперь собственно наращивание: берем карту, которая одинакова по масти с предпоследней картой и ставим в конец.
      for (var value in firstGroup) {
        //Смотрите, чтобы не было двух подряд идущих карт одинаковых номиналов.
        if (value.suit == cards[cards.length - 2].suit &&
            value.nominal != cards.last.nominal) {
          cards.add(value);
          firstGroup.remove(value);
          break;
        }
      }
      //print(cards);
      var newSuit =
          suitsSecondGroup.where((element) => element != lastSuit).first;
      lastSuit = newSuit;
      //Далее берем карту с второй группы. Она должна быть одинаковой по номиналу с последней картой.
      //Кладем ее так, чтобы она создавала свертку с последней картой, то есть ставим ее третьей с конца.
      for (var value in secondGroup) {
        if (value.suit != newSuit && value.nominal == cards.last.nominal) {
          cards.insert(cards.length - 2, value);
          secondGroup.remove(value);
          break;
        }
      }
      //print(cards);
    }
    if (cards.length < 36) {
      cards.clear();
    }
    //print(cards);
    if (maskCards.length > 0 && cards.length == 36) {
      maskCards.sort((a, b) {
        return a.indexInDeck.compareTo(b.indexInDeck);
      });
      CardItem wantedTransit =
          CardItem(maskCards.last.suit, maskCards.last.nominal);
      CardItem swapCard = new CardItem(cards.last.suit, cards.last.nominal);
      if (swapCard != wantedTransit) {
        //ищем ее в картах и меняем
        //поменять все масти
        //и все номиналы
        var newCards = <CardItem>[];
        cards.forEach((element) {
          if (element.suit == swapCard.suit) {
            element.suit = wantedTransit.suit;
          } else if (element.suit == wantedTransit.suit) {
            element.suit = swapCard.suit;
          }
          if (element.nominal == swapCard.nominal) {
            element.nominal = wantedTransit.nominal;
          } else if (element.nominal == wantedTransit.nominal) {
            element.nominal = swapCard.nominal;
          }
        });
      }
      cards.last.fixed = true;
    }
    //print(cards);
    cards.asMap().forEach((key, value) {
      value.indexInDeck = key;
      value.efl = 0;
    });
  }

  CardItem? nextMirrorCard(CardItem fromCard) {
    //ищем первую подходящую
    for (var j = 0; j < cards.length; j++) {
      var nextCard = cards[j];
      if (nextCard.indexInDeck != -1 || fromCard == nextCard) {
        continue;
      }
      if (nextCard.suit == fromCard.suit ||
          nextCard.nominal == fromCard.nominal) {
        return nextCard;
      }
    }
    return null;
  }

  //тут похоже можно ускорить если для очередной генерить рандомную подходящую в зеркальной позиции
  //с учетом количества использований номинала/масти в половине. а то они в 3/4 случаев собираются в кучку
  bool shuffleMirror() {
    cards.shuffle();
    cards.removeWhere((element) => maskCards.contains(element));
    maskCards.forEach((element) {
      cards.insert(element.indexInDeck, element);
    });
    cards.forEach((element) {
      if (!maskCards.contains(element)) {
        element.indexInDeck = -1;
      }
    });
    //print(cards.map((e) => e.indexInDeck));
    for (var i = 0; i < cards.length; i++) {
      var card = cards[i];
      if (!card.fixed) {
        continue;
      }
      var mirrorIndex =
          cards.length - card.indexInDeck - 1; //куда вставить зеркальную
      var existCard = cards[mirrorIndex];
      if (existCard.suit == card.suit || existCard.nominal == card.nominal) {
        continue;
      }

      var nextCard = nextMirrorCard(card);
      if (nextCard == null) {
        return false;
      }
      var nextCardIdx = cards.indexOf(nextCard);
      var swap = cards[mirrorIndex]; //что тут было
      cards[mirrorIndex] = nextCard;
      cards[nextCardIdx] = swap; //меняем местами
      nextCard.indexInDeck = mirrorIndex;
    }

    for (var i = 0; i < cards.length; i++) {
      var card = cards[i];
      if (card.indexInDeck != -1) {
        continue;
      }
      card.indexInDeck = i;
      var found = false;
      //ищем первую подходящую
      for (var j = i + 1; j < cards.length; j++) {
        var nextCard = cards[j];
        if (nextCard.indexInDeck != -1) {
          continue;
        }
        if (nextCard.suit == card.suit || nextCard.nominal == card.nominal) {
          var newIndex = cards.length - 1 - i;
          var swap = cards[newIndex];
          cards[newIndex] = nextCard;
          nextCard.indexInDeck = newIndex;
          cards[j] = swap;
          found = true;
          break;
        }
      }
      if (!found) {
        return false;
      }
    }
    cards.asMap().forEach((key, value) {
      if (value.indexInDeck == -1) {
        value.indexInDeck = key;
      }
      value.efl = 0;
    });
    return true;
  }

  void shuffle() {
    // cards.shuffle(MersenneTwister(DateTime.now().microsecond));
    cards.shuffle();
    cards.removeWhere((element) => maskCards.contains(element));
    maskCards.forEach((element) {
      cards.insert(element.indexInDeck, element);
    });

    //небольшая хитрость - если у нас есть заданные транзиты с фиксированноой позицией подставляем
    // за одну карту до них только подходящие чтоб сделать их транзитом
    var allLinked = <CardItem>[];
    for (var item in fixedTransits) {
      if (item.indexInDeck > 1) {
        item.linked.shuffle();
        for (var linkedItem in item.linked) {
          if (!allLinked.contains(linkedItem)) {
            allLinked.add(linkedItem);
            var linkedPos = cards.indexOf(linkedItem);
            var preTransitIdx = item.indexInDeck - 2;
            var temp = cards[preTransitIdx];
            if (temp.fixed) {
              break;
            }
            cards[preTransitIdx] = linkedItem;
            cards[linkedPos] = temp;
            allLinked.add(linkedItem);
            break;
          }
        }
      }
    }
    cards.asMap().forEach((key, value) {
      value.indexInDeck = key;
      if (value.indexInDeck == 35) {
        //print("oy vei");
      }
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
      var fixedChain = s.trim().replaceAll("Х", "X").replaceAll("] ", "]");
      if (fixedChain.contains("<")) {
        fixedChain = s
            .trim()
            .replaceAll("10", "X")
            .toLowerCase()
            .runes
            .toList()
            .fold("", (previousValue, element) {
          var s = String.fromCharCode(element);
          return (previousValue).toString() + (okSymbols.contains(s) ? s : "");
        });
      } else if (fixedChain.contains("]")) {
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
          return (previousValue).toString() + (okSymbols.contains(s) ? s : "");
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
          return (previousValue).toString() + (okSymbols.contains(s) ? s : "");
        });
      } else {
        var lowerCased = s.trim().replaceAll("10", "X").toLowerCase();

        var charList = [];
        lowerCased.runes.forEach((int rune) {
          var character = new String.fromCharCode(rune);
          charList.add(character);
        });
        var list = [];
        for (var i = 0; i < charList.length; i += 2) {
          list.add("${charList[i]}${charList[i + 1]}");
        }
        list
            .map((e) => e.substring(0, 2))
            .fold<String>(
                "", (previousValue, element) => previousValue + element)
            .runes
            .toList()
            .fold("", (previousValue, element) {
          var s = String.fromCharCode(element);
          return (previousValue).toString() + (okSymbols.contains(s) ? s : "");
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
        left.nextTransit = right;
        right.prevTransit.add(left);

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

  bool check(
      {int maxTransits = 0,
      bool reverse = false,
      bool fullBalanced = false,
      bool onlyDifferentHexes = false}) {
    mobiles.clear();
    stationars.clear();
    hex.clear();
    rightTransit = null;
    cards.forEach((element) {
      element.prevTransit.clear();
      element.nextTransit = null;
    });
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
    reverseDeck = null;
    if (bool && reverse) {
      final deck = Deck();
      deck.cards.clear();
      var index = 0;
      deck.cards.addAll(cards.reversed.map((e) {
        var cardItem = CardItem(e.suit, e.nominal);
        cardItem.indexInDeck = index;
        index++;
        return cardItem;
      }));
      if (bool) {
        bool = deck.check(maxTransits: maxTransits);
        if (bool) {
          reverseDeck = deck;
        }
      }
    }

    if (bool) {
      CardSuit.values.forEach((suit) {
        var hex = Hex();
        List.generate(6, (index) {
          final cardsInLine = cardsToHexLines[index];
          if (mobiles.contains(CardItem(suit, cardsInLine!.first))) {
            hex.data[index] = [true];
          } else {
            hex.data[index] = [false];
          }
          if (cardsInLine.length > 1) {
            if (mobiles.contains(CardItem(suit, cardsInLine[1]))) {
              hex.data[index]!.add(true);
            } else {
              hex.data[index]!.add(false);
            }
          }
        });
        hex.makeStrings();
        if (onlyDifferentHexes) {
          if (this.hex.values.contains(hex)) {
            bool = false;
          }
        }
        this.hex[suit] = hex;
      });

      //тест точного поиска по гексам
      //очень долго =(
      /*if (bool) {
        final spades = "1-1-01-00";
        final hearts = "0-1+01+00";
        final diamonds="1+1+10-11";
        final clubs =  "1+0-11+11";
        if (this.hex[CardSuit.spades]!.fullValue != spades) {
          bool = false;
        } else if (this.hex[CardSuit.clubs]!.fullValue != clubs) {
          bool = false;
        } else if (this.hex[CardSuit.hearts]!.fullValue != hearts) {
          bool = false;
        } else if (this.hex[CardSuit.diamonds]!.fullValue != diamonds) {
          bool = false;
        }
      }*/

      if (bool) {
        //поиск с полным балансом
        if (fullBalanced) {
          for (var i = 0; i < cardsToHexLines.length; i++) {
            var sum = 0;
            CardSuit.values.forEach((suit) {
              sum += this.hex[suit]!.data[i]!.first ? 1 : 0;
            });
            if (sum != 2) {
              bool = false;
            }
          }
        }
      }

      if (bool) {
        needHex.keys.forEach((suit) {
          final val = needHex[suit] ?? [];
          if (val.length == 1) {
            if (val.first == -1) {
              //хорошие
            } else if (val.first == -2) {
              //G.-гексы
            } else {
              //точно
              if (!val.contains(hexToNumberMap[this.hex[suit]!.value])) {
                bool = false;
              }
            }
          } else if (val.length > 1) {
            //любая точно
            //точно
            if (!val.contains(hexToNumberMap[this.hex[suit]!.value])) {
              bool = false;
            }
          }
        });
      }
    }
    if (bool) {
      printed = asShortString();
    }
    return bool;
  }

  void printStats() {
    //print(asString(true));
  }

  @override
  bool operator ==(Object other) {
    return other is Deck && other.printed == printed;
  }

  @override
  int get hashCode => printed.hashCode;
}
