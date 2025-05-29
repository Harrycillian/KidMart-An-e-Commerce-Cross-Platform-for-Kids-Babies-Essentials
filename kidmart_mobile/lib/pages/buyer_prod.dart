import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'dart:convert';
import 'dart:async';
import 'buyer_home.dart';
import 'buyer_cart.dart';
import 'buyer_checkout.dart';
import '../config/constants.dart';

class ProductDetailPage extends StatefulWidget {
  final Product product;
  final int userId;

  const ProductDetailPage({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late Future<Map<String, dynamic>> _productDetails;
  bool _isLoading = true;
  String _error = '';
  late Dio _dio;
  int _retryCount = 0;
  static const int maxRetries = 3;
  late Product _currentProduct;
  String? _selectedVariation;
  int _quantity = 1;
  bool _isDescriptionExpanded = false;
  static const Duration _timeout = Duration(seconds: 10);
  static const Duration _retryDelay = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _setupDio();
    _currentProduct = widget.product;
    _loadProductDetails();
  }

  void _setupDio() {
    _dio = Dio(BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: Duration(milliseconds: ApiConstants.connectionTimeout),
      receiveTimeout: Duration(milliseconds: ApiConstants.receiveTimeout),
      headers: {
        'Accept': 'application/json',
        'Connection': 'keep-alive',
        'Keep-Alive': 'timeout=60, max=1000',
        'Cache-Control': 'no-cache',
        'Content-Type': 'application/json',
      },
    ));

    _dio.interceptors.add(
      InterceptorsWrapper(
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.sendTimeout ||
              e.type == DioExceptionType.connectionError) {
            print('Dio error: ${e.type} - ${e.message}');
            return handler.next(e);
          }
          return handler.next(e);
        },
      ),
    );
  }

  @override
  void dispose() {
    _dio.close();
    super.dispose();
  }

  Future<Response> _makeRequest(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: Options(
          validateStatus: (status) => status! < 500,
          receiveTimeout: _timeout,
          sendTimeout: _timeout,
        ),
      );
    } on DioException catch (e) {
      print('Dio error: ${e.type} - ${e.message}');
      rethrow;
    }
  }

  // fetch product details based on Pid
  Future<void> _loadProductDetails() async {
    if (_retryCount >= maxRetries) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load product details after multiple attempts. Please try again later.';
        });
      }
      return;
    }

    try {
      print('Fetching product details for ID: ${widget.product.id} (Attempt ${_retryCount + 1})');
      
      final response = await _makeRequest(
        '/mview-product-details',
        queryParameters: {
          'pid': widget.product.id,
          'user_id': widget.userId,
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Raw response data: ${response.data}');
      
      if (response.statusCode == 200) {
        final data = response.data;
        print('Data received: ${data.keys}');
        
        if (data['status'] == 'success' && data['data'] != null) {
          final responseData = data['data'];
          print('Response data: $responseData');
          
          if (responseData['product'] == null) {
            throw Exception('Product data is null in response');
          }
          
          final productData = responseData['product'];
          print('Product data: $productData');
          
          if (productData['ptitle'] == null) {
            print('Warning: Product title is null, using fallback');
          }
          
          final variations = responseData['variations'] as List? ?? [];
          print('Raw variations data: $variations');
          
          double lowestPrice = double.infinity;
          if (variations.isNotEmpty) {
            for (var variation in variations) {
              print('Processing variation: $variation');
              print('Variation stocks: ${variation['pstocks']}');
              final price = double.tryParse(variation['price']?.toString() ?? '0') ?? 0.0;
              if (price < lowestPrice) {
                lowestPrice = price;
              }
            }
          }
          
          final price = lowestPrice != double.infinity 
              ? lowestPrice 
              : (double.tryParse(productData['pprice']?.toString() ?? '0') ?? widget.product.price);
          
          print('Final price: $price');
          
          final updatedProduct = Product(
            id: widget.product.id,
            name: productData['ptitle']?.toString() ?? widget.product.name,
            price: price,
            imageBase64: productData['pimage']?.toString() ?? widget.product.imageBase64,
            description: productData['pdesc']?.toString() ?? widget.product.description,
            rating: 0.0,
            numSold: int.tryParse(productData['num_sold']?.toString() ?? '0') ?? widget.product.numSold,
            sellerId: int.tryParse(productData['seller_ID']?.toString() ?? '0') ?? widget.product.sellerId,
            variations: variations.map((v) {
              print('Mapping variation: $v');
              print('Stocks value: ${v['pstocks']}');
              return {
                'name': v['variation']?.toString() ?? 'Unknown',
                'price': v['price']?.toString() ?? '0',
                'stocks': v['pstocks']?.toString() ?? '0',
              };
            }).toList(),
          );

          print('Updated product variations: ${updatedProduct.variations}');

          if (mounted) {
            setState(() {
              _productDetails = Future.value(responseData);
              _currentProduct = updatedProduct;
              _isLoading = false;
              _error = '';
              _retryCount = 0;
            });
          }
        } else {
          final errorMessage = data['message'] ?? 'Unknown error occurred';
          print('Error in response: $errorMessage');
          throw Exception(errorMessage);
        }
      } else {
        print('Error status code: ${response.statusCode}');
        print('Error response: ${response.data}');
        throw Exception('Failed to load product details: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading product details: $e');
      print('Error type: ${e.runtimeType}');
      _handleError('Failed to load product details. Retrying...');
    }
  }

  // variations of a certain product
  List<Map<String, dynamic>> _parseVariations(dynamic variationsData) {
    if (variationsData == null) return [];
    
    try {
      if (variationsData is List) {
        return variationsData.map((v) {
          if (v is Map<String, dynamic>) {
            return v;
          } else if (v is Map) {
            return Map<String, dynamic>.from(v);
          } else {
            return {'name': v.toString()};
          }
        }).toList();
      } else if (variationsData is Map) {
        return [Map<String, dynamic>.from(variationsData)];
      } else {
        return [{'name': variationsData.toString()}];
      }
    } catch (e) {
      print('Error parsing variations: $e');
      return [];
    }
  }

  void _handleError(String errorMessage) {
    if (!mounted) return;
    
    setState(() {
      _error = errorMessage;
      _isLoading = false;
    });
    
    if (_retryCount < maxRetries) {
      _retryCount++;
      final delay = Duration(seconds: _retryCount * 2);
      print('Retrying in ${delay.inSeconds} seconds...');
      
      Future.delayed(delay, () {
        if (mounted) {
          setState(() {
            _isLoading = true;
            _error = '';
          });
          _loadProductDetails();
        }
      });
    } else {
      setState(() {
        _error = 'Failed to load product details after multiple attempts. Please try again later.';
      });
    }
  }

  // show add to cart modal
  Future<void> _addToCart() async {
    if (_selectedVariation == null && _currentProduct.variations.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a variation first')),
      );
      return;
    }

    try {
      print('Adding to cart: ${_currentProduct.id}, ${_currentProduct.price}, $_selectedVariation, $_quantity, ${widget.userId}');
      
      final formData = FormData.fromMap({
        'pid': _currentProduct.id.toString(),
        'selected_price': _currentProduct.price.toString(),
        'selected_variation': _selectedVariation ?? '',
        'quantity': _quantity.toString(),
        'user_id': widget.userId.toString(),
      });

      final response = await _dio.post(
        '/madd_to_cart',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'multipart/form-data',
          },
        ),
      );

      print('Add to cart response: ${response.data}');
      
      final data = response.data;
      if (data['status'] == 'success') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'])),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['message'] ?? 'Failed to add item to cart')),
          );
        }
      }
    } catch (e) {
      print('Error adding to cart: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to add item to cart. Please try again.')),
        );
      }
    }
  }

  void _showAddToCartModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_currentProduct.variations.isNotEmpty) ...[
                const Text(
                  'Variations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _currentProduct.variations.map((variation) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildVariationButton(
                          variation['name']?.toString() ?? 'Unknown',
                          onPressed: () {
                            setModalState(() {
                              _selectedVariation = variation['name']?.toString() ?? 'Unknown';
                              _currentProduct = Product(
                                id: _currentProduct.id,
                                name: _currentProduct.name,
                                price: double.tryParse(variation['price']?.toString() ?? '0') ?? _currentProduct.price,
                                imageBase64: _currentProduct.imageBase64,
                                description: _currentProduct.description,
                                rating: _currentProduct.rating,
                                numSold: _currentProduct.numSold,
                                variations: _currentProduct.variations,
                                sellerId: _currentProduct.sellerId
                              );
                              _quantity = 1;
                            });
                            setState(() {});
                          },
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 150),
                Text(
                  'Stocks: ${_getMaxStocks()}',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    ),
                  ),
                ]
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) {
                          setModalState(() {
                            _quantity--;
                          });
                        }
                      },
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
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final maxStocks = _getMaxStocks();
                        if (_quantity < 50 && (_quantity < maxStocks || maxStocks == 0)) {
                          setModalState(() {
                            _quantity++;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                maxStocks == 0
                                    ? 'Maximum allowed is 50'
                                    : 'Only ${maxStocks < 50 ? maxStocks : 50} items left in stock',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _addToCart();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B4BB5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add to Cart',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showBuyNowModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_currentProduct.variations.isNotEmpty) ...[
                const Text(
                  'Variations',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _currentProduct.variations.map((variation) => 
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: _buildVariationButton(
                          variation['name']?.toString() ?? 'Unknown',
                          onPressed: () {
                            setModalState(() {
                              _selectedVariation = variation['name']?.toString() ?? 'Unknown';
                              _currentProduct = Product(
                                id: _currentProduct.id,
                                name: _currentProduct.name,
                                price: double.tryParse(variation['price']?.toString() ?? '0') ?? _currentProduct.price,
                                imageBase64: _currentProduct.imageBase64,
                                description: _currentProduct.description,
                                rating: _currentProduct.rating,
                                numSold: _currentProduct.numSold,
                                variations: _currentProduct.variations,
                                sellerId: _currentProduct.sellerId
                              );
                              _quantity = 1;
                            });
                            setState(() {});
                          },
                        ),
                      ),
                    ).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              Row(
                children: [
                const Text(
                  'Quantity',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 150),
                Text(
                  'Stocks: ${_getMaxStocks()}',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                    ),
                  ),
                ]
              ),
              const SizedBox(height: 8),
              Container(
                width: 140,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    InkWell(
                      onTap: () {
                        if (_quantity > 1) {
                          setModalState(() {
                            _quantity--;
                          });
                        }
                      },
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
                      width: 50,
                      alignment: Alignment.center,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        final maxStocks = _getMaxStocks();
                        if (_quantity < 50 && (_quantity < maxStocks || maxStocks == 0)) {
                          setModalState(() {
                            _quantity++;
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                maxStocks == 0
                                    ? 'Maximum allowed is 50'
                                    : 'Only ${maxStocks < 50 ? maxStocks : 50} items left in stock',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _BuyNow();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4B4BB5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Buy Now',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // show buy now modal
  void _BuyNow() async {
    if (_selectedVariation == null && _currentProduct.variations.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a variation first')),
      );
      return;
    }

    try {
      final response = await _dio.post(
        '/mbuy_now',
        data: {
          'user_id': widget.userId,
          'pid': _currentProduct.id,
          'selected_variation': _selectedVariation ?? '',
          'selected_price': _currentProduct.price,
          'quantity': _quantity,
        },
      );

      print('Buy Now Response: ${response.data}');

      if (response.data['order_id'] != null) {
        final cartItem = CartItem(
          cartId: '0',
          pid: _currentProduct.id.toString(),
          name: _currentProduct.name,
          price: _currentProduct.price,
          imageBase64: _currentProduct.imageBase64,
          variation: _selectedVariation ?? '',
          sellerId: _currentProduct.sellerId.toString(),
          quantity: _quantity,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CheckoutPage(
              totalAmount: (_currentProduct.price * _quantity).toInt(),
              selectedItems: [cartItem],
              userId: widget.userId,
              orderIds: [response.data['order_id']],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.data['message'] ?? 'Failed to process order')),
        );
      }
    } catch (e) {
      print('Buy Now Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process order. Please try again.')),
      );
    }
  }

  Map<String, dynamic>? _getSelectedVariation() {
    if (_selectedVariation == null) return null;
    try {
      print('Getting variation for: $_selectedVariation');
      print('Available variations: ${_currentProduct.variations}');
      final variation = _currentProduct.variations.firstWhere(
        (v) => v['name']?.toString() == _selectedVariation,
      );
      print('Found variation: $variation');
      return variation;
    } catch (e) {
      print('Error getting variation: $e');
      return null;
    }
  }

  // stocks of selected variation
  int _getMaxStocks() {
    final variation = _getSelectedVariation();
    if (variation == null) {
      print('No variation found, returning 0 stocks');
      return 0;
    }
    final stocks = variation['stocks']?.toString() ?? '0';
    print('Raw stocks value: $stocks');
    final maxStocks = int.tryParse(stocks) ?? 0;
    print('Parsed max stocks: $maxStocks');
    return maxStocks;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Image.asset('assets/images/prod_back.png',width: 40, height: 40),
          onPressed: () => Navigator.pop(context),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      if (_retryCount < maxRetries) ...[
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isLoading = true;
                              _error = '';
                            });
                            _loadProductDetails();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 400,
                        width: double.infinity,
                        color: Colors.grey[50],
                        child: Image.memory(
                          base64Decode(_currentProduct.imageBase64),
                          fit: BoxFit.contain,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentProduct.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '\u20B1${_currentProduct.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                                fontFamily: 'Calibri',
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Description',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _currentProduct.description,
                                    maxLines: _isDescriptionExpanded ? null : 3,
                                    overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontFamily: 'Arial',
                                      height: 1.3,
                                      color: Color(0xFF666666),
                                    ),
                                    textAlign: TextAlign.justify,
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isDescriptionExpanded = !_isDescriptionExpanded;
                                      });
                                    },
                                    child: Text(
                                      _isDescriptionExpanded ? 'See Less' : 'See More',
                                      style: const TextStyle(color: Color(0xFF4B4BB5)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                              thickness: 1,
                              color: Color(0xDD444444),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Ratings',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  children: [
                                    Text(
                                      '${_currentProduct.rating.toStringAsFixed(1)} / 5',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Icon(
                                      Icons.star,
                                      color: Colors.amber,
                                      size: 20,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            SizedBox(height: 10),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _productDetails,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }
                                if (!snapshot.hasData || snapshot.data == null || snapshot.data!['reviews'] == null) {
                                  return const Center(
                                    child: Text(
                                      '\n\nNo reviews yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                    ),
                                  );
                                }
                                final reviews = snapshot.data!['reviews'] as List<dynamic>;
                                if (reviews.isEmpty) {
                                  return const Center(
                                    child: Text(
                                      'No reviews yet.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
                                    ),
                                  );
                                }
                                return Column(
                                  children: reviews.map((review) {
                                    return Container(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.grey.withOpacity(0.08),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                'Rating: ${review['feedback_rating']}/5',
                                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                                              ),
                                              const SizedBox(width: 4),
                                              const Icon(Icons.star, color: Colors.amber, size: 18),
                                            ],
                                          ),
                                          if (review['review_img'] != null && review['review_img'].toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.memory(
                                                  base64Decode(review['review_img']),
                                                  height: 60,
                                                  width: 60,
                                                  fit: BoxFit.cover,
                                                ),
                                              ),
                                            ),
                                          if (review['feedback_review'] != null && review['feedback_review'].toString().isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4.0),
                                              child: Text(
                                                review['feedback_review'],
                                                style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _showAddToCartModal,
                  icon: const Icon(Icons.shopping_cart_outlined),
                  label: const Text('Add to Cart',
                  style: TextStyle(
                    color: Color(0xFF4B4BB5),
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    side: const BorderSide(color: Color(0xFF4B4BB5)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _showBuyNowModal,
                  icon: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
                  label: const Text('Buy Now',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Color(0xFF4B4BB5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildVariationButton(String text, {VoidCallback? onPressed}) {
    final isSelected = _selectedVariation == text;
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          side: BorderSide(
            color: isSelected ? const Color(0xFF4B4BB5) : Colors.grey[300]!,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? const Color(0xFF4B4BB5) : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}