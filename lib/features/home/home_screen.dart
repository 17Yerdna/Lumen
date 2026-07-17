part of '../../screens.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity =
        ref.watch(readingActivityProvider).value ?? const <ReadingEntry>[];
    final noteCount = ref.watch(notesProvider).value?.length ?? 0;
    final stats = calculateReadingStats(activity, DateTime.now());
    final goal = ref.watch(dailyGoalProvider).value ?? 10;
    final preview =
        ref.watch(lastReadingPreviewProvider).value ??
        ReadingPreview(ReaderLocation(bibleBooks.first, 1), '');
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
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 760;
              final continueCard = _ContinueReadingCard(
                preview: preview,
                onContinue: () {
                  unawaited(
                    ref
                        .read(readerViewProvider.notifier)
                        .openChapter(
                          preview.location.book,
                          preview.location.chapter,
                        ),
                  );
                  context.go('/reader');
                },
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
          const SizedBox(height: 32),
          Text('Tu camino', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 14),
          _StatGrid(stats: stats, noteCount: noteCount),
          const SizedBox(height: 32),
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
  const _ContinueReadingCard({required this.preview, required this.onContinue});

  final ReadingPreview preview;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: colors.primaryContainer,
      child: Stack(
        children: [
          const Positioned.fill(
            child: LumenArtwork(opacity: .26, alignment: Alignment.centerRight),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CONTINUAR LECTURA',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  '${preview.location.book.name} ${preview.location.chapter}',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: colors.onPrimaryContainer,
                  ),
                ),
                const SizedBox(height: 10),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Text(
                    preview.text.isEmpty
                        ? 'Comienza tu lectura.'
                        : '“${preview.text}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colors.onPrimaryContainer.withValues(alpha: .88),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.surface,
                    foregroundColor: colors.primary,
                  ),
                  onPressed: onContinue,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Seguir leyendo'),
                ),
              ],
            ),
          ),
        ],
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
            const SizedBox(height: 28),
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
              minHeight: 8,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
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
                        CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.secondaryContainer,
                          child: Icon(stat.$1),
                        ),
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
