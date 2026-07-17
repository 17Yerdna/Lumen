import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'bible_providers.dart';

enum WindowClass { compact, medium, expanded }

WindowClass windowClassFor(double width) {
  if (width < 600) return WindowClass.compact;
  if (width < 1024) return WindowClass.medium;
  return WindowClass.expanded;
}

const _destinations = <NavigationDestination>[
  NavigationDestination(
    icon: Icon(Icons.home_outlined),
    selectedIcon: Icon(Icons.home_rounded),
    label: 'Inicio',
  ),
  NavigationDestination(
    icon: Icon(Icons.menu_book_outlined),
    selectedIcon: Icon(Icons.menu_book_rounded),
    label: 'Biblia',
  ),
  NavigationDestination(
    icon: Icon(Icons.search_rounded),
    selectedIcon: Icon(Icons.manage_search_rounded),
    label: 'Buscar',
  ),
  NavigationDestination(
    icon: Icon(Icons.edit_note_outlined),
    selectedIcon: Icon(Icons.edit_note_rounded),
    label: 'Notas',
  ),
  NavigationDestination(
    icon: Icon(Icons.person_outline_rounded),
    selectedIcon: Icon(Icons.person_rounded),
    label: 'Perfil',
  ),
];

class AdaptiveShell extends ConsumerWidget {
  const AdaptiveShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  void _select(WidgetRef ref, int index) {
    if (index == 1) ref.read(readerViewProvider.notifier).showBooks();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return switch (windowClassFor(constraints.maxWidth)) {
          WindowClass.compact => Scaffold(
            body: SafeArea(bottom: false, child: navigationShell),
            bottomNavigationBar: NavigationBar(
              key: const Key('compact-navigation'),
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: (index) => _select(ref, index),
              destinations: _destinations,
            ),
          ),
          WindowClass.medium => Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    key: const Key('medium-navigation'),
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: (index) => _select(ref, index),
                    labelType: NavigationRailLabelType.all,
                    leading: const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: _LumenMark(),
                    ),
                    destinations: _destinations
                        .map(
                          (item) => NavigationRailDestination(
                            icon: item.icon,
                            selectedIcon: item.selectedIcon,
                            label: Text(item.label),
                          ),
                        )
                        .toList(),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ),
          WindowClass.expanded => Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  _DesktopSidebar(
                    selectedIndex: navigationShell.currentIndex,
                    onSelect: (index) => _select(ref, index),
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: navigationShell),
                ],
              ),
            ),
          ),
        };
      },
    );
  }
}

class _DesktopSidebar extends StatelessWidget {
  const _DesktopSidebar({required this.selectedIndex, required this.onSelect});

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      key: const Key('expanded-navigation'),
      width: 248,
      color: colors.surfaceContainerLow,
      padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            children: [
              _LumenMark(),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Lumen Biblia',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
          const SizedBox(height: 36),
          for (var index = 0; index < _destinations.length; index++)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _SidebarButton(
                destination: _destinations[index],
                selected: selectedIndex == index,
                onTap: () => onSelect(index),
              ),
            ),
          const Spacer(),
          Card(
            color: colors.primaryContainer.withValues(alpha: .5),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.cloud_done_outlined),
                  SizedBox(height: 8),
                  Text(
                    'Modo invitado',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  SizedBox(height: 4),
                  Text('Tu progreso se guarda en este dispositivo.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatelessWidget {
  const _SidebarButton({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavigationDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: selected ? colors.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              selected
                  ? destination.selectedIcon ?? destination.icon
                  : destination.icon,
              const SizedBox(width: 14),
              Text(
                destination.label,
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LumenMark extends StatelessWidget {
  const _LumenMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.auto_stories_rounded,
        color: colors.onPrimary,
        size: 22,
      ),
    );
  }
}
