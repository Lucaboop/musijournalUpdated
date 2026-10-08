import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:toastification/toastification.dart';
import 'home_page.dart';
import 'SignUp.dart';
import 'home_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';


class profile_setup extends StatefulWidget {
  const profile_setup({super.key});

  @override
  State<profile_setup> createState() => _profile_setupState();
}

class _profile_setupState extends State<profile_setup> {
  List<String> Genres = [
    "Currently Trending",
    "Classical",
    "Rock and Roll",
    "EDM",
    "Rap",
    "HipHop",
    "Pop",
    "Jazz",
  ];
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  String? selectedGenre;
  final FirebaseFirestore db = FirebaseFirestore.instance;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  String? _uploadedImageUrl;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80, // Compresses image for better performance
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadAndSaveProfile() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (_selectedImage == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      // Point to Firebase Storage: user_profiles/userId.jpg
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profiles')
          .child('${user?.uid}.jpg');

      // Upload the file
      await storageRef.putFile(_selectedImage!);

      // Get the resulting download URL
      final String downloadUrl = await storageRef.getDownloadURL();

      // Save the URL to the user's Firestore document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid)
          .set({
        'profilePictureUrl': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isUploading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture saved!')),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading: $e')),
        );
      }
    }
  }
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
            end: Alignment.topRight,
            colors: [Colors.lightBlueAccent, Colors.blue],
          ),
        ),
        child: Column(
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
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(top: 15.0, left: 15, right: 15, bottom:20),
                child: Text(
                  "Profile Setup:",
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
                      SizedBox(height: 25),
                      GestureDetector(
                        onTap: _isUploading ? null : _pickImage,
                        child: CircleAvatar(
                          radius: 65,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: _selectedImage != null
                              ? FileImage(_selectedImage!)
                              : (_uploadedImageUrl != null
                                ? NetworkImage(_uploadedImageUrl!) as ImageProvider
                                : null),
                          child: (_selectedImage == null && _uploadedImageUrl == null)
                              ? const Icon(Icons.add_a_photo_outlined, size: 40, color: Colors.grey)
                              : null,
                        ),
                      ),
                      SizedBox(height: 10,),
                      if (_isUploading)
                        const CircularProgressIndicator()
                      else if (_selectedImage != null && _uploadedImageUrl == null)
                      // Show save button if they picked a new image but haven't uploaded yet
                        ElevatedButton(
                          onPressed: _uploadAndSaveProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Save Profile Picture'),
                        )
                      else
                      // Helper text
                        Text(
                          _uploadedImageUrl == null
                              ? 'Tap to add a photo'
                              : 'Tap your photo to change it',
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      // Text(
                      //   "Press on avatar to choose profile picture.",
                      //   style: TextStyle(
                      //     color: Colors.black45,
                      //     fontSize: 15,
                      //   )
                      // ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, left: 30, right: 15),
                          child: Text(
                            "First Name",
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
                          controller: firstName,
                          decoration: InputDecoration(
                            hintText: "First name",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 30, left: 30, right: 15),
                          child: Text(
                            "Last Name",
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
                          controller: lastName,
                          decoration: InputDecoration(
                            hintText: "Last Name",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(),
                          ),
                          style: TextStyle(
                            color: Colors.black,
                          ),
                          onChanged: (value) {
                            setState(() {});
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, left: 25, right: 15),
                          child: Text(
                              "Preferred Music Genre",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              )
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 29, right: 29),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(5)),
                          ),
                          initialValue: selectedGenre,

                          hint: const Text("Select a Genre"),
                          onChanged: (String? newValue) {
                            setState(() {
                              selectedGenre = newValue;
                            });
                          },
                          items: Genres.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 25.0),
                                child: Text(
                                    value,
                                    style: TextStyle(
                                      color: Colors.black,
                                    )
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10.0, right: 10, bottom: 10, top: 60),
                        child: SizedBox(
                          height: 40,
                          width: double.infinity,
                          child: FloatingActionButton.large(
                            backgroundColor: Colors.blue[300],
                            onPressed: () async {

                              final User? user = FirebaseAuth.instance.currentUser;
                              final String? uid = user?.uid;

                              await db.collection("users").doc(uid).update({
                                "first": firstName.text,
                                "last": lastName.text,
                                "preferredGenre": selectedGenre,
                              });

                              Navigator.push(
                                context,
                                MaterialPageRoute<void>(
                                  builder: (context) => const HomePage(), // The new page widget
                                ),
                              );
                            },
                            child: Text(
                              "Continue",
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              )
            )
          ],
        )
      )
    );
  }
}
