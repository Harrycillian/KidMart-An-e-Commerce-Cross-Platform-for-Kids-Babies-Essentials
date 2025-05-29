import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'courier_orders.dart';
import 'courier_notifs.dart';
import 'courier_profile.dart';
import '../config/constants.dart';

class CourierHomePage extends StatefulWidget {
  final int userId;
  const CourierHomePage({super.key, required this.userId});

  @override
  _CourierHomePageState createState() => _CourierHomePageState();
}

class _CourierHomePageState extends State<CourierHomePage> {
  int _selectedIndex = 0;
  Map<String, dynamic> _stats = {
    'total_deliveries': '0',
    'pending_deliveries': '0'
  };
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  // dashboard statistics
  Future<void> _fetchStats() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/mcourier-stats/${widget.userId}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            _stats = {
              'total_deliveries': data['stats']['total_deliveries'].toString(),
              'pending_deliveries': data['stats']['pending_deliveries'].toString()
            };
            _isLoading = false;
          });
        } else {
          setState(() {
            _error = 'Failed to load stats';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _error = 'Failed to load stats';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error: $e';
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
        MaterialPageRoute(builder: (context) => CourierHomePage(userId: widget.userId)),
      );
    }
    else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage(userId: widget.userId)),
      );
    }
    else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CourierProfilePage(userId: widget.userId)),
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
          width: 110,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ), 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Image.asset('assets/images/blue_home.png',width: 35, height: 35), label: 'Home',
          ),
          BottomNavigationBarItem(icon: Image.asset('assets/images/notifs.png', width: 35, height: 35), label: 'Notifications',
          ),
          BottomNavigationBarItem(icon: Image.asset( 'assets/images/profile.png', width: 35, height: 35), label: 'Profile',
          ),
        ],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF4B4BB5)),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      body: Container(
        color: const Color(0xFFF7F7F7),
        width: double.infinity,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 35),
              Text(
                "Welcome, Courier!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2C2C2C),
                ),
              ),
              const SizedBox(height: 30),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_error != null)
                      Center(child: Text(_error!, style: TextStyle(color: Colors.red)))
                    else ...[
                      _CourierStatCard(
                        value: _stats['total_deliveries'] ?? "0",
                        label: "Total Deliveries Today",
                        color: Color(0xFF4B4BB5),
                        onTap: null,
                      ),
                      const SizedBox(height: 18),
                      _CourierStatCard(
                        value: _stats['pending_deliveries'] ?? "0",
                        label: "Pending Deliveries",
                        color: Color(0xFF8D8DE2),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOrdersPage(userId: widget.userId)),
                          );
                        },
                        actionLabel: "Tap to proceed",
                      ),
                      const SizedBox(height: 18),
                      _CourierOrderCard(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOrdersPage(userId: widget.userId)),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourierStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final String? actionLabel;

  const _CourierStatCard({
    required this.value,
    required this.label,
    required this.color,
    this.onTap,
    this.actionLabel,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: Colors.white70,
                    thickness: 1.5,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  actionLabel!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

class _CourierOrderCard extends StatelessWidget {
  final VoidCallback? onTap;

  const _CourierOrderCard({this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFA4A4CF),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset('assets/images/white_box.png', width: 40, height: 40),
                const SizedBox(width: 10),
                Text(
                  "Orders",
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: Colors.white70,
                  thickness: 1.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                "Tap to view all",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
            ],
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}