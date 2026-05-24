import 'package:flutter/material.dart';
import 'package:smart_canteen/change_password_screen.dart';
import 'package:smart_canteen/change_username_screen.dart';

class ChangeCredentialsScreen extends StatelessWidget {
  final bool isGoogleUser;

  const ChangeCredentialsScreen({
    super.key,
    required this.isGoogleUser,
  });

  void _showBlockedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "Users logged in through Gmail cannot change Username and Password",
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Account")),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            _MenuTile(
              text: "Change Username",
              icon: Icons.person,
              onTap: () async {
                if (isGoogleUser) {
                  _showBlockedSnackBar(context);
                  return;
                }

                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangeUsernameScreen(),
                  ),
                );

                if (updated == true && context.mounted) {
                  Navigator.pop(context, true); // forward result
                }
              },
            ),

            _MenuTile(
              text: "Change Password",
              icon: Icons.lock,
              onTap: () {
                if (isGoogleUser) {
                  _showBlockedSnackBar(context);
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangePasswordScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuTile({
    required this.text,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          backgroundColor: const Color(0xFFF5F6F9),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onTap,
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFFF7643)),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF757575)),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }
}
