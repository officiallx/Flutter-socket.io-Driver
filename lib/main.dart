import 'package:flutter/material.dart';
import 'package:socket_client/background_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Socket.IO",
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: const BackgroundPage(),
    );
  }
}
