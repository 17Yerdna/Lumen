import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bible_catalog.dart';
import 'bible_providers.dart';
import 'backend.dart';
import 'database.dart';
import 'reminders.dart';

class PageFrame extends StatelessWidget {
  const PageFrame({required this.child, this.maxWidth = 1180, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

class ScreenHeading extends StatelessWidget {
  const ScreenHeading({
    required this.title,
    required this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 16), trailing!],
      ],
    );
  }
}

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity =
        ref.watch(readingActivityProvider).value ?? const <ReadingEntry>[];
    final noteCount = ref.watch(notesProvider).value?.length ?? 0;
    final stats = calculateReadingStats(activity, DateTime.now());
    final goal = ref.watch(dailyGoalProvider).value ?? 10;
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Buenos días',
            subtitle: 'Un momento de lectura puede iluminar todo el día.',
            trailing: IconButton.filledTonal(
              tooltip: 'Notificaciones',
              onPressed: () => showReadingSettings(context, ref),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
          ),
          const SizedBox(height: 28),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final continueCard = _ContinueReadingCard(
                onContinue: () => context.go('/reader'),
              );
              final goalCard = _DailyGoalCard(read: stats.today, goal: goal);
              return wide
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 3, child: continueCard),
                          const SizedBox(width: 18),
                          Expanded(flex: 2, child: goalCard),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        continueCard,
                        const SizedBox(height: 16),
                        goalCard,
                      ],
                    );
            },
          ),
          const SizedBox(height: 26),
          Text('Tu camino', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _StatGrid(stats: stats, noteCount: noteCount),
          const SizedBox(height: 26),
          Text(
            'Actividad reciente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _RecentActivity(entries: activity.take(3).toList()),
        ],
      ),
    );
  }
}

