import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'buyer_cart.dart';
import 'buyer_home.dart';
import 'buyer_profile.dart';
import '../config/constants.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  final int userId;
  NotificationsPage({required this.userId});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  int _selectedIndex = 1;
  bool _isLoading = true;
  String _error = '';
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  // fetching of notifs for certain user id
  Future<void> _fetchNotifications() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/api/mnotifications/${widget.userId}'),
        headers: {'Accept': 'application/json'},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _notifications = data['notifications'] ?? [];
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = data['message'] ?? 'Failed to load notifications.';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load notifications. (${response.statusCode})';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  // footer buttons
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userId: widget.userId)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.userId)),
      );
    }
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage(userId: widget.userId)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Image.asset(
          'assets/images/LOGO.png',
          height: 55,
          width: 100,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(icon: Image.asset('assets/images/cart.png',width: 30,height: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CartPage(userId: widget.userId)),
              );
            },
          ),
          IconButton(icon: Image.asset('assets/images/message.png', width: 30, height: 30),
            onPressed: () {},
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Image.asset('assets/images/home.png',width: 35, height: 35), label: 'Home'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/blue_notif.png', width: 35, height: 35), label: 'Notifications'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/profile.png', width: 35, height: 35), label: 'Profile'),
        ],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF4B4BB5)),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : _notifications.isEmpty
                  ? const Center(child: Text('No notifications yet.'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _notifications.length,
                      itemBuilder: (context, index) {
                        final notification = _notifications[index];
                        return Card(
                          elevation: 0,
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      notification['bnotif_title'] ?? '',
                                      style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4B4BB5),
                                  ),
                                ),
                                if (notification['notif_datetime'] != null)
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6.0),
                                        child: Text(
                                          () {
                                            String rawDate = (notification['notif_datetime'] as String).replaceAll('GMT', '').trim();
                                            DateTime parsedDate = DateFormat('EEE, dd MMM yyyy HH:mm:ss').parse(rawDate);
                                            return DateFormat('MM/dd HH:mm').format(parsedDate);
                                          }(),
                                          style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                                        ),
                                      ),
                                    ],
                                  ),
                                ]
                              ),
                              const SizedBox(height: 4),
                              Text(
                                notification['bnotif_text'] ?? '',
                                textAlign: TextAlign.justify,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                  
                                ),
                              ),
                            ],
                          ),  
                        ),
                      );
                    },
                  ),
    );
  }
}

class NotificationItem {
  final String title;
  final String description;

  NotificationItem({required this.title, required this.description});
}