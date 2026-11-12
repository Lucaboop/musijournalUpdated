import 'package:cloud_functions/cloud_functions.dart';

// All OpenAI and Spotify calls go through Cloud Functions (see functions/index.js),
// so no API keys or secrets are shipped inside the app.
final FirebaseFunctions _functions = FirebaseFunctions.instance;

// Search Spotify for tracks matching [query].
Future<List<dynamic>> searchTracks(String query, {int limit = 10}) async {
  final result = await _functions
      .httpsCallable('searchTracks')
      .call({'query': query, 'limit': limit});
  return result.data as List<dynamic>;
}

// Get cover art URL, name and artist for a Spotify track id.
Future<Map<String, String>?> fetchSongDetails(String songId) async {
  try {
    final result =
        await _functions.httpsCallable('getTrack').call({'id': songId});
    final data = Map<String, dynamic>.from(result.data as Map);
    return {
      'imageUrl': data['imageUrl'] as String,
      'name': data['name'] as String,
      'artist': data['artist'] as String,
    };
  } catch (e) {
    print('Failed to load track: $e');
  }
  return null;
}

// 3 Spotify tracks recommended by ChatGPT from the user's preferred genre.
Future<List<dynamic>> getRecommendedSongs() async {
  try {
    final result = await _functions.httpsCallable('getRecommendedSongs').call();
    return result.data as List<dynamic>;
  } catch (e) {
    print('Failed to get recommendations: $e');
  }
  return [];
}

// ChatGPT overview of the journal entry and a 1-100 emotion intensity score.
Future<({String? overview, int? intensity})> getJournalInsights({
  required String journal,
  required String? songName,
  required String emotion,
}) async {
  try {
    final result = await _functions.httpsCallable('getJournalInsights').call({
      'journal': journal,
      'songName': songName,
      'emotion': emotion,
    });
    final data = Map<String, dynamic>.from(result.data as Map);
    return (
      overview: data['overview'] as String?,
      intensity: (data['intensity'] as num?)?.toInt(),
    );
  } catch (e) {
    print("Something went wrong: $e");
  }
  return (overview: null, intensity: null);
}

// Permanently deletes the user's journals, profile, profile picture and login.
// The user must have re-entered their password in the last 5 minutes.
Future<void> deleteAccount() async {
  await _functions.httpsCallable('deleteAccount').call();
}
