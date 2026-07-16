part of '../../screens.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final selected = <int>{};
  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  void toggleVerse(int number) {
    setState(() {
      selected.contains(number)
          ? selected.remove(number)
          : selected.add(number);
    });
  }

  @override
  Widget build(BuildContext context) {
    final view = ref.watch(readerViewProvider);
    final location = ref.watch(readerLocationProvider);
    ref.listen(readerLocationProvider, (previous, next) {
      if (previous != null &&
          (previous.book != next.book || previous.chapter != next.chapter) &&
          mounted) {
        setState(() {
          selected.clear();
          noteController.clear();
        });
      }
    });
    final child = switch (view) {
      ReaderView.books => _BibleCatalog(
        onBook: _showChapters,
        onContinue: _openChapter,
      ),
      ReaderView.chapters => _ChapterCatalog(
        book: location.book,
        onBack: _showBooks,
        onChapter: (chapter) => _openChapter(location.book, chapter),
      ),
      ReaderView.reader => _buildReader(location),
    };
    return PopScope(
      canPop: view == ReaderView.books,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _goBack(view, location);
      },
      child: child,
    );
  }

  Widget _buildReader(ReaderLocation location) {
    final verses = ref.watch(chapterVersesProvider);
    final preferences = {
      for (final item
          in ref.watch(versePreferencesProvider).value ??
              const <VersePreference>[])
        item.verseId: item,
    };
    return LayoutBuilder(
      builder: (context, constraints) {
        final showPanel = constraints.maxWidth >= 1024;
        final reader = verses.when(
          data: (items) => _ReaderDocument(
            location: location,
            selected: selected,
            verses: items,
            preferences: preferences,
            onToggle: toggleVerse,
            onPrevious: () => _moveChapter(-1),
            onNext: () => _moveChapter(1),
            onBack: () => _showChapters(location.book),
            onBooks: _showBooks,
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('No se pudo cargar la Biblia: $error'),
            ),
          ),
        );
        return Scaffold(
          body: Row(
            children: [
              Expanded(child: reader),
              if (showPanel) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: math.min(370, constraints.maxWidth * .32),
                  child: _StudyPanel(
                    selected: selected,
                    location: location,
                    noteController: noteController,
                    onExplain: _openAssistant,
                    onMarkRead: _markRead,
                    onSaveNote: _saveNote,
                    onFavorite: () => _setFavorite(true),
                    onHighlight: _setHighlight,
                  ),
                ),
              ],
            ],
          ),
          bottomNavigationBar: !showPanel && selected.isNotEmpty
              ? SafeArea(
                  child: Material(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${selected.length} seleccionado${selected.length == 1 ? '' : 's'}',
                            ),
                          ),
                          IconButton(
                            tooltip: 'Marcar leído',
                            onPressed: _markRead,
                            icon: const Icon(Icons.check_circle_outline),
                          ),
                          IconButton(
                            tooltip: 'Nota',
                            onPressed: _showNoteSheet,
                            icon: const Icon(Icons.edit_note_rounded),
                          ),
                          IconButton(
                            tooltip: 'Explicar',
                            onPressed: _openAssistant,
                            icon: const Icon(Icons.auto_awesome_outlined),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : null,
        );
      },
    );
  }

  void _goBack(ReaderView view, ReaderLocation location) {
    if (view == ReaderView.reader) {
      _showChapters(location.book);
    } else if (view == ReaderView.chapters) {
      _showBooks();
    }
  }

  void _showBooks() {
    ref.read(readerViewProvider.notifier).showBooks();
    setState(selected.clear);
  }

  void _showChapters(BookInfo book) {
    ref.read(readerViewProvider.notifier).showChapters(book);
    setState(selected.clear);
  }

  void _openChapter(BookInfo book, int chapter) {
    setState(selected.clear);
    unawaited(ref.read(readerViewProvider.notifier).openChapter(book, chapter));
  }

  void _moveChapter(int offset) {
    setState(selected.clear);
    unawaited(ref.read(readerViewProvider.notifier).moveChapter(offset));
  }

  Iterable<String> _selectedIds() {
    final location = ref.read(readerLocationProvider);
    return selected.map(
      (verse) => '${location.book.code}.${location.chapter}.$verse',
    );
  }

  void _openAssistant() {
    final location = ref.read(readerLocationProvider);
    final numbers = selected.toList()..sort();
    final verses =
        (ref.read(chapterVersesProvider).value ?? const <BibleVerse>[])
            .where((verse) => selected.contains(verse.verse))
            .toList();
    if (numbers.isEmpty || verses.isEmpty) return;
    final consecutive = numbers.indexed.every(
      (item) => item.$2 == numbers.first + item.$1,
    );
    final verseLabel = numbers.length == 1
        ? '${numbers.first}'
        : consecutive
        ? '${numbers.first}–${numbers.last}'
        : numbers.join(', ');
    context.push(
      '/assistant',
      extra: AssistantPassage(
        reference: '${location.book.name} ${location.chapter}:$verseLabel',
        text: verses.map((verse) => '${verse.verse} ${verse.body}').join('\n'),
      ),
    );
  }

  Future<void> _markRead() async {
    final location = ref.read(readerLocationProvider);
    await ref
        .read(databaseProvider)
        .markRead(location.book.code, location.chapter, selected);
    ref.invalidate(syncProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lectura registrada')));
    }
  }

  Future<void> _saveNote() async {
    final body = noteController.text.trim();
    if (body.isEmpty) return;
    final location = ref.read(readerLocationProvider);
    await ref
        .read(databaseProvider)
        .saveNote(location.book, location.chapter, selected, body);
    ref.invalidate(syncProvider);
    if (!mounted) return;
    noteController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nota guardada')));
  }

  Future<void> _setFavorite(bool value) async {
    await ref.read(databaseProvider).setFavorite(_selectedIds(), value);
    ref.invalidate(syncProvider);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Añadido a favoritos')));
    }
  }

  Future<void> _setHighlight(Color color) async {
    await ref
        .read(databaseProvider)
        .setHighlight(_selectedIds(), color.toARGB32());
    ref.invalidate(syncProvider);
  }

  void _showNoteSheet() {
    final controller = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Nueva nota',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '¿Qué quieres recordar de este pasaje?',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                noteController.text = controller.text;
                await _saveNote();
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Guardar nota'),
            ),
          ],
        ),
      ),
    ).whenComplete(controller.dispose);
  }
}

