import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'home_page.dart';
import 'SignUp.dart';
import 'home_page.dart';
import 'package:google_fonts/google_fonts.dart';
class SignIn extends StatefulWidget {
  const SignIn({super.key});

  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final username = TextEditingController();
  final password = TextEditingController();

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
                  "Sign in:",
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
                              fontSize: 20,
                              color: Colors.black,
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
                              fontSize: 20,
                              color: Colors.black,
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
                            hintText: "Password",
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
                          child: FloatingActionButton.large( //create button
                            backgroundColor: Colors.blue[300],
                            onPressed: () async {
                              try { // try to sign in using given credentials
                                final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                                    email: username.text,
                                    password: password.text,
                                );
                                User? user = FirebaseAuth.instance.currentUser;
                                FirebaseFirestore.instance.collection("users").doc(user?.uid).update({"email": username.text});
                                //update current user's document named "email"
                                Navigator.push(//send user to the home page
                                    context,
                                    MaterialPageRoute<void>(
                                      builder: (context) => const HomePage(),
                                    )
                                );
                              } on FirebaseAuthException catch (e) {
                                if (e.code == "invalid-credential") { //if there is an invalid credential error
                                  toastification.show( // show invalid credential error
                                    type: ToastificationType.error,
                                    context: context,
                                    title: Text('Email or password incorrect.'),
                                    autoCloseDuration: const Duration(seconds: 5),
                                  );
                                }
                                else if(e.code == "too-many-requests") { //if there have been too many requests
                                  toastification.show(// show too many requests error
                                    type: ToastificationType.error,
                                    context: context,
                                    title: Text('Too many requests sent. Please try again later.'),
                                    autoCloseDuration: const Duration(seconds: 5),
                                  );
                                }
                              }
                              catch (e) { // if another error happens
                                toastification.show(// show error messsage
                                  context: context,
                                  title: Text('Sorry! We encountered an error. Please try again later.'),
                                  autoCloseDuration: const Duration(seconds: 5),
                                );
                                print(e);
                              }
                            },
                            child: Text(
                              "Finish",
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
                            "Don't have an account? Sign up here:",
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
                                    builder: (context) => const SignUp()
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
