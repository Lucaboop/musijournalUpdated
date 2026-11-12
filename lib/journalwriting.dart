import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_api.dart';
import 'play_on_spotify_button.dart';

class journalWriting extends StatefulWidget {
  final String? selectedSongName;
  final String? selectedArtistName;
  final String? selectedCoverUrl;
  final String? selectedSongId;

  const journalWriting({
    super.key,
    this.selectedSongName,
    this.selectedArtistName,
    this.selectedCoverUrl,
    this.selectedSongId,
  });

  @override
  State<journalWriting> createState() => _journalWritingState();
}

class _journalWritingState extends State<journalWriting> {
  Future<List<dynamic>>? _searchResultsFuture;
  String? _selectedSongId;
  String? songName;

  bool isUsingRecommendedSong = false;

  final List<IconData> items = [
    Icons.sentiment_very_satisfied,
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_neutral,
  ];

  final List<String> dropDownValueList = ['Happy', 'Sad', 'Angry', 'Neutral'];

  String dropDownValue = '';
  int? selectedIndex;
  final journalController = TextEditingController();
  final songController = TextEditingController();
  String? AIOverview;

  @override
  void initState() {
    super.initState();

    if (widget.selectedSongId != null) {
      _selectedSongId = widget.selectedSongId;
      songName = widget.selectedSongName;
      isUsingRecommendedSong = true;
    }
  }

