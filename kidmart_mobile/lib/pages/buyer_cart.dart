import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'buyer_checkout.dart';
import '../config/constants.dart';

class CartPage extends StatefulWidget {
  final int userId;
  
  const CartPage({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<CartItem> cartItems = [];
  bool selectAll = false;
  bool _isLoading = true;
  String _error = '';
  late Dio _dio;

  @override
  void initState() {
    super.initState();
    _setupDio();
    _loadCartItems();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: '${ApiConstants.baseUrl}',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    ));
  }

  // population of cart items
  Future<void> _loadCartItems() async {
    try {
      print('Loading cart items for user ID: ${widget.userId}');
      final response = await _dio.get(
        '/mshopping-cart',
        queryParameters: {'user_id': widget.userId},
        options: Options(
          validateStatus: (status) => status! < 500,
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
        if (data['status'] == 'success' && data['data'] != null) {
          final cartData = data['data']['cart_items'] as List;
          setState(() {
            cartItems = cartData.map((item) => CartItem.fromJson(item)).toList();
            _isLoading = false;
          });
          print('Loaded ${cartItems.length} cart items');
        } else {
          print('Error in response data: $data');
          setState(() {
            _error = data['message'] ?? 'Failed to load cart items';
            _isLoading = false;
          });
        }
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error response: ${response.data}');
        setState(() {
          _error = 'Server error: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } on DioException catch (e) {
      print('Dio error: ${e.type} - ${e.message}');
      print('Error response: ${e.response?.data}');
      setState(() {
        _error = 'Failed to load cart items. Please try again.';
        _isLoading = false;
      });
    } catch (e) {
      print('Unexpected error: $e');
      setState(() {
        _error = 'An unexpected error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  // fselect all button
  void toggleSelectAll() {
    setState(() {
      selectAll = !selectAll;
      for (var item in cartItems) {
        item.isSelected = selectAll;
      }
    });
  }

  // select checkbox function
  void toggleSelectItem(int index) {
    setState(() {
      cartItems[index].isSelected = !cartItems[index].isSelected;
      selectAll = cartItems.every((item) => item.isSelected);
    });
  }

  // remove selected items from cart
  Future<void> removeSelectedItems() async {
    try {
      final selectedItems = cartItems.where((item) => item.isSelected).toList();
      if (selectedItems.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select items to remove')),
        );
        return;
      }

      final response = await _dio.post(
        '/mremove-selected-from-cart',
        queryParameters: {'user_id': widget.userId},
        data: {
          'product_ids': selectedItems.map((item) => item.cartId).toList(),
        },
      );

      if (response.data['success'] == true) {
        await _loadCartItems(); 
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Selected items removed successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['error'] ?? 'Failed to remove items')),
          );
        }
      }
    } catch (e) {
      print('Error removing items: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove items. Please try again.')),
        );
      }
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    try {
      final item = cartItems[index];
      await _dio.put(
        '/mupdate-cart-quantity',
        data: {
          'cart_id': item.cartId,
          'quantity': newQuantity,
          'user_id': widget.userId,
        },
      );
      await _loadCartItems();
    } catch (e) {
      print('Error updating quantity: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update quantity. Please try again.')),
      );
    }
  }

  void increaseQuantity(int index) {
    final newQuantity = cartItems[index].quantity + 1;
    updateQuantity(index, newQuantity);
  }

  void decreaseQuantity(int index) {
    if (cartItems[index].quantity > 1) {
      final newQuantity = cartItems[index].quantity - 1;
      updateQuantity(index, newQuantity);
    }
  }

  // update total price preview before checkout
  double get totalPrice {
    return cartItems
        .where((item) => item.isSelected)
        .fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  // checkout selected items
  Future<void> checkout(List<CartItem> selectedItems) async {
    try {
      final selectedItemsJson = selectedItems.map((item) => {
        'pid': item.pid,
        'price': item.price.toString(),
        'quantity': item.quantity.toString(),
        'variation': item.variation,
        'total_unit_price': (item.price * item.quantity).toString(),
        'seller_id': item.sellerId,
        'cid': item.cartId,
      }).toList();

      final response = await _dio.post(
        '/mcheckout/${widget.userId}',
        data: {
          'shipping_fee': '40',
          'selected_items': jsonEncode(selectedItemsJson),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/x-www-form-urlencoded',
          },
        ),
      );

      print('Checkout response: ${response.data}');

      if (response.data['success'] == true) {
        final orderIds = response.data['order_ids'];
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CheckoutPage(
                totalAmount: totalPrice.toInt(),
                selectedItems: selectedItems,
                userId: widget.userId,
                orderIds: orderIds,
              ),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.data['message'] ?? 'Checkout failed')),
          );
        }
      }
    } catch (e) {
      print('Error during checkout: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to process checkout. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF4B4BB5),
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/images/white_back.png', width: 40, height: 40),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: kToolbarHeight + 8,
        title: Container(
          height: 48,
          padding: const EdgeInsets.only(right: 50),
          child: Center(
            child: Image.asset(
              'assets/images/logoo.png',
              height: 65,
              width: 100,
              fit: BoxFit.contain,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(child: Text(_error))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 25, bottom: 15),
                      child: Center(
                        child: RichText(
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                              fontFamily: 'Poppins',
                            ),
                            children: [
                              TextSpan(text: 'Shopping Cart'),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          return Container(
                            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white
                            ),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: item.isSelected,
                                  onChanged: (_) => toggleSelectItem(index),
                                  activeColor: const Color(0xFF4B4BB5),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: item.imageBase64.isNotEmpty
                                      ? Image.memory(
                                          base64Decode(item.imageBase64),
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
                                        item.name,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        item.variation,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '\u20b1${item.price.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: 'Arial',
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Row(
                                        children: [
                                          InkWell(
                                            onTap: () => decreaseQuantity(index),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.remove,
                                                size: 16,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            width: 28,
                                            height: 28,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              border: Border(
                                                left: BorderSide(color: Colors.grey[300]!),
                                                right: BorderSide(color: Colors.grey[300]!),
                                              ),
                                            ),
                                            child: Text(
                                              '${item.quantity}',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          InkWell(
                                            onTap: () => increaseQuantity(index),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              child: const Icon(
                                                Icons.add,
                                                size: 16,
                                                color: Colors.black54,
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
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 150,
                          height: 60,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF9898E3),
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(25)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(-1, -2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  const Text(
                                    'Total:',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Text(
                                    '\u20b1${totalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
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
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.2),
                            spreadRadius: 2,
                            blurRadius: 5,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Row(
                            children: [
                              Checkbox(
                                value: selectAll,
                                onChanged: (_) => toggleSelectAll(),
                                activeColor: const Color(0xFF4B4BB5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const Text(
                                'Select All',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topCenter,
                              child: Container(
                                width: 70,
                                height: 75,
                                child: TextButton(
                                  onPressed: removeSelectedItems,
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.zero,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      Image.asset('assets/images/trash.png', width: 35, height: 35),
                                      const SizedBox(height: 4),
                                      const Text(
                                        'Remove',
                                        style: TextStyle(
                                          color: Colors.red,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              final selectedItems = cartItems.where((item) => item.isSelected).toList();
                              if (selectedItems.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Please select items to checkout')),
                                );
                                return;
                              }
                              
                              checkout(selectedItems);
                            },
                            child: Container(
                              width: 150,
                              height: 100,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4B4BB5)
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/images/bag.png', width: 45, height: 45),
                                  const SizedBox(height: 4),
                                  const Text(
                                    'Checkout',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
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
}

class CartItem {
  final String cartId;
  final String pid;
  final String name;
  final double price;
  final String imageBase64;
  final String variation;
  final String sellerId;
  int quantity;
  bool isSelected;

  CartItem({
    required this.cartId,
    required this.pid,
    required this.name,
    required this.price,
    required this.imageBase64,
    required this.variation,
    required this.sellerId,
    this.quantity = 1,
    this.isSelected = false,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      cartId: json['cid'].toString(),
      pid: json['pid'].toString(),
      name: json['ptitle'] ?? '',
      price: double.tryParse(json['price']?.toString() ?? '0') ?? 0.00,
      imageBase64: json['image']?.toString() ?? '',
      variation: json['variation'] ?? '',
      sellerId: json['seller_id']?.toString() ?? '',
      quantity: int.tryParse(json['quantity']?.toString() ?? '1') ?? 1,
    );
  }
}


                              