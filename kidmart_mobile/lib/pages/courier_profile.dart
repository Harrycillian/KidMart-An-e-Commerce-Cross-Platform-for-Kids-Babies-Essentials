import 'package:flutter/material.dart';
import 'courier_home.dart';
import 'courier_notifs.dart';
import 'login.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/constants.dart';
import 'courier_orders.dart';

class CourierProfilePage extends StatefulWidget {
  final int userId;
  const CourierProfilePage({super.key, required this.userId});

  @override
  _CourierProfilePageState createState() => _CourierProfilePageState();
}

class _CourierProfilePageState extends State<CourierProfilePage> {
  int _selectedIndex = 2;
  String courierName = '';
  String courierId = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCourierProfile();
  }

  // courier details
  Future<void> fetchCourierProfile() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/mcourier-profile/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            courierName = data['profile']['name'];
            courierId = data['profile']['courier_id'].toString();
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching courier profile: $e');
      setState(() {
        isLoading = false;
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
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CourierProfilePage(userId: widget.userId)),
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
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Image.asset(
              'assets/images/LOGO.png',
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(icon: Image.asset('assets/images/home.png',width: 35, height: 35), label: 'Home'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/notifs.png', width: 35, height: 35), label: 'Notifications'),
          BottomNavigationBarItem(icon: Image.asset('assets/images/blue_user.png', width: 35, height: 35), label: 'Profile'),
        ],
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins', color: Color(0xFF4B4BB5)),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontFamily: 'Poppins'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                const Center(
                  child: Text(
                    "My Deliveries",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0xFF888888)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _OrderStatusButton(
                        icon: Icons.assignment_turned_in,
                        label: "To Pick Up",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOrdersPage(userId: widget.userId)),
                          );
                        },
                      ),
                      _OrderStatusButton(
                        icon: Icons.local_shipping,
                        label: "In Transit",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOrdersPage(userId: widget.userId)),
                          );
                        },
                      ),
                      _OrderStatusButton(
                        icon: Icons.check_circle_outline,
                        label: "Delivered",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => CourierOrdersPage(userId: widget.userId)),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // mock data

                // const SizedBox(height: 32),
                // const Center(
                //   child: Text(
                //     "My Routes",
                //     style: TextStyle(
                //       fontSize: 22,
                //       fontWeight: FontWeight.w500,
                //     ),
                //   ),
                // ),
                // const SizedBox(height: 18),
                // _AddressCard(
                //   name: "Route 1",
                //   phone: "Bay - Sta. Cruz",
                //   address: "Pick up: 123 Main St, Bay\nDrop off: 456 Rizal Ave, Sta. Cruz",
                // ),
                // const SizedBox(height: 10),
                // _AddressCard(
                //   name: "Route 2",
                //   phone: "Pila - Lumban",
                //   address: "Pick up: 789 Pila Blvd, Pila\nDrop off: 321 Lumban Rd, Lumban",
                // ),
                // const SizedBox(height: 10),
                // _AddressCard(
                //   name: "Route 3",
                //   phone: "Calauan - Victoria",
                //   address: "Pick up: 654 Calauan St, Calauan\nDrop off: 987 Victoria Ave, Victoria",
                // ),
                const SizedBox(height: 80),
                const Center(
                  child: Text(
                    "Courier Profile",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    courierName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    "Courier ID: $courierId",
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () async {
                        final shouldLogout = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Log Out'),
                            content: const Text('Are you sure you want to log out?'),
                            actions: [                            
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Yes'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('No'),
                              ),
                            ],
                          ),
                        );
                        if (shouldLogout == true) {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => LoginPage()),
                            (Route<dynamic> route) => false,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        backgroundColor: const Color(0xFFFFC4CC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: Text(
                        'Log Out',
                        style: TextStyle(
                          color: Colors.red[400],
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderStatusButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _OrderStatusButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 60, color: Color(0xFF4b44b5)),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: Color(0xFF4b44b5)),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final String name;
  final String phone;
  final String address;

  const _AddressCard({
    required this.name,
    required this.phone,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFF888888)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                phone,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            address,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
    
  }
}