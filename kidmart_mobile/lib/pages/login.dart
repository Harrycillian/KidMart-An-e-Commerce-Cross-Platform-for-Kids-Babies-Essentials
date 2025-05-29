import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'buyer_home.dart';
import 'register.dart';
import 'forgot_pass.dart';
import 'courier_otp.dart';
import 'courier_home.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  // return log in function
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true;
      });

      try {
        final response = await http.post(
          Uri.parse('${ApiConstants.baseUrl}/mlogin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': emailController.text,
            'password': passwordController.text,
          }),
        );

        final data = jsonDecode(response.body);
        
        if (response.statusCode == 200 && data['status'] == 'success') {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt('userId', data['user_id']);
          await prefs.setString('position', data['position']);

          // Navigate based on user position
          if (data['position'] == 'Buyer') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => HomePage(userId: data['user_id']),
              ),
            );
          } else if (data['position'] == 'Courier') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => CourierHomePage(userId: data['user_id']),
              ),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Login failed')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      } finally {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 90),
                    Center(child: Text('Log In', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w600))),
                    const SizedBox(height: 50),
                    Text('Email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    TextFormField(
                      controller: emailController,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!value.contains('@')) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 27, horizontal: 25),
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text('Password', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(vertical: 27, horizontal: 25),
                        errorStyle: TextStyle(color: Colors.red),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
                          );
                        },
                        child: Text('Forgot Password?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(height: 30),
                    Center(
                      child: Column(
                        children: [
                          if (isLoading)
                            CircularProgressIndicator()
                          else
                            ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                elevation: 0,
                                padding: EdgeInsets.zero,
                              ),
                              child: Image.asset('assets/images/login_btn.png'),
                            ),
                          const SizedBox(height: 30),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => CreateAccountPage(),
                                ),
                              );
                            },
                            child: Image.asset('assets/images/signup_btn.png'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 25),
                    Center(
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOTPPage()),
                          );
                        },
                        child: Text('Register as Courier', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4B4BB5), decoration: TextDecoration.underline)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
