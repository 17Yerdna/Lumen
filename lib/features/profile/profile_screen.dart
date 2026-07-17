part of '../../screens.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activity =
        ref.watch(readingActivityProvider).value ?? const <ReadingEntry>[];
    final notes = ref.watch(notesProvider).value ?? const <UserNote>[];
    final stats = calculateReadingStats(activity, DateTime.now());
    final progress = ref.watch(bibleReadingProgressProvider);
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
          _DataExportCard(
            onExport: (markdown) => _exportData(context, ref, markdown),
          ),
          const SizedBox(height: 22),
          _ProfileSummary(
            stats: stats,
            noteCount: notes.length,
            progress: progress,
          ),
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

class _DataExportCard extends StatelessWidget {
  const _DataExportCard({required this.onExport});

  final ValueChanged<bool> onExport;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tus datos', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          const Text('Guarda una copia portable de tu actividad y notas.'),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => onExport(false),
                icon: const Icon(Icons.data_object_rounded),
                label: const Text('Exportar JSON'),
              ),
              OutlinedButton.icon(
                onPressed: () => onExport(true),
                icon: const Icon(Icons.description_outlined),
                label: const Text('Exportar Markdown'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Future<void> _exportData(
  BuildContext context,
  WidgetRef ref,
  bool markdown,
) async {
  final extension = markdown ? 'md' : 'json';
  final location = await getSaveLocation(
    suggestedName: 'lumen-biblia-export.$extension',
    acceptedTypeGroups: [
      XTypeGroup(
        label: markdown ? 'Markdown' : 'JSON',
        extensions: [extension],
      ),
    ],
  );
  if (location == null) return;
  final database = ref.read(databaseProvider);
  final content = markdown
      ? await database.exportUserDataMarkdown()
      : await database.exportUserDataJson();
  final file = XFile.fromData(
    Uint8List.fromList(utf8.encode(content)),
    mimeType: markdown ? 'text/markdown' : 'application/json',
    name: 'lumen-biblia-export.$extension',
  );
  await file.saveTo(location.path);
  if (context.mounted) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exportación guardada')));
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
  const _ProfileSummary({
    required this.stats,
    required this.noteCount,
    required this.progress,
  });

  final ReadingStats stats;
  final int noteCount;
  final BibleReadingProgress progress;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        '${progress.completedChapterCount}/${progress.totalChapters}',
        'Capítulos',
      ),
      ('${progress.completedBookCount}', 'Libros concluidos'),
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
