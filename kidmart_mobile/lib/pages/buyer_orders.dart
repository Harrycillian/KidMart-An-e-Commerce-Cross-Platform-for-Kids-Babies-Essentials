import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'buyer_cart.dart';
import '../config/constants.dart';

class BuyerOrders extends StatefulWidget {
  final int userId;
  final String initialStatus;

  const BuyerOrders({
    Key? key, 
    required this.userId,
    this.initialStatus = 'To Approve',
  }) : super(key: key);

  @override
  State<BuyerOrders> createState() => _BuyerOrdersState();
}

class _BuyerOrdersState extends State<BuyerOrders> {
  late String selectedStatus;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.initialStatus;
    _fetchOrders();
  }

  // fetch orders depending on selected status
  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });

      try {
      final url = '${ApiConstants.baseUrl}/mview-my-orders/${widget.userId}?status=${Uri.encodeComponent(selectedStatus)}';
      print('Attempting to fetch orders from URL: $url');
      print('User ID: ${widget.userId}');

        final response = await http.get(
        Uri.parse(url),
          headers: {
          'Accept': 'application/json',
            'Content-Type': 'application/json',
          'Accept-Encoding': 'gzip',
          'Connection': 'keep-alive',
          'Keep-Alive': 'timeout=120, max=1000',
          'Cache-Control': 'no-cache',
          'Pragma': 'no-cache',
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
          
          if (responseData != null && responseData.containsKey('orders')) {
            final List<dynamic> ordersData = responseData['orders'];
            print('Found ${ordersData.length} orders');
              setState(() {
              orders = List<Map<String, dynamic>>.from(ordersData);
                isLoading = false;
              error = null;
              });
            } else {
              setState(() {
                orders = [];
                isLoading = false;
              error = null;
              });
            }
          } catch (e) {
          print('Error parsing orders response: $e');
              setState(() {
            error = 'Error parsing server response: $e';
                isLoading = false;
              });
          }
        } else if (response.statusCode == 500) {
          print('Server error details: ${response.body}');
            setState(() {
              error = 'Server error. Please try again later.';
              isLoading = false;
            });
        } else {
          print('Server error: ${response.statusCode} - ${response.body}');
            setState(() {
              error = 'Error loading orders. Please try again.';
              isLoading = false;
            });
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

  // change display of orders
  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
    });
    _fetchOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFf5f5f5),
      appBar: AppBar(
        backgroundColor: Color(0xFF4B4BB5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Image.asset('assets/images/white_back.png', width: 40, height: 40),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Image.asset(
          'assets/images/LOGO.png',
          height: 55,
          width: 100,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(icon: Image.asset('assets/images/white_search.png', width: 30, height: 30),
            onPressed: () {},
            ),
          IconButton(icon: Image.asset('assets/images/white_cart.png',width: 30,height: 30),
            onPressed: () {
              Navigator.push(
                context,
              MaterialPageRoute(builder: (context) => CartPage(userId: widget.userId)),
              );
            },
          ),
          IconButton(icon: Image.asset('assets/images/white_message.png', width: 30, height: 30),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.zero,
            margin: EdgeInsets.zero,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildStatusButton('To Approve'),
                  _buildStatusButton('To Ship'),
                  _buildStatusButton('To Receive'),
                  _buildStatusButton('To Rate'),
                  _buildStatusButton('Completed'),
                  _buildStatusButton('Cancelled'),
                ],
              ),
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(child: Text(error!))
                    : orders.isEmpty
                        ? const Center(child: Text('No Orders Yet'))
                        : ListView.builder(
                            itemCount: orders.length,
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return _buildOrderCard(order);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  // status selection button
  Widget _buildStatusButton(String status) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: ElevatedButton(
        onPressed: () => _onStatusChanged(status),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(bottomLeft: Radius.circular(15), bottomRight: Radius.circular(15)),
          ),
          backgroundColor: isSelected ? Color(0xFFf5f5f5) : Color(0xFF7674DA),
          foregroundColor: isSelected ? Color(0xFF4B4BB5) : Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 23, vertical: 16),
        ),
        child: isSelected ? Text(status, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)) :
          Text(status, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      ),
    );
  }

  // structure of orders display
  Widget _buildOrderCard(Map<String, dynamic> order) {
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
                child: Row(
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
                              Text(
                                item['ptitle'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₱${item['price']}',
                                style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Arial',
                              ),
                            ),
                          ],
                        ),
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
                              'x ${item['quantity']}',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Color(0xFF222222),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Total: ₱${item['price'] * item['quantity']}',
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Status: ${order['parcel_loc']}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B4BB5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (order['status'] == 'To Approve')
                  ElevatedButton(
                    onPressed: () => _showCancelDialog(order['order_id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                    child: const Text('Cancel'),
                  )
                else if (order['status'] == 'To Receive')
                  ElevatedButton(
                    onPressed: order['parcel_loc'] == 'Parcel has been delivered.'
                        ? () => _confirmReceived(order['order_id'])
                        : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B4BB5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                    child: const Text('Order Received'),
                  )
                else if (order['status'] == 'To Rate')
                  ElevatedButton(
                    onPressed: () => _showRatingDialog(order['order_id']),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4B4BB5),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                    child: const Text('Rate'),
                  )
                else if (order['status'] == 'Completed' && order['feedback_rating'] != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber),
                      Text('${order['feedback_rating']}/5'),
                      TextButton(
                        onPressed: () => _viewRating(order['order_id']),
                        child: const Text('View Rating'),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCancelDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select a reason for cancellation:'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              items: [
                'Change of Mind',
                'Order Mistake',
                'Shipping Delay',
                'Incorrect Order Details',
                'Duplicate Order',
              ].map((reason) => DropdownMenuItem(
                value: reason,
                child: Text(reason),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  _cancelOrder(orderId, value);
                  Navigator.pop(context);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cancelOrder(int orderId, String reason) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mbcancel-order/$orderId/${widget.userId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order cancelled successfully')),
        );
        _fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to cancel order')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _confirmReceived(int orderId) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/morder-received/$orderId/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order marked as received')),
        );
        _fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to mark order as received')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _showRatingDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Order'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              items: [5, 4, 3, 2, 1].map((rating) => DropdownMenuItem(
                value: rating,
                child: Text('$rating - ${_getRatingText(rating)}'),
              )).toList(),
              onChanged: (value) {
                if (value != null) {
                  _submitRating(orderId, value);
                  Navigator.pop(context);
                }
              },
              decoration: const InputDecoration(
                labelText: 'Rating',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Review',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              onChanged: (value) {
                // Store review text
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 5:
        return 'Excellent';
      case 4:
        return 'Good';
      case 3:
        return 'Average';
      case 2:
        return 'Poor';
      case 1:
        return 'Terrible';
      default:
        return '';
    }
  }

  Future<void> _submitRating(int orderId, int rating) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/mrate-order'),
        body: {
          'order_id': orderId.toString(),
          'rating': rating.toString(),
          'review': 'Review text',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );
        _fetchOrders();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit rating')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _viewRating(int orderId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/mget-review/$orderId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Order Rating'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Rating: ${data['review']['feedback_rating']}/5'),
                  const SizedBox(height: 8),
                  Text('Review: ${data['review']['feedback_review']}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
} 