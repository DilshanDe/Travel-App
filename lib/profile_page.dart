import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:traveltest_app/login.dart';
import 'package:traveltest_app/services/shared_pref.dart';
import 'package:traveltest_app/services/database.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String? name, email, image, displayName, userId;
  File? _imageFile;
  bool _isLoading = false;
  bool _isUpdatingImage = false;

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get current Firebase user
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        // Reload user to get the latest data
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;

        if (updatedUser != null) {
          // Get user data with priority system
          email = updatedUser.email ??
              await SharedpreferenceHelper().getUserEmail();
          image = updatedUser.photoURL ??
              await SharedpreferenceHelper().getUserImage();
          userId = updatedUser.uid;

          // Handle display name with multiple fallbacks
          String? firebaseDisplayName = updatedUser.displayName;
          String? sharedPrefName = await SharedpreferenceHelper().getUserName();
          String? sharedPrefDisplayName =
              await SharedpreferenceHelper().getUserDisplayName();

          // Try to get name from database if available
          String? databaseName;
          try {
            if (userId != null) {
              var userData = await DatabaseMethods().getUserDetails(userId!);
              if (userData != null && userData['UserName'] != null) {
                databaseName = userData['UserName'];
              }
            }
          } catch (e) {
            print('Error fetching from database: $e');
          }

          // Priority order: Firebase Display Name > Database Name > SharedPref Name > Email prefix
          if (firebaseDisplayName != null && firebaseDisplayName.isNotEmpty) {
            name = firebaseDisplayName;
            displayName = firebaseDisplayName;
          } else if (databaseName != null && databaseName.isNotEmpty) {
            name = databaseName;
            displayName = databaseName;
          } else if (sharedPrefName != null && sharedPrefName.isNotEmpty) {
            name = sharedPrefName;
            displayName = sharedPrefName;
          } else if (sharedPrefDisplayName != null &&
              sharedPrefDisplayName.isNotEmpty) {
            name = sharedPrefDisplayName;
            displayName = sharedPrefDisplayName;
          } else if (email != null && email!.isNotEmpty) {
            // Use email prefix as last resort
            name = email!.split('@')[0];
            displayName = name;
          } else {
            name = "Guest User";
            displayName = "Guest User";
          }

          // Update SharedPreferences with the resolved name
          if (name != null && name!.isNotEmpty) {
            await SharedpreferenceHelper().saveUserName(name!);
            await SharedpreferenceHelper().saveUserDisplayName(name!);
          }

          // Update other fields in SharedPreferences
          if (email != null) {
            await SharedpreferenceHelper().saveUserEmail(email!);
          }
          if (image != null) {
            await SharedpreferenceHelper().saveUserImage(image!);
          }
          await SharedpreferenceHelper().saveUserId(userId!);

          // If Firebase doesn't have display name but we have one, update Firebase
          if ((firebaseDisplayName == null || firebaseDisplayName.isEmpty) &&
              name != null &&
              name!.isNotEmpty &&
              name != "Guest User") {
            try {
              await updatedUser.updateDisplayName(name);
              await updatedUser.reload();
            } catch (e) {
              print('Error updating Firebase display name: $e');
            }
          }
        }
      } else {
        // Fallback to SharedPreferences if no current user
        name = await SharedpreferenceHelper().getUserName();
        email = await SharedpreferenceHelper().getUserEmail();
        image = await SharedpreferenceHelper().getUserImage();
        displayName = await SharedpreferenceHelper().getUserDisplayName();
        userId = await SharedpreferenceHelper().getUserId();

        // If we still don't have a name, use email prefix as fallback
        if ((name == null || name!.isEmpty) &&
            email != null &&
            email!.isNotEmpty) {
          name = email!.split('@')[0];
          displayName = name;
          await SharedpreferenceHelper().saveUserName(name!);
          await SharedpreferenceHelper().saveUserDisplayName(name!);
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      // Handle error - maybe show a snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading profile data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<String?> _uploadImageToFirebase(File imageFile) async {
    try {
      setState(() {
        _isUpdatingImage = true;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Create a unique filename with timestamp
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('user_profile_images')
          .child('${user.uid}_$timestamp.jpg');

      // Upload with metadata
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'userId': user.uid},
      );

      final uploadTask = storageRef.putFile(imageFile, metadata);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } catch (e) {
      print('Error uploading image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to upload image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUpdatingImage = false;
        });
      }
    }
  }

  Future<void> _updateUserProfile(String photoUrl) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Update Firebase Auth profile
        await user.updatePhotoURL(photoUrl);
        await user.reload();

        // Update SharedPreferences
        await SharedpreferenceHelper().saveUserImage(photoUrl);

        // Update Firestore if using custom database
        if (userId != null) {
          Map<String, dynamic> updateData = {
            "Image": photoUrl,
            "UserName": name ?? user.displayName ?? "User",
            "Email": email ?? user.email ?? "",
          };

          try {
            await DatabaseMethods().updateUserDetails(updateData, userId!);
          } catch (e) {
            print('Error updating database: $e');
            // Continue even if database update fails
          }
        }

        if (mounted) {
          setState(() {
            image = photoUrl;
            _imageFile = null;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
        });

        final photoUrl = await _uploadImageToFirebase(file);
        if (photoUrl != null) {
          await _updateUserProfile(photoUrl);
        }
      }
    } catch (e) {
      print('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to select image. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        setState(() {
          _imageFile = file;
        });

        final photoUrl = await _uploadImageToFirebase(file);
        if (photoUrl != null) {
          await _updateUserProfile(photoUrl);
        }
      }
    } catch (e) {
      print('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to take photo. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: const Text("Update Profile Photo"),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.photo_library, color: Colors.blue),
                  title: const Text('Choose from Gallery'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: Colors.blue),
                  title: const Text('Take a Photo'),
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

  Future<void> _refreshProfile() async {
    await _loadUserData();
  }

  Future<void> _logout() async {
    // Show confirmation dialog
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Logout'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) {
      try {
        await SharedpreferenceHelper().clearUserData();
        await FirebaseAuth.instance.signOut();

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const LogIn()),
            (Route<dynamic> route) => false,
          );
        }
      } catch (e) {
        print('Error during logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error logging out. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showInfoDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          title: Text(title),
          content: SingleChildScrollView(child: Text(content)),
          actions: [
            TextButton(
              child: const Text('Close'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        backgroundColor: const Color(0xFF273671),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProfile,
            tooltip: 'Refresh Profile',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshProfile,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFF273671),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                      ),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 3),
                                ),
                                child: CircleAvatar(
                                  radius: 60,
                                  backgroundImage: _imageFile != null
                                      ? FileImage(_imageFile!)
                                      : (image != null && image!.isNotEmpty)
                                          ? NetworkImage(image!)
                                          : null,
                                  backgroundColor: Colors.grey[300],
                                  child: (image == null || image!.isEmpty) &&
                                          _imageFile == null
                                      ? const Icon(Icons.person,
                                          size: 60, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 5,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: _isUpdatingImage
                                    ? const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(Icons.camera_alt,
                                            color: Color(0xFF273671)),
                                        onPressed: _showImagePickerDialog,
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text(
                            name ?? "Guest User",
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 5),
                          if (email != null && email!.isNotEmpty)
                            Text(
                              email!,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white70,
                              ),
                            ),
                          if (displayName != null &&
                              displayName!.isNotEmpty &&
                              displayName != name)
                            Text(
                              displayName!,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white60,
                              ),
                            ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildProfileOption(
                      Icons.settings,
                      "Settings",
                      subtitle: "Manage your app preferences",
                      onTap: () => _showInfoDialog(
                        "Settings",
                        "Settings options will be available soon for your travel experience!",
                      ),
                    ),
                    _buildProfileOption(
                      Icons.help_outline,
                      "FAQ",
                      subtitle: "Frequently asked questions",
                      onTap: () => _showInfoDialog(
                        "Frequently Asked Questions",
                        "Here you will find answers to common questions about our travel app.",
                      ),
                    ),
                    _buildProfileOption(
                      Icons.description,
                      "Terms and Conditions",
                      subtitle: "Review our terms of service",
                      onTap: () => _showInfoDialog(
                        "Terms and Conditions",
                        "By using this travel app, you agree to our terms and conditions. Please review them carefully.",
                      ),
                    ),
                    _buildProfileOption(
                      Icons.privacy_tip,
                      "Privacy Policy",
                      subtitle: "Learn how we protect your data",
                      onTap: () => _showInfoDialog(
                        "Privacy Policy",
                        "We value your privacy. Read about how we protect your data in our travel app.",
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 15),
                      child: ElevatedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout),
                        label: const Text("Log Out",
                            style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProfileOption(IconData icon, String text,
      {String? subtitle, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF273671).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF273671)),
        ),
        title: Text(text,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(fontSize: 12))
            : null,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
