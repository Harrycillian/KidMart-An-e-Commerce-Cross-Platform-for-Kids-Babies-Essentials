import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:typed_data';
import 'buyer_prod.dart';
import 'buyer_cart.dart';
import 'buyer_notif.dart';
import 'buyer_profile.dart';
import '../config/constants.dart';

class HomePage extends StatefulWidget {
  final int userId;

  HomePage({required this.userId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Product> _products = [];
  bool _isLoading = true;
  String _error = '';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProducts(widget.userId);
  }

  // fetching product details from ddatabase
  Future<void> _loadProducts(int userId) async {
    int retryCount = 0;
    const maxRetries = 3;
    
    while (retryCount < maxRetries) {
      try {
        print('Starting to fetch products for user: $userId (Attempt ${retryCount + 1})');
        
        final client = http.Client();
        try {
          final response = await client.get(
            Uri.parse('${ApiConstants.baseUrl}/api/mbuyer_products/$userId'),
            headers: {
              'Accept': 'application/json',
              'Connection': 'keep-alive',
              'Keep-Alive': 'timeout=30, max=1000',
            },
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('The connection has timed out, Please try again!');
            },
          );

          print('Response received. Status code: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            print('Response decoded. Status: ${data['status']}');
            
            if (data['status'] == 'success' && data['products'] != null) {
              final productsList = data['products'] as List;
              print('Number of products received: ${productsList.length}');
              
              setState(() {
                _products = productsList.map((item) {
                  try {
                    return Product.fromJson(item);
                  } catch (e) {
                    print('Error parsing product: $e');
                    print('Problematic product data: $item');
                    return null;
                  }
                }).whereType<Product>().toList();
                _isLoading = false;
                _error = '';
              });
              print('Products loaded successfully. Count: ${_products.length}');
              return;
            } else {
              throw Exception('Invalid response format or no products data received');
            }
          } else {
            throw Exception('Failed to load products: ${response.statusCode}');
          }
        } finally {
          client.close();
        }
      } on TimeoutException {
        print('Timeout occurred while fetching products (Attempt ${retryCount + 1})');
        retryCount++;
        if (retryCount == maxRetries) {
          setState(() {
            _isLoading = false;
            _error = 'Connection timed out after $maxRetries attempts. Please check your internet connection and try again.';
          });
        } else {
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
      } on FormatException {
        print('Format error occurred while parsing response');
        setState(() {
          _isLoading = false;
          _error = 'Invalid data received from server. Please try again.';
        });
        break;
      } catch (e) {
        print('Error loading products: $e');
        print('Error type: ${e.runtimeType}');
        retryCount++;
        if (retryCount == maxRetries) {
          setState(() {
            _isLoading = false;
            _error = 'Error: ${e.toString()}';
          });
        } else {
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        }
      }
    }
  }

  // fetching proucts based on search hcaracters
  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _products = _products
          .where((product) =>
              product.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
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
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => NotificationsPage(userId: widget.userId)),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.userId)),
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
          Container(
            width: 175,
            height: 36,
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: TextField(
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: Icon(Icons.search, size: 20),
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: const Color(0xFFE0E0E0)),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                isDense: true,
              ),
              style: const TextStyle(fontSize: 15),
            ),
          ),
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
        backgroundColor: Color(0xFFF5F5F5),
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
        color: Colors.white,
        margin: EdgeInsets.zero,
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            Stack(
              children: [
                Image.asset(
                  'assets/images/babyee.png',
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
                Positioned(
                  left: 16,
                  top: 50,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Searching For', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
                      Text('Kiddie Essential', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C2C2C))),
                      Text("There's nothing like KidMart!", style: TextStyle(fontSize: 14, color: Color(0xFF2C2C2C))),
                    ],
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: RichText(
                  text: const TextSpan(
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
                    children: [
                      TextSpan(text: 'Shop For The Little Ones '),
                      TextSpan(text: 'With Love', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error.isNotEmpty
                    ? Center(child: Text('Error: $_error'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _products.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: _products[index],
                          userId: widget.userId,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }
}

// product card structure
class ProductCard extends StatelessWidget {
  final Product product;
  final int userId;

  const ProductCard({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Uint8List imageBytes = base64Decode(product.imageBase64);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailPage(product: product, userId: userId),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                child: Container(
                  width: double.infinity,
                  color: Colors.grey[100],
                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\u20B1${product.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Calibri',
                      fontSize: 16,
                      color: Color(0xFF4B4BB5)
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Product {
  final int id;
  final String name;
  final double price;
  final String imageBase64;
  final String description;
  final double rating;
  final int numSold;
  final List<Map<String, dynamic>> variations;
  final int sellerId;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.imageBase64,
    required this.description,
    required this.rating,
    required this.numSold,
    required this.variations,
    required this.sellerId,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    print('Parsing product: ${json['pid']}');
    List<Map<String, dynamic>> variationsList = [];
    if (json['variations'] != null) {
      try {
        variationsList = List<Map<String, dynamic>>.from(json['variations']);
      } catch (e) {
        print('Error parsing variations: $e');
        variationsList = [];
      }
    }
    
    return Product(
      id: json['pid'] ?? 0,
      name: json['ptitle'] ?? '',
      price: double.tryParse(json['pprice']?.toString() ?? '0') ?? 0.0,
      imageBase64: json['pimage'] ?? '',
      description: json['pdesc'] ?? '',
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      numSold: int.tryParse(json['num_sold']?.toString() ?? '0') ?? 0,
      variations: variationsList,
      sellerId: int.tryParse(json['seller_id']?.toString() ?? '0') ?? 0,
    );
  }
}

