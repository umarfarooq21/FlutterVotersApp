import 'package:flutter/material.dart';

class ActiveSubscription extends StatefulWidget {
  const ActiveSubscription({super.key});

  @override
  State<ActiveSubscription> createState() => _ActiveSubscription();
}
class _ActiveSubscription extends State<ActiveSubscription> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Active Subscription'),
      ),
    );
  }
}