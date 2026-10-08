import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'home_page.dart';

import 'SignIn.dart';
import 'profile_setup.dart';
import 'package:google_fonts/google_fonts.dart';
class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final username = TextEditingController();
  final password = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      "MusiJournal",
                      style: GoogleFonts.poppins(
                        fontSize: 40,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 15.0, left: 15, right: 15, bottom:20),
                  child: Text(
                      "Sign up:",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 30,
                      )
                  ),
                ),
              ),

              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, bottom: 15),
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
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30, left: 30, right: 15),
                            child: Text(
                                "Email",
                                style: GoogleFonts.poppins(
                                  color: Colors.black,
                                  fontSize: 20,
                                )
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left:30.0, right: 30.0,),
                          child: TextField(
                            controller: username,
                            decoration: InputDecoration(
                              hintText: "Email",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 30.0, left: 30, right: 15),
                            child: Text(
                                "Password",
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 20,
                                )
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 30.0, right: 30.0, top: 5.0, bottom: 100),
                          child: TextField(
                            controller: password,
                            obscureText: true,
                            decoration: InputDecoration(
                              hintText: "Password, minimum 6 characters",
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            style: TextStyle(
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(10.0), //decoration code
                          child: SizedBox(
                            height: 40,
                            width: double.infinity,
                            child: FloatingActionButton.large( // button created
                              backgroundColor: Colors.blue[300],
                              onPressed: () async {
                                try {
                                  final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                                    email: username.text,
                                    password: password.text,
                                  ); // try to create an account using given username and password
                                  String uid = credential.user!.uid;

                                  db.collection("users").doc(uid).set({ // set up this user's documents for future use
                                    "email": FirebaseAuth.instance.currentUser?.email,
                                    "first": "placeholder",
                                    "last": "placeholder",
                                    "preferredGenre": "placeholder",
                                    "lastWrittenDate": DateTime.now().subtract(const Duration(days: 1)),
                                    "lastRecommendDate": DateTime.now().subtract(const Duration(days: 1)),
                                  });
                                  Navigator.push( // if successful, send user to the profile setup page
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) => const profile_setup(),
                                      )
                                  );
                                } on FirebaseAuthException catch (e) { // if a weak password error has occurred
                                  if (e.code == 'weak-password') {
                                    toastification.show( // show weak password error
                                      context: context,
                                      type: ToastificationType.error,
                                      title: Text('Your password is too short. It must be at least 6 characters.'),
                                      autoCloseDuration: const Duration(seconds: 5),
                                    );
                                  } else if (e.code == 'email-already-in-use') { // if an email already in use error has occurred
                                    toastification.show( // show email already in use error
                                      context: context,
                                      type: ToastificationType.error,
                                      title: Text('That email is already in use.'),
                                      autoCloseDuration: const Duration(seconds: 5),
                                    );
                                  }
                                } catch (e) { // if another error occurs
                                  toastification.show( // show error message
                                    context: context,
                                    title: Text('Sorry! We encountered an error. Please try again later.'),
                                    autoCloseDuration: const Duration(seconds: 5),
                                  );
                                  print(e);
                                }
                              },
                              child: Text(
                                "Sign Up",
                                style: TextStyle(
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Already have an account? Sign in here:",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 13,
                              ),
                            ),
                            IconButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                          builder: (context) => const SignIn()
                                      )
                                  );
                                },
                                icon: const Icon(
                                  Icons.subdirectory_arrow_right_outlined,
                                  size: 20,
                                )
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
              ),
            ]
        ),
      ),
    );
  }
}
