import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LeadDetailPage extends StatefulWidget {
  final String leadName;

  const LeadDetailPage({super.key, required this.leadName});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  final Dio _dio = Dio();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  Map<String, dynamic>? _leadDetails;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchLeadDetails();
  }

  Future<void> _fetchLeadDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final sid = await _secureStorage.read(key: 'sid');
      if (sid == null) {
        Get.snackbar('Error', 'Session expired. Please log in again.');
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired.';
        });
        return;
      }

      final response = await _dio.get(
        'https://mysahayog.com/api/resource/Lead/${widget.leadName}',
        options: Options(
          headers: {'Cookie': 'sid=$sid'},
        ),
      );

      if (response.statusCode == 200) {
        setState(() {
          _leadDetails = response.data['data'];
        });
      } else {
        _errorMessage = 'Failed to fetch lead details: ${response.statusCode}';
      }
    } on DioException catch (e) {
      _errorMessage = e.response?.data['message'] ?? 'An error occurred while fetching lead details';
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
        title: Text(_isLoading || _leadDetails == null
            ? 'Lead Details'
            : _leadDetails!['first_name'] ?? 'Lead Details'),
        backgroundColor: const Color(0xFF006767),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text(_errorMessage))
              : _leadDetails == null
                  ? const Center(child: Text('Lead details not found.'))
                  : ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        const Text(
                          'Lead Details',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildLeadInfoTab(),
                        const SizedBox(height: 20),
                        const Text(
                          'Product Information',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildProductTab(),
                        const SizedBox(height: 20),
                        const Text(
                          'Appointment',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        _buildAppointmentTab(),
                      ],
                    ),
    );
  }

  Widget _buildLeadInfoTab() {
    return Card(
      margin: EdgeInsets.zero, // Remove default card margin if any
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Lead Name', _leadDetails!['first_name']),
            _buildDetailRow('Status', _leadDetails!['status']),
            _buildDetailRow('Branch', _leadDetails!['custom_branch']),
            _buildDetailRow('Source', _leadDetails!['source']),
            _buildDetailRow('Mobile No', _leadDetails!['mobile_no']),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    final List<dynamic>? products = _leadDetails!['custom_product_table'];

    if (products == null || products.isEmpty) {
      return const Center(child: Text('No products associated with this lead.'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: products.map((product) {
        final amount = (product['product_amount'] ?? 0.0) as num;
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Product Name', product['product_name']),
                _buildDetailRow('Amount', amount.toStringAsFixed(2)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAppointmentTab() {
    return const Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: EdgeInsets.all(12.0),
        child: Center(
          child: Text(
            'Appointment functionality coming soon.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value ?? 'N/A'),
          ),
        ],
      ),
    );
  }
}