import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class Hotel {
  final String name;
  final String url;
  final double rating;
  final String address;
  final String phone;

  Hotel({
    required this.name,
    required this.url,
    required this.rating,
    required this.address,
    required this.phone,
  });

  factory Hotel.fromMap(Map<dynamic, dynamic> map) {
    return Hotel(
      name: map['name'] ?? 'Unknown Hotel',
      url: map['url'] ?? 'https://example.com',
      rating: map['rating']?.toDouble() ?? 0.0,
      address: map['address'] ?? 'No address provided',
      phone: map['phone'] ?? 'No phone provided',
    );
  }
}

class PostPlace extends StatefulWidget {
  final String place;

  const PostPlace({super.key, required this.place});

  @override
  _PostPlaceState createState() => _PostPlaceState();
}

class _PostPlaceState extends State<PostPlace> {
  List<Hotel> hotels = [];
  List<String> pendingTravels = [];
  double? latitude, longitude;

  @override
  void initState() {
    super.initState();
    _fetchPlaceDetails();
  }

  void _fetchPlaceDetails() async {
    final dbRef =
        FirebaseDatabase.instance.ref().child("places/${widget.place}");
    final snapshot = await dbRef.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      setState(() {
        hotels = List<Hotel>.from(
          (data["hotels"] as List<dynamic>)
              .map((hotel) => Hotel.fromMap(hotel)),
        );
        pendingTravels = List<String>.from(data["pendingTravels"] ?? []);
        latitude = data["latitude"];
        longitude = data["longitude"];
      });
    } else {
      print("Snapshot does not exist for place: ${widget.place}");
    }
  }

  void _launchHotelUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      throw 'Could not launch $url';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.toUpperCase(),
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue,
      ),
      body: hotels.isEmpty
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Nearest Hotels:",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: hotels.length,
                      itemBuilder: (context, index) {
                        final hotel = hotels[index];
                        return Card(
                          elevation: 3.0,
                          child: ListTile(
                            leading: Icon(Icons.hotel, color: Colors.blue),
                            title: Text(hotel.name),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Rating: ${hotel.rating}"),
                                Text("Address: ${hotel.address}"),
                                Text("Phone: ${hotel.phone}"),
                              ],
                            ),
                            onTap: () => _launchHotelUrl(hotel.url),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
                  Text("Pending Travels:",
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      itemCount: pendingTravels.length,
                      itemBuilder: (context, index) {
                        final travel = pendingTravels[index];
                        return Card(
                          elevation: 3.0,
                          child: ListTile(
                            leading:
                                Icon(Icons.directions_bus, color: Colors.red),
                            title: Text(travel),
                          ),
                        );
                      },
                    ),
                  ),
                  SizedBox(height: 20),
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
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _launchUber,
                        icon: Icon(Icons.directions_car, color: Colors.white),
                        label: Text("Book Uber"),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black),
                      ),
                      ElevatedButton.icon(
                        onPressed: _launchPickMe,
                        icon: Icon(Icons.directions_bus, color: Colors.white),
                        label: Text("Book PickMe"),
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
