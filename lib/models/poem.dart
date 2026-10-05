class PoemToken {
  final String text;
  final bool isContext;
  final bool isUppercase;

  PoemToken({
    required this.text,
    required this.isContext,
    required this.isUppercase,
  });

  factory PoemToken.fromJson(Map<String, dynamic> json) {
    return PoemToken(
      text: json['text'] ?? '',
      isContext: json['isContext'] ?? false,
      isUppercase: json['isUppercase'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'isContext': isContext, 'isUppercase': isUppercase};
  }
}

class Poem {
  final int id;
  final String word;
  final String phonetic;
  final String meanings;
  final String letter;
  final bool isFree;
  final bool isLearned;
  final List<PoemToken> tokens;
  // Number of highlighted meaning words; sent even when tokens are hidden.
  final int meaningsCount;
  // Ready-made meanings list, shown verbatim; empty when tokens are hidden.
  final List<String> meaningLines;

  Poem({
    required this.id,
    required this.word,
    required this.phonetic,
    required this.meanings,
    required this.letter,
    required this.isFree,
    this.isLearned = false,
    required this.tokens,
    this.meaningsCount = 0,
    this.meaningLines = const [],
  });

  factory Poem.fromJson(Map<String, dynamic> json) {
    return Poem(
      id: json['id'],
      word: json['word'] ?? '',
      phonetic: json['phonetic'] ?? '',
      meanings: json['meanings'] ?? '',
      letter: json['letter'] ?? '',
      isFree: json['is_free'] ?? false,
      isLearned: json['is_learned'] ?? false,
      tokens:
          (json['tokens'] as List<dynamic>?)
              ?.map((token) => PoemToken.fromJson(token))
              .toList() ??
          [],
      meaningsCount: json['meanings_count'] ?? 0,
      meaningLines:
          (json['meaning_lines'] as List<dynamic>?)
              ?.whereType<String>()
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'phonetic': phonetic,
      'meanings': meanings,
      'letter': letter,
      'is_free': isFree,
      'is_learned': isLearned,
      'tokens': tokens.map((token) => token.toJson()).toList(),
      'meanings_count': meaningsCount,
      'meaning_lines': meaningLines,
    };
  }

  String getFullText() {
    return tokens.map((token) => token.text).join();
  }
}
