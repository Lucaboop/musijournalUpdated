import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:musictherapytracker_windows/profile_setup.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'SignIn.dart';
import 'SignUp.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Wait for Firebase to restore a saved login, so signed-in users skip Sign Up.
  final User? user = await FirebaseAuth.instance.authStateChanges().first;
  runApp(MyApp(isSignedIn: user != null));
}

class MyApp extends StatelessWidget {
  final bool isSignedIn;
  const MyApp({super.key, required this.isSignedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'MusiJournal',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: Colors.white,      // Default color for body text
            displayColor: Colors.white,   // Default color for headlines, etc.
          ),

        ),
        // home: SignIn()
        home: isSignedIn ? const HomePage() : const SignUp()
    );
  }
}