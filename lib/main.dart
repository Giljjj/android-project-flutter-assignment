import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hello_me/data/auth_repository.dart';
import 'package:hello_me/data/favorites_repository.dart';
import 'package:hello_me/ui/sheet.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  final Future<FirebaseApp> _initialization = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
              body: Center(
                  child: Text(snapshot.error.toString(),
                      textDirection: TextDirection.ltr)));
        }
        if (snapshot.connectionState == ConnectionState.done) {
          return MultiProvider(providers: [
            ChangeNotifierProvider<AuthRepository>(
                create: (_) => AuthRepository.instance()),
            ChangeNotifierProvider<FavoritesRepository>(
                create: (_) => FavoritesRepository())
          ], child: const MyApp());
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Remove the const from here
      title: 'Startup Name Generator',
      theme: ThemeData(
          // Add the 5 lines from here...
          brightness: Brightness.light,
          colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.deepPurple)
          // appBarTheme: const AppBarTheme(
          //   backgroundColor: primaryColor
          // ),
          ), // ... to here.
      home: const Scaffold(body: Sheet()),
    );
  }
}
