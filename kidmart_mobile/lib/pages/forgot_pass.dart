import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/constants.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();
  
  bool isOtpSent = false;
  bool isOtpVerified = false;
  String? errorMessage;

  // send OTP to email
  Future<void> sendOtp() async {
    final email = emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        errorMessage = 'Please enter your email';
      });
      return;
    }

    try {
      print('Sending OTP request for email: $email');
      final url = Uri.parse('${ApiConstants.baseUrl}/mforgot-password/send-otp');
      print('Request URL: $url');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Connection': 'keep-alive',
        },
        body: jsonEncode({'email': email}),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          print('Request timed out');
          throw TimeoutException('Connection timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true;
          errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'OTP sent successfully')),
        );
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Failed to send OTP';
        });
      }
    } on TimeoutException {
      print('Timeout occurred');
      setState(() {
        errorMessage = 'Connection timed out. Please check if the server is running and try again.';
      });
    } on FormatException {
      print('Format exception occurred');
      setState(() {
        errorMessage = 'Invalid response from server';
      });
    } catch (e) {
      print('Error sending OTP: $e');
      setState(() {
        errorMessage = 'Network error occurred: ${e.toString()}';
      });
    }
  }

  // verify OTP is correct
  Future<void> verifyOtp() async {
    final email = emailController.text.trim();
    final otp = otpController.text.trim();
    
    if (otp.isEmpty) {
      setState(() {
        errorMessage = 'Please enter the OTP';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mforgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'new_password': newPasswordController.text,
          'confirm_password': confirmPasswordController.text,
        }),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        setState(() {
          isOtpVerified = true;
          errorMessage = null;
        });
        AlertDialog(
          title: Text(data['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Back to Login'),
            ),
          ],
        );
        Navigator.pop(context);
      } else {
        setState(() {
          errorMessage = data['error'] ?? 'Invalid OTP';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Network error occurred';
      });
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
                image: AssetImage('assets/images/reg_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: Image.asset('assets/images/prod_back.png', width: 45, height: 45),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'Reset Password',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 25),
                    Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            enabled: !isOtpSent,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25))),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                              hintText: 'Enter your email',
                              hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          height: 70,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B4BB5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.only(topRight: Radius.circular(15), bottomRight: Radius.circular(15)),
                              ),
                              padding: EdgeInsets.symmetric(horizontal: 18),
                            ),
                            onPressed: isOtpSent ? null : sendOtp,
                            child: Text(
                              'SEND\nCODE',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, fontFamily: 'Poppins'),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isOtpSent) ...[
                      const SizedBox(height: 18),
                      Text('OTP', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextField(
                        controller: otpController,
                        enabled: !isOtpVerified,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                          hintText: 'Enter the OTP sent to your email',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Text('New Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextField(
                        controller: newPasswordController,
                        enabled: !isOtpVerified,
                        obscureText: true,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                          hintText: '20 maximum characters',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('Confirm New Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      TextField(
                        controller: confirmPasswordController,
                        enabled: !isOtpVerified,
                        obscureText: true,
                        maxLength: 20,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(vertical: 24, horizontal: 35),
                          hintText: 'Make sure to match the new password',
                          hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Center(
                        child: SizedBox(
                          width: double.infinity,
                          height: 65,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF4B4BB5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            onPressed: verifyOtp,
                            child: Text(
                              'Reset Password',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                    if (errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          errorMessage!,
                          style: TextStyle(color: Colors.red, fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 32),
                    Center(
                      child: Image.asset(
                        'assets/images/kidmart_logo.png',
                        height: 60,
                        fit: BoxFit.fill,
                      ),
                    ),
                    const SizedBox(height: 24),
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