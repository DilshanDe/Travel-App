import 'package:flutter/material.dart';
import 'package:traveltest_app/post_place.dart';
import 'package:firebase_database/firebase_database.dart';

class TopPlaces extends StatefulWidget {
  const TopPlaces({super.key});

  @override
  State<TopPlaces> createState() => _TopPlacesState();
}

class _TopPlacesState extends State<TopPlaces> {
  List<Map<String, dynamic>> places = [];

  @override
  void initState() {
    super.initState();
    _fetchPlaces();
  }

  void _fetchPlaces() async {
    final dbRef = FirebaseDatabase.instance.ref().child("places");
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      List<Map<String, dynamic>> loadedPlaces = [];

      data.forEach((key, value) {
        loadedPlaces.add({
          "name": key,
          "image":
              "images/${key.toLowerCase()}.jpg", // Assuming images are named correctly
        });
      });

      setState(() {
        places = loadedPlaces;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("TOP PLACES"), // App bar title in uppercase
        centerTitle: true,
        backgroundColor: Colors.blue, // Change color as needed
        elevation: 4.0, // Add shadow effect
      ),
      body: Container(
        margin: EdgeInsets.only(top: 10.0),
        child: places.isEmpty
            ? Center(
                child: CircularProgressIndicator()) // Show loading indicator
            : SingleChildScrollView(
                child: Column(
                  children: places.map((place) {
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  PostPlace(place: place["name"])),
                        );
                      },
                      child: Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: Material(
                          elevation: 3.0,
                          borderRadius: BorderRadius.circular(20),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.asset(
                                  place["image"],
                                  height: 300,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 250),
                                height: 50,
                                width: double.infinity,
                                color: Colors.black26,
                                child: Center(
                                  child: Text(
                                    place["name"]
                                        .toUpperCase(), // Convert name to uppercase
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
      ),
    );
  }
}
