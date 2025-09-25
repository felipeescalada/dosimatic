import 'package:flutter/material.dart';
import 'profile_widget.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(
            height: 120,
            child: ProfileWidget(),
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Usuarios'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/users');
            },
          ),
          ListTile(
            leading: const Icon(Icons.article),
            title: const Text('Documentos'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/documentos');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Contactos 1'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/contact1');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Contactos 2'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/contact2');
            },
          ),
          ListTile(
            leading: const Icon(Icons.contacts),
            title: const Text('Contactos 3'),
            onTap: () {
              Navigator.pushReplacementNamed(context, '/contact3');
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.draw),
            title: const Text('Demo Firma Digital'),
            onTap: () {
              Navigator.pushNamed(context, '/signature-demo');
            },
          ),
        ],
      ),
    );
  }
}
