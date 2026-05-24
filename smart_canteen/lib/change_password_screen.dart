import 'package:flutter/material.dart';
import 'package:smart_canteen/auth_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _old = TextEditingController();
  final _new = TextEditingController();

  bool _loading = false;
  bool _showOldPassword = false;
  bool _showNewPassword = false;

  Future<void> _submit() async {
    if (_old.text.isEmpty || _new.text.isEmpty) return;

    setState(() => _loading = true);

    try {
      await AuthService().changePassword(
        oldPassword: _old.text,
        newPassword: _new.text,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated")),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _old.dispose();
    _new.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Change Password")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🔐 Current Password
            TextField(
              controller: _old,
              obscureText: !_showOldPassword,
              decoration: InputDecoration(
                labelText: "Current Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _showOldPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showOldPassword = !_showOldPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 12),

            // 🔐 New Password
            TextField(
              controller: _new,
              obscureText: !_showNewPassword,
              decoration: InputDecoration(
                labelText: "New Password",
                suffixIcon: IconButton(
                  icon: Icon(
                    _showNewPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _showNewPassword = !_showNewPassword;
                    });
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }
}
