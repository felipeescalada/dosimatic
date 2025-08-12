import 'package:flutter/material.dart';
import '../widgets/app_drawer.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Usuarios'),
      ),
      drawer: const AppDrawer(),
      body: const Center(
        child: Text('Lista de Usuarios'),
      ),
    );
  }
}