  void searchSong(String controller) {
    if (controller.isEmpty) {
      setState(() {
        _selectedSongId = null;
        _searchResultsFuture = null;
      });
    } else {
      setState(() {
        _selectedSongId = null;
        _searchResultsFuture = searchTracks(controller);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromRGBO(253, 247, 254, 1),
      appBar: AppBar(toolbarHeight: 4, backgroundColor: Colors.black),
      body: Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlueAccent, Colors.blue],
          ),
        ),
        child: SingleChildScrollView(
          child: Stack(
            children: [
              Positioned(
                right: 10,
                top: 14,
                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.arrow_back),
                ),
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      right: 20,
                      left: 20,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: const Text(
                        "Today's Journal",
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: 20.0,
                      top: 20,
                      bottom: 10,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: const Text(
                        "Choose your song:",
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  if (isUsingRecommendedSong)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Card(
                        elevation: 8,
                        shadowColor: Colors.black,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              widget.selectedCoverUrl!,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            widget.selectedSongName!,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            widget.selectedArtistName!,
                            style: const TextStyle(color: Colors.black54),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PlayOnSpotifyButton(
                                trackId: widget.selectedSongId!,
                                compact: true,
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.black),
                                onPressed: () {
                                  // If they change their mind, clear it and show the search bar!
                                  setState(() {
                                    isUsingRecommendedSong = false;
                                    _selectedSongId = null;
                                    songName = null;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                  left: 20,
                                  right: 20,
                                ),
                                child: Material(
                                  elevation: 8.0,
                                  // Control shadow depth here
                                  borderRadius: BorderRadius.circular(15.0),
                                  shadowColor: Colors.black,
                                  // Change shadow color
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: TextField(
                                      onChanged: (value) {
                                        searchSong(value);
                                      },
                                      controller: songController,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        suffixIcon: Icon(Icons.search),
                                        filled: true,
                                        fillColor: Colors.white,
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15.0,
                                          ),
                                          borderSide: BorderSide.none,
                                        ),
                                        hintText: "Search a song...",
                                      ),
                                      style: TextStyle(color: Colors.black),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        FutureBuilder<List<dynamic>>(
                          // 1. The Future: We give it the search function we want it to run
                          future: _searchResultsFuture,

                          // 2. The Builder: What to draw on the screen
                          builder: (BuildContext context, AsyncSnapshot<List<dynamic>> snapshot) {
                            if(_searchResultsFuture == null)
                            {
                              return Padding(
                                  padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 10),
                                child: Material(
                                  elevation: 8.0, // Control shadow depth here
                                  borderRadius: BorderRadius.circular(15.0),
                                  shadowColor: Colors.black, // Change shadow color
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      children: [
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Icon(
                                          Icons.music_off,
                                          size: 40,
                                          color: Colors.black,
                                        ),
                                        SizedBox(
                                          width: 10,
                                        ),
                                        Text(
                                          "No songs found.",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 17,
                                          )
                                        ),
                                      ],
                                    )
                                  ),
                                ),
                                  // child: const Text("No songs found.", style: TextStyle(fontSize: 20))
                              );
                            }
                            // State 1: We are still waiting for Spotify to reply
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator();
                            }

                                // State 2: Spotify replied, but there was a network error
                                if (snapshot.hasError) {
                                  return Text(
                                    'Error searching: ${snapshot.error}',
                                  );
                                }

                                // State 3: Spotify replied with our data! Let's build a list.
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  List<dynamic> tracks = snapshot.data!;

                                  return Padding(
                                    padding: const EdgeInsets.all(20.0),
                                    child: Material(
                                      elevation: 8.0,
                                      // Control shadow depth here
                                      borderRadius: BorderRadius.circular(15.0),
                                      shadowColor: Colors.black,
                                      // Change shadow color
                                      child: DropdownButtonFormField<String>(
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: Colors.white,
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15.0,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              15.0,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                        // 1. WHAT IS CURRENTLY SELECTED?
                                        // We point it to our variable.
                                        initialValue: _selectedSongId,

                                        // 2. THE DEFAULT TEXT
                                        // What to show when _selectedSongId is null
                                        hint: const Text(
                                          "Tap to choose a song",
                                          style: TextStyle(color: Colors.black),
                                        ),

                                        // Prevents the dropdown text from overflowing the screen
                                        isExpanded: true,
                                        isDense: false,
                                        // 3. THE LIST OF OPTIONS
                                        // We map over the Spotify tracks and build a menu item for each one
                                        items: tracks.map<DropdownMenuItem<String>>((
                                          track,
                                        ) {
                                          String imageUrl = '';
                                          var images = track['album']['images'];
                                          if (images != null &&
                                              images.isNotEmpty) {
                                            imageUrl = images
                                                .last['url']; // Grabs the thumbnail-sized image
                                          }

                                          return DropdownMenuItem<String>(
                                            value: track['id'],

                                            // 2. Swap the Text for a Row!
                                            child: Row(
                                              children: [
                                                // 3. The Album Art (or a fallback icon)
                                                if (imageUrl.isNotEmpty)
                                                  Image.network(
                                                    imageUrl,
                                                    width: 40,
                                                    // Lock the size so the menu looks neat
                                                    height: 40,
                                                    fit: BoxFit.cover,
                                                  )
                                                else
                                                  const SizedBox(
                                                    width: 40,
                                                    height: 40,
                                                    child: Icon(
                                                      Icons.music_note,
                                                    ),
                                                  ),

                                                const SizedBox(width: 12),
                                                // Adds a nice gap between image and text

                                                // 4. The Song Name
                                                // We wrap the text in an 'Expanded' widget.
                                                // If a song title is crazy long, this forces it to add "..."
                                                // instead of crashing your screen!
                                                Expanded(
                                                  child: Text(
                                                    '${track['name']} by ${track['artists'][0]['name']}',
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                        // 4. WHEN THE USER CLICKS AN OPTION
                                        onChanged: (String? newlySelectedId) {
                                          final selectedTrack = tracks
                                              .firstWhere(
                                                (track) =>
                                                    track['id'] ==
                                                    newlySelectedId,
                                              );

                                          // 2. Use setState to update your variables
                                          setState(() {
                                            _selectedSongId = newlySelectedId;
                                            songName =
                                                selectedTrack['name']; // Save the name into your existing variable!
                                          });
                                          // Boom! You have successfully stored their choice!
                                          print(
                                            "Awesome! You stored Song ID: $_selectedSongId",
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }

                                // State 4: Spotify replied, but the search returned 0 results
                                return const Text('No songs found.');
                              },
                        ),
                        if (_selectedSongId != null)
                          PlayOnSpotifyButton(trackId: _selectedSongId!),
                      ],
                    ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 20,
                        top: 20,
                        bottom: 10,
                      ),
                      child: const Text(
                        'Journal Entry:',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20, right: 20),
                    child: Material(
                      elevation: 8.0, // Control shadow depth here
                      borderRadius: BorderRadius.circular(15.0),
                      shadowColor: Colors.black, // Change shadow color
                      child: TextField(
                        controller: journalController,
                        maxLines: 15,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15.0),
                            borderSide: BorderSide.none,
                          ),
                          hintText:
                              "How was your day today, and how does your song connect to it?",
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 20,
                        bottom: 10,
                        left: 20,
                      ),
                      child: const Text(
                        'Choose an emotion:',
                        style: TextStyle(fontSize: 20),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(left: 20, right: 20),
                      child: Material(
                        elevation: 8.0, // Control shadow depth here
                        borderRadius: BorderRadius.circular(15.0),
                        shadowColor: Colors.black, // Change shadow color
                        child: Container(
                          width: 400,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          decoration: BoxDecoration(
                            color: Colors.white, // Your background color here
                            borderRadius: BorderRadius.circular(
                              15.0,
                            ), // Rounded corners
                          ),
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: selectedIndex,
                            hint: const Text(
                              "Select an emotion",
                              style: TextStyle(color: Colors.black),
                            ),
                            items: items.asMap().entries.map((entry) {
                              final index = entry.key;
                              final iconData = entry.value;
                              return DropdownMenuItem<int>(
                                value: index,
                                child: Row(
                                  children: [
                                    Icon(iconData),
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        dropDownValueList[index],
                                        style: TextStyle(color: Colors.black),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (int? newIndex) {
                              setState(() {
                                selectedIndex = newIndex;
                                if (newIndex != null) {
                                  dropDownValue = dropDownValueList[newIndex];
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        height: 40,
                        width: 375,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black,
                          ),

                          onPressed: () async {
                            if (journalController.text.isNotEmpty == true &&
                                _selectedSongId?.isNotEmpty == true &&
                                selectedIndex != null) {
                              final insights = await getJournalInsights(
                                journal: journalController.text,
                                songName: songName,
                                emotion: dropDownValueList[selectedIndex!],
                              );
                              AIOverview = insights.overview;
                              int? intensity = insights.intensity;
                              print(intensity);
                              User? user = FirebaseAuth.instance.currentUser;

                              FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user?.uid)
                                  .update({"lastWrittenDate": DateTime.now()});

                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(user?.uid)
                                  .collection("journal_entries")
                                  .add({
                                    "content": journalController.text,
                                    "song": _selectedSongId,
                                    "mood": selectedIndex!,
                                    "timestamp": FieldValue.serverTimestamp(),
                                    "AIOverview": AIOverview,
                                    "intensity": intensity,
                                  });

                              if (!context.mounted) return;

                              Navigator.pop(context);
                            } else {
                              toastification.show(
                                type: ToastificationType.error,
                                context: context,
                                title: Text(
                                  'Not all fields have been filled out.',
                                ),
                                autoCloseDuration: const Duration(seconds: 5),
                              );
                            }
                          },
                          child: Text("Finish"),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
