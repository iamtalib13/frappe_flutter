import 'package:flutter/material.dart';
import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/models/sync_status.dart';
import 'package:frappe_flutter/services/isar_service.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart' as dio_package;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:frappe_flutter/error_page.dart';

class NewLeadPage extends StatefulWidget {
  final VoidCallback onLeadCreated;
  final Lead? initialLeadData;

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
  final _isarService = IsarService();

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
    _initDataAndPrefill();
  }

  Future<void> _initDataAndPrefill() async {
    // Fetch sources and products first
    await _fetchLeadSources();
    await _fetchProducts();

    if (widget.initialLeadData != null) {
      final lead = widget.initialLeadData!;
      _firstNameController.text = lead.firstName;
      _phoneController.text = lead.mobileNo ?? '';
      _productAmountController.text = lead.productAmount?.toString() ?? '';
      _selectedStatus = lead.status;
      _selectedSource = lead.source;
      _selectedProduct = lead.product;
      _selectedProductName = lead.productName;
      setState(() {}); // Trigger rebuild to update dropdowns
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
      Get.offAll(() => ErrorPage(errorMessage: e.response?.data['message'] ?? 'Failed to fetch lead sources. Contact admin.'));
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
      Get.offAll(() => ErrorPage(errorMessage: e.response?.data['message'] ?? 'Failed to fetch products. Contact admin.'));
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

    final isUpdating = widget.initialLeadData != null;

    final leadToSave = isUpdating ? widget.initialLeadData! : Lead();

    leadToSave
      ..firstName = _firstNameController.text
      ..mobileNo = _phoneController.text
      ..status = _selectedStatus
      ..source = _selectedSource
      ..product = _selectedProduct
      ..productName = _selectedProductName
      ..productAmount = double.tryParse(_productAmountController.text) ?? 0.0
      ..syncStatus = SyncStatus.pending
      ..lastModified = DateTime.now();

    await _isarService.saveLead(leadToSave);

    widget.onLeadCreated();
    Get.back(result: true);
    Get.snackbar(
        'Success', isUpdating ? 'Lead updated locally.' : 'Lead saved locally.');

    setState(() {
      _isLoading = false;
    });
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
