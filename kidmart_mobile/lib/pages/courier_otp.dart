import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'courier_reg.dart';
import '../config/constants.dart';

class CourierOTPPage extends StatefulWidget {
  @override
  State<CourierOTPPage> createState() => _CourierOTPPageState();
}

class _CourierOTPPageState extends State<CourierOTPPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController otpController = TextEditingController();
  bool isOtpSent = false;
  bool isOtpVerified = false;

  // send oTP to entered email
  Future<void> sendOtp() async {
    if (emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mcourier-send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': emailController.text}),
      );

      if (response.statusCode == 200) {
        setState(() {
          isOtpSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('OTP sent successfully! Check your email.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // verify if OTP is correct
  Future<void> verifyOtp() async {
    if (otpController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter the OTP')),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mcourier-verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': emailController.text,
          'otp': otpController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          isOtpVerified = true;
        });
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => CourierRegisterPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid OTP. Please try again.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    otpController.dispose();
    super.dispose();
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
                    const SizedBox(height: 30),
                    Center(
                      child: Text(
                        'Courier Registration',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(height: 80),
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
                              hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
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
                    const SizedBox(height: 25),
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
                        hintStyle: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Center(
                      child: SizedBox(
                        width: double.infinity,
                        height: 75,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF4B4BB5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          onPressed: verifyOtp,
                          child: Text(
                            'Confirm',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                        ),
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