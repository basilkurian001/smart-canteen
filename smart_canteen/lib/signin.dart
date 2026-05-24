// lib/sign_in_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:smart_canteen/google_auth_service.dart';
import 'package:smart_canteen/homescreen.dart';
import 'package:smart_canteen/signup.dart';
import 'auth_service.dart';
import 'main.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Sign In", style: TextStyle(color: Colors.black)),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const WelcomeText(
                title: "Welcome to",
                text:
                    "Enter your Phone number or Email \naddress for sign in. Enjoy your food :)",
              ),
              const SignInForm(),
              const SizedBox(height: 16),
              Center(
                child: Text("Or",
                    style: TextStyle(
                        color: const Color(0xFF010F07).withOpacity(0.7))),
              ),
              const SizedBox(height: 16 * 1.5),
              Center(
                child: Text.rich(
                  TextSpan(
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall!
                        .copyWith(fontWeight: FontWeight.w600),
                    text: "Don’t have account? ",
                    children: <TextSpan>[
                      TextSpan(
                        text: "Create new account.",
                        style: const TextStyle(color: Color(0xFF22A45D)),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Navigate to Sign Up Screen
                            //Navigator.pushNamed(context, './signup.dart');
                            Navigator.push(
                              context,
                              MaterialPageRoute<void>( // Specify the return type, e.g., <bool>, <String>, or <void>
                                builder: (BuildContext context) => const SignUpScreen(),
                              ),
                            );
                          },
                      )
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),

              // Google
              SocalButton(
                press: () async{
                                try {
                    final data = await GoogleAuthService().signInWithGoogle(
                       backendUrl: 'http://10.125.22.31:3000/auth/google'
                    );

                    final token = data["token"];
                    final user = data["user"];

                    // Save token using your AuthService
                    await AuthService().saveToken(token);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomeScreen(me: user)),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                text: "Connect with Google",
                color: const Color(0xFF4285F4),
                icon: SvgPicture.string(
                  googleIcon,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class WelcomeText extends StatelessWidget {
  final String title, text;

  const WelcomeText({super.key, required this.title, required this.text});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge!
              .copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16 / 2),
        Text(text, style: const TextStyle(color: Color(0xFF868686))),
        const SizedBox(height: 24),
      ],
    );
  }
}

class SignInForm extends StatefulWidget {
  const SignInForm({super.key});

  @override
  State<SignInForm> createState() => _SignInFormState();
}

class _SignInFormState extends State<SignInForm> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscureText = true;
  bool _loading = false;
  String? _error;

  final AuthService _auth = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
    });

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    setState(() {
      _loading = true;
    });

    try {
      final loginResponse = await _auth.login(email, password);
      // Optionally call /auth/me to get the user object (AuthService.me returns that)
      final meResponse = await _auth.me();
      print('meResponse: $meResponse');

      // Navigate to HomeScreen and remove login from back stack
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomeScreen(me: meResponse)),
      );
      /* Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      ); */

    } catch (e) {
      setState(() {
        //_error = e.toString();
        _error = "Invalid Email or Password";
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String? _validateEmail(String? val) {
    if (val == null || val.trim().isEmpty) return 'Please enter email';
    final email = val.trim();
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? val) {
    if (val == null || val.isEmpty) return 'Please enter password';
    if (val.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email Field
          TextFormField(
            controller: _emailController,
            textInputAction: TextInputAction.next,
            keyboardType: TextInputType.emailAddress,
            validator: _validateEmail,
            decoration: const InputDecoration(
              hintText: "Email Address",
              border: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF3F2F2)),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF3F2F2)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Password Field
          TextFormField(
            controller: _passwordController,
            obscureText: _obscureText,
            validator: _validatePassword,
            decoration: InputDecoration(
              hintText: "Password",
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF3F2F2)),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Color(0xFFF3F2F2)),
              ),
              suffixIcon: GestureDetector(
                onTap: () {
                  setState(() {
                    _obscureText = !_obscureText;
                  });
                },
                child: _obscureText
                    ? const Icon(Icons.visibility_off, color: Color(0xFF868686))
                    : const Icon(Icons.visibility, color: Color(0xFF868686)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Forget Password
          GestureDetector(
            onTap: () {
              // TODO: implement forgot password flow (OTP/email)
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Forgot password not implemented')),
              );
            },
            child: Text(
              "Forget Password?",
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 16),

          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _error!,
                style: const TextStyle(color: Colors.red),
              ),
            ),

          // Sign In Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF22A45D),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text("Sign in"),
            ),
          ),
        ],
      ),
    );
  }
}

class SocalButton extends StatelessWidget {
  final Color color;
  final String text;
  final Widget icon;
  final GestureTapCallback press;

  const SocalButton({
    super.key,
    required this.color,
    required this.icon,
    required this.press,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 8);
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: padding,
          backgroundColor: color,
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(8))),
        ),
        onPressed: press,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              height: 28,
              width: 28,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(4)),
              ),
              child: icon,
            ),
            const Spacer(flex: 2),
            Text(
              text.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .bodySmall!
                  .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
            ),
            const Spacer(flex: 3),
          ],
        ),
      ),
    );
  }
}

const String googleIcon =
    '''<svg version="1.1" id="Layer_1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" x="0px" y="0px"
     viewBox="0 0 512 512" style="enable-background:new 0 0 512 512;" xml:space="preserve">
 <path style="fill:#FBBB00;" d="M113.47,309.408L95.648,375.94l-65.139,1.378C11.042,341.211,0,299.9,0,256
     c0-42.451,10.324-82.483,28.624-117.732h0.014l57.992,10.632l25.404,57.644c-5.317,15.501-8.215,32.141-8.215,49.456
     C103.821,274.792,107.225,292.797,113.47,309.408z"/>
 <path style="fill:#518EF8;" d="M507.527,208.176C510.467,223.662,512,239.655,512,256c0,18.328-1.927,36.206-5.598,53.451
     c-12.462,58.683-45.025,109.925-90.134,146.187l-0.014-0.014l-73.044-3.727l-10.338-64.535
     c29.932-17.554,53.324-45.025,65.646-77.911h-136.89V208.176h138.887L507.527,208.176L507.527,208.176z"/>
 <path style="fill:#28B446;" d="M416.253,455.624l0.014,0.014C372.396,490.901,316.666,512,256,512
     c-97.491,0-182.252-54.491-225.491-134.681l82.961-67.91c21.619,57.698,77.278,98.771,142.53,98.771
     c28.047,0,54.323-7.582,76.87-20.818L416.253,455.624z"/>
 <path style="fill:#F14336;" d="M419.404,58.936l-82.933,67.896c-23.335-14.586-50.919-23.012-80.471-23.012
     c-66.729,0-123.429,42.957-143.965,102.724l-83.397-68.276h-0.014C71.23,56.123,157.06,0,256,0
     C318.115,0,375.068,22.126,419.404,58.936z"/>
 </svg>''';
