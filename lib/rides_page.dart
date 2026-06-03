import 'package:flutter/material.dart';

class RidesPage extends StatelessWidget {
  const RidesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rides'),
      ),
      body: const Center(
        child: Text('Rides Screen'),
      ),
    );
  }
}
