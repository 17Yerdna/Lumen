class BookInfo {
  const BookInfo(
    this.code,
    this.name,
    this.chapters, [
    this.aliases = const [],
  ]);

  final String code;
  final String name;
  final int chapters;
  final List<String> aliases;
}

const bibleBooks = <BookInfo>[
  BookInfo('GEN', 'Génesis', 50, ['genesis', 'gn']),
  BookInfo('EXO', 'Éxodo', 40, ['exodo', 'ex']),
  BookInfo('LEV', 'Levítico', 27, ['levitico', 'lv']),
  BookInfo('NUM', 'Números', 36, ['numeros', 'nm']),
  BookInfo('DEU', 'Deuteronomio', 34, ['dt']),
  BookInfo('JOS', 'Josué', 24, ['josue']),
  BookInfo('JDG', 'Jueces', 21, ['jue']),
  BookInfo('RUT', 'Rut', 4),
  BookInfo('1SA', '1 Samuel', 31, ['1 samuel', '1 sam']),
  BookInfo('2SA', '2 Samuel', 24, ['2 samuel', '2 sam']),
  BookInfo('1KI', '1 Reyes', 22, ['1 reyes', '1 rey']),
  BookInfo('2KI', '2 Reyes', 25, ['2 reyes', '2 rey']),
  BookInfo('1CH', '1 Crónicas', 29, ['1 cronicas', '1 cr']),
  BookInfo('2CH', '2 Crónicas', 36, ['2 cronicas', '2 cr']),
  BookInfo('EZR', 'Esdras', 10, ['esd']),
  BookInfo('NEH', 'Nehemías', 13, ['nehemias']),
  BookInfo('EST', 'Ester', 10),
  BookInfo('JOB', 'Job', 42),
  BookInfo('PSA', 'Salmos', 150, ['salmo', 'sal', 'sl']),
  BookInfo('PRO', 'Proverbios', 31, ['prov', 'pr']),
  BookInfo('ECC', 'Eclesiastés', 12, ['eclesiastes', 'ecl']),
  BookInfo('SOL', 'Cantar de los Cantares', 8, ['cantares', 'cantar']),
  BookInfo('ISA', 'Isaías', 66, ['isaias', 'is']),
  BookInfo('JER', 'Jeremías', 52, ['jeremias', 'jer']),
  BookInfo('LAM', 'Lamentaciones', 5, ['lam']),
  BookInfo('EZE', 'Ezequiel', 48, ['ez']),
  BookInfo('DAN', 'Daniel', 12, ['dn']),
  BookInfo('HOS', 'Oseas', 14, ['os']),
  BookInfo('JOE', 'Joel', 3),
  BookInfo('AMO', 'Amós', 9, ['amos']),
  BookInfo('OBA', 'Abdías', 1, ['abdias']),
  BookInfo('JON', 'Jonás', 4, ['jonas']),
  BookInfo('MIC', 'Miqueas', 7, ['miq']),
  BookInfo('NAH', 'Nahum', 3),
  BookInfo('HAB', 'Habacuc', 3),
  BookInfo('ZEP', 'Sofonías', 3, ['sofonias']),
  BookInfo('HAG', 'Hageo', 2),
  BookInfo('ZEC', 'Zacarías', 14, ['zacarias', 'zac']),
  BookInfo('MAL', 'Malaquías', 4, ['malaquias', 'mal']),
  BookInfo('MAT', 'Mateo', 28, ['mt']),
  BookInfo('MAR', 'Marcos', 16, ['mr', 'mc']),
  BookInfo('LUK', 'Lucas', 24, ['lc']),
  BookInfo('JOH', 'Juan', 21, ['jn']),
  BookInfo('ACT', 'Hechos', 28, ['hch']),
  BookInfo('ROM', 'Romanos', 16, ['rom', 'ro']),
  BookInfo('1CO', '1 Corintios', 16, ['1 corintios', '1 cor']),
  BookInfo('2CO', '2 Corintios', 13, ['2 corintios', '2 cor']),
  BookInfo('GAL', 'Gálatas', 6, ['galatas', 'gal']),
  BookInfo('EPH', 'Efesios', 6, ['ef']),
  BookInfo('PHI', 'Filipenses', 4, ['fil']),
  BookInfo('COL', 'Colosenses', 4, ['col']),
  BookInfo('1TH', '1 Tesalonicenses', 5, ['1 tesalonicenses', '1 tes']),
  BookInfo('2TH', '2 Tesalonicenses', 3, ['2 tesalonicenses', '2 tes']),
  BookInfo('1TI', '1 Timoteo', 6, ['1 timoteo', '1 tim']),
  BookInfo('2TI', '2 Timoteo', 4, ['2 timoteo', '2 tim']),
  BookInfo('TIT', 'Tito', 3),
  BookInfo('PHM', 'Filemón', 1, ['filemon', 'flm']),
  BookInfo('HEB', 'Hebreos', 13, ['heb']),
  BookInfo('JAM', 'Santiago', 5, ['stg']),
  BookInfo('1PE', '1 Pedro', 5, ['1 pedro', '1 pe']),
  BookInfo('2PE', '2 Pedro', 3, ['2 pedro', '2 pe']),
  BookInfo('1JO', '1 Juan', 5, ['1 juan', '1 jn']),
  BookInfo('2JO', '2 Juan', 1, ['2 juan', '2 jn']),
  BookInfo('3JO', '3 Juan', 1, ['3 juan', '3 jn']),
  BookInfo('JUD', 'Judas', 1),
  BookInfo('REV', 'Apocalipsis', 22, ['apoc', 'ap']),
];

