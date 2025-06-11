import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PostPlace extends StatefulWidget {
  final String place;

  const PostPlace({super.key, required this.place});

  @override
  _PostPlaceState createState() => _PostPlaceState();
}

class _PostPlaceState extends State<PostPlace> {
  List<Map<String, String>> hotels = [];
  List<String> pendingTravels = [];
  double? latitude, longitude;

  @override
  void initState() {
    super.initState();
    fetchPlaceDetails();
  }

  void fetchPlaceDetails() async {
    final dbRef =
        FirebaseDatabase.instance.ref().child("places/${widget.place}");
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        hotels = (data["hotels"] as List<dynamic>?)?.map((hotel) {
              return {
                "name": (hotel["name"] as String?) ?? "Unknown Hotel",
                "bookingUrl": (hotel["bookingUrl"] as String?) ??
                    "https://www.booking.com"
              };
            }).toList() ??
            [];
        pendingTravels = List<String>.from(data["pendingTravels"] ?? []);
        latitude = (data["latitude"] is double)
            ? data["latitude"]
            : (data["latitude"] is int
                ? (data["latitude"] as int).toDouble()
                : null);
        longitude = (data["longitude"] is double)
            ? data["longitude"]
            : (data["longitude"] is int
                ? (data["longitude"] as int).toDouble()
                : null);
      });
    }
  }

  void _launchUber() async {
    if (latitude != null && longitude != null) {
      String uberUrl =
          "uber://?action=setPickup&dropoff[latitude]=$latitude&dropoff[longitude]=$longitude";
      String uberWebUrl =
          "https://m.uber.com/ul/?action=setPickup&dropoff[latitude]=$latitude&dropoff[longitude]=$longitude";
      if (await canLaunchUrl(Uri.parse(uberUrl))) {
        await launchUrl(Uri.parse(uberUrl));
      } else {
        await launchUrl(Uri.parse(uberWebUrl));
      }
    }
  }

  void _launchPickMe() async {
    if (latitude != null && longitude != null) {
      String pickMeUrl =
          "pickme://?action=ride&dropoff_lat=$latitude&dropoff_lng=$longitude";
      String pickMeWebUrl = "https://pickme.lk";
      if (await canLaunchUrl(Uri.parse(pickMeUrl))) {
        await launchUrl(Uri.parse(pickMeUrl));
      } else {
        await launchUrl(Uri.parse(pickMeWebUrl));
      }
    }
  }

  void _launchBooking(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $url')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.toUpperCase(),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: hotels.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nearest Hotels Section
                  const Text("Nearest Hotels:",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 150,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: hotels.map((hotel) {
                        return Card(
                          elevation: 3.0,
                          child: ListTile(
                            leading:
                                const Icon(Icons.hotel, color: Colors.blue),
                            title: Text(hotel["name"] ?? "Unknown Hotel"),
                            trailing: ElevatedButton(
                              onPressed: () {
                                final url = hotel["bookingUrl"];
                                if (url != null) {
                                  _launchBooking(url);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Booking URL not available")),
                                  );
                                }
                              },
                              child: const Text("Book on Booking.com"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Pending Travels Section
                  const Text("Pending Travels:",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 100,
                    child: ListView(
                      physics: const BouncingScrollPhysics(),
                      children: pendingTravels.map((travel) {
                        return Card(
                          elevation: 3.0,
                          child: ListTile(
                            leading: const Icon(Icons.directions_bus,
                                color: Colors.red),
                            title: Text(travel),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Google Map Section
                  if (latitude != null && longitude != null)
                    SizedBox(
                      height: 250,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: LatLng(latitude!, longitude!),
                          zoom: 12,
                        ),
                        markers: {
                          Marker(
                            markerId: MarkerId(widget.place),
                            position: LatLng(latitude!, longitude!),
                            infoWindow: InfoWindow(title: widget.place),
                          ),
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Ride Booking Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _launchUber,
                        icon: const Icon(Icons.directions_car,
                            color: Colors.white),
                        label: const Text("Book Uber"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                      ),
                      ElevatedButton.icon(
                        onPressed: _launchPickMe,
                        icon: const Icon(Icons.directions_bus,
                            color: Colors.white),
                        label: const Text("Book PickMe"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