class _BibleCatalog extends ConsumerWidget {
  const _BibleCatalog({required this.onBook, required this.onContinue});

  final ValueChanged<BookInfo> onBook;
  final void Function(BookInfo, int) onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview =
        ref.watch(lastReadingPreviewProvider).value ??
        ReadingPreview(ReaderLocation(bibleBooks.first, 1), '');
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const ScreenHeading(
                      title: 'Biblia',
                      subtitle: 'Elige un libro y después un capítulo.',
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.play_circle_outline_rounded),
                        title: Text(
                          'Continuar en ${preview.location.book.name} '
                          '${preview.location.chapter}',
                        ),
                        subtitle: Text(
                          preview.text.isEmpty
                              ? 'Comienza tu lectura.'
                              : preview.text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.arrow_forward_rounded),
                        onTap: () => onContinue(
                          preview.location.book,
                          preview.location.chapter,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const TabBar(
                      tabs: [
                        Tab(text: 'Antiguo Testamento'),
                        Tab(text: 'Nuevo Testamento'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _BookGroupsList(
                  categories: oldTestamentCategories,
                  onBook: onBook,
                ),
                _BookGroupsList(
                  categories: newTestamentCategories,
                  onBook: onBook,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BookGroupsList extends StatelessWidget {
  const _BookGroupsList({required this.categories, required this.onBook});

  final List<BibleCategory> categories;
  final ValueChanged<BookInfo> onBook;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
    children: [
      Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final category in categories) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 18, bottom: 10),
                  child: Text(
                    category.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 190,
                    mainAxisExtent: 58,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                  ),
                  itemCount: category.books.length,
                  itemBuilder: (context, index) {
                    final book = category.books[index];
                    return OutlinedButton(
                      key: Key('book-${book.code}'),
                      onPressed: () => onBook(book),
                      child: Text(
                        book.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    ],
  );
}

class _ChapterCatalog extends ConsumerWidget {
  const _ChapterCatalog({
    required this.book,
    required this.onBack,
    required this.onChapter,
  });

  final BookInfo book;
  final VoidCallback onBack;
  final ValueChanged<int> onChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last = ref.watch(lastReaderLocationProvider).value;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 16, 20, 12),
          child: Row(
            children: [
              IconButton(
                key: const Key('chapters-back-books'),
                tooltip: 'Todos los libros',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Text('Selecciona un capítulo'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 86,
              mainAxisExtent: 58,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: book.chapters,
            itemBuilder: (context, index) {
              final chapter = index + 1;
              final isLast = last?.book == book && last?.chapter == chapter;
              final child = Text('$chapter');
              return isLast
                  ? FilledButton.tonal(
                      key: Key('chapter-$chapter'),
                      onPressed: () => onChapter(chapter),
                      child: child,
                    )
                  : OutlinedButton(
                      key: Key('chapter-$chapter'),
                      onPressed: () => onChapter(chapter),
                      child: child,
                    );
            },
          ),
        ),
      ],
    );
  }
}

class _ReaderDocument extends StatelessWidget {
  const _ReaderDocument({
    required this.location,
    required this.selected,
    required this.verses,
    required this.preferences,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
    required this.onBack,
    required this.onBooks,
  });

  final ReaderLocation location;
  final Set<int> selected;
  final List<BibleVerse> verses;
  final Map<String, VersePreference> preferences;
  final ValueChanged<int> onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onBooks;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              IconButton(
                key: const Key('reader-back-chapters'),
                tooltip: 'Capítulos de este libro',
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              IconButton(
                tooltip: 'Capítulo anterior',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  onTap: onBack,
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    children: [
                      Text(
                        location.book.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        'Capítulo ${location.chapter} · RV1909',
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Capítulo siguiente',
                onPressed: onNext,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
              IconButton(
                tooltip: 'Todos los libros',
                onPressed: onBooks,
                icon: const Icon(Icons.library_books_outlined),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SelectionArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 80),
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${location.book.name} ${location.chapter}',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        for (final verse in verses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Material(
                              color: selected.contains(verse.verse)
                                  ? colors.primaryContainer.withValues(
                                      alpha: .75,
                                    )
                                  : preferences[verse.id]?.highlightColor !=
                                        null
                                  ? Color(
                                      preferences[verse.id]!.highlightColor!,
                                    ).withValues(alpha: .45)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => onToggle(verse.verse),
                                onLongPress: () => onToggle(verse.verse),
                                borderRadius: BorderRadius.circular(10),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  child: Text.rich(
                                    TextSpan(
                                      children: [
                                        TextSpan(
                                          text: '${verse.verse}  ',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: verse.body,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyLarge
                                              ?.copyWith(fontSize: 19),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _StudyPanel extends StatelessWidget {
  const _StudyPanel({
    required this.selected,
    required this.location,
    required this.noteController,
    required this.onExplain,
    required this.onMarkRead,
    required this.onSaveNote,
    required this.onFavorite,
    required this.onHighlight,
  });

  final Set<int> selected;
  final ReaderLocation location;
  final TextEditingController noteController;
  final VoidCallback onExplain;
  final VoidCallback onMarkRead;
  final VoidCallback onSaveNote;
  final VoidCallback onFavorite;
  final ValueChanged<Color> onHighlight;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Text('Estudio', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 6),
        Text(
          selected.isEmpty
              ? 'Selecciona un versículo'
              : '${location.book.name} ${location.chapter}:${selected.toList()..sort()}'
                    .replaceAll('[', '')
                    .replaceAll(']', ''),
        ),
        const SizedBox(height: 22),
        FilledButton.icon(
          onPressed: selected.isEmpty ? null : onExplain,
          icon: const Icon(Icons.auto_awesome_rounded),
          label: const Text('Explicar este pasaje'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: selected.isEmpty ? null : onMarkRead,
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar como leído'),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: selected.isEmpty ? null : onFavorite,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('Añadir a favoritos'),
        ),
        const SizedBox(height: 24),
        Text('Nota personal', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        TextField(
          controller: noteController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'Escribe una reflexión...',
          ),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: selected.isEmpty ? null : onSaveNote,
          child: const Text('Guardar nota'),
        ),
        const SizedBox(height: 24),
        Text('Resaltado', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: [
            for (final color in const [
              Color(0xFFFFD166),
              Color(0xFF95D5B2),
              Color(0xFFA9D6E5),
              Color(0xFFE4C1F9),
              Color(0xFFFFADAD),
            ])
              _ColorDot(color: color, onTap: () => onHighlight(color)),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color, required this.onTap});
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    customBorder: const CircleBorder(),
    child: Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    ),
  );
}
