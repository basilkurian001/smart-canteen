import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_canteen/auth_service.dart';
import 'package:smart_canteen/change_credentials_screen.dart';
import 'package:smart_canteen/homescreen.dart';
import 'package:smart_canteen/order_history_screen.dart';
import 'package:smart_canteen/signin.dart';
import 'google_auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatelessWidget {
  final Map<String, dynamic>? user;

  const ProfileScreen({
    super.key,
    this.user,
  });

  @override
  Widget build(BuildContext context) {
    final String name = user?['name'] ?? 'User';
    final String? avatar = user?['avatar'];
    final bool isGoogleUser = user?['google_id'] != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          children: [
            ProfilePic(
              avatar: avatar,
              canEdit: !isGoogleUser,
            ),

            const SizedBox(height: 12),

            Text(
              name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            if (isGoogleUser)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  "Profile photo managed by Google",
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),

            const SizedBox(height: 24),

            ProfileMenu(
              text: "My Account",
              icon: "assets/icons/User Icon.svg",
              press: () async {
                final updated = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ChangeCredentialsScreen(isGoogleUser: false),
                  ),
                );

                if (updated == true && context.mounted) {
                  final me = await AuthService().me();
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: me['user']),
                    ),
                  );
                }
              },
            ),
            ProfileMenu(
              text: "Notifications",
              icon: "assets/icons/Bell.svg",
              press: () {},
            ),
            ProfileMenu(
              text: "Order History",
              icon: "assets/icons/Settings.svg",
              press: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const OrderHistoryScreen(),
                  ),
                );
              },
            ),
            ProfileMenu(
              text: "Help Center",
              icon: "assets/icons/Question mark.svg",
              press: () {},
            ),

            ProfileMenu(
              text: "Log Out",
              icon: "assets/icons/Log out.svg",
              press: () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Logout"),
                    content: const Text("Are you sure you want to logout?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text("Logout"),
                      ),
                    ],
                  ),
                );

                if (shouldLogout == true) {
                  await AuthService().clearToken();
                  await GoogleAuthService().signOutGoogle();

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SignInScreen(),
                    ),
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ProfilePic extends StatefulWidget {
  final String? avatar;
  final bool canEdit;

  const ProfilePic({
    super.key,
    this.avatar,
    required this.canEdit,
  });

  @override
  State<ProfilePic> createState() => _ProfilePicState();
}

class _ProfilePicState extends State<ProfilePic> {
  File? _localImage;
  final picker = ImagePicker();

  Future<void> _pickImage() async {
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (picked == null) return;

      final file = File(picked.path);

      try {
        // Upload to server
        await AuthService().uploadAvatar(file);

        // Show immediately in UI
        setState(() {
          _localImage = file;
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile picture updated")),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    }



  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      width: 115,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            backgroundImage: _localImage != null
                ? FileImage(_localImage!)
                : (widget.avatar != null && widget.avatar!.isNotEmpty)
                    ? NetworkImage(widget.avatar!)
                    : null,
            child: (_localImage == null &&
                    (widget.avatar == null || widget.avatar!.isEmpty))
                ? const Icon(Icons.person, size: 50)
                : null,
          ),

          if (widget.canEdit)
            Positioned(
              right: -10,
              bottom: 0,
              child: IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _pickImage,
              ),
            ),
        ],
      ),
    );
  }
}


class ProfileMenu extends StatelessWidget {
  final String text;
  final String icon;
  final VoidCallback? press;

  const ProfileMenu({
    super.key,
    required this.text,
    required this.icon,
    this.press,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: TextButton(
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFFF7643),
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          backgroundColor: const Color(0xFFF5F6F9),
        ),
        onPressed: press,
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              width: 22,
              colorFilter: const ColorFilter.mode(
                Color(0xFFFF7643),
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(color: Color(0xFF757575)),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Color(0xFF757575),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

const String cameraIcon = '''
<svg width="20" height="16" viewBox="0 0 20 16" fill="none"
xmlns="http://www.w3.org/2000/svg">
<path fill-rule="evenodd" clip-rule="evenodd"
d="M10 12.0152C8.49151 12.0152 7.26415 10.8137 7.26415 9.33902C7.26415 7.86342 8.49151 6.6619 10 6.6619C11.5085 6.6619 12.7358 7.86342 12.7358 9.33902C12.7358 10.8137 11.5085 12.0152 10 12.0152Z"
fill="#757575"/>
</svg>
''';
