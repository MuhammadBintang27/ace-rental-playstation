import 'package:ace_rental/components/my_drawer.dart';
import 'package:flutter/material.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override 
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("admin"),
        backgroundColor: Theme.of(context).colorScheme.background,
      ),
      drawer: MyDrawer(),
    );
  }
}