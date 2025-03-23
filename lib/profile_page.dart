import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traveltest_app/services/shared_pref.dart';
import 'package:traveltest_app/login.dart'; // Import your login page
import 'dart:io';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name, email, image, displayName;
  File? _imageFile; // To store the selected image file

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    getthesharedpref();
  }

  // Fetch user details from shared preferences
  getthesharedpref() async {
    name = await SharedpreferenceHelper().getUserName();
    email = await SharedpreferenceHelper().getUserEmail();
    image = await SharedpreferenceHelper().getUserImage();
    displayName = await SharedpreferenceHelper().getUserDisplayName();
    setState(() {});
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Store the selected image file
      });

      // Save the new image path to shared preferences
      await SharedpreferenceHelper().saveUserImage(pickedFile.path);
    }
  }

  // Function to take a photo using the camera
  Future<void> _takePhoto() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path); // Store the captured image file
      });

      // Save the new image path to shared preferences
      await SharedpreferenceHelper().saveUserImage(pickedFile.path);
    }
  }

  // Function to show a dialog for choosing between gallery and camera
  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Choose an option"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                GestureDetector(
                  child: const Text("Gallery"),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                const Padding(padding: EdgeInsets.all(8.0)),
                GestureDetector(
                  child: const Text("Camera"),
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to handle logout
  Future<void> _logout() async {
    // Clear user data from shared preferences
    await SharedpreferenceHelper().clearUserData();

    // Navigate to the login page and remove all previous routes
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LogIn()),
      (Route<dynamic> route) => false, // Remove all routes
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.blue,
        actions: [
          // Logout button in the app bar
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout, // Call the logout function
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Column(
            children: [
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _showImagePickerDialog, // Open image picker dialog
                child: CircleAvatar(
                  radius: 50,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) // Use the selected image
                      : image != null
                          ? NetworkImage(image!) // Use the existing image
                          : null,
                  child: _imageFile == null && image == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                name ?? "Guest",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                displayName ?? "",
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.email, color: Colors.blue),
                title: Text(
                  email ?? "No Email",
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Additional user information can be displayed here.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
