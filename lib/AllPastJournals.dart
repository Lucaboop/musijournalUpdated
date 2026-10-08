import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'PastJournal.dart';
class PastJournals extends StatefulWidget {
  const PastJournals({super.key});

  @override
  State<PastJournals> createState() => _PastJournalsState();
}

class _PastJournalsState extends State<PastJournals> {
  final dateEditingController = TextEditingController();
  final List<IconData> items = [
    Icons.sentiment_very_satisfied,
    Icons.sentiment_very_dissatisfied,
    Icons.sentiment_very_dissatisfied_outlined,
    Icons.sentiment_neutral,
  ];

  List<String> months = [
    "January", "February", "March", "April", "May", "June",
    "July", "August", "September", "October", "November", "December"
  ];

  final List<String> dropDownValueList = [
    'Happy',
    'Sad',
    'Angry',
    'Neutral',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 4,
        backgroundColor: Colors.black,
      ),
      body: ConstrainedBox(
        constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height),
        child: Container(
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
                  left:340,
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
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          Text(
                              'Your Past Journals',
                              style: TextStyle(
                                fontSize: 25,
                                fontWeight: FontWeight.bold,
                              )
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: TextField(
                              controller: dateEditingController,
                              onChanged: (value) {
                                setState(() {});
                              },
                              maxLines: 1,
                              decoration: InputDecoration(
                                // contentPadding: EdgeInsets.symmetric(
                                //   vertical: 100,
                                //   horizontal: 1,
                                // ),
                                filled: true,
                                fillColor: Colors.white,
                                prefixIcon: Icon(Icons.search),
                                border: OutlineInputBorder(),
                                // hintStyle: TextStyle(color: Colors.black),
                                hintText: "Search for a date...",
                              ),
                              style: TextStyle(
                                color: Colors.black,
                              ),
                            ),
                          ),
                          StreamBuilder<QuerySnapshot>(
                            stream: FirebaseFirestore.instance
                              .collection("users")
                              .doc(FirebaseAuth.instance.currentUser?.uid)
                              .collection("journal_entries")
                              .orderBy("timestamp", descending: true)
                              .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) return Text("Something went wrong");
                              if (snapshot.connectionState == ConnectionState.waiting) return CircularProgressIndicator();
                              final data = snapshot.data!.docs;
                              final filteredData = data.where((entry) {
                                Timestamp timestamp = entry["timestamp"];
                                DateTime date = timestamp.toDate();
                                String monthName = months[date.month - 1];

                                String displayDate = "$monthName ${date.day}, ${date.year}".toLowerCase();

                                // Grab the text straight from your controller and make it lowercase
                                String currentSearch = dateEditingController.text.toLowerCase();

                                return displayDate.contains(currentSearch);
                              }).toList();
                              return ListView.builder(
                                shrinkWrap: true, // Fixes the "Unbounded Height" error
                                physics: const NeverScrollableScrollPhysics(), // Let the parent scroll
                                itemCount: filteredData.length,
                                itemBuilder: (context, index) {
                                  var entry = filteredData[index];
                                  String journal = entry['content'];
                                  String song = entry['song'];
                                  int mood = entry["mood"];
                                  Timestamp timestamp = entry["timestamp"];
                                  DateTime date = timestamp.toDate();
                                  String monthName = months[date.month-1];
                                  String AIOverview = entry['AIOverview'];
                                  return Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: InkWell(
                                      onTap: (){
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute<void>(
                                            builder: (context) => PastJournal(
                                              journalData: {
                                                "content": journal,
                                                "song": song, //THISWILL PROBABLY BE CHANGED LATER
                                                "month": monthName,
                                                "dateAndYear": date,
                                                "mood": dropDownValueList[mood],
                                                "AIOverview": AIOverview,
                                              }
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(10),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black26,
                                              blurRadius: 10,
                                              offset: Offset(0, 2),
                                              spreadRadius: 0.01,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: [
                                            Icon(
                                              items[mood],
                                              size: 60,
                                            ),
                                            Text(
                                              "$monthName ${date.day}, ${date.year}",
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 20,
                                              )
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }
                              );
                            }
                          )
                        ],
                      ),
                    )
                  ],
                ),
              ]
            ),
          ),
        ),
      ),
    );
  }
}
