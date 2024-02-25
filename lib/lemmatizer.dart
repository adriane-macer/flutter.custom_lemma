import 'package:flutter/services.dart';

enum POS { NOUN, VERB, ADJ, ADV, ABBR, UNKNOWN }

class Lemmatizer {
  static const WN_FILES = {
    POS.NOUN: ['index_noun.txt', 'noun_exc.txt'],
    POS.VERB: ['index_verb.txt', 'verb_exc.txt'],
    POS.ADJ: ['index_adj.txt', 'adj_exc.txt'],
    POS.ADV: ['index_adv.txt', 'adv_exc.txt']
  };

  static const MORPHOLOGICAL_SUBSTITUTIONS = {
    POS.NOUN: [
      ['s', ''],
      ['ses', 's'],
      ['ves', 'f'],
      ['xes', 'x'],
      ['zes', 'z'],
      ['ches', 'ch'],
      ['shes', 'sh'],
      ['men', 'man'],
      ['ies', 'y']
    ],
    POS.VERB: [
      ['s', ''],
      ['ies', 'y'],
      ['ied', 'y'],
      ['es', 'e'],
      ['es', ''],
      ['ed', 'e'],
      ['ed', ''],
      ['ing', 'e'],
      ['ing', '']
    ],
    POS.ADJ: [
      ['er', ''],
      ['est', ''],
      ['er', 'e'],
      ['est', 'e']
    ],
    POS.ADV: [],
    POS.ABBR: [],
    POS.UNKNOWN: []
  };

  Map wordLists = {};
  Map exceptions = {};

  Lemmatizer() {
    wordLists = {};
    exceptions = {};

    for (final item in MORPHOLOGICAL_SUBSTITUTIONS.keys) {
      wordLists[item] = {};
      exceptions[item] = {};
    }

    for (final entry in WN_FILES.entries) {
      loadWordnetFiles(entry.key, entry.value[0], entry.value[1]);
    }
  }

  String lemma(String form, {String pos = "noun"}) {
    final words = ["verb", "noun", "adj", "adv", "abbr"];
    if (!words.contains(pos)) {
      for (final item in words) {
        final result = lemma(form, pos: item);
        if (result != form) {
          return result;
        }
      }
      return form;
    }

    final POS poss = strToPos(pos);
    final ea = eachLemma(form, poss);
    if (ea != null) {
      return ea.toString();
    }
    return form;
  }

  Future<void> loadWordnetFiles(POS pos, String list, String exc) async {
    final fileList =
        await rootBundle.loadString("packages/lemmma/assets/$list");
    final listLines = fileList.split("\n");

    for (final line in listLines) {
      final w = line.split(" ")[0];
      wordLists[pos][w] = w;
    }

    final fileExc =
        await rootBundle.loadString("packages/lemmma/assets/$exc");
    final listExc = fileExc.split("\n");

    if (fileExc.trim().isNotEmpty) {
      for (final line in listExc) {
        if (line.trim().isNotEmpty) {
          final w = line.split(" ")[0];
          exceptions[pos][w[0]] = exceptions[pos][w[0]] ?? [];
          exceptions[pos][w[0]] = w[1];
        }
      }
    }
  }

  dynamic eachLemma(String form, POS pos) {
    final lemma = exceptions[pos][form];
    if (lemma != null) {
      return lemma;
    }

    if (pos == POS.NOUN && form.endsWith('ful')) {
      return "${eachLemma(form.substring(0, form.length - 3), pos)} ful"; //todo : bak
    }

    return eachSubstitutions(form, pos);
  }

  dynamic eachSubstitutions(String form, POS pos) {
    final lemma = wordLists[pos][form];
    if (lemma != null) {
      return lemma;
    }

    final lst = MORPHOLOGICAL_SUBSTITUTIONS[pos];
    for (final item in lst!) {
      final _old = item[0].toString();
      final _new = item[1].toString();
      if (form.endsWith(_old)) {
        final res = eachSubstitutions(
            form.substring(0, form.length - _old.length) + _new, pos);
        if (res != null) {
          return res;
        }
      }
    }
  }

  POS strToPos(String str) {
    switch (str) {
      case "n":
      case "noun":
        return POS.NOUN;
      case "v":
      case "verb":
        return POS.VERB;
      case "a":
      case "j":
      case "adjective":
      case "adj":
        return POS.ADJ;
      case "r":
      case "adverb":
      case "adv":
        return POS.ABBR;
      default:
        return POS.UNKNOWN;
    }
  }
}
