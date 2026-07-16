part of '../../screens.dart';

class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});

  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
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

  Future<void> deleteAccount() async {
    final confirmation = TextEditingController();
    var matches = false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Eliminar cuenta definitivamente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Se eliminarán tu cuenta, progreso, notas y consultas. '
                'Esta acción no se puede deshacer. Escribe ELIMINAR.',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmation,
                autofocus: true,
                onChanged: (value) =>
                    setDialogState(() => matches = value.trim() == 'ELIMINAR'),
                decoration: const InputDecoration(labelText: 'Confirmación'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: matches ? () => Navigator.pop(context, true) : null,
              child: const Text('Eliminar definitivamente'),
            ),
          ],
        ),
      ),
    );
    confirmation.dispose();
    if (confirmed != true || !mounted) return;
    setState(() {
      busy = true;
      message = null;
    });
    try {
      await deleteRemoteAccount();
      await ref.read(databaseProvider).clearPersonalData();
      await supabaseClient?.auth.signOut();
      if (mounted) context.go('/');
    } catch (error) {
      if (mounted) setState(() => message = 'No se pudo eliminar: $error');
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
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: busy ? null : deleteAccount,
                                  icon: const Icon(
                                    Icons.delete_forever_outlined,
                                  ),
                                  label: const Text('Eliminar cuenta'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
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
