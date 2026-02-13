import 'package:flutter/material.dart';

class BookARidePage extends StatelessWidget {
  const BookARidePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Ride'),
      ),
      body: const Center(
        child: Text('Book a Ride Screen'),
      ),
    );
  }
}
