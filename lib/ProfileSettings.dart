import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'SignIn.dart';
import 'cloud_api.dart';

class ProfileSettings extends StatefulWidget {
  const ProfileSettings({super.key});

  @override
  State<ProfileSettings> createState() => _ProfileSettingsState();
}

class _ProfileSettingsState extends State<ProfileSettings> {
  User? user = FirebaseAuth.instance.currentUser;
  final FocusNode emailFocusNode = FocusNode();
  FocusNode firstNameFocusNode = FocusNode();
  FocusNode lastnameFocusNode = FocusNode();
  final emailController = TextEditingController(
    text: FirebaseAuth.instance.currentUser?.email,
  );
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final oldPasswordController = TextEditingController();
  final newPasswordController = TextEditingController();
  Color saveAllBGColor = Colors.white;
  Color saveAllTextColor = Colors.black;
  bool changesMade = false;
  bool changesSaved = false;

  // Highlights Save All once something on the page has been edited.
  void _markChanged() {
    setState(() {
      saveAllBGColor = Colors.blue;
      saveAllTextColor = Colors.white;
      changesMade = true;
      changesSaved = false;
    });
  }

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
      await FirebaseFirestore.instance.collection('users').doc(user?.uid).set({
        'profilePictureUrl': downloadUrl,
      }, SetOptions(merge: true));

