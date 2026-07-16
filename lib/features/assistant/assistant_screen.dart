part of '../../screens.dart';

class AssistantScreen extends ConsumerStatefulWidget {
  const AssistantScreen({required this.passage, super.key});

  final AssistantPassage? passage;

  @override
  ConsumerState<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends ConsumerState<AssistantScreen> {
  final questionController = TextEditingController();
  String answer = '';
  String? error;
  bool loading = false;

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  Future<void> explain() async {
    final passage = widget.passage;
    if (passage == null || loading) return;
    final question = questionController.text.trim().isEmpty
        ? 'Explica este pasaje en su contexto.'
        : questionController.text.trim();
    setState(() {
      loading = true;
      answer = '';
      error = null;
    });
    try {
      await for (final delta in explainPassage(passage, question: question)) {
        if (!mounted) return;
        setState(() => answer += delta);
      }
      if (!mounted || answer.trim().isEmpty) return;
      await ref
          .read(databaseProvider)
          .saveAssistantConversation(
            reference: passage.reference,
            passageText: passage.text,
            question: question,
            answer: answer.trim(),
          );
      ref.invalidate(syncProvider);
    } catch (exception) {
      if (mounted) setState(() => error = _friendlyError(exception));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final passage = widget.passage;
    final signedIn = supabaseClient?.auth.currentUser != null;
    final history = ref.watch(assistantConversationsProvider);
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
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      passage == null
                          ? 'Selecciona uno o más versículos en el lector.'
                          : '${passage.reference}\n${passage.text}',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (!signedIn)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.lock_outline_rounded),
                      title: const Text('Inicia sesión para preguntar'),
                      subtitle: const Text(
                        'Las explicaciones usan una función segura con cuota diaria.',
                      ),
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => context.push('/account'),
                    ),
                  )
                else if (answer.isEmpty && !loading)
                  FilledButton.icon(
                    onPressed: passage == null ? null : explain,
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: const Text('Generar explicación'),
                  ),
                if (loading) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  const Text('Estudiando el contexto y las fuentes…'),
                ],
                if (answer.isNotEmpty) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: SelectableText(answer),
                    ),
                  ),
                  const Text(
                    'La IA puede equivocarse. Contrasta la respuesta con la Biblia y las fuentes enlazadas.',
                  ),
                ],
                if (error != null)
                  Card(
                    color: Theme.of(context).colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(error!),
                    ),
                  ),
                const SizedBox(height: 24),
                Text(
                  'Consultas guardadas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                history.when(
                  data: (items) => items.isEmpty
                      ? const Text('Aún no hay explicaciones guardadas.')
                      : Column(
                          children: [
                            for (final item in items.take(5))
                              Card(
                                child: ExpansionTile(
                                  title: Text(item.reference),
                                  subtitle: Text(item.question),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    18,
                                    0,
                                    18,
                                    18,
                                  ),
                                  children: [SelectableText(item.answer)],
                                ),
                              ),
                          ],
                        ),
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) =>
                      const Text('No se pudo abrir el historial local.'),
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
              Expanded(
                child: TextField(
                  controller: questionController,
                  enabled: signedIn && !loading,
                  onSubmitted: (_) => explain(),
                  decoration: InputDecoration(
                    hintText: 'Haz una pregunta sobre el pasaje...',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Enviar pregunta',
                onPressed: signedIn && passage != null && !loading
                    ? explain
                    : null,
                icon: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _friendlyError(Object exception) {
    final message = exception.toString().replaceFirst('Bad state: ', '');
    return message.startsWith('ClientException')
        ? 'No hay conexión. Tus explicaciones anteriores siguen disponibles.'
        : message;
  }
}
