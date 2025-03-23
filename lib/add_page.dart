import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:random_string/random_string.dart';
import 'package:traveltest_app/services/database.dart';
import 'package:traveltest_app/services/shared_pref.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  String? name, image;
  bool isLoading = false; // Loading state

  getthesharedpref() async {
    name = await SharedpreferenceHelper().getUserName() ??
        ""; //methna thma wenas kre
    image = await SharedpreferenceHelper().getUserImage() ?? "";
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    getthesharedpref();
  }

  final ImagePicker _picker = ImagePicker();
  File? selectedImage;

  Future<void> getImage() async {
    try {
      var pickedImage = await _picker.pickImage(source: ImageSource.gallery);
      if (pickedImage != null) {
        selectedImage = File(pickedImage.path);
        setState(() {});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          backgroundColor: Colors.red,
          content: Text("No image selected."),
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error selecting image: $e"),
      ));
    }
  }

  TextEditingController placenamecontroller = TextEditingController();
  TextEditingController citynamecontroller = TextEditingController();
  TextEditingController captioncontroller = TextEditingController();

  Future<void> uploadPost() async {
    if (selectedImage == null ||
        placenamecontroller.text.isEmpty ||
        citynamecontroller.text.isEmpty ||
        captioncontroller.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content:
            Text("All fields must be filled, and an image must be selected."),
      ));
      return;
    }

    setState(() {
      isLoading = true; // Show loading
    });

    String addId = randomAlphaNumeric(10);
    try {
      Reference firebaseStorageRef =
          FirebaseStorage.instance.ref().child("blogImage").child(addId);

      UploadTask uploadTask = firebaseStorageRef.putFile(selectedImage!);
      TaskSnapshot snapshot = await uploadTask.whenComplete(() => null);
      String downloadUrl = await snapshot.ref.getDownloadURL();

      Map<String, dynamic> addPost = {
        "Image": downloadUrl,
        "PlaceName": placenamecontroller.text,
        "CityName": citynamecontroller.text,
        "Caption": captioncontroller.text,
        "Name": name, //methanth wenas kara
        "UserImage": image,
        "Like": [],
      };

      await DatabaseMethods().addPost(addPost, addId);

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.green,
        content: Text("Post has been uploaded successfully!"),
      ));

      await Future.delayed(Duration(seconds: 5)); // Keep loading for 5 seconds

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: Colors.red,
        content: Text("Error uploading post: $e"),
      ));
    } finally {
      setState(() {
        isLoading = false; // Hide loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 20.0, top: 40.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Material(
                      elevation: 3.0,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(30)),
                        child: Icon(
                          Icons.arrow_back_ios_new_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: MediaQuery.of(context).size.width / 4.5,
                  ),
                  Text(
                    "Add Post",
                    style: TextStyle(
                        color: Colors.blue,
                        fontSize: 28.0,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 30.0,
            ),
            Expanded(
              child: Material(
                elevation: 3.0,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: Container(
                  padding: EdgeInsets.only(left: 20.0, right: 10.0, top: 30.0),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(186, 250, 247, 247),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  width: MediaQuery.of(context).size.width,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        selectedImage != null
                            ? Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.file(
                                    selectedImage!,
                                    height: 180,
                                    width: 180,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            : Center(
                                child: GestureDetector(
                                  onTap: getImage,
                                  child: Container(
                                    height: 180,
                                    width: 180,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.black45, width: 2.0),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(Icons.camera_alt_outlined),
                                  ),
                                ),
                              ),
                        SizedBox(height: 20.0),
                        Text("Place Name",
                            style: TextStyle(
                                fontSize: 22.0, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: placenamecontroller,
                          decoration: InputDecoration(
                              filled: true, hintText: "Enter Place Name"),
                        ),
                        SizedBox(height: 20.0),
                        Text("City Name",
                            style: TextStyle(
                                fontSize: 22.0, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: citynamecontroller,
                          decoration: InputDecoration(
                              filled: true, hintText: "Enter City Name"),
                        ),
                        SizedBox(height: 20.0),
                        Text("Caption",
                            style: TextStyle(
                                fontSize: 22.0, fontWeight: FontWeight.bold)),
                        SizedBox(height: 15.0),
                        TextField(
                          controller: captioncontroller,
                          maxLines: 6,
                          decoration: InputDecoration(
                              filled: true, hintText: "Enter Caption..."),
                        ),
                        SizedBox(height: 30.0),
                        GestureDetector(
                          onTap: isLoading ? null : uploadPost,
                          child: Center(
                            child: Container(
                              height: 50,
                              width: MediaQuery.of(context).size.width / 2,
                              decoration: BoxDecoration(
                                  color: isLoading ? Colors.grey : Colors.blue,
                                  borderRadius: BorderRadius.circular(10)),
                              child: Center(
                                child: isLoading
                                    ? CircularProgressIndicator(
                                        color: Colors.white)
                                    : Text("Post",
                                        style: TextStyle(
                                            fontSize: 22.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
