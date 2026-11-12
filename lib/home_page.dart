import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloud_api.dart';
import 'play_on_spotify_button.dart';
import 'JournalAlreadyWritten.dart';
import 'journalwriting.dart';
import 'AllPastJournals.dart';
import 'ProfileSettings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool userWroteToday = false;
  bool isLoading = true;
  late Future<List<Map<String, dynamic>>> journalsFuture;
  int _weekOffset = 0;

  Map<String, DateTime> _getWeekRange(int offset) {
    DateTime now = DateTime.now();

    int daysFromMonday = now.weekday - 1;
    DateTime currentMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
    DateTime targetMonday = currentMonday.add(Duration(days: offset * 7));
    DateTime targetSunday = targetMonday.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));

    return {
      'start': targetMonday,
      'end': targetSunday,
    };
  }

  String _getGreeting() {
    int hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning!';
    if (hour < 17) return 'Good afternoon!';
    return 'Good evening!';
  }

  late Future<List<dynamic>> recommendedSongs;

    Future<List<Map<String, dynamic>>> retrieveUserInfo() async {
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final weekRange = _getWeekRange(_weekOffset);
      DateTime startOfWeek = weekRange['start']!;
      DateTime endOfWeek = weekRange['end']!;

      QuerySnapshot<Map<String, dynamic>> userDoc = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(user.uid)
          .collection("journal_entries")
          .where(
          "timestamp", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfWeek))
          .where(
          "timestamp", isLessThanOrEqualTo: Timestamp.fromDate(endOfWeek))
          .orderBy("timestamp", descending: true)
          .get();

      List<Map<String, dynamic>> answer = [];

      for (var doc in userDoc.docs) {
        final Map<String, dynamic> data = doc.data();
        if (data["timestamp"] == null) continue;

        answer.add(data);
      }

      return answer.reversed.toList();
    }

    void _refreshJournals() {
      setState(() {
        journalsFuture = retrieveUserInfo();
      });
    }

    Future<void> _checkIfUserWroteToday() async {
      try {
        User? user = FirebaseAuth.instance.currentUser;

        if (user == null) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection(
            'users').doc(user.uid).get();

        if (!userDoc.exists) {
          setState(() {
            isLoading = false;
          });
          return;
        }

        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;

        if (!data.containsKey("lastWrittenDate")) {
          setState(() {
            isLoading = false;
          });
          return;
        }


        Timestamp? timestamp = data["lastWrittenDate"] as Timestamp?;

        if (timestamp != null) {
          DateTime now = DateTime.now();
          DateTime lastDate = timestamp.toDate();


          if (now.year == lastDate.year && now.month == lastDate.month &&
              now.day == lastDate.day) {
            setState(() {
              userWroteToday = true;
            });
          } else {}
        }
      } catch (e) {} finally {
        setState(() {
          isLoading = false;
        });
      }
    }

    @override
    void initState() {
      super.initState();
      journalsFuture = retrieveUserInfo();
      _checkIfUserWroteToday();

      // Assign the Future IMMEDIATELY. Do not use 'await' here!
      // This satisfies the 'late' keyword requirement.
      recommendedSongs = getRecommendedSongs();
    }
    User? user = FirebaseAuth.instance.currentUser;

    final List<Color> Moods = [
      Colors.yellow,
      Colors.blue,
      Colors.red,
      Colors.grey,
    ];

    final List<String> Days = [
      "Mon",
      "Tue",
      "Wed",
      "Thu",
      "Fri",
      "Sat",
      "Sun",
    ];



    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 4,
          backgroundColor: Colors.black,
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.lightBlueAccent, Colors.blue],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Text (
                                _getGreeting(),
                                style: const TextStyle(
                                  fontSize: 25,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                )
                            ),
                          ),
                          SizedBox(
                            width: 20,
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left:34, top:9),
                            child: IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute<void>(
                                    builder: (
                                        context) => const ProfileSettings(), // The new page widget
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.settings,
                                size: 30,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(top: 9),
                            child: StreamBuilder<DocumentSnapshot>(
                              // 1. Listen to this specific user's document
                              stream: FirebaseFirestore.instance.collection('users').doc(user?.uid).snapshots(),
                              builder: (context, snapshot) {

                                // 2. Handle loading state
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return CircleAvatar(
                                    radius: 32,
                                    backgroundColor: Colors.grey.shade200,
                                    child: const CircularProgressIndicator(strokeWidth: 2),
                                  );
                                }

                                // 3. Extract the URL from Firestore data
                                final userData = snapshot.data?.data() as Map<String, dynamic>?;
                                final String? photoUrl = userData?['profilePictureUrl'];

                                // 4. Display the image or a default icon
                                return CircleAvatar(
                                  radius: 32,
                                  backgroundColor: Colors.blue.shade50,
                                  backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                                  child: photoUrl == null
                                      ? Icon(Icons.person, size: 20 * 1.2, color: Colors.blueAccent)
                                      : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20, bottom: 20),
                        child: Text(
                            'What would you like to do today?',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            )
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () {
                              _checkIfUserWroteToday();
                              if (userWroteToday == true) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      context) => const JournalAlreadyWritten()),
                                ).then((_) {
                                  _checkIfUserWroteToday();
                                  _refreshJournals();
                                });
                              }
                              else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (
                                      context) => const journalWriting()),
                                ).then((_) {
                                  _checkIfUserWroteToday();
                                  _refreshJournals();
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              fixedSize: const Size(180, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.edit, color: Colors.black),
                            label: const Text(
                                "New Journal",
                                style: TextStyle(
                                  color: Colors.black,
                                )
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const PastJournals()),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              elevation: 3,
                              fixedSize: const Size(180, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              backgroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.search, color: Colors.black),
                            label: const Text(
                                "Past Journals",
                                style: TextStyle(
                                  color: Colors.black,
                                )
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Text(
                            "Today's Recommendations",
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.bold,
                            )
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0, right: 20),
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
                        ),
                      ),
                      FutureBuilder<List<dynamic>>(
                        future: recommendedSongs,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          final List<dynamic> mySongs = snapshot.data ?? [];

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: mySongs.length,
                            itemBuilder: (context, index) {

                              // 1. Grab the Spotify track
                              var track = mySongs[index];

                              // 2. Extract the strings and the image URL
                              String spotifyID = track['id'];
                              String songName = track['name'];
                              String artistName = track['artists'][0]['name'];

                              // Grab the medium-sized cover art (index 1)
                              String coverArtUrl = track['album']['images'][1]['url'];

                              // 3. Draw a beautiful ListTile
                              return Padding(
                                padding: const EdgeInsets.only(left: 18.0, right: 18),
                                child: Card( // A Card gives it a nice slight shadow and rounded corners
                                  elevation: 2,
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  color: Colors.white,
                                  child: ListTile(
                                    // leading is the widget on the far left
                                    leading: ClipRRect(
                                      borderRadius: BorderRadius.circular(4), // slightly round the image corners
                                      child: Image.network(
                                        coverArtUrl,
                                        width: 50,
                                        height: 50,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    title: Text(
                                      songName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                    subtitle: Text(artistName),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        PlayOnSpotifyButton(trackId: spotifyID, compact: true),
                                        IconButton(
                                          color: Colors.black,
                                          icon: const Icon(Icons.edit),
                                          onPressed: () {
                                            _checkIfUserWroteToday();
                                            if (userWroteToday == true) {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (
                                                    context) => const JournalAlreadyWritten()),
                                              ).then((_) {
                                                _checkIfUserWroteToday();
                                                _refreshJournals();
                                              });
                                            }
                                            else {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(builder: (
                                                    context) => journalWriting(
                                                  selectedSongName: songName,
                                                  selectedArtistName: artistName,
                                                  selectedCoverUrl: coverArtUrl,
                                                  selectedSongId: spotifyID,)),
                                              ).then((_) {
                                                _checkIfUserWroteToday();
                                                _refreshJournals();
                                              });
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                            },
                          );
                        }
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20, left: 10, right: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(
                                  Icons.arrow_back_ios, color: Colors.white),
                              onPressed: () {
                                setState(() {
                                  _weekOffset--;
                                });
                                _refreshJournals();
                              },
                            ),

                            Text(
                              _weekOffset == 0
                                  ? "This Week's Trend"
                                  : _weekOffset == -1
                                  ? "Last Week's Trend"
                                  : "Week of ${_getWeekRange(
                                  _weekOffset)['start']!.month}/${_getWeekRange(
                                  _weekOffset)['start']!.day}",
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),

                            IconButton(
                              icon: Icon(
                                Icons.arrow_forward_ios,
                                color: _weekOffset >= 0
                                    ? Colors.white38
                                    : Colors.white,
                              ),
                              onPressed: _weekOffset >= 0 ? null : () {
                                setState(() {
                                  _weekOffset++;
                                });
                                _refreshJournals();
                              },
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            left: 20.0, right: 20, bottom: 20),
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
                                Align(
                                  alignment: Alignment.bottomLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                        left: 15.0, top: 15),
                                    child: Text(
                                      "Emotional Intensity:",
                                      style: TextStyle(
                                        color: Colors.black,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: FutureBuilder(
                                        future: journalsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Center(
                                                child: CircularProgressIndicator());
                                          }

                                          // 2. Check if Firebase threw an error

                                          if (snapshot.hasError) {
                                            return Text(
                                                "Error: ${snapshot.error}");
                                          }

                                          final data = snapshot.data;
                                          if (data == null || data.isEmpty) {
                                            return Column(
                                              children: [
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      8.0),
                                                  child: Text(
                                                    "No journals this week...",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 30,
                                                    ),
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.all(
                                                      8.0),
                                                  child: Text(
                                                    "Write your first?",
                                                    style: TextStyle(
                                                      color: Colors.black,
                                                      fontSize: 20,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          return SizedBox(
                                            height: 220,
                                            width: double.infinity,
                                            child: ListView.builder(
                                                scrollDirection: Axis
                                                    .horizontal,
                                                shrinkWrap: true,
                                                physics: const NeverScrollableScrollPhysics(),
                                                itemCount: data.length,
                                                itemBuilder: (context, index) {
                                                  final fields = data[index];

                                                  DateTime Date = fields["timestamp"]
                                                      .toDate();
                                                  return Padding(
                                                    padding: const EdgeInsets
                                                        .all(8.0),
                                                    child: Column(
                                                      mainAxisAlignment: MainAxisAlignment
                                                          .end,
                                                      children: [
                                                        Container(
                                                          height: fields["intensity"] *
                                                              1.7,
                                                          width: 30,
                                                          decoration: BoxDecoration(
                                                            color: Moods[fields["mood"]],
                                                            borderRadius: BorderRadius
                                                                .only(
                                                                topLeft: Radius
                                                                    .circular(
                                                                    10),
                                                                topRight: Radius
                                                                    .circular(
                                                                    10)),
                                                          ),
                                                        ),
                                                        Text(
                                                          Days[Date.weekday -
                                                              1],
                                                          style: TextStyle(
                                                            color: Colors.black,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }
                                            ),
                                          );
                                        }
                                    )
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
          ],
        ),
      );
    }
  }