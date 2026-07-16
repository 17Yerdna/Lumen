import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabasePublishableKey = String.fromEnvironment(
  'SUPABASE_PUBLISHABLE_KEY',
);

bool get isSupabaseConfigured =>
    supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;

SupabaseClient? get supabaseClient =>
    isSupabaseConfigured ? Supabase.instance.client : null;

Future<void> initializeBackend() async {
  if (!isSupabaseConfigured) return;
  await Supabase.initialize(
    url: supabaseUrl,
    publishableKey: supabasePublishableKey,
  );
}

class AssistantPassage {
  const AssistantPassage({required this.reference, required this.text});

  final String reference;
  final String text;
}

Stream<String> explainPassage(
  AssistantPassage passage, {
  String question = '',
}) async* {
  final session = supabaseClient?.auth.currentSession;
  if (!isSupabaseConfigured || session == null) {
    throw StateError('Inicia sesión para usar el asistente.');
  }

  final client = http.Client();
  try {
    final request =
        http.Request(
            'POST',
            Uri.parse('$supabaseUrl/functions/v1/explain-passage'),
          )
          ..headers.addAll({
            'apikey': supabasePublishableKey,
            'Authorization': 'Bearer ${session.accessToken}',
            'Content-Type': 'application/json',
          })
          ..body = jsonEncode({
            'reference': passage.reference,
            'text': passage.text,
            'question': question.trim(),
          });
    final response = await client.send(request);
    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw StateError(_errorMessage(body, response.statusCode));
    }
    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final delta = parseAssistantDelta(line);
      if (delta != null) yield delta;
    }
  } finally {
    client.close();
  }
}

String? parseAssistantDelta(String line) {
  if (!line.startsWith('data: ')) return null;
  final data = line.substring(6);
  if (data == '[DONE]') return null;
  final event = jsonDecode(data) as Map<String, dynamic>;
  if (event['type'] == 'response.output_text.delta') {
    return event['delta'] as String?;
  }
  if (event['type'] == 'error' || event['type'] == 'response.failed') {
    final error = event['error'];
    final message = error is Map ? error['message'] : null;
    throw StateError(message?.toString() ?? 'La explicación falló.');
  }
  return null;
}

String _errorMessage(String body, int statusCode) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    return json['error']?.toString() ?? 'Error del asistente ($statusCode).';
  } on FormatException {
    return 'Error del asistente ($statusCode).';
  }
}