class _ContinueReadingCard extends StatelessWidget {
  const _ContinueReadingCard({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      color: colors.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_stories_rounded,
                  color: colors.onPrimaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'CONTINUAR LECTURA',
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: colors.onPrimaryContainer,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            Text(
              'Juan 3',
              style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                color: colors.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '“Porque de tal manera amó Dios al mundo...”',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: colors.onPrimaryContainer.withValues(alpha: .8),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Seguir leyendo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _DailyGoalCard extends StatelessWidget {
  const _DailyGoalCard({required this.read, required this.goal});

  final int read;
  final int goal;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Meta de hoy',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Icon(Icons.flag_outlined),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$read',
                  style: const TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8, left: 6),
                  child: Text('de $goal versículos'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: (read / goal).clamp(0, 1),
              minHeight: 10,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            const SizedBox(height: 16),
            Text(
              read >= goal
                  ? 'Meta completada por hoy.'
                  : 'Te faltan ${goal - read} para completar tu meta.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats, required this.noteCount});

  final ReadingStats stats;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        Icons.local_fire_department_outlined,
        '${stats.currentStreak} días',
        'Racha actual',
      ),
      (Icons.menu_book_outlined, '${stats.total}', 'Versículos leídos'),
      (Icons.sticky_note_2_outlined, '$noteCount', 'Notas guardadas'),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 700
            ? (constraints.maxWidth - 32) / 3
            : constraints.maxWidth;
        return Wrap(
          spacing: 16,
          runSpacing: 12,
          children: [
            for (final stat in items)
              SizedBox(
                width: itemWidth,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        CircleAvatar(child: Icon(stat.$1)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stat.$2,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                stat.$3,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity({required this.entries});

  final List<ReadingEntry> entries;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.auto_stories_rounded)),
          title: Text('Tu actividad aparecerá aquí'),
          subtitle: Text('Marca un versículo como leído para comenzar.'),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var index = 0; index < entries.length; index++) ...[
            if (index > 0) const Divider(height: 1, indent: 72),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.check_rounded)),
              title: Text(
                'Marcaste ${findBibleBook(entries[index].bookCode)!.name} '
                '${entries[index].chapter}:${entries[index].verse} como leído',
              ),
              subtitle: Text(entries[index].readDay),
            ),
          ],
        ],
      ),
    );
  }
}

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  final selected = <int>{16};
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
    final location = ref.watch(readerLocationProvider);
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
            onChoosePassage: _choosePassage,
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
                            onPressed: () => context.push('/assistant'),
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

  void _moveChapter(int offset) {
    ref.read(readerLocationProvider.notifier).move(offset);
    setState(selected.clear);
  }

  Future<void> _choosePassage() async {
    final current = ref.read(readerLocationProvider);
    var book = current.book;
    var chapter = current.chapter;
    final result = await showDialog<ReaderLocation>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ir a un pasaje'),
          content: SizedBox(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<BookInfo>(
                  initialValue: book,
                  decoration: const InputDecoration(labelText: 'Libro'),
                  items: [
                    for (final item in bibleBooks)
                      DropdownMenuItem(value: item, child: Text(item.name)),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() {
                      book = value;
                      chapter = chapter.clamp(1, book.chapters);
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  key: ValueKey(book.code),
                  initialValue: chapter,
                  decoration: const InputDecoration(labelText: 'Capítulo'),
                  items: [
                    for (var number = 1; number <= book.chapters; number++)
                      DropdownMenuItem(value: number, child: Text('$number')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => chapter = value ?? chapter),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, ReaderLocation(book, chapter)),
              child: const Text('Ir'),
            ),
          ],
        ),
      ),
    );
    if (result == null) return;
    ref.read(readerLocationProvider.notifier).goTo(result.book, result.chapter);
    setState(selected.clear);
  }

  Iterable<String> _selectedIds() {
    final location = ref.read(readerLocationProvider);
    return selected.map(
      (verse) => '${location.book.code}.${location.chapter}.$verse',
    );
  }

  Future<void> _markRead() async {
    final location = ref.read(readerLocationProvider);
    await ref
        .read(databaseProvider)
        .markRead(location.book.code, location.chapter, selected);
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
    if (!mounted) return;
    noteController.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Nota guardada')));
  }

  Future<void> _setFavorite(bool value) async {
    await ref.read(databaseProvider).setFavorite(_selectedIds(), value);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Añadido a favoritos')));
    }
  }

  Future<void> _setHighlight(Color color) =>
      ref.read(databaseProvider).setHighlight(_selectedIds(), color.toARGB32());

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

class _ReaderDocument extends StatelessWidget {
  const _ReaderDocument({
    required this.location,
    required this.selected,
    required this.verses,
    required this.preferences,
    required this.onToggle,
    required this.onPrevious,
    required this.onNext,
    required this.onChoosePassage,
  });

