import 'package:cloud_firestore/cloud_firestore.dart';

import 'journalwriting.dart';
import 'AllPastJournals.dart';
import 'ProfileSettings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class JournalAlreadyWritten extends StatefulWidget {
  const JournalAlreadyWritten({super.key});

  @override
  State<JournalAlreadyWritten> createState() => _JournalAlreadyWrittenState();
}

class _JournalAlreadyWrittenState extends State<JournalAlreadyWritten> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue,
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
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children:
          [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 2,
                          offset: Offset(0, 10),
                        )
                      ],
                    ),
                    child: Align(
                        alignment: AlignmentGeometry.center,
                        child: Column(
                          children: [
                            Text("Sorry!", style: TextStyle(fontSize:80, color: Colors.black)),

                            Padding(
                              padding: const EdgeInsets.only(left:30, right:30),
                              child: Text("You have already written a journal today. Come back tommorow.", style: TextStyle(fontSize:20, color: Colors.black)),
                            ),

                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                }, child: Text("Return to home page"),
                              ),
                            ),
                          ],
                        )
                    )
                  ),
                ),
              ],
            ),
          ]
        ),
      ),
    );
  }
}
