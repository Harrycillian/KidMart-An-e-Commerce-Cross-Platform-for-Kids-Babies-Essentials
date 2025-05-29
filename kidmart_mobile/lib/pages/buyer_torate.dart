import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'buyer_cart.dart';
import '../config/constants.dart';
import 'buyer_toship.dart';
import 'buyer_toreceive.dart';
import 'buyer_toapprove.dart';
import 'buyer_completed.dart';
import 'buyer_cancelled.dart';
import 'buyer_profile.dart';

class ToRateOrders extends StatefulWidget {
  final int userId;

  const ToRateOrders({
    Key? key, 
    required this.userId,
  }) : super(key: key);

  @override
  State<ToRateOrders> createState() => _ToRateOrdersState();
}

class _ToRateOrdersState extends State<ToRateOrders> {
  late String selectedStatus;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;
  String? error;
  String? _selectedRating;
  String _reviewText = '';

  @override
  void initState() {
    super.initState();
    selectedStatus = 'To Rate';
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
      error = null;
    });

    int retryCount = 0;
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);

    while (retryCount < maxRetries) {
      try {
        final client = http.Client();
        try {
          final response = await client.get(
            Uri.parse('${ApiConstants.baseUrl}/mview-to-rate-orders/${widget.userId}'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'Connection': 'keep-alive',
              'Keep-Alive': 'timeout=60, max=1000',
            },
          ).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException('The connection has timed out, please try again!');
            },
          );

          print('Response status: ${response.statusCode}');
          
          if (response.statusCode == 200) {
            try {
              final data = jsonDecode(response.body);
              if (data != null && data['orders'] != null) {
                setState(() {
                  orders = List<Map<String, dynamic>>.from(data['orders']);
                  isLoading = false;
                });
                return;
              } else {
                setState(() {
                  orders = [];
                  isLoading = false;
                });
                return;
              }
            } catch (e) {
              print('Error parsing response: $e');
              if (retryCount == maxRetries - 1) {
                setState(() {
                  error = 'Invalid response from server';
                  isLoading = false;
                });
              }
            }
          } else if (response.statusCode == 500) {
            print('Server error details: ${response.body}');
            if (retryCount == maxRetries - 1) {
              setState(() {
                error = 'Server error. Please try again later.';
                isLoading = false;
              });
            }
          } else {
            print('Server error: ${response.statusCode} - ${response.body}');
            if (retryCount == maxRetries - 1) {
              setState(() {
                error = 'Error loading orders. Please try again.';
                isLoading = false;
              });
            }
          }
        } finally {
          client.close();
        }
      } catch (e) {
        print('Error fetching orders (attempt ${retryCount + 1}): $e');
        if (retryCount == maxRetries - 1) {
          setState(() {
            error = 'Network error. Please check your connection and try again.';
            isLoading = false;
          });
        }
      }

      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(retryDelay * retryCount);
      }
    }
  }

  void _onStatusChanged(String status) {
    setState(() {
      selectedStatus = status;
    });
    _fetchOrders();
  }

  void _navigateToStatusPage(String status) {
    switch (status) {
      case 'To Approve':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToApproveOrders(userId: widget.userId),
          ),
        );
        break;
      case 'To Ship':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToShipOrders(userId: widget.userId),
          ),
        );
        break;
      case 'To Receive':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ToReceiveOrders(userId: widget.userId),
          ),
        );
        break;
      case 'To Rate':
        
        break;
      case 'Completed':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CompletedOrders(userId: widget.userId),
          ),
        );
        break;
      case 'Cancelled':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CancelledOrders(userId: widget.userId),
          ),
        );
        break;
    }
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
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage(userId: widget.userId)),
            );
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

  Widget _buildStatusButton(String status) {
    final isSelected = selectedStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 2),
      child: ElevatedButton(
        onPressed: () {
          _onStatusChanged(status);
          _navigateToStatusPage(status);
        },
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

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final Map<String, Map<String, dynamic>> groupedItems = {};
    
    for (var item in order['items']) {
      final key = '${item['pid']}_${item['variation']}';
      if (!groupedItems.containsKey(key)) {
        groupedItems[key] = Map<String, dynamic>.from(item);
      }
    }

    return Card(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Color(0xFF808080), width: 1),
      ),
      elevation: 0,
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            ...groupedItems.values.map<Widget>((item) => _buildOrderItem(item)),
            const Divider(),

            _buildInfoSection(
              'Ship To',
              [
                'Buyer Name: ${order['buyer_name']}',
                'Contact: (+63) ${order['contact_number']}',
                'Address: ${order['shipping_address']}',
              ],
            ),

            _buildInfoSection(
              'Shipping Details',
              [
                'Purchase Date: ${order['order_datetime'] ?? 'N/A'}',
                'Shipment Date: ${order['order_ship_datetime'] ?? 'N/A'}',
                'Delivered: ${order['order_delivered_datetime'] ?? 'N/A'}',
              ],
            ),

            _buildOrderSummary(order),
            _buildActionButtons(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Map<String, dynamic> item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (item['pimage'] != null)
            Image.memory(
              base64Decode(item['pimage']),
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            )
          else
            const SizedBox(
              width: 80,
              height: 80,
              child: Icon(Icons.image_not_supported),
            ),
          const SizedBox(width: 16),
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
                    'Total: ₱${(double.parse(item['price'].toString()) * item['quantity']).toStringAsFixed(2)}',
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
    );
  }

  Widget _buildInfoSection(String title, List<String> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...details.map((detail) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(detail),
            )),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOrderSummary(Map<String, dynamic> order) {
    // Convert string values to doubles for calculations
    final orderTotal = double.parse(order['order_total'].toString());
    final shippingFee = double.parse(order['shipping_fee'].toString());
    final merchandiseTotal = orderTotal - shippingFee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Order Summary',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text('Order ID: ${order['order_id']}'),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Merchandise Subtotal'),
            Text('₱${merchandiseTotal.toStringAsFixed(2)}'),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Shipping Subtotal'),
            Text('₱${shippingFee.toStringAsFixed(2)}'),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Payment',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '₱${orderTotal.toStringAsFixed(2)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Status: ${order['parcel_loc']}'),
          if (order['status'] == 'To Approve')
            ElevatedButton(
              onPressed: () => _showCancelDialog(order['order_id']),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Cancel'),
            )
          else if (order['status'] == 'To Receive')
            ElevatedButton(
              onPressed: order['parcel_loc'] == 'Parcel has been delivered.'
                  ? () => _confirmReceived(order['order_id'])
                  : null,
              child: const Text('Order Received'),
            )
          else if (order['status'] == 'To Rate')
            ElevatedButton(
              onPressed: () => _showRatingDialog(order['order_id']),
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
                  Navigator.pop(context);
                  _showCancelConfirmationDialog(orderId, value);
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

  void _showCancelConfirmationDialog(int orderId, String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Cancellation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to cancel this order?',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              'Reason: $reason',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showCancelDialog(orderId);
            },
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrder(orderId, reason);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
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
                  setState(() {
                    _selectedRating = value.toString();
                  });
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
                setState(() {
                  _reviewText = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_selectedRating != null) {
                Navigator.pop(context);
                _showConfirmationDialog(orderId);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select a rating')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B4BB5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  void _showConfirmationDialog(int orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rating'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '$_selectedRating/5 - ${_getRatingText(int.parse(_selectedRating!))}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_reviewText.isNotEmpty) ...[
              const Text(
                'Your Review:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _reviewText,
                style: const TextStyle(fontSize: 14),
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to submit this rating?',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRatingDialog(orderId);
            },
            child: const Text('Edit'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _submitRating(orderId, int.parse(_selectedRating!));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF4B4BB5),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm'),
          ),
        ],
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
          'review': _reviewText,
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
    // Find the order with the matching ID
    final order = orders.firstWhere(
      (order) => order['order_id'] == orderId,
      orElse: () => <String, dynamic>{},
    );

    if (order.isNotEmpty && order['feedback_rating'] != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Order Rating'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  Text(
                    '${order['feedback_rating']}/5',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (order['feedback_review'] != null && order['feedback_review'].toString().isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Review:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      order['feedback_review'],
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rating found for this order')),
      );
    }
  }
} 