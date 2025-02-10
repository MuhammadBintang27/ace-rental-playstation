import 'package:ace_rental/components/my_drawer_tile.dart';
import 'package:ace_rental/pages/setting_page.dart';
import 'package:ace_rental/service/auth/auth_gate.dart';
import 'package:ace_rental/service/auth/auth_service.dart';
import 'package:flutter/material.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({Key? key}) : super(key: key);

  void Logout(BuildContext context) async {
  final _authService = AuthService();
  try {
    await _authService.signOut();
    print("User successfully signed out.");
    
    // Navigasi ke AuthGate tanpa menggunakan nilai return
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthGate()),
      (route) => false,
    );
  } catch (e) {
    print("Error during sign-out: $e");
  }
}



  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.background,
      child: Column(
        children: [
          // app logo
          Padding(
            padding: const EdgeInsets.only(top: 100.0),
            child: Icon(
              Icons.lock_open_rounded,
              size: 100,
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(25.0),
            child: Divider(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          // home list title
          MyDrawerTile(
            icon: Icons.home,
            text: "H O M E",
            onTap: () => Navigator.pop(context),
          ),

          //setting list title
          MyDrawerTile(
            icon: Icons.settings,
            text: "S E T T I N G S",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingPage()));
            },
          ),
          const Spacer(),
          
          //logout list title
          MyDrawerTile(
            icon: Icons.logout,
            text: "L O G O U T",
            onTap: () => Logout(context),
          ),
          const SizedBox(height: 25,)
        ]
      ),
    );
  }
}