  final ReaderLocation location;
  final Set<int> selected;
  final List<BibleVerse> verses;
  final Map<String, VersePreference> preferences;
  final ValueChanged<int> onToggle;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onChoosePassage;

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
                tooltip: 'Capítulo anterior',
                onPressed: onPrevious,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: InkWell(
                  onTap: onChoosePassage,
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
    required this.onMarkRead,
    required this.onSaveNote,
    required this.onFavorite,
    required this.onHighlight,
  });

  final Set<int> selected;
  final ReaderLocation location;
  final TextEditingController noteController;
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
          onPressed: selected.isEmpty ? null : () => context.push('/assistant'),
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

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final controller = TextEditingController();
  Timer? debounce;
  String query = '';
  bool searching = false;
  List<BibleVerse> results = const [];

  @override
  void dispose() {
    debounce?.cancel();
    controller.dispose();
    super.dispose();
  }

  void search(String value) {
    debounce?.cancel();
    setState(() {
      query = value;
      if (value.trim().isEmpty) {
        results = const [];
        searching = false;
      }
    });
    if (value.trim().isEmpty) return;
    debounce = Timer(const Duration(milliseconds: 250), () async {
      setState(() => searching = true);
      await ref.read(bibleReadyProvider.future);
      final found = await ref.read(databaseProvider).search(value);
      if (!mounted || controller.text != value) return;
      setState(() {
        results = found;
        searching = false;
      });
    });
  }

  void useSuggestion(String value) {
    controller.text = value;
    controller.selection = TextSelection.collapsed(offset: value.length);
    search(value);
  }

  void openVerse(BibleVerse verse) {
    final book = bibleBooks.firstWhere((item) => item.code == verse.bookCode);
    ref.read(readerLocationProvider.notifier).goTo(book, verse.chapter);
    context.go('/reader');
  }

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      maxWidth: 900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ScreenHeading(
            title: 'Buscar',
            subtitle: 'Encuentra una referencia, palabra o frase.',
          ),
          const SizedBox(height: 24),
          TextField(
            controller: controller,
            autofocus: true,
            onChanged: search,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search_rounded),
              hintText: 'Ej. Juan 3:16 o “Dios es amor”',
            ),
          ),
          const SizedBox(height: 24),
          if (query.isEmpty) ...[
            Text(
              'Búsquedas sugeridas',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['amor', 'esperanza', 'Salmos 23', 'fe']
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () => useSuggestion(item),
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            Text(
              searching ? 'Buscando…' : '${results.length} resultados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (searching) const LinearProgressIndicator(),
            for (final result in results)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(
                    result.reference,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(result.body),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => openVerse(result),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  String section = 'notes';

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);
    final favorites = ref.watch(favoritesProvider);
    return PageFrame(
      maxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Notas y guardados',
            subtitle: 'Tus reflexiones permanecen privadas.',
            trailing: FilledButton.icon(
              onPressed: () => context.go('/reader'),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nueva nota'),
            ),
          ),
          const SizedBox(height: 24),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'notes',
                label: Text('Notas'),
                icon: Icon(Icons.edit_note_rounded),
              ),
              ButtonSegment(
                value: 'favorites',
                label: Text('Favoritos'),
                icon: Icon(Icons.bookmark_outline_rounded),
              ),
            ],
            selected: {section},
            onSelectionChanged: (value) =>
                setState(() => section = value.first),
          ),
          const SizedBox(height: 20),
          if (section == 'notes')
            notes.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.edit_note_rounded,
                      message: 'Aún no tienes notas.',
                    )
                  : Column(
                      children: [
                        for (final note in items)
                          _NoteCard(
                            reference: note.reference,
                            body: note.body,
                            date: _shortDate(note.updatedAt),
                            onDelete: () =>
                                ref.read(databaseProvider).deleteNote(note.id),
                          ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar: $error'),
            )
          else
            favorites.when(
              data: (items) => items.isEmpty
                  ? const _EmptyCollection(
                      icon: Icons.bookmark_outline_rounded,
                      message: 'Aún no tienes favoritos.',
                    )
                  : Column(
                      children: [
                        for (final verse in items)
                          Card(
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(18),
                              title: Text(verse.reference),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(verse.body),
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () {
                                final book = bibleBooks.firstWhere(
                                  (item) => item.code == verse.bookCode,
                                );
                                ref
                                    .read(readerLocationProvider.notifier)
                                    .goTo(book, verse.chapter);
                                context.go('/reader');
                              },
                            ),
                          ),
                      ],
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => Text('No se pudieron cargar: $error'),
            ),
        ],
      ),
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.reference,
    required this.body,
    required this.date,
    required this.onDelete,
  });
  final String reference;
  final String body;
  final String date;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(child: Icon(Icons.edit_note_rounded)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reference,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Text(date),
                    IconButton(
                      tooltip: 'Eliminar nota',
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(body, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48),
    child: Center(
      child: Column(
        children: [
          Icon(icon, size: 42),
          const SizedBox(height: 12),
          Text(message),
        ],
      ),
    ),
  );
}

String _shortDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

