import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:project56/authentication/signup/registerscreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../dashboard/dashboard_screen.dart';
import '../../others/mycolors.dart';
import '../header_auth.dart';
import '../widgets/brown_top_clipper.dart';
import '../widgets/gold_top_clipper.dart';
import '../widgets/lightgold_top_clipper.dart';

class LoginScreen extends StatefulWidget {
const LoginScreen({super.key});

@override
State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

var username = TextEditingController();
var password = TextEditingController();
var mobileno = TextEditingController();

bool _isObscurePassword = true;
late SharedPreferences sharedPreferences;
var newuser;

@override
void initState() {
super.initState();
checkValue();
}

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
/// 🎨 Background Design
ClipPath(
clipper: const GoldTopClipper(),
child: Container(color: kPrimary),
),
ClipPath(
clipper: const BrownTopClipper(),
child: Container(color: kPrimaryDark),
),
ClipPath(
clipper: const LightGoldTopClipper(),
child: Container(color: kPrimaryLight),
),

/// ✅ Scrollable Content (Fix overflow)
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
/// 🔥 Header with background (logo + tagline fix)
Padding(
padding: const EdgeInsets.symmetric(horizontal: kPaddingL),
child: Container(
padding: const EdgeInsets.all(kPaddingS2),
decoration: BoxDecoration(
color: kCardBg,
borderRadius: BorderRadius.circular(26),
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

/// 📥 Form Section
Padding(
padding: const EdgeInsets.all(kPaddingL),
child: Column(
crossAxisAlignment: CrossAxisAlignment.start,
children: [
SizedBox(height: space * 2),

Text(
'Login here using your username and password.',
style: Theme.of(context)
    .textTheme
    .bodyMedium!
    .copyWith(color: kTextSecondary),
),

SizedBox(height: space),

/// 👤 Username
TextField(
controller: username,
decoration: const InputDecoration(
hintText: 'Username',
prefixIcon: Icon(Icons.person),
),
),

SizedBox(height: space),

/// 🔒 Password
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
_isObscurePassword =
!_isObscurePassword;
});
},
),
),
),

SizedBox(height: space),

/// 📱 Mobile Number
TextField(
controller: mobileno,
keyboardType: TextInputType.phone,
decoration: const InputDecoration(
hintText: 'Mobile Number',
prefixIcon: Icon(Icons.phone),
),
),

SizedBox(height: space * 1.5),

/// 🔘 Login Button
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () {
checklogin();
},
child: const Text("Login to continue"),
),
),

SizedBox(height: space),

/// 🔁 Forgot Password
Center(
child: TextButton(
onPressed: () {},
child: Text(
"Forgot Password?",
style: Theme.of(context)
    .textTheme
    .bodyMedium!
    .copyWith(
color: kPrimary,
fontWeight: FontWeight.w600,
),
),
),
),

SizedBox(height: space),

/// 🆕 Create Account
SizedBox(
width: double.infinity,
child: ElevatedButton(
onPressed: () {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) =>
RegisterScreen(),
),
);
},
child: const Text("Create an Account"),
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

/// 🔐 LOGIN FUNCTION (UNCHANGED)
checklogin() async {
var url =
Uri.parse("https://prakrutitech.xyz/FlutterProject/login.php");

var response = await http.post(url, body: {
"mobileno": mobileno.text.toString(),
"password": password.text.toString()
});

var data = json.decode(response.body);

if (data == 0) {
ScaffoldMessenger.of(context)
    .showSnackBar(const SnackBar(content: Text("Login Fail")));
} else {
ScaffoldMessenger.of(context)
    .showSnackBar(const SnackBar(content: Text("Login Success")));

sharedPreferences.setBool('tops', false);
sharedPreferences.setString('mymob', mobileno.text.toString());

Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => DashboardScreen(),
),
);
}
}

/// 🔁 SESSION CHECK (UNCHANGED)
checkValue() async {
sharedPreferences = await SharedPreferences.getInstance();
newuser = sharedPreferences.getBool('tops') ?? true;

if (newuser == false) {
Navigator.pushReplacement(
context,
MaterialPageRoute(
builder: (context) => DashboardScreen(),
),
);
}
}
}

