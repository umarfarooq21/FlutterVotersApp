import 'package:flutter/material.dart';


class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  //static const LatLng _initial = LatLng(24.8607, 67.0011); // Karachi example

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("On-Demand Ride")),
     
    );
  }
}
