import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'login.dart'; // Importe sua tela de login
import 'user_provider.dart'; // Importe o provider de usuário

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => UserProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Meu App',
      home: LoginScreen(),
    );
  }
}
