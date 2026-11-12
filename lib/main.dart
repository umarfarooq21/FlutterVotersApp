import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_app/controllers/auth_controller.dart';
import 'package:quiz_app/controllers/contacts_controller.dart';
import 'package:quiz_app/controllers/home_controller.dart';
import 'package:quiz_app/controllers/impact_controller.dart';
import 'package:quiz_app/views/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthController()),
        ChangeNotifierProvider(create: (_) => HomeController()),
        ChangeNotifierProvider(create: (_) => ContactsController()),
        ChangeNotifierProvider(create: (_) => ImpactController()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Voting App',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        ),
        home: const LoginPage(),
      ),
    );
  }
}