Future<void> showReadingSettings(BuildContext context, WidgetRef ref) async {
  final database = ref.read(databaseProvider);
  var goal = int.tryParse(await database.getSetting('daily_goal') ?? '') ?? 10;
  final savedReminder = await database.getSetting('reminder_time');
  var reminderEnabled = savedReminder != null;
  final parts = savedReminder?.split(':');
  var reminderTime = TimeOfDay(
    hour: int.tryParse(parts?.first ?? '') ?? 20,
    minute: int.tryParse(parts?.last ?? '') ?? 0,
  );
  if (!context.mounted) return;

  final result = await showDialog<(int, bool, TimeOfDay)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Meta y recordatorio'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                initialValue: goal,
                decoration: const InputDecoration(
                  labelText: 'Meta diaria de versículos',
                ),
                items: [
                  for (final value in const [5, 10, 15, 20, 30])
                    DropdownMenuItem(value: value, child: Text('$value')),
                ],
                onChanged: (value) =>
                    setDialogState(() => goal = value ?? goal),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Recordatorio diario'),
                value: reminderEnabled,
                onChanged: (value) =>
                    setDialogState(() => reminderEnabled = value),
              ),
              if (reminderEnabled)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Hora'),
                  trailing: Text(reminderTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: reminderTime,
                    );
                    if (picked != null) {
                      setDialogState(() => reminderTime = picked);
                    }
                  },
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, (goal, reminderEnabled, reminderTime)),
            child: const Text('Guardar'),
          ),
        ],
      ),
    ),
  );
  if (result == null) return;

  await database.setSetting('daily_goal', '${result.$1}');
  try {
    if (result.$2) {
      await reminderService.scheduleDaily(result.$3.hour, result.$3.minute);
      await database.setSetting(
        'reminder_time',
        '${result.$3.hour.toString().padLeft(2, '0')}:'
            '${result.$3.minute.toString().padLeft(2, '0')}',
      );
    } else {
      await reminderService.cancel();
      await database.setSetting('reminder_time', null);
    }
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preferencias guardadas')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo programar el recordatorio: $error')),
      );
    }
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity =
        ref.watch(readingActivityProvider).value ?? const <ReadingEntry>[];
    final notes = ref.watch(notesProvider).value ?? const <UserNote>[];
    final stats = calculateReadingStats(activity, DateTime.now());
    return PageFrame(
      maxWidth: 1050,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Tu camino de lectura',
            subtitle: 'Perfil privado · Modo invitado',
            trailing: IconButton.filledTonal(
              onPressed: () => showReadingSettings(context, ref),
              tooltip: 'Configuración',
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(height: 24),
          const _AccountSummary(),
          const SizedBox(height: 22),
          _ProfileSummary(stats: stats, noteCount: notes.length),
          const SizedBox(height: 22),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Últimos 365 días',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'La intensidad representa cuántos versículos leíste cada día.',
                  ),
                  const SizedBox(height: 20),
                  _ActivityHeatmap(byDay: stats.byDay),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummary extends StatelessWidget {
  const _AccountSummary();

  @override
  Widget build(BuildContext context) {
    final client = supabaseClient;
    if (client == null) {
      return const Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(Icons.cloud_off_outlined)),
          title: Text('Modo invitado'),
          subtitle: Text('La sincronización remota aún no está configurada.'),
        ),
      );
    }
    return StreamBuilder(
      stream: client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final user = client.auth.currentUser;
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              child: Icon(
                user == null ? Icons.person_outline : Icons.cloud_done_outlined,
              ),
            ),
            title: Text(user?.email ?? 'Modo invitado'),
            subtitle: Text(
              user == null
                  ? 'Inicia sesión para sincronizar entre dispositivos.'
                  : 'Cuenta conectada · Datos privados',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/account'),
          ),
        );
      },
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary({required this.stats, required this.noteCount});

  final ReadingStats stats;
  final int noteCount;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('${stats.total}', 'Versículos'),
      ('${stats.currentStreak}', 'Racha actual'),
      ('${stats.bestStreak}', 'Mejor racha'),
      ('$noteCount', 'Notas'),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Wrap(
          spacing: 40,
          runSpacing: 20,
          children: [
            for (final item in items)
              SizedBox(
                width: 130,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.$1,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(item.$2),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActivityHeatmap extends StatelessWidget {
  const _ActivityHeatmap({required this.byDay});

  final Map<String, int> byDay;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth < 500 ? 8.0 : 11.0;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            height: 7 * cell + 18,
            child: Wrap(
              direction: Axis.vertical,
              spacing: 3,
              runSpacing: 3,
              children: List.generate(365, (index) {
                final date = DateTime.now().subtract(
                  Duration(days: 364 - index),
                );
                final key =
                    '${date.year.toString().padLeft(4, '0')}-'
                    '${date.month.toString().padLeft(2, '0')}-'
                    '${date.day.toString().padLeft(2, '0')}';
                final value = byDay[key] ?? 0;
                final intensity = value == 0
                    ? 0.08
                    : value < 4
                    ? .25
                    : value < 7
                    ? .5
                    : value < 10
                    ? .72
                    : 1.0;
                return Tooltip(
                  message: '$key · $value versículos',
                  child: Container(
                    width: cell,
                    height: cell,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: intensity),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool busy = false;
  String? message;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> submit({required bool createAccount}) async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    if (!email.contains('@') || password.length < 8) {
      setState(
        () =>
            message = 'Usa un correo válido y una contraseña de 8 caracteres.',
      );
      return;
    }
    setState(() {
      busy = true;
      message = null;
    });
    try {
      final auth = supabaseClient!.auth;
      if (createAccount) {
        await auth.signUp(email: email, password: password);
        message = 'Cuenta creada. Revisa tu correo para confirmarla.';
      } else {
        await auth.signInWithPassword(email: email, password: password);
        message = 'Sesión iniciada.';
      }
    } catch (error) {
      message = 'No se pudo completar: $error';
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = supabaseClient;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta'),
        leading: IconButton(
          onPressed: context.pop,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (client == null)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Supabase no está configurado en esta compilación. '
                        'Puedes seguir usando todas las funciones offline.',
                      ),
                    ),
                  )
                else
                  StreamBuilder(
                    stream: client.auth.onAuthStateChange,
                    builder: (context, snapshot) {
                      final user = client.auth.currentUser;
                      if (user != null) {
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Icon(Icons.cloud_done_outlined, size: 48),
                                const SizedBox(height: 12),
                                Text(
                                  user.email ?? 'Cuenta conectada',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: 16),
                                OutlinedButton(
                                  onPressed: busy
                                      ? null
                                      : () => client.auth.signOut(),
                                  child: const Text('Cerrar sesión'),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Sincroniza tu lectura',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'El modo invitado seguirá disponible. Al iniciar '
                            'sesión, tus datos locales podrán fusionarse.',
                          ),
                          const SizedBox(height: 24),
                          TextField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            decoration: const InputDecoration(
                              labelText: 'Correo',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextField(
                            controller: passwordController,
                            obscureText: true,
                            autofillHints: const [AutofillHints.password],
                            onSubmitted: (_) => submit(createAccount: false),
                            decoration: const InputDecoration(
                              labelText: 'Contraseña',
                            ),
                          ),
                          const SizedBox(height: 18),
                          FilledButton(
                            onPressed: busy
                                ? null
                                : () => submit(createAccount: false),
                            child: const Text('Iniciar sesión'),
                          ),
                          const SizedBox(height: 10),
                          OutlinedButton(
                            onPressed: busy
                                ? null
                                : () => submit(createAccount: true),
                            child: const Text('Crear cuenta'),
                          ),
                        ],
                      );
                    },
                  ),
                if (busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(),
                ],
                if (message != null) ...[
                  const SizedBox(height: 16),
                  Text(message!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explicar pasaje'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Card(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: Text(
                      'Juan 3:16\n“Porque de tal manera amó Dios al mundo...”',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Asistente contextual',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'La explicación con fuentes adventistas estará disponible al conectar el servicio seguro. La clave de IA nunca se almacenará en la aplicación.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Haz una pregunta sobre el pasaje...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                onPressed: null,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
