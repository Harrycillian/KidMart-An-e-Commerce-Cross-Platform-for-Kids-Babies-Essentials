import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import '../config/constants.dart';
import 'delivered_orders.dart';

class CourierOrdersPage extends StatefulWidget {
  final int userId;
  const CourierOrdersPage({super.key, required this.userId});

  @override
  _CourierOrdersPageState createState() => _CourierOrdersPageState();
}

class _CourierOrdersPageState extends State<CourierOrdersPage> {
  String selectedStatus = 'To Receive';
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  // display orders assigned to the logged-in courier
  Future<void> fetchOrders() async {
    try {
      final url = '${ApiConstants.baseUrl}/mcourier-orders/${widget.userId}';
      print('Attempting to fetch orders from URL: $url');
      print('Courier ID: ${widget.userId}');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'Accept-Encoding': 'gzip',
        },
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Server connection timed out');
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      
      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> responseData = json.decode(response.body);
          print('Decoded response data successfully');
          
          if (responseData['status'] == 'success' && responseData.containsKey('orders')) {
            final List<dynamic> ordersData = responseData['orders'];
            print('Found ${ordersData.length} orders');
            
            final processedOrders = ordersData.map((order) {
              final Map<String, dynamic> processedOrder = Map<String, dynamic>.from(order);
              
              final Map<int, List<Map<String, dynamic>>> groupedItems = {};
              for (var item in order['items']) {
                final int productId = item['pid'];
                if (!groupedItems.containsKey(productId)) {
                  groupedItems[productId] = [];
                }
                groupedItems[productId]!.add(item);
              }
              
              final List<Map<String, dynamic>> combinedItems = [];
              groupedItems.forEach((productId, items) {
                if (items.length == 1) {
                  combinedItems.add(items[0]);
                } else {
                  final Map<String, dynamic> combinedItem = Map<String, dynamic>.from(items[0]);
                  
                  final Map<String, Map<String, dynamic>> uniqueVariations = {};
                  
                  for (var item in items) {
                    final String variationKey = item['variation'].toString();
                    if (!uniqueVariations.containsKey(variationKey)) {
                      uniqueVariations[variationKey] = {
                        'variation': item['variation'],
                        'quantity': item['quantity'],
                        'price': double.parse(item['price'].toString()),
                      };
                    } else {
                      uniqueVariations[variationKey]!['quantity'] = 
                          (uniqueVariations[variationKey]!['quantity'] as int) + (item['quantity'] as int);
                    }
                  }
                  
                  combinedItem['variations'] = uniqueVariations.values.toList();
                  
                  int totalQuantity = 0;
                  double totalPrice = 0;
                  for (var variation in uniqueVariations.values) {
                    totalQuantity += variation['quantity'] as int;
                    totalPrice += (variation['price'] as double) * (variation['quantity'] as int);
                  }
                  
                  combinedItem['quantity'] = totalQuantity;
                  combinedItem['total_price'] = totalPrice;
                  combinedItems.add(combinedItem);
                }
              });
              
              processedOrder['items'] = combinedItems;
              return processedOrder;
            }).toList();
            
            setState(() {
              orders = List<Map<String, dynamic>>.from(processedOrders);
              isLoading = false;
              error = null;
            });
          } else {
            setState(() {
              error = responseData['message'] ?? 'Invalid response format';
              isLoading = false;
            });
            print('Error: ${responseData['message']}');
          }
        } catch (e) {
          print('Error parsing orders response: $e');
          setState(() {
            error = 'Error parsing server response: $e';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'Failed to load orders: ${response.statusCode}\nURL: $url';
          isLoading = false;
        });
        print('Error: HTTP ${response.statusCode}');
      }
    } on TimeoutException {
      print('Request timed out');
      setState(() {
        error = 'Request timed out. Please check your internet connection and try again.';
        isLoading = false;
      });
    } catch (e) {
      print('Exception in fetchOrders: $e');
      setState(() {
        error = 'Error connecting to server: $e';
        isLoading = false;
      });
    }
  }

  // update of parcel status
  Future<void> updateParcelStatus(int orderId, String newStatus) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mcourier-update-status/$orderId'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'status': newStatus}),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Status updated successfully')),
          );
          fetchOrders();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to update status')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update status')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error connecting to server')),
      );
    }
  }

  Future<void> _showConfirmationDialog(int orderId, String newStatus) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Status Update'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('Are you sure you want to update the parcel status to:'),
                const SizedBox(height: 8),
                Text(
                  newStatus,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Confirm'),
              onPressed: () {
                Navigator.of(context).pop();
                updateParcelStatus(orderId, newStatus);
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildHomePage() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(child: Text(error!, style: const TextStyle(color: Colors.red)));
    }

    if (orders.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Orders',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            // TextField(
            //   controller: _searchController,
            //   decoration: InputDecoration(
            //     hintText: 'Search Order ID',
            //     prefixIcon: const Icon(Icons.search),
            //     border: OutlineInputBorder(
            //       borderRadius: BorderRadius.circular(8),
            //       borderSide: BorderSide.none,
            //     ),
            //     filled: true,
            //     fillColor: Colors.white,
            //   ),
            // ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Color(0xFF808080), width: 1),
                  ),
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
                              'Order ${order['order_id']}',
                              style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${order['order_datetime']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        ...order['items'].map<Widget>((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (item['pimage'] != null && item['pimage'].isNotEmpty)
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        color: Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Image.memory(
                                        base64Decode(item['pimage']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item['ptitle'],
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (item['variations'] != null)
                                          ...item['variations'].map<Widget>((variation) => Padding(
                                            padding: const EdgeInsets.only(top: 4),
                                            child: Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    'Variation: ${variation['variation']}',
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 13,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '₱${variation['price']} x ${variation['quantity']}',
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Color(0xFF222222),
                                                    fontWeight: FontWeight.w500,
                                                    fontFamily: 'Arial'
                                                  ),
                                                ),
                                              ],
                                            ),
                                          )).toList()
                                        else
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Variation: ${item['variation']}',
                                                style: TextStyle(
                                                  color: Colors.grey[600],
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Text(
                                                '₱${item['price']} x ${item['quantity']}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF222222),
                                                  fontWeight: FontWeight.w500,
                                                  fontFamily: 'Arial'
                                                ),
                                              ),
                                            ],
                                          ),
                                        const SizedBox(height: 10),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            'Total: ₱${(item['total_price'] ?? (double.parse(item['price'].toString()) * item['quantity'])).toStringAsFixed(2)}',
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF4B4BB5),
                                              fontFamily: 'Arial',
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )).toList(),
                        const Divider(height: 24),
                        const Text(
                          'Customer Details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Buyer Name:             ${order['buyer_name']}', style: const TextStyle(fontSize: 12, color: Colors.black),),
                        Text('Contact Number:   (+63) ${order['contact_number']}', style: const TextStyle(fontSize: 12, color: Colors.black),),
                        Text('Address:                   ${order['shipping_address']}', style: const TextStyle(fontSize: 12, color: Colors.black),),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SizedBox(
                              width: 340,
                              child: DropdownButtonFormField<String>(
                                value: order['parcel_loc'] ?? 'Select status',
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(25),
                                    borderSide: BorderSide(color: Color(0xFF4B4BB5)),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                style: const TextStyle(fontSize: 13, color: Color(0xFF3E3E97)),
                                items: [
                                  'Parcel has arrived at sorting facility.',
                                  'Parcel has departed from sorting facility.',
                                  'Parcel has arrived and to be received by the delivery hub.',
                                  'Your Parcel has arrived at the delivery hub.',
                                  'Delivery driver has been assigned.',
                                  'Parcel is out for delivery.',
                                  'Parcel has been delivered.',
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: SizedBox(
                                      width: 290,
                                      child: Text(
                                        value,
                                        style: const TextStyle(fontSize: 13, color: Color(0xFF3E3E97)),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 1,
                                        softWrap: false,
                                      ),
                                    ),
                                  );
                                }).toList(),
                                onChanged: (String? value) {
                                  if (value != null) {
                                    _showConfirmationDialog(order['order_id'], value);
                                  }
                                },
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DeliveredOrdersPage(userId: widget.userId),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF4B44B5),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'View Delivered Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _buildHomePage(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: Image.asset('assets/images/prod_back.png', width: 40, height: 40),
        onPressed: () => Navigator.pop(context),
      ),
      title: Image.asset(
        'assets/images/LOGO.png',
        height: 55,
        width: 110,
        fit: BoxFit.contain,
      ),
      centerTitle: true,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

class CourierOrder {
  final String productName;
  final String variation;
  final double price;
  final String image;
  final String buyerName;
  final String contactNumber;
  final String address;

  CourierOrder({
    required this.productName,
    required this.variation,
    required this.price,
    required this.image,
    required this.buyerName,
    required this.contactNumber,
    required this.address,
  });
}