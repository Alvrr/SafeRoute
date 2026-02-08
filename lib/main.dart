import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCb928Hg5e5Q2HfyRaAruJ_TrFKIC29izc",
        authDomain: "saferoute-129158.firebaseapp.com",
        databaseURL:
            "https://saferoute-129158-default-rtdb.asia-southeast1.firebasedatabase.app",
        projectId: "saferoute-129158",
        storageBucket: "saferoute-129158.firebasestorage.app",
        messagingSenderId: "295695171818",
        appId: "1:295695171818:web:43462c8b377a17d254d793",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  runApp(const SafeRouteApp());
}