part of '../../screens.dart';

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
    unawaited(
      ref.read(readerViewProvider.notifier).openChapter(book, verse.chapter),
    );
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
