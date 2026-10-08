import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:musictherapytracker_windows/profile_setup.dart';
import 'firebase_options.dart';
import 'home_page.dart';
import 'SignIn.dart';
import 'SignUp.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:dart_openai/dart_openai.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  OpenAI.apiKey = dotenv.env['OPENAI_API_KEY']!;
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          textTheme: GoogleFonts.poppinsTextTheme().apply(
            bodyColor: Colors.white,      // Default color for body text
            displayColor: Colors.white,   // Default color for headlines, etc.
          ),

        ),
        // home: SignIn()
        home: SignUp()
    );
  }
}