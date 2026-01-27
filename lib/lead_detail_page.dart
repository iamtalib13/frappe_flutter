import 'package:flutter/material.dart';
import 'package:frappe_flutter/models/lead_model.dart';
import 'package:frappe_flutter/services/isar_service.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:frappe_flutter/new_lead_page.dart';

class LeadDetailPage extends StatefulWidget {
  final String leadName;

  const LeadDetailPage({super.key, required this.leadName});

  @override
  State<LeadDetailPage> createState() => _LeadDetailPageState();
}

class _LeadDetailPageState extends State<LeadDetailPage> {
  final IsarService _isarService = IsarService();
  Lead? _leadDetails;
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
      final lead = await _isarService.getLeadByName(widget.leadName);
      if (lead != null) {
        setState(() {
          _leadDetails = lead;
        });
      } else {
        _errorMessage = 'Failed to fetch lead details';
      }
    } catch (e) {
      _errorMessage = 'An error occurred while fetching lead details';
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
            : _leadDetails!.firstName),
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
      floatingActionButton: _leadDetails != null
          ? FloatingActionButton.extended(
              onPressed: () async {
                if (_leadDetails != null) {
                  final result = await Get.to(() => NewLeadPage(
                        initialLeadData: _leadDetails,
                        onLeadCreated:
                            () {}, // This is not used anymore, but it is required
                      ));
                  if (result == true) {
                    _fetchLeadDetails();
                  }
                }
              },
              label: const Text('Update Lead'),
              icon: const Icon(Icons.edit),
              backgroundColor: const Color(0xFF006767),
            )
          : null,
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
            _buildDetailRow('Lead Name', _leadDetails!.firstName),
            _buildDetailRow('Status', _leadDetails!.status),
            _buildDetailRow('Source', _leadDetails!.source),
            _buildDetailRow('Mobile No', _leadDetails!.mobileNo),
          ],
        ),
      ),
    );
  }

  Widget _buildProductTab() {
    if (_leadDetails!.productName == null) {
      return const Center(
          child: Text('No products associated with this lead.'));
    }

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Product Name', _leadDetails!.productName),
            _buildDetailRow(
                'Amount', _leadDetails!.productAmount!.toStringAsFixed(2)),
          ],
        ),
      ),
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
