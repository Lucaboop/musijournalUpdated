import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const Color spotifyGreen = Color.fromRGBO(30, 215, 96, 1);

// Opens the track in the Spotify app (or the web player if the app isn't installed).
Future<void> openInSpotify(BuildContext context, String trackId) async {
  final url = Uri.https('open.spotify.com', '/track/$trackId');
  bool opened = await launchUrl(url, mode: LaunchMode.externalApplication);
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open Spotify.')),
    );
  }
}

class PlayOnSpotifyButton extends StatelessWidget {
  final String trackId;
  // compact: icon only (for list tiles). Otherwise a labeled "Play on Spotify" button.
  final bool compact;

  const PlayOnSpotifyButton({
    super.key,
    required this.trackId,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Play on Spotify',
        icon: const Icon(Icons.play_circle_fill, color: spotifyGreen, size: 32),
        onPressed: () => openInSpotify(context, trackId),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: spotifyGreen,
        foregroundColor: Colors.black,
        shape: const StadiumBorder(),
      ),
      icon: const Icon(Icons.play_arrow),
      label: const Text(
        'Play on Spotify',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      onPressed: () => openInSpotify(context, trackId),
    );
  }
}
