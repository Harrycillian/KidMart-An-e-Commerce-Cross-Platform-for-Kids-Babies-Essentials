import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'buyer_cart.dart';
import 'buyer_home.dart';
import '../config/constants.dart';

void main() {
  runApp(const _CheckoutPage());
}

class _CheckoutPage extends StatelessWidget {
  const _CheckoutPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KidMart Checkout',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Roboto',
      ),
      home: const CheckoutPage(totalAmount: 196, selectedItems: [], userId: 0, orderIds: []),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CheckoutPage extends StatefulWidget {
  final int totalAmount;
  final List<CartItem> selectedItems;
  final int userId;
  final List<dynamic> orderIds;

  const CheckoutPage({
    Key? key, 
    required this.totalAmount,
    required this.selectedItems,
    required this.userId,
    required this.orderIds,
  }) : super(key: key);

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String deliveryMethod = 'Delivery';
  String paymentMethod = 'Cash on Delivery';
  bool _isLoading = true;
  String _error = '';
  late Dio _dio;
  Map<String, dynamic>? _addressData;
  Map<String, dynamic>? _orderData;
  int? _selectedAddressId;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _loadData();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));
  }

  // load checked-out items
  Future<void> _loadData() async {
    try {
      final orderIds = widget.orderIds.map((id) => id.toString()).toList();
      print('Fetching checkout data for user: ${widget.userId}');
      print('Order IDs: $orderIds');
      
      final response = await _dio.get(
        '/mcheckout_page/${widget.userId}',
        queryParameters: {
          'order_id': orderIds,
        },
        options: Options(
          validateStatus: (status) => true,
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Response status: ${response.statusCode}');
      print('Response data: ${response.data}');

      if (response.statusCode == 200) {
        final data = response.data;
        print('Order items: ${data['all_order_items']}');
        print('Number of order items: ${(data['all_order_items'] as List).length}');
        
        setState(() {
          _addressData = data;
          _isLoading = false;
        });
      } else {
        print('Error response: ${response.data}');
        setState(() {
          _addressData = {
            'user_infos': [],
            'merchandise_total': widget.totalAmount,
            'combined_shipping_fee': 40,
            'grand_total': widget.totalAmount + 40,
            'all_order_items': [],
          };
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        _addressData = {
          'user_infos': [],
          'merchandise_total': widget.totalAmount,
          'combined_shipping_fee': 40,
          'grand_total': widget.totalAmount + 40,
          'all_order_items': [],
        };
        _isLoading = false;
      });
    }
  }

  // function for placing/confirming order
  Future<void> _placeOrder() async {
    try {
      if (_selectedAddressId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a delivery address')),
        );
        return;
      }

      setState(() => _isLoading = true);

      final orderIds = widget.orderIds.map((id) => id.toString()).toList();
      final cartIds = _addressData?['all_order_items']?.map((item) => item['cid'].toString()).toList() ?? [];
      final vidddValues = _addressData?['all_order_items']?.map((item) => item['vid'].toString()).toList() ?? [];
      final quantities = _addressData?['all_order_items']?.map((item) => item['quantity'].toString()).toList() ?? [];

      final formData = FormData.fromMap({
        'order_ids': orderIds.join(','),
        'selected_address': _selectedAddressId.toString(),
        'payment': paymentMethod,
        'shipping_method': deliveryMethod,
        'user_id': widget.userId.toString(),
        'cart_ids': cartIds,
        'viddd': vidddValues,
        'quantity': quantities,
      });

      print('Placing order with data: ${formData.fields}');

      final response = await _dio.post(
        '/mplace_order',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Place order response: ${response.data}');

      if (response.statusCode == 200) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => HomePage(userId: widget.userId),
            ),
            (route) => false,
          );
          WidgetsBinding.instance.addPostFrameCallback((_) {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Order Successful'),
                content: const Text('Your order has been placed successfully!'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                ],
              ),
            );
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Failed to place order')),
          );
        }
      }
    } catch (e) {
      print('Error placing order: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to place order. Please try again.')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty) {
      return Scaffold(
        body: Center(child: Text(_error)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0xFF4B4BB5),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/images/logoo.png',
          height: 48,
          width: 96,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Address',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_addressData != null && _addressData!['user_infos'] != null && (_addressData!['user_infos'] as List).isNotEmpty)
                ...(_addressData!['user_infos'] as List).asMap().entries.map((entry) {
                  final index = entry.key;
                  final userInfo = entry.value as Map<String, dynamic>;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4B4BB5),
                        width: 1,
                      ),
                    ),
                    child: RadioListTile(
                      value: userInfo['add_id'],
                      groupValue: _selectedAddressId,
                      onChanged: (value) {
                        setState(() {
                          _selectedAddressId = value as int;
                        });
                      },
                      activeColor: const Color(0xFF4B4BB5),
                      title: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                userInfo['add_name']?.toString() ?? 'No name provided',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                "(+63)${userInfo['add_num']?.toString() ?? 'No number provided'}",
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'Arial',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${userInfo['brgy'] ?? ''}, ${userInfo['city'] ?? ''}, ${userInfo['province'] ?? ''}, ${userInfo['region'] ?? ''}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  );
                }).toList()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No address yet.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 24),

              const Text(
                'Shipment',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile(
                      title: const Text('Delivery'),
                      value: 'Delivery',
                      groupValue: deliveryMethod,
                      onChanged: (value) {
                        setState(() {
                          deliveryMethod = value.toString();
                        });
                      },
                    ),
                    RadioListTile(
                      title: const Text('Pick-up'),
                      value: 'Pick-up',
                      groupValue: deliveryMethod,
                      onChanged: null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Payment Method',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: paymentMethod,
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: 'Cash on Delivery',
                        child: Text('Cash on Delivery'),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Credit Card',
                        enabled: false,
                        child: Text(
                          'Credit Card (Coming Soon)',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      DropdownMenuItem<String>(
                        value: 'Bank Transfer',
                        enabled: false,
                        child: Text(
                          'Bank Transfer (Coming Soon)',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          paymentMethod = newValue;
                        });
                      }
                    },
                  ),
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Order Items',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (_addressData != null && _addressData!['all_order_items'] != null && (_addressData!['all_order_items'] as List).isNotEmpty)
                ...(_addressData!['all_order_items'] as List).map((item) {
                  print('Processing item: $item');
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: item['image'] != null && item['image'].toString().isNotEmpty
                              ? Image.memory(
                                  base64Decode(item['image']),
                                  fit: BoxFit.cover,
                                )
                              : const Icon(Icons.image_not_supported),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item['ptitle']?.toString() ?? 'No title',
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  fontFamily: 'Arial',
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['variation']?.toString() ?? 'No variation',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  fontFamily: 'Arial',
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '\u20B1${item['price']?.toString() ?? '0.00'}',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Arial',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'x${item['quantity']?.toString() ?? '0'}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                fontFamily: 'Arial',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList()
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(
                    child: Text(
                      'No items in order.',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                        fontFamily: 'Arial',
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Merchandise Subtotal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text('\u20B1${_addressData?['merchandise_total'] ?? widget.totalAmount}', style: TextStyle(fontFamily: 'Arial'),),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Shipping Subtotal',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Text('\u20B1${_addressData?['combined_shipping_fee'] ?? '40'}', style: TextStyle(fontFamily: 'Arial'),),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\u20B1${_addressData?['grand_total'] ?? (widget.totalAmount + 40)}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4B4BB5),
                            fontFamily: 'Arial',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4B4BB5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Place Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}