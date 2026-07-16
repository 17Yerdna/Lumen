import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Buenos días',
            subtitle: 'Un momento de lectura puede iluminar todo el día.',
            trailing: IconButton.filledTonal(
              tooltip: 'Notificaciones',
              onPressed: () {},
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
              final goalCard = const _DailyGoalCard();
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
          const _StatGrid(),
          const SizedBox(height: 26),
          Text(
            'Actividad reciente',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          const _RecentActivity(),
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
  const _DailyGoalCard();

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
            const Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '6',
                  style: TextStyle(fontSize: 42, fontWeight: FontWeight.w800),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 6),
                  child: Text('de 10 versículos'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const LinearProgressIndicator(
              value: .6,
              minHeight: 10,
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
            const SizedBox(height: 16),
            Text(
              'Te faltan 4 para completar tu meta.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid();

  @override
  Widget build(BuildContext context) {
    const stats = [
      (Icons.local_fire_department_outlined, '7 días', 'Racha actual'),
      (Icons.menu_book_outlined, '128', 'Versículos leídos'),
      (Icons.sticky_note_2_outlined, '12', 'Notas guardadas'),
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
            for (final stat in stats)
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
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: const [
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.check_rounded)),
            title: Text('Marcaste Juan 3:16–18 como leído'),
            subtitle: Text('Hoy · 08:42'),
          ),
          Divider(height: 1, indent: 72),
          ListTile(
            leading: CircleAvatar(child: Icon(Icons.edit_note_rounded)),
            title: Text('Añadiste una nota en Salmos 23:1'),
            subtitle: Text('Ayer · 21:10'),
          ),
        ],
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  final selected = <int>{16};

  static const verses = <int, String>{
    14: 'Y como Moisés levantó la serpiente en el desierto, así es necesario que el Hijo del hombre sea levantado;',
    15: 'Para que todo aquel que en él creyere, no se pierda, sino que tenga vida eterna.',
    16: 'Porque de tal manera amó Dios al mundo, que ha dado á su Hijo unigénito, para que todo aquel que en él cree, no se pierda, mas tenga vida eterna.',
    17: 'Porque no envió Dios á su Hijo al mundo para que condene al mundo, mas para que el mundo sea salvo por él.',
    18: 'El que en él cree, no es condenado; mas el que no cree, ya es condenado, porque no creyó en el nombre del unigénito Hijo de Dios.',
    19: 'Y esta es la condenación: porque la luz vino al mundo, y los hombres amaron más las tinieblas que la luz; porque sus obras eran malas.',
    20: 'Porque todo aquel que hace lo malo, aborrece la luz y no viene á la luz, porque sus obras no sean redargüidas.',
    21: 'Mas el que obra verdad, viene á la luz, para que sus obras sean manifestadas que son hechas en Dios.',
  };

  void toggleVerse(int number) {
    setState(() {
      selected.contains(number)
          ? selected.remove(number)
          : selected.add(number);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showPanel = constraints.maxWidth >= 1024;
        final reader = _ReaderDocument(
          selected: selected,
          verses: verses,
          onToggle: toggleVerse,
        );
        return Scaffold(
          body: Row(
            children: [
              Expanded(child: reader),
              if (showPanel) ...[
                const VerticalDivider(width: 1),
                SizedBox(
                  width: math.min(370, constraints.maxWidth * .32),
                  child: _StudyPanel(selected: selected),
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
                            onPressed: () {},
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

  void _showNoteSheet() {
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Nueva nota',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 16),
            TextField(
              maxLines: 5,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '¿Qué quieres recordar de este pasaje?',
              ),
            ),
            SizedBox(height: 16),
            FilledButton(onPressed: null, child: Text('Guardar nota')),
          ],
        ),
      ),
    );
  }
}

class _ReaderDocument extends StatelessWidget {
  const _ReaderDocument({
    required this.selected,
    required this.verses,
    required this.onToggle,
  });

  final Set<int> selected;
  final Map<int, String> verses;
  final ValueChanged<int> onToggle;

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
                onPressed: () {},
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text('Juan', style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      'Capítulo 3 · RV1909',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Capítulo siguiente',
                onPressed: () {},
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
                          'El amor de Dios',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 24),
                        for (final entry in verses.entries)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Material(
                              color: selected.contains(entry.key)
                                  ? colors.primaryContainer.withValues(
                                      alpha: .75,
                                    )
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              child: InkWell(
                                onTap: () => onToggle(entry.key),
                                onLongPress: () => onToggle(entry.key),
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
                                          text: '${entry.key}  ',
                                          style: TextStyle(
                                            color: colors.primary,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        TextSpan(
                                          text: entry.value,
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
  const _StudyPanel({required this.selected});

  final Set<int> selected;

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
              : 'Juan 3:${selected.toList()..sort()}'
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
          onPressed: selected.isEmpty ? null : () {},
          icon: const Icon(Icons.check_circle_outline),
          label: const Text('Marcar como leído'),
        ),
        const SizedBox(height: 24),
        Text('Nota personal', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 6,
          decoration: InputDecoration(hintText: 'Escribe una reflexión...'),
        ),
        const SizedBox(height: 12),
        FilledButton.tonal(
          onPressed: selected.isEmpty ? null : () {},
          child: const Text('Guardar nota'),
        ),
        const SizedBox(height: 24),
        Text('Resaltado', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          children: const [
            _ColorDot(color: Color(0xFFFFD166)),
            _ColorDot(color: Color(0xFF95D5B2)),
            _ColorDot(color: Color(0xFFA9D6E5)),
            _ColorDot(color: Color(0xFFE4C1F9)),
            _ColorDot(color: Color(0xFFFFADAD)),
          ],
        ),
      ],
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {},
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

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String query = '';

  static const results = [
    (
      'Juan 3:16',
      'Porque de tal manera amó Dios al mundo, que ha dado á su Hijo unigénito...',
    ),
    ('1 Juan 4:8', 'El que no ama, no conoce á Dios; porque Dios es amor.'),
    (
      'Romanos 5:8',
      'Mas Dios encarece su caridad para con nosotros, porque siendo aún pecadores...',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = results
        .where(
          (item) => '${item.$1} ${item.$2}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
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
            autofocus: true,
            onChanged: (value) => setState(() => query = value),
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
                      onPressed: () => setState(() => query = item),
                    ),
                  )
                  .toList(),
            ),
          ] else ...[
            Text(
              '${filtered.length} resultados',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final result in filtered)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.all(18),
                  title: Text(
                    result.$1,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(result.$2),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => context.go('/reader'),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class NotesScreen extends StatelessWidget {
  const NotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      maxWidth: 960,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Notas y guardados',
            subtitle: 'Tus reflexiones permanecen privadas.',
            trailing: FilledButton.icon(
              onPressed: () {},
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
            selected: const {'notes'},
            onSelectionChanged: (_) {},
          ),
          const SizedBox(height: 20),
          const _NoteCard(
            reference: 'Salmos 23:1',
            body:
                'La imagen del pastor habla de cuidado constante, no de ausencia de dificultades.',
            date: 'Ayer',
          ),
          const _NoteCard(
            reference: 'Juan 3:16',
            body: 'El amor de Dios toma la iniciativa y se expresa en entrega.',
            date: '12 jul',
          ),
          const _NoteCard(
            reference: 'Génesis 2:3',
            body:
                'El descanso también puede ser una forma de recordar quién sostiene la creación.',
            date: '8 jul',
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
  });
  final String reference;
  final String body;
  final String date;

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

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PageFrame(
      maxWidth: 1050,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ScreenHeading(
            title: 'Tu camino de lectura',
            subtitle: 'Perfil privado · Modo invitado',
            trailing: IconButton.filledTonal(
              onPressed: () {},
              tooltip: 'Configuración',
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
          const SizedBox(height: 24),
          const _ProfileSummary(),
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
                  const _ActivityHeatmap(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileSummary extends StatelessWidget {
  const _ProfileSummary();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('128', 'Versículos'),
      ('7', 'Racha actual'),
      ('14', 'Mejor racha'),
      ('12', 'Notas'),
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
  const _ActivityHeatmap();

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
                final value = (index * 17 + index ~/ 9) % 11;
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
                  message: '$value versículos',
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
