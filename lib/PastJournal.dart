import 'package:flutter/material.dart';
import 'cloud_api.dart';
import 'play_on_spotify_button.dart';

String truncateString(String text)
{
  if(text.length <= 13)
    {
      return text;
    }
  return "${text.substring(0, 13)}...";
}

class PastJournal extends StatefulWidget {
  final Map<String, dynamic> journalData;
  const PastJournal({super.key, required this.journalData});

  @override
  State<PastJournal> createState() => _PastJournalState();
}


final List<IconData> items = [
  Icons.sentiment_very_satisfied,
  Icons.sentiment_very_dissatisfied,
  Icons.sentiment_very_dissatisfied_outlined,
  Icons.sentiment_neutral,
];

String? TruncatedTitle;

class _PastJournalState extends State<PastJournal> {

  // Notice we changed String? to Map<String, String>?
  Future<Map<String, String>?> _loadSongData() async {
  return fetchSongDetails(widget.journalData['song']);
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 4,
        backgroundColor: Colors.black,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlueAccent, Colors.blue],
          ),
        ),
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,

            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10,
                          offset: Offset(0, 5),
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Row(
                                children: [
                                  Column(
                                    children: [
                                      FutureBuilder<Map<String, String>?>(
                                        future: _loadSongData(), // <-- Point it to the new combined function!
                                        builder: (context, snapshot) {

                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const CircularProgressIndicator(); // Loading spinner
                                          }

                                          if (snapshot.hasData && snapshot.data != null) {
                                            // We got the URL! Draw the image.
                                            final songData = snapshot.data!;
                                            TruncatedTitle = truncateString(songData["name"]!);

                                            return Column(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    songData['imageUrl']!,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                const SizedBox(height: 8), // A little spacing

                                                // 2. Draw the Song Name
                                                Text(
                                                  TruncatedTitle!,
                                                  // TruncatedTitle!,
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  songData['artist']!,
                                                  style: const TextStyle(
                                                    color: Colors.black54, // Slightly faded color for the artist
                                                    fontSize: 14,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                const SizedBox(height: 8),
                                                PlayOnSpotifyButton(trackId: widget.journalData['song']),
                                              ],
                                            );
                                          }

                                          // Fallback if there was an error or no image
                                          return const Icon(Icons.album, size: 100);
                                        },
                                      ),
                                    ],
                                  ),
                                  SizedBox( // just for separating the music and text
                                    width: 20,
                                  ),
                                  Expanded( // text
                                    child: Text("${widget.journalData['month']} ${widget.journalData['dateAndYear'].day}, ${widget.journalData['dateAndYear'].year}",
                                        softWrap: true,
                                        style: TextStyle(
                                          fontSize: 25,
                                          color: Colors.black,
                                          fontWeight: FontWeight.bold,
                                        )
                                    ),
                                  ),
                                ],
                              )
                            ),
                            Positioned(
                              left: 320,
                              top: 5,
                              child: IconButton (
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                icon: const Icon(Icons.arrow_back),
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
                          child: Text(widget.journalData['content'],
                              style: TextStyle(
                                  height: 1.6,
                                  color: Colors.black,
                                  fontSize: 18
                              )
                          ),
                        ),

                        Padding(
                          padding: const EdgeInsets.only(left: 20, bottom: 20, right: 20),
                          child: Text("Emotion: ${widget.journalData['mood']}",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            )
                          ),
                        ),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lightbulb_circle_outlined, size: 50),
                            Text(
                              "AI Overview:",
                              // "hi",
                              style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold
                              ),
                            ),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            widget.journalData["AIOverview"],
                            style: TextStyle(
                              height: 1.6,
                              color: Colors.black,
                              fontSize: 18
                            )
                          ),
                        ),
                      ],
                    )
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}