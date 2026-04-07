import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project56/authentication/signin/loginscreen.dart';

import '../../others/mycolors.dart';
import '../header_auth.dart';
import '../widgets/brown_top_clipper.dart';
import '../widgets/gold_top_clipper.dart';
import '../widgets/lightgold_top_clipper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  var username = TextEditingController();
  var password = TextEditingController();
  var mobileno = TextEditingController();
  var confirmpassword = TextEditingController();
  bool _isObscurePassword = true;

  @override
  Widget build(BuildContext context) {
    final height =
        MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top;
    final space = height > 650 ? kSpaceM : kSpaceS;

    return Scaffold(
      key: scaffoldKey,
      backgroundColor: kScaffoldBg,
      body: Stack(
        children: [
          ClipPath(clipper: const GoldTopClipper(), child: Container(color: kPrimary)),
          ClipPath(clipper: const BrownTopClipper(), child: Container(color: kPrimaryDark)),
          ClipPath(clipper: const LightGoldTopClipper(), child: Container(color: kPrimaryLight)),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: kPaddingL),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      // 🔥 Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: kPaddingL),
                        child: Container(
                          padding: const EdgeInsets.all(kPaddingM),
                          decoration: BoxDecoration(
                            color: kCardBg,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Header(),
                        ),
                      ),

                      // 📥 Form
                      Padding(
                        padding: const EdgeInsets.all(kPaddingL),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: space * 2),
                            Text(
                              'Register here using your username and password.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium!
                                  .copyWith(color: kTextSecondary),
                            ),
                            SizedBox(height: space),

                            // 👤 Username
                            TextField(
                              controller: username,
                              decoration: const InputDecoration(
                                hintText: 'Username',
                                prefixIcon: Icon(Icons.person),
                              ),
                            ),
                            SizedBox(height: space),

                            // 🔒 Password
                            TextField(
                              controller: password,
                              obscureText: _isObscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscurePassword = !_isObscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: space),

                            // 🔒 Confirm Password
                            TextField(
                              controller: confirmpassword,
                              obscureText: _isObscurePassword,
                              decoration: InputDecoration(
                                hintText: 'Confirm Password',
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isObscurePassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isObscurePassword = !_isObscurePassword;
                                    });
                                  },
                                ),
                              ),
                            ),
                            SizedBox(height: space),

                            // 📱 Mobile Number
                            TextField(
                              controller: mobileno,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                hintText: 'Mobile Number',
                                prefixIcon: Icon(Icons.phone),
                              ),
                            ),
                            SizedBox(height: space * 1.5),

                            // 🔘 Register Button
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (password.text == confirmpassword.text) {
                                    registerUser();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "Password and confirm password must be same"),
                                      ),
                                    );
                                  }
                                },
                                child: const Text("Register to continue"),
                              ),
                            ),
                            SizedBox(height: space),

                            // 🔁 Already have account
                            SizedBox(
                              width: double.infinity,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  backgroundColor: kScaffoldBg,
                                  padding: const EdgeInsets.all(kPaddingS + 5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => const LoginScreen()),
                                  );
                                },
                                child: Text(
                                  "Alreadyy have an account?",
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium!
                                      .copyWith(
                                    color: kPrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void registerUser() async {
    var url = "https://prakrutitech.xyz/FlutterProject/signup.php";
    await http.post(Uri.parse(url), body: {
      "username": username.text,
      "password": password.text,
      "mobileno": mobileno.text,
      "identifier": "User"
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Registered Successfully!')));

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (context) => const LoginScreen()));
  }
}