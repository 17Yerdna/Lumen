import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bible_catalog.dart';
import 'database.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});

final bibleReadyProvider = FutureProvider<void>(
  (ref) => ref.watch(databaseProvider).ensureBibleSeeded(),
);

class ReaderLocation {
  const ReaderLocation(this.book, this.chapter);

  final BookInfo book;
  final int chapter;
}

class ReaderLocationController extends Notifier<ReaderLocation> {
  @override
  ReaderLocation build() => ReaderLocation(findBibleBook('Juan')!, 3);

  void goTo(BookInfo book, int chapter) {
    state = ReaderLocation(book, chapter);
  }

  void move(int offset) {
    var bookIndex = bibleBooks.indexOf(state.book);
    var chapter = state.chapter + offset;
    if (chapter < 1 && bookIndex > 0) {
      bookIndex--;
      chapter = bibleBooks[bookIndex].chapters;
    } else if (chapter > state.book.chapters &&
        bookIndex < bibleBooks.length - 1) {
      bookIndex++;
      chapter = 1;
    }
    state = ReaderLocation(
      bibleBooks[bookIndex],
      chapter.clamp(1, bibleBooks[bookIndex].chapters),
    );
  }
}

final readerLocationProvider =
    NotifierProvider<ReaderLocationController, ReaderLocation>(
      ReaderLocationController.new,
    );

final chapterVersesProvider = StreamProvider<List<BibleVerse>>((ref) async* {
  await ref.watch(bibleReadyProvider.future);
  final location = ref.watch(readerLocationProvider);
  yield* ref
      .watch(databaseProvider)
      .watchChapter(location.book.code, location.chapter);
});