      setState(() {
        _uploadedImageUrl = downloadUrl;
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error uploading: $e')));
      }
    }
  }

  String? selectedGenre;

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

  Future<bool> checkIfEmailExists(String email) async {
    var snapshot = await FirebaseFirestore.instance
        .collection("users")
        .where('email', isEqualTo: email)
        .get();
    if (snapshot.docs.isNotEmpty) {
      return true;
    }
    return false;
  }

  Future<void> getUserData(String? userId) async {
    DocumentSnapshot user = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();
    Map<String, dynamic> data = user.data() as Map<String, dynamic>;
    setState(() {
      firstNameController.text = data['first'];
      lastNameController.text = data['last'];
      selectedGenre = data['preferredGenre'];
    });
    print("current email is ${FirebaseAuth.instance.currentUser?.email}");
  }

  Future<bool> verifyOldPassword(String oldPassword) async {
    User? user = FirebaseAuth
        .instance
        .currentUser; // store the current user in a variable
    AuthCredential credential = EmailAuthProvider.credential(
      // variable with type credential to validate
      email: user?.email ?? '',
      password: oldPassword,
    );
    try {
      await user?.reauthenticateWithCredential(
        credential,
      ); // attempt to reauthenticate with old password
      return true; // will only return true if an error does not occur
    } on FirebaseException catch (e) {
      // if an error occurs
      if (e.code == 'wrong-password') // if the error was a wrong password
      {
        return false; // return false
      }
    }
    return false;
  }

  // Asks for the password, then permanently deletes the account and goes back to Sign In.
  Future<void> _confirmDeleteAccount() async {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorText;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text(
            "Delete account?",
            style: TextStyle(color: Colors.black, fontSize: 20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "This permanently deletes your account, all of your journals, and your profile picture. This cannot be undone.",
                style: TextStyle(color: Colors.black),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  hintText: "Enter your password to confirm",
                  errorText: errorText,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.black),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: isDeleting
                  ? null
                  : () async {
                      setDialogState(() {
                        isDeleting = true;
                        errorText = null;
                      });

                      bool passwordCorrect = await verifyOldPassword(
                        passwordController.text,
                      );
                      if (!passwordCorrect) {
                        setDialogState(() {
                          isDeleting = false;
                          errorText = "Password incorrect.";
                        });
                        return;
                      }

                      try {
                        await deleteAccount();
                        await FirebaseAuth.instance.signOut();
                        if (!mounted) return;
                        toastification.show(
                          context: context,
                          type: ToastificationType.success,
                          title: const Text('Your account has been deleted.'),
                          autoCloseDuration: const Duration(seconds: 5),
                        );
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute<void>(
                            builder: (context) => const SignIn(),
                          ),
                          (route) => false,
                        );
                      } catch (e) {
                        print("Failed to delete account: $e");
                        setDialogState(() {
                          isDeleting = false;
                          errorText =
                              "Could not delete account. Please try again.";
                        });
                      }
                    },
              child: isDeleting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchCurrentPicture() async {
    try {
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user?.uid) // Make sure you pass the userId to this widget
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('profilePictureUrl')) {
          setState(() {
            // This will instantly swap the "add photo" icon for their real picture
            _uploadedImageUrl = data['profilePictureUrl'];
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching profile picture: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final User? user = FirebaseAuth.instance.currentUser;
    late final String? uid = user?.uid;
    getUserData(uid);
    _fetchCurrentPicture();
    print(user?.email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(toolbarHeight: 4, backgroundColor: Colors.black),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.bottomRight,
            colors: [Colors.lightBlueAccent, Colors.blue],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: const Text(
                      'Profile Settings',
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 130.0),
                    child: IconButton(
                      onPressed: () {
                        if (changesMade == true && changesSaved == false) {
                          showDialog<void>(
                            context: context,
                            barrierDismissible: false,
                            builder: (BuildContext dialogContext) {
                              return AlertDialog(
                                title: const Text(
                                  'Changes not saved. Discard your changes?',
                                  style: TextStyle(color: Colors.black),
                                ),
                                backgroundColor: Colors.white,
                                actions: <Widget>[
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                          Navigator.of(context).pop();
                                        },
                                        child: const Text('Yes'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(dialogContext).pop();
                                        },
                                        child: const Text('No'),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _isUploading ? null : _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (_uploadedImageUrl != null
                            ? NetworkImage(_uploadedImageUrl!) as ImageProvider
                            : null),
                  child: (_selectedImage == null && _uploadedImageUrl == null)
                      ? const Icon(
                          Icons.add_a_photo_outlined,
                          size: 40,
                          color: Colors.grey,
                        )
                      : null,
                ),
              ),
              Text(
                "Click on profile picture to edit.",
                style: TextStyle(fontSize: 15, color: Colors.white),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(40),
                    color: Colors.white,
                    boxShadow: [
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
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 17,
                            left: 25,
                            right: 15,
                          ),
                          child: Text(
                            "First Name",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: TextField(
                                onChanged: (value) => _markChanged(),
                                focusNode: firstNameFocusNode,
                                controller: firstNameController,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => firstNameFocusNode.requestFocus(),
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 17,
                            left: 25,
                            right: 15,
                          ),
                          child: Text(
                            "Last Name",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: TextField(
                                onChanged: (value) => _markChanged(),
                                focusNode: lastnameFocusNode,
                                controller: lastNameController,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => lastnameFocusNode.requestFocus(),
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 17,
                            left: 25,
                            right: 15,
                          ),
                          child: Text(
                            "Email",
                            style: TextStyle(fontSize: 20, color: Colors.black),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: TextField(
                                onChanged: (value) => _markChanged(),
                                controller: emailController,
                                focusNode: emailFocusNode,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => emailFocusNode.requestFocus(),
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 17,
                            left: 25,
                            right: 15,
                          ),
                          child: Text(
                            "Password",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 25.0),
                              child: TextField(
                                readOnly: true,
                                style: TextStyle(color: Colors.black),
                                decoration: InputDecoration(
                                  hintText: "* * * * * * * * *",
                                  // i cant access passwords, so ill do this
                                  filled: true,
                                  fillColor: Colors.white,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            // button created to change password
                            onPressed: () {
                              // when the button is pressed:
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    // create a new pop up screen to show new widgets
                                    backgroundColor: Colors.white,
                                    title: Text(
                                      "Enter your old password",
                                      style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                    actions: [
                                      Column(
                                        children: [
                                          TextField(
                                            // text field for old password
                                            controller: oldPasswordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          Text(
                                            "Enter your new password",
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 20,
                                            ),
                                          ),
                                          TextField(
                                            // text field for new password
                                            controller: newPasswordController,
                                            obscureText: true,
                                            decoration: InputDecoration(
                                              border: OutlineInputBorder(),
                                            ),
                                            style: TextStyle(color: Colors.black),
                                          ),
                                          ElevatedButton(
                                            // enter button
                                            onPressed: () async {
                                              // when the button is pressed:
                                              bool isOldPassCorrect =
                                                  await verifyOldPassword(
                                                    oldPasswordController.text,
                                                  ); // call function
                                              if (isOldPassCorrect) {
                                                if (oldPasswordController.text ==
                                                    newPasswordController
                                                        .text) // if old password = new password
                                                {
                                                  toastification.show(
                                                    // show error
                                                    type:
                                                        ToastificationType.error,
                                                    context: context,
                                                    title: Text(
                                                      'Old and new passwords are identical',
                                                    ),
                                                    autoCloseDuration:
                                                        const Duration(
                                                          seconds: 5,
                                                        ),
                                                  );
                                                } else // if old password is not = new password
                                                {
                                                  User? user = FirebaseAuth
                                                      .instance
                                                      .currentUser;
                                                  try {
                                                    // try to update password
                                                    await user?.updatePassword(
                                                      newPasswordController.text,
                                                    );
                                                    toastification.show(
                                                      // only shows success notification if no error occurs
                                                      type: ToastificationType
                                                          .success,
                                                      context: context,
                                                      title: Text(
                                                        'Password successfully changed.',
                                                      ),
                                                      autoCloseDuration:
                                                          const Duration(
                                                            seconds: 5,
                                                          ),
                                                    );
                                                  } on FirebaseAuthException catch (
                                                    e
                                                  ) {
                                                    // if an error occurs
                                                    if (e.code ==
                                                        "weak-password") // and that error is a weak password
                                                    {
                                                      toastification.show(
                                                        // show weak password notification
                                                        type: ToastificationType
                                                            .error,
                                                        context: context,
                                                        title: Text(
                                                          'New password too short, must be 6 characters or more.',
                                                        ),
                                                        autoCloseDuration:
                                                            const Duration(
                                                              seconds: 5,
                                                            ),
                                                      );
                                                    }
                                                  }
          
                                                  Navigator.pop(context);
                                                }
                                              } else // if the old password is incorrect
                                              {
                                                toastification.show(
                                                  // show old password incorrect notification
                                                  type: ToastificationType.error,
                                                  context: context,
                                                  title: Text(
                                                    'Old password incorrect.',
                                                  ),
                                                  autoCloseDuration:
                                                      const Duration(seconds: 5),
                                                );
                                              }
                                            },
                                            child: Text("Enter"),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                            icon: Icon(Icons.edit),
                          ),
                        ],
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(
                            top: 17,
                            left: 25,
                            right: 15,
                          ),
                          child: Text(
                            "Preferred Music Genre",
                            style: TextStyle(color: Colors.black, fontSize: 20),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 10,
                          left: 25,
                          right: 45,
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: InputDecoration(
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          value: selectedGenre,
                          onChanged: (String? newValue) {
                            _markChanged();
                            setState(() {
                              selectedGenre = newValue;
                            });
                          },
                          items: Genres.map<DropdownMenuItem<String>>((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 25.0),
                                child: Text(
                                  value,
                                  style: TextStyle(color: Colors.black),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 30.0,
                          bottom: 30,
                          left: 20,
                          right: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    User? user =
                                        FirebaseAuth.instance.currentUser;
                                    FirebaseFirestore.instance
                                        .collection("users")
                                        .doc(user?.uid)
                                        .set({
                                          "first": firstNameController.text,
                                          "last": lastNameController.text,
                                          "preferredGenre": selectedGenre,
                                          "email": FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.email,
                                        });
                                    await _uploadAndSaveProfile();
                                    if (user?.email != emailController.text) {
                                      if (await checkIfEmailExists(
                                            emailController.text,
                                          ) ==
                                          true) {
                                        toastification.show(
                                          type: ToastificationType.error,
                                          context: context,
                                          title: Text(
                                            'That email is already in use.',
                                          ),
                                          autoCloseDuration: const Duration(
                                            seconds: 5,
                                          ),
                                        );
                                      } else {
                                        await user?.verifyBeforeUpdateEmail(
                                          emailController.text,
                                        );
                                        showDialog(
                                          context: context,
                                          builder: (BuildContext context) {
                                            return AlertDialog(
                                              title: Text(
                                                "Verification Email Sent",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              content: Text(
                                                "Please sign in again after verifying.",
                                                style: TextStyle(
                                                  color: Colors.black,
                                                ),
                                              ),
                                              backgroundColor: Colors.white,
                                              actions: [
                                                Center(
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                    setState(() {
                                      changesSaved = true;
                                      saveAllBGColor = Colors.white;
                                      saveAllTextColor = Colors.black;
                                    });
                                                      User? user = FirebaseAuth
                                                          .instance
                                                          .currentUser;
                                                      await FirebaseAuth.instance
                                                          .signOut();
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute<void>(
                                                          builder: (context) =>
                                                              const SignIn(), // The new page widget
                                                        ),
                                                      );
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      fixedSize: const Size(
                                                        180,
                                                        50,
                                                      ),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              5,
                                                            ),
                                                      ),
                                                      side: BorderSide(width: 1),
                                                      backgroundColor:
                                                          Colors.white,
                                                    ),
                                                    icon: const Icon(
                                                      Icons.logout,
                                                    ),
                                                    label: const Text(
                                                      "Sign Out",
                                                      style: TextStyle(
                                                        color: Colors.black,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                      }
                                    } else {
                                      toastification.show(
                                        type: ToastificationType.success,
                                        context: context,
                                        description: Text('Changes saved.'),
                                        autoCloseDuration: const Duration(
                                          seconds: 5,
                                        ),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(180, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(width: 1),
                                    backgroundColor: saveAllBGColor,
                                  ),
                                  icon: Icon(
                                    Icons.save_alt,
                                    color: saveAllTextColor,
                                  ),
                                  label: Text(
                                    "Save All",
                                    style: TextStyle(color: saveAllTextColor),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    await FirebaseAuth.instance.signOut();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute<void>(
                                        builder: (context) =>
                                            const SignIn(), // The new page widget
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    fixedSize: const Size(180, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    side: BorderSide(width: 1),
                                    backgroundColor: Colors.white,
                                  ),
                                  icon: const Icon(
                                    Icons.logout,
                                    color: Colors.red,
                                  ),
                                  label: const Text(
                                    "Sign Out",
                                    style: TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 30),
                        child: TextButton.icon(
                          onPressed: _confirmDeleteAccount,
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.red,
                          ),
                          label: const Text(
                            "Delete Account",
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