class BibleCategory {
  const BibleCategory(this.name, this.start, this.end);

  final String name;
  final int start;
  final int end;

  List<BookInfo> get books => bibleBooks.sublist(start, end);
}

const oldTestamentCategories = <BibleCategory>[
  BibleCategory('Pentateuco', 0, 5),
  BibleCategory('Históricos', 5, 17),
  BibleCategory('Poéticos y sapienciales', 17, 22),
  BibleCategory('Profetas mayores', 22, 27),
  BibleCategory('Profetas menores', 27, 39),
];

const newTestamentCategories = <BibleCategory>[
  BibleCategory('Evangelios', 39, 43),
  BibleCategory('Historia', 43, 44),
  BibleCategory('Cartas paulinas', 44, 57),
  BibleCategory('Cartas generales', 57, 65),
  BibleCategory('Profecía', 65, 66),
];

String normalizeBibleText(String value) {
  return value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ü', 'u')
      .replaceAll(RegExp(r'\s+'), ' ');
}

BookInfo? findBibleBook(String input) {
  final normalized = normalizeBibleText(input);
  for (final book in bibleBooks) {
    final candidates = [book.code, book.name, ...book.aliases];
    if (candidates.any(
      (candidate) => normalizeBibleText(candidate) == normalized,
    )) {
      return book;
    }
  }
  return null;
}

class BibleReference {
  const BibleReference({
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });

  final BookInfo book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;

  String get label {
    if (startVerse == null) return '${book.name} $chapter';
    final range = endVerse != null && endVerse != startVerse
        ? '$startVerse–$endVerse'
        : '$startVerse';
    return '${book.name} $chapter:$range';
  }
}

BibleReference? parseBibleReference(String input) {
  final match = RegExp(
    r'^(.+?)\s+(\d+)(?::(\d+)(?:\s*[-–]\s*(\d+))?)?$',
  ).firstMatch(input.trim());
  if (match == null) return null;

  final book = findBibleBook(match.group(1)!);
  final chapter = int.tryParse(match.group(2)!);
  final start = int.tryParse(match.group(3) ?? '');
  final end = int.tryParse(match.group(4) ?? '');
  if (book == null ||
      chapter == null ||
      chapter < 1 ||
      chapter > book.chapters) {
    return null;
  }
  if (start != null && start < 1) return null;
  if (end != null && (start == null || end < start)) return null;
  return BibleReference(
    book: book,
    chapter: chapter,
    startVerse: start,
    endVerse: end,
  );
}
