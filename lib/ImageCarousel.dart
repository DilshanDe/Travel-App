import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';

class ImageCarousel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final List<String> imagePaths = [
      "images/sigiriya.jpg",
      "images/kandy.jpg",
      "images/jaffna.jpg",
      "images/trincomalee.jpg",
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: MediaQuery.of(context).size.height / 2.5,
        autoPlay: true, // Enables automatic sliding
        enlargeCenterPage: true, // Adds zoom effect
        aspectRatio: 16 / 9,
        viewportFraction: 1.0, // Makes images take full width
      ),
      items: imagePaths.map((imagePath) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(10.0), // Optional: Rounds corners
          child: Image.asset(
            imagePath,
            width: MediaQuery.of(context).size.width, // Ensures full width
            fit: BoxFit.cover, // Adjusts the image to fit nicely
          ),
        );
      }).toList(),
    );
  }
}
