import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

class NewLeadPage extends StatefulWidget {
  final VoidCallback onLeadCreated;
  final Map<String, dynamic>? initialLeadData;

  const NewLeadPage({
    super.key,
    required this.onLeadCreated,
    this.initialLeadData,
  });

  @override
  State<NewLeadPage> createState() => _NewLeadPageState();
}

class _NewLeadPageState extends State<NewLeadPage> {
  final _formKey = GlobalKey<FormState>();
  final _dio = dio_package.Dio();
  final _secureStorage = const FlutterSecureStorage();

  // Form Controllers
  final _firstNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _productAmountController = TextEditingController();

  // State for Dropdowns
  String? _selectedStatus;
  String? _selectedSource;
  String? _selectedProduct;
  String? _selectedProductName;

  // State for lead sources dropdown
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _leadSources = [];
  // ignore: prefer_final_fields
  bool _sourcesLoading = true;

  // State for products dropdown
  // ignore: prefer_final_fields
  List<Map<String, dynamic>> _products = [];
  // ignore: prefer_final_fields
  bool _productsLoading = true;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLeadSources();
    _fetchProducts();

    if (widget.initialLeadData != null) {
      _firstNameController.text = widget.initialLeadData!['first_name'] ?? '';
      _phoneController.text = widget.initialLeadData!['mobile_no'] ?? '';
      _selectedStatus = widget.initialLeadData!['status'];
      _selectedSource = widget.initialLeadData!['source'];

      // Handle product table if it exists
      final productTable = widget.initialLeadData!['custom_product_table'];
      if (productTable != null && productTable.isNotEmpty) {
        final product = productTable[0]; // Assuming only one product per lead for simplicity
        _selectedProduct = product['product'];
        _selectedProductName = product['product_name'];
        _productAmountController.text = product['product_amount']?.toString() ?? '';
      }
    }
  }

  Future<void> _fetchLeadSources() async {
    // ... (omitted for brevity, already implemented)
    setState(() {
      _sourcesLoading = true;
    });
    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired.');
        setState(() => _sourcesLoading = false);
        return;
      }
      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Lead Source',
        queryParameters: {
          'fields': jsonEncode(['name']),
        },
        options: dio_package.Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200 && response.data['data'] is List) {
        setState(() {
          _leadSources = List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } on dio_package.DioException catch (e) {
      Get.snackbar('Error',
          e.response?.data['message'] ?? 'Could not fetch lead sources.');
    } finally {
      setState(() {
        _sourcesLoading = false;
      });
    }
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _productsLoading = true;
    });
    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired.');
        setState(() => _productsLoading = false);
        return;
      }
      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Product',
        queryParameters: {
          'fields': jsonEncode(['name', 'product_name']),
          'limit_page_length': 100
        },
        options: dio_package.Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200 && response.data['data'] is List) {
        setState(() {
          _products = List<Map<String, dynamic>>.from(response.data['data']);
        });
      }
    } on dio_package.DioException catch (e) {
      Get.snackbar(
          'Error', e.response?.data['message'] ?? 'Could not fetch products.');
    } finally {
      setState(() {
        _productsLoading = false;
      });
    }
  }

  Future<void> _saveLead() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired. Please log in again.');
        setState(() {
          _isLoading = false;
        });
        return;
      }

      final isUpdating = widget.initialLeadData != null;
      final String apiUrl;
      final String successMessage;
      final String errorMessage;
      final String requestMethod;

      if (isUpdating) {
        final leadName = widget.initialLeadData!['name'];
        apiUrl = 'https://mysahayog.com/api/resource/Lead/$leadName';
        successMessage = 'Lead updated successfully';
        errorMessage = 'Failed to update lead';
        requestMethod = 'PUT'; // Frappe uses PUT for updates
      } else {
        apiUrl = 'https://mysahayog.com/api/resource/Lead';
        successMessage = 'Lead created successfully';
        errorMessage = 'Failed to create lead';
        requestMethod = 'POST';
      }

      final leadData = {
        'doctype': 'Lead',
        'first_name': _firstNameController.text,
        'mobile_no': _phoneController.text,
        'status': _selectedStatus,
        'source': _selectedSource,
        'custom_product_table': [
          {
            'product': _selectedProduct,
            'product_name': _selectedProductName,
            'product_amount': _productAmountController.text,
          }
        ]
      };

      dio_package.Response response; // Specify Dio's Response
      if (requestMethod == 'PUT') {
        response = await _dio.put(
          apiUrl,
          data: leadData,
          options: dio_package.Options(
            headers: {'Cookie': 'sid=$sid'},
            contentType: 'application/json',
          ),
        );
      } else {
        response = await _dio.post(
          apiUrl,
          data: leadData,
          options: dio_package.Options(
            headers: {'Cookie': 'sid=$sid'},
            contentType: 'application/json',
          ),
        );
      }

      if (response.statusCode == 200) {
        widget.onLeadCreated(); // This callback will now also act as onLeadUpdated
        Get.back();
        Get.snackbar('Success', successMessage);
      } else {
        Get.snackbar('Error', '$errorMessage: ${response.statusMessage}');
      }
        } on dio_package.DioException catch (e) {
          Get.snackbar(
              'Error', e.response?.data?['message'] ?? 'An error occurred');
        } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialLeadData != null ? 'Edit Lead' : 'New Lead'),
        backgroundColor: const Color(0xFF006767),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                hint: const Text('Select Status'),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value;
                  });
                },
                items: ['Lead', 'Converted', 'Follow Up', 'Not Interested']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'Please select a status' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedSource,
                decoration: InputDecoration(
                  labelText: 'Lead Source',
                  suffixIcon: _sourcesLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.0)),
                        )
                      : null,
                ),
                hint: const Text('Select Source'),
                onChanged: _sourcesLoading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedSource = value;
                        });
                      },
                items: _leadSources.map<DropdownMenuItem<String>>((source) {
                  return DropdownMenuItem<String>(
                    value: source['name'],
                    child: Text(source['name'] as String),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'Please select a source' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
                keyboardType: TextInputType.phone,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a phone number' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: _selectedProduct,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: 'Product',
                  suffixIcon: _productsLoading
                      ? const Padding(
                          padding: EdgeInsets.all(10.0),
                          child: SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(strokeWidth: 2.0)),
                        )
                      : null,
                ),
                hint: const Text('Select Product'),
                onChanged: _productsLoading
                    ? null
                    : (value) {
                        final selected =
                            _products.firstWhere((p) => p['name'] == value);
                        setState(() {
                          _selectedProduct = value;
                          _selectedProductName = selected['product_name'];
                        });
                      },
                items: _products.map<DropdownMenuItem<String>>((product) {
                  return DropdownMenuItem<String>(
                    value: product['name'],
                    child:
                        Text("${product['name']} - ${product['product_name']}"),
                  );
                }).toList(),
                validator: (value) =>
                    value == null ? 'Please select a product' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _productAmountController,
                decoration: const InputDecoration(labelText: 'Product Amount'),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a product amount' : null,
              ),
              const SizedBox(height: 32),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _saveLead,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF006767),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 50, vertical: 15),
                        ),
                        child: const Text('Save',
                            style: TextStyle(color: Colors.white)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
