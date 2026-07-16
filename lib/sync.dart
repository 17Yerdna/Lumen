import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'database.dart';

Future<void> syncDatabase(
  AppDatabase database,
  SupabaseClient client,
  String userId,
) async {
  final syncedUser = await database.getSetting('synced_user_id');
  if (syncedUser == null) {
    await database.enqueueAllForSync();
  } else if (syncedUser != userId) {
    // ponytail: v1 binds one local database to one account. Add separate local
    // databases when account switching becomes a real product requirement.
    throw StateError('Esta base local ya pertenece a otra cuenta.');
  }

  for (final item in await database.pendingSyncItems()) {
    final payload = Map<String, dynamic>.from(jsonDecode(item.payload) as Map)
      ..['user_id'] = userId;
    if (item.isDelete) {
      await client.from(item.entity).delete().eq('id', item.recordKey);
    } else {
      await client
          .from(item.entity)
          .upsert(payload, onConflict: _conflicts[item.entity]);
    }
    await database.removeSyncItem(item.id);
  }

  final readings = await client.from('reading_activity').select();
  final preferences = await client.from('verse_preferences').select();
  final notes = await client.from('notes').select();
  final conversations = await client.from('assistant_conversations').select();
  final profile = await client
      .from('profiles')
      .select('daily_goal')
      .maybeSingle();
  await database.mergeRemoteReadings(readings);
  await database.mergeRemotePreferences(preferences);
  // ponytail: v1 notes are append-only, so device UUIDs preserve both versions.
  // Add note revisions only when editing notes ships.
  await database.mergeRemoteNotes(notes);
  await database.mergeRemoteConversations(conversations);
  await database.applyRemoteDailyGoal(profile?['daily_goal'] as int?);
  await database.setSetting('synced_user_id', userId);
}

const _conflicts = {
  'profiles': 'user_id',
  'reading_activity': 'user_id,book_code,chapter,verse,read_day',
  'verse_preferences': 'user_id,verse_id',
  'notes': 'id',
  'assistant_conversations': 'id',
};
