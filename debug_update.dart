import 'dart:io';
import 'package:supabase/supabase.dart';

void main() async {
  // Read .env
  final envLines = File('.env').readAsLinesSync();
  String url = '';
  String key = '';
  for (var line in envLines) {
    if (line.startsWith('SUPABASE_URL=')) url = line.split('=')[1].trim();
    if (line.startsWith('SUPABASE_ANON_KEY=')) key = line.split('=')[1].trim();
  }

  final client = SupabaseClient(url, key);
  
  print("Connected to Supabase.");

  final events = await client.from('events').select('id, title, date, group_id').limit(1);
  if (events.isEmpty) {
    print("No events found to test with.");
    return;
  }

  final event = events.first;
  final eventId = event['id'];
  final oldDate = event['date'];
  final newDate = DateTime.now().toUtc().toIso8601String();

  print("Found event: ${event['title']} (ID: $eventId)");
  print("Old date: $oldDate");
  print("Attempting to update to: $newDate...");

  try {
    final response = await client
        .from('events')
        .update({'date': newDate})
        .eq('id', eventId)
        .select();
    
    if (response.isEmpty) {
      print("Update failed: No rows were affected (likely RLS blocking or wrong ID).");
    } else {
      print("Update SUCCESS! New date in DB: ${response.first['date']}");
    }
  } catch (e) {
    print("Update CRASHED with error: $e");
  }
}
